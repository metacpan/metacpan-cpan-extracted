use strict;
use warnings;

use Test::More tests => 2;

use MsgPack::Decoder;

my $decoder = MsgPack::Decoder->new(
    log_to_stderr => 1,
    debug         => 0,
);

sub to_binary { map { chr } @_ }

is_deeply $decoder->read_all( to_binary  0x94, 1, 2, 0xc0, 0xc0 ) => [1,2,undef,undef];

is_deeply $decoder->read_all( to_binary  0x94, 1, 3, 0xc0, 0xa0 ) => [1,3,undef,''];
