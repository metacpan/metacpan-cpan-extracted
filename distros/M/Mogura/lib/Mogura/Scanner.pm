package Mogura::Scanner;
use Mojo::Base -base;
use Cwd qw(abs_path);
use Fcntl qw(:flock F_SETFD);
use POSIX qw(WNOHANG);
use Time::HiRes qw(time sleep);
use Mojo::File qw(path);
use Mojo::JSON qw(decode_json);
use Mogura::Protocol qw(random_id valid_id now);
use Mogura::Scanner::Config qw(trusted_path);
use Mogura::Scanner::Spool;
use Mogura::Scanner::Disk;
use Mogura::Scanner::Scan;
use Mogura::Scanner::Client;

has config => sub { Mogura::Scanner::Config->new };
has client => sub { Mogura::Scanner::Client->new(config => shift->config) };
has disk => sub { Mogura::Scanner::Disk->new(config => shift->config, app_root => abs_path($0)) };
has spool => sub { Mogura::Scanner::Spool->new(config => shift->config) };
has scan => sub {
    my $self = shift;
    Mogura::Scanner::Scan->new(config => $self->config, store => $self->spool, disk => $self->disk);
};
has active => sub { {} };

sub initialize {
    my ($self) = @_;
    my $config = $self->config;
    die 'Scanner requires root' if $>;
    umask 0077;
    chdir '/' or die "chdir: $!";
    for my $tool ($config->syft, $config->grype,
        qw(/usr/bin/lsblk /usr/bin/findmnt /usr/bin/mount /usr/bin/umount /usr/sbin/blockdev /usr/bin/df /usr/bin/prlimit)
        )
    {
        die
            "Missing executable $tool. Install Syft and Grype from Anchore releases and the util-linux, mount and coreutils packages.\n"
            unless -f $tool && -x _;
        trusted_path($tool);
    }
    for my $d ($config->state, $config->runtime, $config->mounts, path($config->state, 'spool')) {
        my $p = path($d);
        trusted_path($p->dirname);
        $p->make_path({mode => 0700});
        trusted_path($p);
        die "Private directory required: $p" if (stat($p))[2] & 0077;
    }
    trusted_path($config->token_file);
    $self->client->initialize;
    $self->acquire_lock;
    for my $dir (path($config->state, 'spool')->list({dir => 1})->each) {
        $dir->remove_tree if $dir->basename =~ /\Adelivered-[a-f0-9]{32}\z/;
    }
}

sub acquire_lock {
    my ($self) = @_;
    open my $fh, '>>', path($self->config->state, 'scanner.lock') or die "Scanner lock: $!";
    flock($fh, LOCK_EX | LOCK_NB) or die 'Scanner or surviving descendant already running';
    fcntl($fh, F_SETFD, 0) or die "Inherit scanner lock: $!";
    $self->{lock} = $fh;
}

sub managed_mounts {
    my ($self) = @_;
    my $root = $self->config->mounts;
    return [
        map { $_->{target} }
        grep { $_->{target} eq $root || index($_->{target}, "$root/") == 0 }
            @{$self->disk->mount_table}
    ];
}

sub _records {
    my ($self) = @_;
    return
        grep { valid_id($_->basename) } path($self->config->state, 'spool')->list({dir => 1})->each;
}

sub _recover {
    my ($self, $intent, $mounts) = @_;
    my $id = $intent->{id};
    my $scan = $self->spool->get($id) // $self->scan->queued($intent);
    my $root = $self->config->mounts . "/$id";
    my $remaining = grep { $_ eq $root || index($_, "$root/") == 0 } @$mounts;

    # Exec descendants inherit the scan lock even when their supervisor dies.
    my $prior_cleanup = $scan->{cleanup_status};
    my $lock = eval { $self->scan->_acquire_lock("scan-$id") };
    if (!$lock || $remaining) {
        $scan->{cleanup_status} = 'needs_cleanup';
    }
    elsif ($scan->{cleanup_status} eq 'needs_cleanup' || $scan->{cleanup_status} eq 'mounted') {
        $scan->{cleanup_status} = 'unmounted';
    }
    elsif ($scan->{phase} eq 'finished') {
        return $scan;
    }
    return $scan if $scan->{phase} eq 'finished' && $prior_cleanup eq $scan->{cleanup_status};
    $scan->{status} = 'partial'
        if $scan->{status} eq 'completed' && $scan->{cleanup_status} eq 'needs_cleanup';
    unless ($scan->{phase} eq 'finished') {
        $scan->{status} = 'interrupted';
        $scan->{phase} = 'finished';
        $scan->{error} = 'Scan process stopped before completion';
        $scan->{finished_at} = now();
    }
    return $self->scan->save_finished($scan);
}

sub _transfer {
    my ($self, $dir, $intent, $scan) = @_;
    my $route = "/jobs/$intent->{id}/$intent->{run}";
    my $record = $dir->child('delivery.json');
    my $sent = -e $record ? decode_json($record->slurp) : {};
    $self->client->request('POST', "$route/progress", $scan);
    for my $kind (qw(syft cdx grype log)) {
        my $file = $self->spool->artifact($intent->{id}, $kind) or next;
        next if $sent->{$kind};
        $self->client->request('PUT', "$route/files/$kind", undef, $file);
        $sent->{$kind} = 1;
        $self->spool->write_record($record, $sent);
    }
    $self->client->request('POST', "$route/complete", $scan);
    if ($scan->{cleanup_status} eq 'needs_cleanup') {
        $sent->{complete} = $scan->{sequence};
        $self->spool->write_record($record, $sent);
        return;
    }

    # Only acknowledged spool files are disposable. Atomically retire the
    # directory so a stop during deletion cannot resurrect a partial run.
    my $retired = $dir->sibling('delivered-' . $dir->basename);
    rename $dir, $retired or die "Retire spool: $!";
    $retired->remove_tree;
}

sub _retire_unstarted {
    my ($self, $intent, $cancel) = @_;
    my $id = $intent->{id};
    if ($cancel) {

        # A lost claim reply may be retried after cancellation, before any
        # local work started. Acknowledge before retiring the saved intent.
        $self->client->request(
            'POST',
            "/jobs/$id/$intent->{run}/complete",
            {
                status => 'cancelled',
                phase => 'finished',
                finished_at => now(),
                cleanup_status => 'not_needed',
                sequence => 1
            }
        );
    }
    my $dir = $self->spool->directory($id);
    unlink $dir->child('intent.json') or die "Discard unstarted claim: $!";
    rmdir $dir or die "Remove empty claim directory: $!";
}

sub _fork_job {
    my ($self, $id, $work, $slot) = @_;
    my $pid = fork;
    die "fork: $!" unless defined $pid;
    if (!$pid) {
        $SIG{$_} = 'DEFAULT' for qw(INT TERM HUP);
        my $ok = eval { $work->(); 1 };
        warn $@ unless $ok;
        POSIX::_exit($ok ? 0 : 1);
    }
    $self->active->{$id} = {pid => $pid, slot => $slot};
}

sub _capacity {
    my ($self) = @_;
    my $root = path($self->config->state, 'spool');
    my $used = 0;
    $used += (-s $_ // 0) for $root->list_tree->each;
    my $available =
        $self->scan->command->run(['/usr/bin/df', '-B1', '--output=avail', '--', "$root"]);
    return 0 unless $available =~ /\n\s*(\d+)\s*\z/;
    my $free = $1 - 16 * 1024**2;
    my $reserved = 0;
    $reserved += ($_->{limit} // 0) * 5 for values %{$self->active};
    my $budget = $self->config->spool_limit - $used - $reserved;
    $free -= $reserved;
    $budget = $free if $free < $budget;

    # Divide among concurrent scans and four output streams. prlimit enforces
    # the reservation in the tools even if the parent loses its connection.
    my $slots = $self->config->jobs - grep { $_->{slot} } values %{$self->active};
    return 0 unless $slots;
    my $limit = int($budget / ($slots * 5));
    $limit = 4 * 1024**3 if $limit > 4 * 1024**3;
    return $limit >= 65536 ? $limit : 0;
}

sub _identify {
    my ($self) = @_;
    my $identity = $self->client->request('GET', '/identity');
    die 'Invalid scanner identity'
        unless valid_id($identity->{server})
        && ($identity->{scanner} // '') =~ /\A[a-zA-Z0-9_-]{1,64}\z/;
    my $file = path($self->config->state, 'identity.json');
    if (-e $file) {
        my $saved = decode_json($file->slurp);
        die 'Spool belongs to a different server or scanner'
            unless $saved->{server} eq $identity->{server}
            && $saved->{scanner} eq $identity->{scanner};
    }
    else {
        $self->spool->write_record($file, $identity);
    }
    $self->{identified} = 1;
}

sub tick {
    my ($self) = @_;
    $self->_identify unless $self->{identified};
    $self->_reap_children;
    my ($pending, $blocked) = $self->_reconcile_spool;
    $self->_send_inventory($pending, $blocked)
        if @$blocked || time >= ($self->{inventory_due} // 0);
    return if @$blocked;
    $self->_claim_and_start($pending);
}

sub _reap_children {
    my ($self) = @_;
    my $active = $self->active;
    for my $id (keys %$active) {
        next unless waitpid($active->{$id}{pid}, WNOHANG) > 0;
        my $child = delete $active->{$id};
        next if $child->{slot};
        my $delay = $? ? ($self->{delivery_delay} || 1) * 2 : 0;
        $self->{delivery_delay} = $delay > 30 ? 30 : $delay;
        $self->{delivery_due} = time + $self->{delivery_delay};
    }
}

sub _reconcile_spool {
    my ($self) = @_;
    my $active = $self->active;
    my $mounts = $self->managed_mounts;
    my %owned =
        map { ($self->config->mounts . "/$_") => 1 } grep { $active->{$_}{slot} } keys %$active;
    my @blocked = grep { !$owned{$_} } @$mounts;
    my %pending;
    my $sending = grep { !$_->{slot} } values %$active;
    for my $dir ($self->_records) {
        my $id = $dir->basename;
        my $file = $dir->child('intent.json');
        next unless -e $file;
        my $intent = decode_json($file->slurp);
        die 'Invalid local execution record'
            unless $intent->{id} eq $id && valid_id($intent->{run});
        die 'Restore the runtime directory recorded for the outstanding scan'
            unless $intent->{runtime} eq $self->config->runtime;
        unless ($intent->{started}) {
            $pending{$id} = $intent;
            next;
        }
        if (my $child = $active->{$id}) {
            my $scan = $self->spool->get($id);
            push @blocked, $id if $scan && $scan->{cleanup_status} eq 'needs_cleanup';
            if ($child->{slot}
                && $scan
                && $scan->{phase} ne 'finished'
                && ($child->{reported} // 0) < $scan->{sequence})
            {
                $self->client->request(
                    'POST',
                    "/jobs/$id/$intent->{run}/progress",
                    Mogura::Scanner::Scan::bounded_report($scan)
                );
                $child->{reported} = $scan->{sequence};
            }
            next;
        }
        my $scan = $self->_recover($intent, $mounts);
        push @blocked, $id if $scan->{cleanup_status} eq 'needs_cleanup';
        my $receipt = $dir->child('delivery.json');
        next
            if $scan->{cleanup_status} eq 'needs_cleanup'
            && -f $receipt
            && (decode_json($receipt->slurp)->{complete} // 0) == $scan->{sequence};
        next if $sending || time < ($self->{delivery_due} // 0);
        $self->_fork_job($id, sub { $self->_transfer($dir, $intent, $scan) }, 0);
        $sending = 1;
    }
    return (\%pending, \@blocked);
}

sub _send_inventory {
    my ($self, $pending, $blocked) = @_;
    my $inventory =
        eval { $self->disk->inventory } // {disks => [], errors => ["Disk discovery failed: $@"]};
    $inventory->{blocked} = $blocked;
    my $reply = $self->client->request('POST', '/inventory', $inventory);
    for my $request (@{$reply->{cancel} // []}) {
        my $id = $request->{id};
        if (my $intent = $pending->{$id}) {
            next unless $intent->{run} eq $request->{run};
            $self->_retire_unstarted($intent, 1);
            delete $pending->{$id};
            next;
        }
        my $child = $self->active->{$id} or next;
        next unless $child->{slot} && $child->{run} eq $request->{run};
        next if $child->{stop_sent};

        # This direct child cannot have its PID reused before we reap it.
        $child->{stop_sent} = kill 'TERM', $child->{pid};
    }
    $self->{inventory_due} = time + $self->config->inventory_interval;
}

sub _claim_and_start {
    my ($self, $pending) = @_;
    my $active = $self->active;
    my %slots = map { $_->{slot} => 1 } values %$active;
    my ($slot) = grep { !$slots{$_} } 1 .. $self->config->jobs;
    return unless $slot;
    my $limit = $self->_capacity or return;
    my ($intent) = values %$pending;
    unless ($intent) {
        my $job = $self->client->request('GET', '/jobs')->{job} or return;
        $intent = {
            %{$self->scan->validate_request($job)},
            run => random_id(),
            runtime => $self->config->runtime,
            started => 0
        };
        my $dir = $self->spool->directory($intent->{id})->make_path({mode => 0700});
        return if -e $dir->child('intent.json');
        $dir->dirname->open('<')->sync or die "Sync spool directory: $!";
        $self->spool->write_record($dir->child('intent.json'), $intent);
    }
    my $id = $intent->{id};
    my $claim = $self->client->request('POST', "/jobs/$id/$intent->{run}/claim", {});
    return $self->_retire_unstarted($intent, $claim->{cancel})
        if $claim->{expired} || $claim->{cancel};
    return if $self->{stopping};
    $intent->{started} = 1;
    $self->spool->write_record($self->spool->directory($id)->child('intent.json'), $intent);
    $self->_fork_job(
        $id,
        sub {
            local $SIG{XFSZ} = 'IGNORE';
            $self->scan->command->run(['/usr/bin/prlimit', '--pid', "$$", "--fsize=$limit:$limit"]);
            $self->scan->cache_slot($slot)->run($intent);
        },
        $slot
    );
    $active->{$id}{limit} = $limit;
    $active->{$id}{run} = $intent->{run};
}

sub run {
    my ($self) = @_;
    my $mounts = $self->managed_mounts;
    for my $dir ($self->_records) {
        my $file = $dir->child('intent.json');
        next unless -e $file;
        my $intent = decode_json($file->slurp);
        die 'Invalid spool execution or runtime'
            unless $intent->{id} eq $dir->basename && $intent->{runtime} eq $self->config->runtime;
        $self->_recover($intent, $mounts) if $intent->{started};
    }
    my $delay = 1;
    local $SIG{INT} = local $SIG{TERM} = local $SIG{HUP} = sub { $self->{stopping} = 1 };
    until ($self->{stopping}) {
        my $ok = eval { $self->tick; 1 };
        warn $@ unless $ok;
        $delay = $ok ? 1 : $delay < 16 ? $delay * 2 : 30;
        sleep $delay unless $self->{stopping};
    }
    kill 'TERM', $_->{pid} for values %{$self->active};
    waitpid($_->{pid}, 0) for values %{$self->active};
}
1;
