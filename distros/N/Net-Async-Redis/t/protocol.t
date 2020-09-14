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
my @resp2 = (
    [ "+OK$Z" => 'OK', 'simple string' ],
    [ ":123$Z" => 123, 'a number' ],
    [ ":0$Z" => 0, 'zero integer' ],
    [ "+123.45$Z" => "123.45", 'floating-point number' ],
    [ "+123.0$Z" => "123.0", 'floating-point number that would be an integer without the trailing zero' ],
    [ "+123.4500$Z" => "123.4500", 'floating-point number with trailing zeroes' ],
    [ "+789$Z" => "789", 'a string that happens to look like an integer' ],
    [ "\$0$Z$Z" => "", 'empty string' ],
    [ "\$-1$Z" => undef, 'null' ],
    [ "\$100${Z}" . ('x' x 100) . "$Z" => ('x' x 100), 'bulk string' ],
    [ "*0$Z" => [], 'empty array' ],
    [ "*1$Z:456$Z" => [456], 'single-element array' ],
    [ "*1$Z*1$Z:456$Z" => [[456]], 'nested single-element array' ],
    [ "*2$Z:808$Z:303$Z" => [808, 303], '2-element array' ],
    [ "*3$Z\$-1$Z:404$Z\$0$Z$Z" => [undef, 404, ""], 'mixed array' ],
);

my @resp3 = (
    [ "_$Z" => undef, 'single-character null' ],
    [ ",1.23$Z" => 1.23, 'double' ],
    [ ",inf$Z" => 0+"Inf", 'infinity' ],
    [ ",-inf$Z" => 0+"-Inf", 'infinity' ],
    # Requires some poking around in internals, since
    # we would only need this for the server implementation
    # have left it out for now.
    # [ "#t$Z" => !!1, 'true' ],
    # [ "#f$Z" => !!0, 'false' ],
    [ "%2$Z+key$Z:1$Z+second$Z:2$Z", +{ key => 1, second => 2 }, 'map' ],
);

subtest decoding => sub {
    my $proto = new_ok('Net::Async::Redis::Protocol', [
        handler => sub { fail 'bad handler' }
    ]);

    for my $case (@resp2, @resp3) {
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

subtest 'RESP2 encoding' => sub {
    my $proto = new_ok('Net::Async::Redis::Protocol', [
        protocol => 'resp2',
        handler => sub { fail 'bad handler' }
    ]);

    for my $case (@resp2) {
        my ($bytes, $data, $msg) = @$case;
        my $actual = $proto->encode($data);
        cmp_deeply($actual, $bytes, $msg // 'data matches');
    }
};

subtest 'RESP3 encoding' => sub {
    my $proto = new_ok('Net::Async::Redis::Protocol', [
        protocol => 'resp3',
        handler => sub { fail 'bad handler' }
    ]);

    for my $case (@resp3) {
        my ($bytes, $data, $msg) = @$case;
        my $actual = $proto->encode($data);
        cmp_deeply($actual, $bytes, $msg // 'data matches');
    }
};

subtest roundtrip => sub {
    my $proto = new_ok('Net::Async::Redis::Protocol', [
        protocol => 'resp2',
        handler => sub { fail 'bad handler' }
    ]);

    for my $case (@resp2) {
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


