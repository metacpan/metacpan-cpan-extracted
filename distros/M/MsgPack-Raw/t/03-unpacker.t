#!perl

use Test::More;
use MsgPack::Raw;

my $unpacker = MsgPack::Raw::Unpacker->new;
isa_ok $unpacker, 'MsgPack::Raw::Unpacker';

ok !$unpacker->next, 'nothing fed yet';

done_testing();

