#!perl

use Test::More;
use MsgPack::Raw;

my $true = MsgPack::Raw::Bool::true();
isa_ok $true, 'MsgPack::Raw::Bool';
is 0+$true, 1;
is $true, 'true';
ok $true;

my $false = MsgPack::Raw::Bool::false();
isa_ok $false, 'MsgPack::Raw::Bool';
is 0+$false, 0;
is $false, 'false';
ok !$false;

done_testing;
