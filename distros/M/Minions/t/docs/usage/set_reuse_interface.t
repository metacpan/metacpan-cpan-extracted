use strict;
use Test::Lib;
use Test::More tests => 3;
use Example::Usage::SetReuseInterface;

my $set = Example::Usage::SetReuseInterface->new;

ok ! $set->has(1);

$set->add(1);
ok $set->has(1);

ok $set->DOES('Example::Usage::SetInterface');
