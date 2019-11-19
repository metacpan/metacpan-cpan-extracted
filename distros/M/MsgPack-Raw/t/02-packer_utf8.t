#!perl

use Test::More;
use MsgPack::Raw;
use Encode;

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
	"",    'a0',
	"a",   'a1 61',
	"€",   'a3 e2 82 ac',
	"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", 'bf 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61',
	"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", 'd9 20 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61',
);

for (my $i = 0; $i < scalar (@data); $i += 2)
{
	$data[$i] = Encode::decode ('UTF-8', $data[$i]);
	is packit ($data[$i]), $data[$i+1], "dump ".$data[$i+1];
}

done_testing;
