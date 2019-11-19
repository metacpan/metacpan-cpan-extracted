#!perl

use Test::More;
use MsgPack::Raw;

my $packer = MsgPack::Raw::Packer->new;
my $unpacker = MsgPack::Raw::Unpacker->new;

$unpacker->feed ($packer->pack (['abc']));
is_deeply $unpacker->next, ['abc'];
ok !$unpacker->next, 'everything consumed';

$unpacker->feed ($packer->pack (['abc', 123, MsgPack::Raw::Bool::false()]));
is_deeply $unpacker->next, ['abc', 123, MsgPack::Raw::Bool::false()];
ok !$unpacker->next, 'everything consumed';

done_testing();

