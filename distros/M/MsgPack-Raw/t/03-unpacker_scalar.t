#!perl

use Encode;
use Test::More;
use MsgPack::Raw;

my $packer = MsgPack::Raw::Packer->new;
my $unpacker = MsgPack::Raw::Unpacker->new;

$unpacker->feed ($packer->pack ('abc'));
$unpacker->feed ($packer->pack (1));
$unpacker->feed ($packer->pack (-1));
$unpacker->feed ($packer->pack (3.14));
$unpacker->feed ($packer->pack ([undef]));
$unpacker->feed ("\xa3\xe2\x82\xac");

is $unpacker->next, 'abc';
is $unpacker->next, 1;
is $unpacker->next, -1;
ok (abs ($unpacker->next -3.14) < 0.000001);
is_deeply $unpacker->next, [undef];
is $unpacker->next, Encode::decode ('UTF-8', "€");

ok !$unpacker->next, 'everything consumed';

done_testing();

