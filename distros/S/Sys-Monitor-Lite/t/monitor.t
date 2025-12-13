use strict;
use warnings;
use Test::More;
use JSON::PP;
use File::Spec;
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

subtest 'json encoding' => sub {
    my $json = Sys::Monitor::Lite::to_json({ foo => 'bar' });
    my $decoded = JSON::PP->new->decode($json);
    is($decoded->{foo}, 'bar', 'default JSON roundtrip');

    my $pretty = Sys::Monitor::Lite::to_json({ foo => 'bar' }, pretty => 1);
    like($pretty, qr/\n/, 'pretty JSON contains newline');
};

subtest 'yaml encoding' => sub {
    my $yaml = Sys::Monitor::Lite::to_yaml({
        foo => 'bar',
        list => [1, 2],
        hash => { nested => 'value' },
    });
    like($yaml, qr/^foo: bar$/m, 'YAML encodes scalar');
    like($yaml, qr/^list:\n  - 1\n  - 2/m, 'YAML encodes array');
    like($yaml, qr/^hash:\n  nested: value$/m, 'YAML encodes hash');
};

subtest 'cli integration' => sub {
    my $perl = $^X;
    my $script = File::Spec->catfile('script', 'sys-monitor-lite');
    my $output = qx{$perl $script --once --collect system --output json};
    ok($? == 0, 'cli exited successfully');

    my $decoded = eval { JSON::PP->new->decode($output) };
    ok(!$@, 'cli output is valid JSON');
    isa_ok($decoded->{system}, 'HASH', 'cli returned system data');

    my $yaml_output = qx{$perl $script --once --collect system --output yaml};
    ok($? == 0, 'cli exited successfully for YAML');
    like($yaml_output, qr/^system:/m, 'cli YAML output contains system key');

    my $proc_output = qx{$perl $script --once --top cpu=3 --output json};
    ok($? == 0, 'cli exited successfully for --top');
    my $proc_decoded = eval { JSON::PP->new->decode($proc_output) };
    ok(!$@, 'cli --top output is valid JSON');
    isa_ok($proc_decoded->{process}, 'ARRAY', 'process metric returned');
};

subtest 'threshold evaluation helpers' => sub {
    my $data = {
        mem  => { used_pct => 75 },
        load => { '1min' => 1.2 },
    };

    my @metrics = Sys::Monitor::Lite::metrics_from_thresholds(
        ['mem.used_pct>80'],
        ['load.1min>2'],
    );
    is_deeply(\@metrics, [qw(load mem)], 'extracts metric roots from thresholds');

    my $ok = Sys::Monitor::Lite::evaluate_thresholds(
        $data,
        warn => ['mem.used_pct>80', 'load.1min>2'],
        crit => ['mem.used_pct>90'],
    );
    is($ok->{status}, 0, 'status OK when under thresholds');
    like($ok->{message}, qr/^OK - load\.1min=1\.2 \(>2\); mem\.used_pct=75 \(>80 >90\)$/,
        'formats OK message with thresholds');

    my $warn = Sys::Monitor::Lite::evaluate_thresholds(
        $data,
        warn => ['mem.used_pct>=70'],
    );
    is($warn->{status}, 1, 'warn triggered');
    like($warn->{message}, qr/^WARN - mem\.used_pct=75 \(>=70\)$/,
        'warn message shown');

    my $crit = Sys::Monitor::Lite::evaluate_thresholds(
        $data,
        crit => ['mem.used_pct>=75'],
    );
    is($crit->{status}, 2, 'crit triggered');
    like($crit->{message}, qr/^CRIT - mem\.used_pct=75 \(>=75\)$/,
        'crit message shown');

    my $missing = Sys::Monitor::Lite::evaluate_thresholds(
        $data,
        crit => ['disk.0.used_pct>80'],
    );
    is($missing->{status}, 2, 'missing value treated as critical');
    like($missing->{message}, qr/CRIT - disk\.0\.used_pct=N\/A/, 'missing path noted');
};
# ensure subtests run before done_testing

# done_testing automatically counts subtests

done_testing();
