use strict;
use warnings;
use Test::More;
use Sys::Monitor::Lite;

subtest 'available metrics' => sub {
    my @metrics = Sys::Monitor::Lite::available_metrics();
    is_deeply(\@metrics, [qw(cpu disk disk_io load mem mounts net process system)], 'expected metric list');
};

subtest 'collect_all structure' => sub {
    my $data = Sys::Monitor::Lite::collect_all();
    isa_ok($data, 'HASH', 'collect_all returns hashref');
    ok($data->{timestamp}, 'timestamp present');

    for my $key (qw(system cpu load mem disk disk_io net)) {
        ok(exists $data->{$key}, "$key metric present");
    }

    isa_ok($data->{system}, 'HASH', 'system data');
    isa_ok($data->{cpu}, 'HASH', 'cpu data');
    isa_ok($data->{load}, 'HASH', 'load data');
    isa_ok($data->{mem}, 'HASH', 'mem data');
    isa_ok($data->{mounts}, 'HASH', 'mount data');
    isa_ok($data->{disk}, 'ARRAY', 'disk data');
    ok(@{ $data->{disk} } >= 1, 'at least one disk entry collected');
    my $disk = $data->{disk}[0];
    isa_ok($disk, 'HASH', 'disk entry structure');
    for my $field (qw(mount filesystem type total_bytes used_bytes free_bytes used_pct options read_only inodes_total inodes_used inodes_free inodes_used_pct)) {
        ok(exists $disk->{$field}, "disk entry has $field");
    }
    if (%{ $data->{mounts} }) {
        my ($first_mount_key) = sort keys %{ $data->{mounts} };
        my $mount_info = $data->{mounts}{$first_mount_key};
        isa_ok($mount_info, 'HASH', 'mount entry structure');
        for my $field (qw(present mount filesystem type options read_only)) {
            ok(exists $mount_info->{$field}, "mount entry has $field");
        }
    }
    isa_ok($data->{disk_io}, 'ARRAY', 'disk_io data');
    if (@{ $data->{disk_io} }) {
        my $io = $data->{disk_io}[0];
        isa_ok($io, 'HASH', 'disk_io entry structure');
        for my $field (qw(device sector_size reads writes in_progress io_ms weighted_io_ms)) {
            ok(exists $io->{$field}, "disk_io entry has $field");
        }
        isa_ok($io->{reads}, 'HASH', 'disk_io reads structure');
        isa_ok($io->{writes}, 'HASH', 'disk_io writes structure');
        for my $rw (qw(reads writes)) {
            for my $field (qw(ios merged sectors bytes ms)) {
                ok(exists $io->{$rw}{$field}, "disk_io $rw has $field");
            }
        }
    }
    isa_ok($data->{net}, 'ARRAY', 'net data');
};

subtest 'process metric collection' => sub {
    my $data = Sys::Monitor::Lite::collect(['process']);
    isa_ok($data->{process}, 'ARRAY', 'process data is array');
    if (@{ $data->{process} }) {
        my $proc = $data->{process}[0];
        isa_ok($proc, 'HASH', 'process entry structure');
        for my $field (qw(pid name command cpu_pct rss_bytes)) {
            ok(exists $proc->{$field}, "process entry has $field");
        }
    }
};

subtest 'selective collect' => sub {
    my $data = Sys::Monitor::Lite::collect(['system', 'cpu']);
    isa_ok($data, 'HASH', 'collect returns hashref');
    is_deeply([sort grep { $_ ne 'timestamp' } keys %$data], [qw(cpu system)], 'only requested metrics collected');
};

# done_testing automatically counts subtests
done_testing();
