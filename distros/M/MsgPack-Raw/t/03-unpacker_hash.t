#!perl

use Test::More;
use MsgPack::Raw;

my $packer = MsgPack::Raw::Packer->new;
my $unpacker = MsgPack::Raw::Unpacker->new;

$unpacker->feed ($packer->pack ({abc => 'def'}));
is_deeply $unpacker->next, {abc => 'def'};
ok !$unpacker->next, 'everything consumed';

$unpacker->feed ($packer->pack ({abc => 'def', ghi => 'jkl', mno => MsgPack::Raw::Bool::true()}));
is_deeply $unpacker->next, {abc => 'def', ghi => 'jkl', mno => MsgPack::Raw::Bool::true()};
ok !$unpacker->next, 'everything consumed';

done_testing();

