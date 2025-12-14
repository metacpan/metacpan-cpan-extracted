use strict;
use warnings;
use Test::More;
use JSON::PP;
use Sys::Monitor::Lite;

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

# done_testing automatically counts subtests
done_testing();
