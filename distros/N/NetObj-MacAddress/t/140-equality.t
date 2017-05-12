#!perl
use strict;
use warnings FATAL => 'all';
use 5.10.1;

BEGIN { chdir 't' if -d 't'; }
use lib '../lib';

use Test::More; END { done_testing; }

use NetObj::MacAddress;

my $mac1 = NetObj::MacAddress->new('001234abcdef');
my $mac2 = NetObj::MacAddress->new($mac1);
my $mac3 = NetObj::MacAddress->new('102030aabbcc');

cmp_ok($mac1, '==', $mac1, 'same object should be equal numerically');
cmp_ok($mac1, '==', $mac2, 'same MAC should be equal numerically');
cmp_ok($mac1, '!=', $mac3, 'different MAC shall not be equal numerically');

cmp_ok($mac1, 'eq', $mac1, 'same object should be equal stringwise');
cmp_ok($mac1, 'eq', $mac2, 'same MAC should be equal stringwise');
cmp_ok($mac1, 'ne', $mac3, 'different MAC shall not be equal stringwise');
