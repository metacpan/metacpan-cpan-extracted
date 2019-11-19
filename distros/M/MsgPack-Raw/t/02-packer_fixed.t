#!perl

use Test::More;
use MsgPack::Raw;

my $packer = MsgPack::Raw::Packer->new;
isa_ok $packer, 'MsgPack::Raw::Packer';

sub packit
{
    local $_ = unpack ("H*", $packer->pack ($_[0]));
    s/(..)/$1 /g;
    s/ $//;
    $_;
}

my @data =
(
    0,     '00',
    1,     '01',
    127,   '7f',
    -1,    'ff',
    -32,   'e0',
	undef, 'c0',
	MsgPack::Raw::Bool::true(),  'c3',
	MsgPack::Raw::Bool::false(), 'c2',
);

for (my $i = 0; $i < scalar (@data); $i += 2)
{
	is packit ($data[$i]), $data[$i+1], "dump ".$data[$i+1];
}

done_testing;
