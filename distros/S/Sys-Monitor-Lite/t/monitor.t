use strict;
use warnings;
use Test::More;
use JSON::PP;
use File::Spec;
use Sys::Monitor::Lite;

subtest 'available metrics' => sub {
    my @metrics = Sys::Monitor::Lite::available_metrics();
    is_deeply(\@metrics, [qw(cpu disk load mem net system)], 'expected metric list');
};

subtest 'collect_all structure' => sub {
    my $data = Sys::Monitor::Lite::collect_all();
    isa_ok($data, 'HASH', 'collect_all returns hashref');
    ok($data->{timestamp}, 'timestamp present');

    for my $key (qw(system cpu load mem disk net)) {
        ok(exists $data->{$key}, "$key metric present");
    }

    isa_ok($data->{system}, 'HASH', 'system data');
    isa_ok($data->{cpu}, 'HASH', 'cpu data');
    isa_ok($data->{load}, 'HASH', 'load data');
    isa_ok($data->{mem}, 'HASH', 'mem data');
    isa_ok($data->{disk}, 'ARRAY', 'disk data');
    ok(@{ $data->{disk} } >= 1, 'at least one disk entry collected');
    my $disk = $data->{disk}[0];
    isa_ok($disk, 'HASH', 'disk entry structure');
    for my $field (qw(mount filesystem type total_bytes used_bytes free_bytes used_pct)) {
        ok(exists $disk->{$field}, "disk entry has $field");
    }
    isa_ok($data->{net}, 'ARRAY', 'net data');
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

subtest 'cli integration' => sub {
    my $perl = $^X;
    my $script = File::Spec->catfile('script', 'sys-monitor-lite');
    my $output = qx{$perl $script --once --collect system --output json};
    ok($? == 0, 'cli exited successfully');

    my $decoded = eval { JSON::PP->new->decode($output) };
    ok(!$@, 'cli output is valid JSON');
    isa_ok($decoded->{system}, 'HASH', 'cli returned system data');
};
# ensure subtests run before done_testing

# done_testing automatically counts subtests

done_testing();
