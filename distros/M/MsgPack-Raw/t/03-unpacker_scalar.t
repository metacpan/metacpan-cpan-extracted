#!perl

use Test::More;
use MsgPack::Raw;

my $packer = MsgPack::Raw::Packer->new;
my $unpacker = MsgPack::Raw::Unpacker->new;

$unpacker->feed ($packer->pack ('abc'));
is $unpacker->next, 'abc';
ok !$unpacker->next, 'everything consumed';

done_testing();

