package Mogura::Server::API;
use Mojo::Base -strict;
use Mojo::File qw(path);
use Mojo::Asset::File;
use Mojo::JSON qw(to_json);
use Mojo::IOLoop::Subprocess;
use Fcntl qw(:flock);
use Scalar::Util qw(weaken);
use Mogura::Protocol qw(valid_id artifact_name);
use Mogura::Server::Results;

use constant ARTIFACT_LIMIT => 4 * 1024**3;

sub register {
    my ($class, $app) = @_;
    my $store = $app->store;
    my $receiving = 0;
    my $validating = 0;
    my $incoming = path($store->state, 'incoming')->make_path({mode => 0700});

    # Serialize allocation and startup sweeping across servers using this state.
    # A validation subprocess inherits the asset lock until it finishes.
    open my $directory_lock, '<', $incoming or die "Open incoming directory: $!";
    flock($directory_lock, LOCK_EX) or die "Lock incoming directory: $!";
    for my $file ($incoming->list->each) {
        next unless $file->basename =~ /\Amojo\.tmp\.[A-Za-z0-9_]+\z/;
        open my $fh, '<', $file or next;
        unlink $file if flock($fh, LOCK_EX | LOCK_NB);
    }
    flock($directory_lock, LOCK_UN) or die "Unlock incoming directory: $!";
    $app->hook(
        after_build_tx => sub {
            my ($tx) = @_;
            weaken($tx);
            $tx->req->content->once(
                body => sub {
                    my ($content) = @_;
                    my $req = $tx->req;
                    return
                        unless $req->method eq 'PUT'
                        && $req->url->path->to_string =~
                        m{\A/api/jobs/([a-f0-9]{32})/([a-f0-9]{32})/files/(syft|cdx|grype|log)\z};
                    my ($id, $run) = ($1, $2);
                    my $headers = $req->headers;
                    my $size = $headers->content_length // '';
                    my $scanner = $store->authenticate($headers->authorization);
                    return
                        unless _secure_connection($tx)
                        && defined($scanner)
                        && $store->owns($scanner, $id, $run);
                    return unless $size =~ /\A[0-9]{1,10}\z/ && $size <= ARTIFACT_LIMIT;
                    return
                        if $headers->transfer_encoding
                        || $headers->content_encoding
                        || ($headers->content_type // '') ne 'application/octet-stream';
                    return if $receiving >= 2;
                    ++$receiving;
                    $tx->once(finish => sub { --$receiving });
                    $tx->{mogura_upload} = 1;
                    my $asset = Mojo::Asset::File->new(tmpdir => "$incoming");
                    flock($directory_lock, LOCK_EX) or die "Lock incoming directory: $!";
                    my $locked =
                        eval { flock($asset->handle, LOCK_EX) or die "Lock upload: $!"; 1 };
                    my $error = $@;
                    flock($directory_lock, LOCK_UN) or die "Unlock incoming directory: $!";
                    die $error unless $locked;
                    $content->auto_upgrade(0)->asset($asset);
                    $req->max_message_size($size + 16384);
                }
            );
        }
    );

    my $api = $app->routes->under('/api')->to(
        cb => sub {
            my ($c) = @_;
            my $id = $store->authenticate($c->req->headers->authorization);
            unless (defined $id && _secure_connection($c->tx)) {
                $c->render(status => 401, json => {});
                return undef;
            }
            $c->stash(scanner => $id);
            return 1;
        }
    );
    $api->get('/identity')->to(
        cb => sub {
            my ($c) = @_;
            $c->render(
                json => {
                    scanner => $c->stash('scanner'),
                    server =>
                        scalar $store->db->selectrow_array(
                        "SELECT value FROM settings WHERE name='id'")
                }
            );
        }
    );
    $api->post('/inventory')->to(
        cb => sub {
            my ($c) = @_;
            my $inv = $c->req->json;
            return $c->render(status => 400, json => {}) unless _valid_inventory($inv);
            $store->db->do('UPDATE scanners SET seen=?,inventory=? WHERE id=?',
                undef, time, to_json($inv), $c->stash('scanner'));
            return $c->render(
                json => {cancel => $store->pending_cancellations($c->stash('scanner'))});
        }
    );
    $api->get('/jobs')->to(
        cb => sub {
            my ($c) = @_;
            $c->render(json => {job => scalar $store->offer($c->stash('scanner'))});
        }
    );
    my $job = $api->under('/jobs/:id/:run')->to(
        cb => sub {
            my ($c) = @_;
            return 1 if valid_id($c->stash('id')) && valid_id($c->stash('run'));
            $c->render(status => 400, json => {});
            return undef;
        }
    );
    $job->post('/claim')->to(
        cb => sub {
            my ($c) = @_;
            my $ok = $store->claim(map { $c->stash($_) } qw(scanner id run));
            $c->render(
                status => ($ok // '') eq 'expired' ? 410 : $ok ? 200 : 409,
                json => {
                    id => $c->stash('id'),
                    run => $c->stash('run'),
                    cancel => ($ok // '') eq 'cancel' ? 1 : 0
                }
            );
        }
    );
    for my $action (qw(progress complete)) {
        $job->post("/$action")->to(
            cb => sub {
                my ($c) = @_;
                my $record = $c->req->json;
                return $c->render(status => 400, json => {})
                    unless ref $record eq 'HASH'
                    && ($record->{sequence} // '') =~ /\A[1-9][0-9]{0,9}\z/
                    && ref($record->{warnings} // []) eq 'ARRAY'
                    && (!defined $record->{grype_db} || ref($record->{grype_db}) eq 'HASH');
                my $ok = $store->update_run((map { $c->stash($_) } qw(scanner id run)),
                    $record, $action eq 'complete');
                $c->render(
                    status => $ok ? 200 : 409,
                    json => {id => $c->stash('id'), run => $c->stash('run'), action => $action}
                );
            }
        );
    }
    $job->put('/files/:kind')->to(
        cb => sub {
            my ($c) = @_;
            my ($scanner, $id, $run, $kind) = map { $c->stash($_) } qw(scanner id run kind);
            return $c->render(status => 403, json => {}) unless $store->owns($scanner, $id, $run);
            return $c->render(status => 400, json => {}) unless artifact_name($kind);
            return $c->render(status => 429, json => {}) unless $c->tx->{mogura_upload};
            my $asset = $c->req->content->asset;
            my $size = $c->req->headers->content_length;
            my $hash = $c->req->headers->header('X-Content-SHA256') // '';
            return $c->render(status => 400, json => {})
                unless $hash =~ /\A[a-f0-9]{64}\z/ && $asset->size == $size;
            return $c->render(status => 429, json => {}) if $validating >= 2;
            ++$validating;
            $c->render_later;
            Mojo::IOLoop::Subprocess->new->run(
                sub {
                    $store->receive($scanner, $id, $run, $kind, $asset->path, $size, $hash);
                    return 1;
                },
                sub {
                    my (undef, $error) = @_;
                    --$validating;
                    if ($error) { $app->log->error("Upload $id/$kind: $error"); }
                    $c->render(
                        status => $error ? 409 : 200,
                        json => $error
                        ? {}
                        : {id => $id, run => $run, kind => $kind, sha256 => $hash}
                    );
                }
            );
        }
    );

    # A single background builder resumes pending receipts after server restart.
    my $building;
    Mojo::IOLoop->recurring(
        1 => sub {
            return if $building;
            my $item = $store->db->selectrow_hashref(
                q{SELECT job,kind FROM receipts WHERE indexed=0 AND kind IN ('syft','grype') LIMIT 1}
            ) or return;
            my ($id, $kind) = @$item{qw(job kind)};
            my $results = Mogura::Server::Results->new(state => $store->state);
            my $file = $results->location($id, $kind);
            my $lock = $results->build_lock($file) or return;
            $building = 1;
            Mojo::IOLoop::Subprocess->new->run(
                sub {
                    my $source = $store->artifact($id, $kind);
                    $results->build(
                        $source, $file, $kind,
                        $results->revision($source),
                        lock => $lock
                    );
                },
                sub {
                    my (undef, $error) = @_;
                    $app->log->error("Index $id/$kind: $error") if $error;
                    $store->db->do(
                        'UPDATE receipts SET indexed=? WHERE job=? AND kind=?',
                        undef, $error ? -1 : 1,
                        $id, $kind
                    );
                    $building = 0;
                }
            );
        }
    );
}

sub _secure_connection {
    my ($tx) = @_;
    my $peer = $tx->original_remote_address // '';
    return ($tx->req->url->base->scheme // '') eq 'https' || $peer eq '127.0.0.1' || $peer eq '::1';
}

sub _valid_inventory {
    my ($inv) = @_;
    return unless ref $inv eq 'HASH' && ref $inv->{disks} eq 'ARRAY';
    for my $key (qw(blocked errors)) { return unless ref($inv->{$key} // []) eq 'ARRAY' }
    my @targets;
    for my $disk (@{$inv->{disks}}) {
        return
            unless ref $disk eq 'HASH'
            && ref $disk->{targets} eq 'ARRAY'
            && ref($disk->{reasons} // []) eq 'ARRAY';
        push @targets, @{$disk->{targets}};
    }
    push @targets, $inv->{host} if defined $inv->{host};
    for my $target (@targets) {
        return
            unless ref $target eq 'HASH'
            && ref($target->{reasons} // []) eq 'ARRAY'
            && ref($target->{mountpoints} // []) eq 'ARRAY';
        next unless $target->{selectable};
        return
            unless ($target->{token} // '') =~ /\A[a-f0-9]{64}\z/
            && ref $target->{identity} eq 'HASH';
        return
            unless ref $target->{identity}{disk} eq 'HASH'
            && ref $target->{identity}{partition} eq 'HASH';
    }
    return 1;
}
1;
