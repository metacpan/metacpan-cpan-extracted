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
    {'a' => 0}, '81 c4 01 61 00',
    {2 => undef}, '81 c4 01 32 c0',
);

for (my $i = 0; $i < scalar (@data); $i += 2)
{
	is packit ($data[$i]), $data[$i+1], "dump ".$data[$i+1];
}

done_testing;
