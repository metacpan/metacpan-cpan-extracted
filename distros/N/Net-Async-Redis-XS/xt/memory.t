use strict;
use warnings;

use Test::More;
use Test::MemoryGrowth;

use Test::Fatal;
use Net::Async::Redis::XS;

my $instance = Net::Async::Redis::Protocol::XS->new;
our $Z = "\x0D\x0A";
note 'scalar';
no_growth {
    my $ret = Net::Async::Redis::XS::decode_buffer($instance, ":3$Z");
    die unless $ret == 3;
} 'scalar context simple integer';
note 'array';
no_growth {
    my ($ret) = Net::Async::Redis::XS::decode_buffer($instance, ":3$Z");
    die unless $ret == 3;
} 'list context simple integer';
note 'nested';
no_growth {
    my @x = Net::Async::Redis::XS::decode_buffer($instance,
        "*1$Z*1$Z*2$Z+8$Z*6$Z+a$Z+83894$Z+b$Z+2$Z+c$Z+3$Z"
        # "*1$Z*1$Z*2$Z:8$Z*6$Z+a$Z:83894$Z+b$Z+2$Z+c$Z+3$Z"
    );
} 'nested data structure';
no_growth {
    my $src = "*1$Z*1$Z*2$Z:8$Z*6$Z+a$Z:83894$Z+b$Z+2$Z+c$Z+3$Z";
    for(0..length($src)) {
        my $data = substr($src, 0, $_);
        my @x = Net::Async::Redis::XS::decode_buffer($instance,
            $data
        );
    }
} 'partial parsing of nested data structures';

done_testing;

