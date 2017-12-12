use strict;
use warnings;

use utf8;
BEGIN {
    # I am philosophically opposed to the necessity for such
    # workarounds, but some crazy person put dots over some
    # of the letters in the output.
    binmode STDOUT, ':encoding(UTF-8)';
    binmode STDERR, ':encoding(UTF-8)';
}

use Test::More;
use Test::Deep;
use Test::HexString;

use Net::Async::Redis::Protocol;

my $Z = "\x0D\x0A";
my @testcases = (
    [ "+OK$Z" => 'OK', 'simple string' ],
    [ ":123$Z" => 123, 'a number' ],
    [ "\$0$Z$Z" => "", 'empty string' ],
    [ "\$-1$Z" => undef, 'null' ],
    [ "\$100${Z}" . ('x' x 100) . "$Z" => ('x' x 100), 'bulk string' ],
    [ "*0$Z" => [], 'empty array' ],
    [ "*1$Z:456$Z" => [456], 'single-element array' ],
    [ "*1$Z*1$Z:456$Z" => [[456]], 'nested single-element array' ],
    [ "*2$Z:808$Z:303$Z" => [808, 303], '2-element array' ],
    [ "*3$Z\$-1$Z:404$Z\$0$Z$Z" => [undef, 404, ""], 'mixed array' ],
);

subtest decoding => sub {
    my $proto = new_ok('Net::Async::Redis::Protocol', [
        handler => sub { fail 'bad handler' }
    ]);

    for my $case (@testcases) {
        my ($bytes, $data, $msg) = @$case;
        my $call_count = 0;
        local $proto->{handler} = sub {
            my $item = shift;
            ++$call_count;
            cmp_deeply($item, $data, $msg // 'data matches');
        };
        $proto->decode(\$bytes);
        fail('unexpected callback count - ' . $call_count . ' (should be 1)') unless $call_count == 1;
        fail('leftover data') if length $bytes;
    }
};

subtest encoding => sub {
    my $proto = new_ok('Net::Async::Redis::Protocol', [
        handler => sub { fail 'bad handler' }
    ]);

    for my $case (@testcases) {
        my ($bytes, $data, $msg) = @$case;
        my $actual = $proto->encode($data);
        cmp_deeply($actual, $bytes, $msg // 'data matches');
    }
};

subtest roundtrip => sub {
    my $proto = new_ok('Net::Async::Redis::Protocol', [
        handler => sub { fail 'bad handler' }
    ]);

    for my $case (@testcases) {
        my ($bytes, $data, $msg) = @$case;
        my $original_bytes = $bytes;
        my $call_count = 0;
        local $proto->{handler} = sub {
            my $item = shift;
            ++$call_count;
            cmp_deeply($item, $data, $msg // 'data matches');
            is_hexstr($proto->encode($item), $original_bytes, 'reëncoding works');
        };
        $proto->decode(\$bytes);
        fail('unexpected callback count - ' . $call_count . ' (should be 1)') unless $call_count == 1;
        fail('leftover data') if length $bytes;
    }
};

done_testing;


