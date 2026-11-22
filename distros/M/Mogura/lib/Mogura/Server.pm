package Mogura::Server;
use Mojo::Base 'Mojolicious';
use utf8;

use Mojo::File qw(path);
use Mojo::IOLoop::Subprocess;

use Cwd qw(abs_path);
use Mogura::Protocol qw(random_id valid_id);
use Mogura::Server::API;
use Mogura::Server::I18N;

use Mogura::Server::Store;
use Mogura::Server::Results;

has store => sub { Mogura::Server::Store->new };
my $assets = path(abs_path(__FILE__))->sibling('Server');
sub assets { $assets }

sub startup {
    my ($self) = @_;

    $self->renderer->paths([Mogura::Server::assets()->child('templates')->to_string]);
    $self->static->paths([Mogura::Server::assets()->child('public')->to_string]);
    $self->store->initialize;
    $self->mode('production');
    $self->secrets(
        [
            scalar $self->store->db->selectrow_array(
                "SELECT value FROM settings WHERE name='session'")
        ]
    );
    $self->sessions->cookie_name('mogura_session');
    $self->sessions->samesite('Strict');
    $self->max_request_size(262144);
    Mogura::Server::API->register($self);
    Mogura::Server::I18N->register($self);
    $self->_register_display_helpers;
    $self->hook(before_dispatch => sub { $self->_protect_request(@_) });

    my $routes = $self->routes;
    $routes->get('/')->to(cb => sub { $self->_show_index(@_) });
    $routes->get('/inventory')->to(
        cb => sub {
            my ($controller) = @_;
            $controller->res->headers->cache_control('no-store');
            $self->_inventory_page($controller);
            $controller->render(template => 'inventory');
        }
    );
    $routes->get('/history')->to(cb => sub { $self->_show_history(@_) });
    $routes->post('/scans')->to(cb => sub { $self->_start_scan(@_) });
    $routes->post('/scans/:id/cancel')->to(
        cb => sub {
            my ($c) = @_;
            return $c->render(status => 403, text => $c->l('invalid_csrf'))
                if $c->validation->csrf_protect->has_error('csrf_token');
            my $id = $c->stash('id');
            return $c->reply->not_found unless $self->store->cancel($id);
            $c->res->code(303);
            return $c->redirect_to("/scans/$id");
        }
    );
    $routes->get('/scans/:id')->to(cb => sub { $self->_show_scan(@_) });
    $routes->post('/scans/:id/tags')->to(cb => sub { $self->_update_tags(@_) });
    $routes->post('/scans/:id/note')->to(cb => sub { $self->_update_note(@_) });
    $routes->get('/scans/:id/download/:kind')->to(cb => sub { $self->_download_artifact(@_) });
    $routes->get('/scans/:id/results/:kind')->to(cb => sub { $self->_result_page(@_) });
    $routes->post('/scans/:id/results/:kind/rebuild')->to(cb => sub { $self->_rebuild_result(@_) });
    $routes->get('/scans/:id/results/:kind/build')
        ->to(cb => sub { $self->_result_build_status(@_) });
}

sub _register_display_helpers {
    my ($self) = @_;

    $self->helper(
        display => sub {
            my ($controller, $value) = @_;
            return $controller->l('unknown')
                unless defined $value && !ref($value) && length($value);
            return $value;
        }
    );

    $self->helper(
        label => sub {
            my ($controller, $value) = @_;
            return $controller->l('unknown') unless defined $value && length $value;
            return $controller->l($value);
        }
    );
    $self->helper(
        exclusion_reasons => sub {
            my ($controller, $reasons) = @_;
            return $self->_exclusion_reasons($controller, $reasons);
        }
    );
}

sub _exclusion_reasons {
    my ($self, $controller, $reasons) = @_;

    # Several partitions can report the same disk-wide exclusion. Present each
    # reason once while preserving the original diagnostic data in inventory.
    my @labels = (
        [
            qr/\A(?:Mounted filesystem|Scanner storage:|Active swap|Referenced)/,
            $controller->l('in_use')
        ],
        [qr/\ANo hardware serial/, $controller->l('no_identity')],
        [
            qr/\A(?:Ambiguous filesystem|Partition table present)/,
            $controller->l('ambiguous_layout')
        ],
        [qr/\AOnly ext4/, $controller->l('unsupported_filesystem')],
        [qr/\ABIOS boot partition:/, $controller->l('bios_boot')],
        [qr/\ACannot resolve scanner storage:/, $controller->l('storage_unresolved')],
    );
    my %seen;
    my @translated;
    for my $reason (@$reasons) {
        my $label = $reason;
        for my $translation (@labels) {
            next unless $reason =~ $translation->[0];
            $label = $translation->[1];
            last;
        }

        # Keep the device and detected layout visible instead of collapsing
        # distinct unsupported partitions into a single generic label.
        if ($label =~ /\AUnsupported partition table/) {
            $label =~ s/\AUnsupported partition table/$controller->l('unsupported_table')/e;
        }
        elsif ($label =~ /\AUnsupported or unknown partition/) {
            $label =~
                s/\AUnsupported or unknown partition/$controller->l('unsupported_partition')/e;
        }
        else {
            $label =~ s/\AUnsupported/$controller->l('unsupported_layout')/e;
        }
        push @translated, $label unless $seen{$label}++;
    }
    return \@translated;
}

sub _protect_request {
    my ($self, $controller) = @_;

    my $headers = $controller->res->headers;
    $headers->header(
        'Content-Security-Policy' => join(
            '; ',
            "default-src 'none'",
            "style-src 'self'",

            "script-src 'self'",
            "worker-src 'self'",
            "connect-src 'self'",
            "form-action 'self'",
            "frame-ancestors 'none'",
            "base-uri 'none'",
        )
    );
    $headers->header('X-Content-Type-Options' => 'nosniff');
    $headers->header('Referrer-Policy' => 'no-referrer');
    $headers->cache_control('no-store');
}

sub _inventory_page {
    my ($self, $controller) = @_;
    my $page = $self->_page_number($controller->param('page'));
    my $items = $self->store->inventories($page);
    my $more = @$items > 4;
    pop @$items if $more;
    $controller->stash(inventory => $items, page => $page, more => $more);
}

sub _show_index {
    my ($self, $controller) = @_;

    $self->_inventory_page($controller);
    $controller->stash(scan_id => random_id());
    $controller->render(template => 'index');
}

sub _show_history {
    my ($self, $controller) = @_;

    my $tag = substr($controller->param('tag') // '', 0, 120);
    my $page = $self->_page_number($controller->param('page'));
    my $history = $self->store->history($tag, $page);
    my $has_more = @$history > 50;
    pop @$history if $has_more;

    $controller->stash(
        history => $history,
        tag => $tag,
        page => $page,
        more => $has_more,
    );
    $controller->render(template => 'history');
}

sub _start_scan {
    my ($self, $controller) = @_;

    return $controller->render(text => $controller->l('invalid_csrf'), status => 403)
        if $controller->validation->csrf_protect->has_error('csrf_token');
    my @tags = @{$controller->every_param('tags')};
    my $draft_tag = $controller->param('new_tag') // '';
    push @tags, $draft_tag if $draft_tag =~ /\S/;
    my $request = {
        id => $controller->param('scan_id'),
        tags => eval { Mogura::Server::Tags->validate(\@tags) },
        note => $controller->param('note') // '',
        token => $controller->param('target'),
    };
    return $controller->render(text => $controller->l('invalid_tags'), status => 400)
        unless defined $request->{tags};
    my ($scanner, $token) = split /:/, $request->{token} // '', 2;
    return $controller->render(text => $controller->l('invalid_input'), status => 400)
        unless valid_id($request->{id})
        && ($token // '') =~ /\A[a-f0-9]{64}\z/
        && length($request->{note}) <= 2000
        && index($request->{note}, "\0") < 0;
    my $status =
        $self->store->submit($request->{id}, $scanner, $token, $request->{tags}, $request->{note});
    return $controller->render(text => $controller->l('target_unavailable'), status => 409)
        if $status == 409;
    return $self->_submission_response($controller, $request->{id}, $status);
}

sub _submission_response {
    my ($self, $controller, $id, $status) = @_;
    if (($controller->req->headers->accept // '') =~ /application\/json/) {
        return $controller->render(
            status => $status,
            json => {
                id => $id,
                url => "/scans/$id",
                next_id => random_id(),
            }
        );
    }
    $controller->res->code($status == 200 ? 302 : 303);
    return $controller->redirect_to("/scans/$id");
}

sub _show_scan {
    my ($self, $controller) = @_;

    my $scan = $self->store->get($controller->param('id'));
    return $controller->reply->not_found unless $scan;

    my ($seen) = $self->store->db->selectrow_array(
        'SELECT seen FROM scanners WHERE id=? AND digest IS NOT NULL',
        undef, $scan->{scanner_id});
    $scan->{online} = ($seen // 0) >= time - 30;
    my $host = ($scan->{target}{kind} // '') eq 'host';
    $scan->{removal} = $host ? 'system_volume' : 'do_not_disconnect';
    $scan->{removal} = 'can_disconnect'
        if !$host && $scan->{online} && $self->store->can_disconnect($scan);
    my $artifacts = $self->_artifacts($scan->{id});
    my (%versions, %result_states);
    my $results = Mogura::Server::Results->new(state => $self->store->state);

    for my $kind (qw(syft grype)) {
        next unless $artifacts->{$kind};
        my $revision = $results->revision($artifacts->{$kind});
        my $file = $results->available($scan->{id}, $kind, $revision);
        $versions{$kind} = $results->version($file, $revision) if $file;
        $result_states{$kind} = $results->build_status($results->location($scan->{id}, $kind));
    }
    $controller->stash(
        scan => $scan,
        artifacts => $artifacts,
        versions => \%versions,
        result_states => \%result_states,
    );
    $controller->render(template => 'scan');
}

sub _result_page {
    my ($self, $controller) = @_;
    my ($id, $kind) = map { $controller->param($_) // '' } qw(id kind);
    return $controller->reply->not_found unless $kind eq 'syft' || $kind eq 'grype';
    my $source = $self->store->artifact($id, $kind);
    return $controller->reply->not_found unless $source;
    my $results = Mogura::Server::Results->new(state => $self->store->state);
    my $revision = $results->revision($source);
    my $file = $results->available($id, $kind, $revision);
    return $controller->render(
        status => 409,
        json => {error => $controller->l('create_list_first')}
    ) unless $file;
    my $version = $results->version($file, $revision);
    return $controller->render(status => 409, json => {error => $controller->l('results_changed')})
        unless ($controller->param('version') // '') eq $version;
    my $request = {
        version => $version,
        query => $controller->param('query') // '',
        start => $controller->param('start') // '0',
        column => $controller->param('column'),
        descending => ($controller->param('descending') // '') eq '1',
    };
    return $controller->render(status => 400, json => {error => $controller->l('invalid_search')})
        if length($request->{query}) > 500
        || $request->{start} !~ /\A[0-9]{1,9}\z/
        || (defined($request->{column}) && $request->{column} !~ /\A[0-4]\z/);

    my $key = "$id-$kind-$revision";

    # Searches and sorting run outside the HTTP event loop, including on old
    # scans. The browser never falls back to decoding the original artifact.
    if (($self->{result_queries} // 0) >= 2) {
        $controller->res->headers->header('Retry-After' => 1);
        return $controller->render(status => 429, json => {pending => 1});
    }
    $self->{result_queries}++;
    $controller->render_later;
    Mojo::IOLoop::Subprocess->new->run(
        sub { $results->page($file, $revision, $request) },
        sub {
            my ($process, $error, $page) = @_;
            $self->{result_queries}--;
            if ($error) {
                $self->log->error("Result query $key: $error");
                $controller->render(
                    status => 500,
                    json => {error => $controller->l('result_load_failed')}
                );
            }
            else {
                $controller->render(json => $page);
            }
        }
    );
}

sub _rebuild_result {
    my ($self, $controller) = @_;
    return $controller->render(status => 403, json => {error => $controller->l('invalid_csrf')})
        if $controller->validation->csrf_protect->has_error('csrf_token');
    my ($id, $kind) = map { $controller->param($_) // '' } qw(id kind);
    return $controller->reply->not_found unless $kind eq 'syft' || $kind eq 'grype';
    my $scan = $self->store->get($id);
    return $controller->reply->not_found unless $scan;
    return $controller->render(status => 409, json => {error => $controller->l('wait_scan')})
        if $scan->{status} eq 'running' || $scan->{status} eq 'queued';
    my $source = $self->store->artifact($id, $kind);
    return $controller->reply->not_found unless $source;
    my $results = Mogura::Server::Results->new(state => $self->store->state);
    my $file = $results->location($id, $kind);
    my $lock = $results->build_lock($file);
    return $controller->render(status => 409, json => {error => $controller->l('wait_build')})
        unless $lock;
    my $revision = $results->revision($source);
    my $status = {state => 'running', token => random_id()};
    $results->save_build_status($file, $status);
    my $process = Mojo::IOLoop::Subprocess->new;
    my $key = "$id-$kind";
    $self->{result_jobs}{$key} = $process;
    $process->run(
        sub {
            my $ok = eval {
                $results->build($source, $file, $kind, $revision, force => 1, lock => $lock);
            };
            my $error = $@;
            $results->save_build_status($file, {%$status, state => $ok ? 'ready' : 'failed'});
            return $error;
        },
        sub {
            my ($process, $error, $build_error) = @_;
            if ($error || $build_error) {
                $self->log->error("Result rebuild $key: " . ($error || $build_error));

                # Status writes can fail for the same reason as the build
                # (for example a full disk). Always release the build lock.
                eval { $results->save_build_status($file, {%$status, state => 'failed'}); };
                $self->log->error("Result rebuild status $key: $@") if $@;
            }
            close $lock;
            delete $self->{result_jobs}{$key};
        }
    );
    return $controller->render(
        status => 202,
        json => {
            status_url => "/scans/$id/results/$kind/build?token=$status->{token}",
        }
    );
}

sub _result_build_status {
    my ($self, $controller) = @_;
    my ($id, $kind) = map { $controller->param($_) // '' } qw(id kind);
    return $controller->reply->not_found unless $kind eq 'syft' || $kind eq 'grype';
    return $controller->reply->not_found unless $self->store->artifact($id, $kind);
    my $results = Mogura::Server::Results->new(state => $self->store->state);
    my $status = $results->build_status($results->location($id, $kind));
    return $controller->render(status => 409, json => {error => $controller->l('refresh_status')})
        unless ($controller->param('token') // '') eq ($status->{token} // '');
    my $response = {state => $status->{state}};

    if ($status->{state} eq 'ready') {
        my $source = $self->store->artifact($id, $kind);
        my $revision = $results->revision($source);
        my $file = $results->available($id, $kind, $revision);
        if ($file) {
            $response->{url} =
                "/scans/$id/results/$kind?version=" . $results->version($file, $revision);
        }
        else {
            $response->{state} = 'failed';
        }
    }
    return $controller->render(json => $response);
}

sub _artifacts {
    my ($self, $id) = @_;
    return {map { $_ => scalar($self->store->artifact($id, $_)) } qw(syft cdx grype log)};
}

sub _update_tags {
    my ($self, $controller) = @_;
    return $controller->render(text => $controller->l('invalid_csrf'), status => 403)
        if $controller->validation->csrf_protect->has_error('csrf_token');
    my $scan = $self->store->get($controller->param('id'));
    return $controller->reply->not_found unless $scan;
    my $operation = $controller->param('operation') // '';
    return $controller->render(text => $controller->l('invalid_tag_operation'), status => 400)
        unless $operation eq 'add' || $operation eq 'remove';
    my $values = eval { Mogura::Server::Tags->validate([$controller->param('tag')]); };
    return $controller->render(text => $controller->l('tag_limit'), status => 400)
        unless defined $values;
    my $tags = eval { $self->store->change_tags($scan->{id}, $operation, $values); };

    unless (defined $tags) {
        my $error = $@;
        die $error unless $error =~ /\A(?:Invalid tag|Tag too long|Remove exactly)/;
        return $controller->render(text => $controller->l('tag_limit'), status => 400);
    }
    return $controller->render(json => {tags => $tags})
        if ($controller->req->headers->accept // '') eq 'application/json';
    $controller->res->code(303);
    $controller->redirect_to('/scans/' . $scan->{id});
}

sub _update_note {
    my ($self, $controller) = @_;
    return $controller->render(text => $controller->l('invalid_csrf'), status => 403)
        if $controller->validation->csrf_protect->has_error('csrf_token');
    my $scan = $self->store->get($controller->param('id'));
    return $controller->reply->not_found unless $scan;
    my $note = $controller->param('note') // '';
    return $controller->render(text => $controller->l('note_limit'), status => 400)
        if length($note) > 2000 || index($note, "\0") >= 0;
    $self->store->db->do('UPDATE jobs SET note=? WHERE id=?', undef, $note, $scan->{id});
    return $controller->render(json => {note => $note})
        if ($controller->req->headers->accept // '') eq 'application/json';
    $controller->res->code(303);
    $controller->redirect_to('/scans/' . $scan->{id});
}

sub _page_number {
    my ($self, $value) = @_;

    return 1 unless ($value // '') =~ /\A[1-9]\d{0,5}\z/;
    return $value;
}

sub _download_artifact {
    my ($self, $controller) = @_;

    # Store resolves a Scan ID plus an allowlisted kind; no request value is
    # ever interpreted as a filesystem path or a download filename.
    my $kind = $controller->param('kind');
    if ($kind eq 'metadata') {
        my $scan = $self->store->get($controller->param('id'))
            or return $controller->reply->not_found;
        $controller->res->headers->content_disposition('attachment; filename="metadata.json"');
        return $controller->render(json => $scan);
    }
    my $file = $self->store->artifact($controller->param('id'), $kind);
    return $controller->reply->not_found unless $file;

    my $headers = $controller->res->headers;
    $headers->content_disposition('attachment; filename="' . $file->basename . '"');
    $headers->content_type($kind eq 'log' ? 'text/plain; charset=UTF-8' : 'application/json');
    $controller->reply->file("$file");
}

1;
