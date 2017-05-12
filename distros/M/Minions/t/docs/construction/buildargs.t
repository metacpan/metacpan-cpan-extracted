use strict;
use Test::Lib;
use Test::More tests => 3;
use Example::Construction::Set_v1;

my $set = Example::Construction::Set_v1->new(1 .. 4);

ok $set->has(1);
ok ! $set->has(5);
$set->add(5);
ok $set->has(5);
