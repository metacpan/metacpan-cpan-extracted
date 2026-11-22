use strict;
use warnings;
use Test::More;
use Digest::SHA qw(sha256_hex);
use File::Temp qw(tempdir);
use Mojo::File qw(path);
use Mojo::JSON qw(encode_json);
use lib 'lib';
use Mogura::Scanner::Config;
use Mogura::Scanner::Spool;
use Mogura::Scanner::Scan;

# These two local fixtures exercise real scan orchestration using ordinary
# temporary directories; no block device or external scanner is involved.
{

    package ScanDisk;
    use Mojo::Base -base;
    has [qw(failure mounted events)];

    sub resolve {
        my ($self, $token) = @_;
        die 'replaced disk' if ($self->failure // '') eq 'identity';
        return {
            name => '/dev/example1',
            'maj:min' => '8:17',
            fstype => 'ext4',
            token => $token,
            identity => {disk => {name => '/dev/example'}, partition => {name => '/dev/example1'}}
        };
    }

    sub make_readonly {
        my ($self, $target) = @_;
        die 'read-only verification failed' if ($self->failure // '') eq 'readonly';
        return $target;
    }

    sub mount_table {
        my ($self) = @_;
        return [] unless $self->mounted;
        return [{target => $self->mounted, number => '8:17'}];
    }

    sub mount {
        my ($self, $target, $root) = @_;
        $self->mounted("$root");
        die 'mount command failed after mounting' if ($self->failure // '') eq 'mount';
        Mojo::File::path($root, $_)->make_path for qw(etc usr var);
        Mojo::File::path($root, 'etc/os-release')->spurt("ID=ubuntu\n")
            unless ($self->failure // '') eq 'no-release';
        Mojo::File::path($root, 'etc/fstab')->spurt("UUID=root / ext4 defaults 0 1\n");
        if (($self->failure // '') eq 'separate-filesystems') {
            Mojo::File::path($root, 'etc/fstab')
                ->spurt(
                "UUID=root / ext4 defaults 0 1\nserver:/export /mnt/nfs nfs defaults 0 0\n"
                    . "fs-example:/ /mnt/efs efs _netdev,tls 0 0\nUUID=var /var xfs defaults 0 0\n"
                );
        }
        if (($self->failure // '') eq 'missing-scope') {
            unlink Mojo::File::path($root, 'etc/fstab') or die $!;
            rmdir Mojo::File::path($root, 'usr') or die $!;
        }
        push @{$self->events}, 'mount';
    }

    sub verify_mount {
        my ($self) = @_;
        die 'missing safety option' if ($self->failure // '') eq 'options';
    }

    sub unmount {
        my ($self) = @_;
        push @{$self->events}, 'unmount';
        die 'busy mount' if ($self->failure // '') eq 'unmount';
        $self->mounted(undef);
    }

    package HostScanDisk;
    use Mojo::Base 'ScanDisk';

    sub resolve {
        return {kind => 'host', identity => {kind => 'host', partition => {name => '/'}}};
    }
    sub host_exclusions { return ['/proc', '/var/lib/mogura'] }
    sub make_readonly { die 'Live root must never change block-device flags' }
    sub mount { die 'Live root must never be mounted' }
    sub verify_mount { die 'Live root is not a guest mount' }
    sub unmount { die 'Live root must never be unmounted' }

    package ScanTools;
    use Mojo::Base -base;

    has [qw(failure events arguments)];
    has timeouts => sub { [] };

    sub run {
        my ($self, $arguments, %options) = @_;

        kill 'TERM', $$
            if ($self->failure // '') eq 'stop-at-version' && $arguments->[1] eq 'version';
        return Mojo::JSON::encode_json({version => 'test'}) if $arguments->[1] eq 'version';
        push @{$self->timeouts}, $options{timeout};
        if ($arguments->[0] =~ /syft$/) {
            $self->arguments($arguments);
            push @{$self->events}, 'syft';
            die 'Syft failed' if ($self->failure // '') eq 'syft';
            kill 'TERM', $$ if ($self->failure // '') eq 'stop';
            $self->_write_sboms($arguments);
        }
        else {
            push @{$self->events}, 'grype';
            die 'Grype DB download failed' if ($self->failure // '') eq 'grype';
            $self->_write_grype_result($options{stdout});
        }
        return '';
    }

    sub _write_sboms {
        my ($self, $arguments) = @_;

        my $native_sbom = {
            artifacts => [],
            source => {type => 'directory'},
            descriptor => {name => 'syft', version => 'test'},
        };
        my $cyclonedx_sbom = {
            bomFormat => 'CycloneDX',
            specVersion => '1.6',
            components => [],
        };
        for my $argument (@$arguments) {
            if ($argument =~ /^syft-json=(.*)/) {
                Mojo::File::path($1)->spurt(Mojo::JSON::encode_json($native_sbom));
            }
            elsif ($argument =~ /^cyclonedx-json=(.*)/) {
                my $output =
                    ($self->failure // '') eq 'cdx'
                    ? '{broken'
                    : Mojo::JSON::encode_json($cyclonedx_sbom);
                Mojo::File::path($1)->spurt($output);
            }
        }
    }

    sub _write_grype_result {
        my ($self, $file) = @_;

        my $database_status = {
            built => '2026-01-01T00:00:00Z',
            schemaVersion => 'v6.1.10',
            valid => ($self->failure // '') eq 'stale' ? Mojo::JSON::false : Mojo::JSON::true,
        };
        my $result = {
            matches => [],
            descriptor => {
                name => 'grype',
                version => 'test',
                db => {status => $database_status},
            },
        };
        Mojo::File::path($file)->spurt(Mojo::JSON::encode_json($result));
    }

}

my $sequence = 0;

sub scan_case {
    my ($failure, $kind) = @_;
    my $directory = tempdir(CLEANUP => 1);
    my $config = Mogura::Scanner::Config->new(
        state => $directory,
        runtime => "$directory/run",
        exclude_paths => ['/srv/backups'],
        command_timeout => 79
    );
    my $store = Mogura::Scanner::Spool->new(config => $config);
    my $events = [];
    my $disk_class = ($kind // '') eq 'host' ? 'HostScanDisk' : 'ScanDisk';
    my $disk = $disk_class->new(failure => $failure, events => $events);
    my $tools = ScanTools->new(failure => $failure, events => $events);
    my $scanner = Mogura::Scanner::Scan->new(
        config => $config,
        store => $store,
        disk => $disk,
        command => $tools
    );
    my $id = sprintf('%032x', ++$sequence);
    my $scan = $scanner->run({id => $id, tags => ['sample'], note => '', token => ('a' x 64)});
    return ($scan, $store, $events, $directory, $tools);
}

# Reject unsafe targets and verify cleanup at every failure boundary.
for my $failure (qw(identity readonly options mount syft)) {
    my ($scan, $store, $events) = scan_case($failure);
    is($scan->{status}, 'failed', "$failure prevents successful scan");
    ok(!grep($_ eq 'syft', @$events), "$failure never reaches Syft") unless $failure eq 'syft';
    if ($failure eq 'identity' || $failure eq 'readonly') {
        is($scan->{cleanup_status}, 'not_needed', 'No mount was attempted');
    }
    else {
        ok(grep($_ eq 'unmount', @$events), 'Cleanup attempted after failure');
        is($scan->{cleanup_status}, 'unmounted', 'Cleanup verified');
    }
}

# Missing distribution metadata must not prevent cataloging or matching.
{
    my ($scan, $store, $events) = scan_case('no-release');
    is($scan->{status}, 'completed', 'Scan completes without any OS release file');
    is_deeply(
        $events,
        [qw(mount syft unmount grype)],
        'Missing release files do not skip tools or cleanup'
    );
    ok(
        $store->artifact($scan->{id}, 'syft')
            && $store->artifact($scan->{id}, 'cdx')
            && $store->artifact($scan->{id}, 'grype'),
        'All artifacts published without distribution metadata'
    );
}

# Missing filesystems and scope metadata preserve results and their warnings.
for my $scope ('separate-filesystems', 'missing-scope') {
    my ($scan, $store, $events) = scan_case($scope);
    is($scan->{status}, 'completed', "$scope still completes available scanning");
    is_deeply($events, [qw(mount syft unmount grype)], 'Tools and cleanup run despite scope gaps');
    for my $kind (qw(syft cdx grype)) {
        ok($store->artifact($scan->{id}, $kind), "$kind artifact published despite scope gaps");
    }
    my $warnings = join(' ', @{$store->get($scan->{id})->{warnings}});
    if ($scope eq 'separate-filesystems') {
        for my $entry ('/mnt/nfs (nfs)', '/mnt/efs (efs)', '/var (xfs)') {
            like(
                $warnings,
                qr/Uninspected separate filesystem: \Q$entry\E/,
                "$entry warning survives persistence"
            );
        }
    }
    else {
        like($warnings, qr/Cannot inspect \/etc\/fstab/, 'Missing fstab warning persists');
        like($warnings, qr/Uninspected directory: \/usr/, 'Missing directory warning persists');
    }
}

# A failed matcher retains both SBOM formats and never publishes a zero-match result.
{
    my ($scan, $store, $events) = scan_case('grype');
    is($scan->{status}, 'partial', 'Grype failure is partial');
    ok($store->artifact($scan->{id}, 'syft') && $store->artifact($scan->{id}, 'cdx'),
        'Both SBOMs survive Grype failure');
    ok(!$store->artifact($scan->{id}, 'grype'),
        'Failed matching is never published as zero vulnerabilities');
    is_deeply($events, [qw(mount syft unmount grype)], 'Grype only runs after unmount');
}

# A remaining mount is unsafe even when both SBOM formats are usable.
{
    my ($scan, $store, $events) = scan_case('unmount');
    is($scan->{status}, 'partial', 'Unmount failure retains SBOM as partial');
    is($scan->{cleanup_status}, 'needs_cleanup', 'Failed unmount remains explicit');
    ok(!grep($_ eq 'grype', @$events), 'No further work after unmount failure');
    like(join(' ', @{$scan->{warnings}}), qr/busy mount/, 'Cleanup error visible');
}

# A valid native SBOM survives failure of the second output format.
{
    my ($scan, $store) = scan_case('cdx');
    is($scan->{status}, 'partial', 'Invalid second output retains valid SBOM');
    ok($store->artifact($scan->{id}, 'syft'), 'Valid native SBOM retained');
    ok(!$store->artifact($scan->{id}, 'cdx'), 'Incomplete JSON never published');
}

# A syntactically valid result is insufficient when DB validation failed.
{
    my ($scan, $store) = scan_case('stale');
    is($scan->{status}, 'partial', 'Invalid DB cannot complete a scan');
    ok(!$store->artifact($scan->{id}, 'grype'), 'Invalid DB result is not evaluated');
}

# A normal stop request follows the same unmount path as other failures.
{
    my ($scan, $store, $events) = scan_case('stop');
    is($scan->{status}, 'interrupted', 'Normal stop interrupts the scan');
    is($scan->{cleanup_status}, 'unmounted', 'Normal stop cleans up');
}

{
    my ($scan, undef, $events) = scan_case('stop-at-version');
    is_deeply($events, [qw(mount unmount)],
        'Cancellation during version lookup skips scanning and unmounts the disk');
    is($scan->{status}, 'interrupted', 'Cancellation survives best-effort version lookup');
}

# A stop signal caught by a best-effort scope check must still stop the scan.
{
    my $guest_path = Mogura::Scanner::Scan->can('guest_path');
    my $signalled = 0;
    no warnings 'redefine';
    local *Mogura::Scanner::Scan::guest_path = sub {
        kill 'TERM', $$ unless $signalled++;
        return $guest_path->(@_);
    };
    my ($scan, $store, $events) = scan_case('');
    is($scan->{status}, 'interrupted', 'Stop during scope inspection is honored');
    is($scan->{cleanup_status}, 'unmounted', 'Stop during scope inspection cleans up');
    is_deeply($events, [qw(mount unmount)], 'No scanner starts after the stop request');
}

# Completion requires all artifacts and a verified unmount.
{
    my ($scan, $store, $events) = scan_case('');
    is($scan->{status}, 'completed', 'All artifacts and verified unmount complete the scan');
    is(
        $scan->{sbom_sha256},
        sha256_hex($store->artifact($scan->{id}, 'syft')->slurp),
        'Recorded digest identifies the actual saved SBOM'
    );
    ok($scan->{grype_db}{status}{built}, 'Actual DB metadata is retained');
}

# Both scan types persist exactly the patterns actually sent to Syft.
for my $kind ('clone', 'host') {
    my ($scan, $store, $events, $directory, $tools) = scan_case('', $kind);
    my @sent;
    my $args = $tools->arguments;
    for my $index (0 .. $#$args - 1) {
        push @sent, $args->[$index + 1] if $args->[$index] eq '--exclude';
    }
    is_deeply(\@sent, $scan->{exclusions}, "$kind persists its actual exclusions");
    is_deeply($tools->timeouts, [79, 79], "$kind applies command_timeout to Syft and Grype");
    for my $pattern ('./srv/backups', './var/log', './var/crash', './var/lib/systemd/coredump') {
        ok(grep($_ eq $pattern, @sent), "$kind excludes $pattern");
    }
}

# Guest absolute symlinks resolve inside the guest; separate /var is reported.
{
    my $root = tempdir(CLEANUP => 1);
    path($root, $_)->make_path for qw(etc usr var);
    path($root, 'usr/os-release')->spurt("ID=ubuntu\n");
    symlink '/usr/os-release', "$root/etc/os-release" or die $!;
    path($root, 'etc/fstab')
        ->spurt("UUID=root / ext4 defaults 0 1\nUUID=var /var ext4 defaults 0 2\n");
    my $scanner = Mogura::Scanner::Scan->new;
    is(
        "" . $scanner->guest_path($root, 'etc/os-release'),
        "$root/usr/os-release",
        'Absolute guest symlink remains inside guest'
    );
    like(
        join(' ', @{$scanner->inspect_root($root, [])}),
        qr/Uninspected separate filesystem: \/var/,
        'Split application/data filesystems produce warnings'
    );
}

# Host runs reuse artifact validation and matching without any block-device
# operation, including when a scanner fails or the process is stopped.
for my $failure ('', 'syft', 'grype', 'stop') {
    my ($scan, $store, $events, $directory, $tools) = scan_case($failure, 'host');
    my %expected = ('' => 'completed', syft => 'failed', grype => 'partial', stop => 'interrupted');
    is($scan->{status}, $expected{$failure}, "Live scan result for '$failure'");
    is($scan->{cleanup_status}, 'not_needed', 'Live root never needs mount cleanup');
    ok(!grep($_ eq 'mount' || $_ eq 'unmount', @$events), 'No live mount or unmount was attempted');
    is($tools->arguments->[2], 'dir:/', 'Live scanner source cannot be supplied by the request');
    ok(grep($_ eq './var/lib/mogura', @{$tools->arguments}),
        'Live scanner receives output exclusion');
    like(
        join(' ', @{$scan->{warnings}}),
        qr/Uninspected live filesystem path.*\/proc/,
        'Live exclusions also produce uninspected warnings'
    );
}

# A per-disk lock excludes other processes and is released when its holder
# exits; distinct disks remain independent.
{
    my $dir = tempdir(CLEANUP => 1);
    my $config = Mogura::Scanner::Config->new(state => $dir, runtime => "$dir/run");
    my $scanner = Mogura::Scanner::Scan->new(config => $config);
    my $lock = $scanner->_acquire_lock('disk-fixture');
    my $pid = fork;
    die "fork: $!" unless defined $pid;
    if (!$pid) {
        close $lock;
        my $other = eval { $scanner->_acquire_lock('disk-fixture') };
        my $excluded = !$other && $@ =~ /already being processed/;
        my $distinct = eval { $scanner->_acquire_lock('disk-other') };
        POSIX::_exit($excluded && $distinct ? 0 : 1);
    }
    waitpid($pid, 0);
    is($?, 0, 'Other processes can lock distinct disks but cannot share a disk');
    close $lock;
    ok($scanner->_acquire_lock('disk-fixture'), 'Disk becomes available after lock release');
}

{
    my ($completed, $store) = scan_case('');
    my $scanner = Mogura::Scanner::Scan->new(config => $store->config, store => $store);
    eval { $scanner->run({id => $completed->{id}, token => 'b' x 64, tags => ['duplicate']}) };
    like($@, qr/already been processed/, 'Duplicate scan ID cannot start again');
    is_deeply($store->get($completed->{id}),
        $completed, 'Duplicate cannot rewrite completed history');
}

done_testing;
