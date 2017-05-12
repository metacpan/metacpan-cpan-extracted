use strict;
use Scalar::Util qw( reftype );
use Test::Lib;
use Test::More tests => 3;
use Minions
    bind => { 'Example::Usage::Set' => 'Example::Usage::HashSet' };

use Example::Usage::Set;

my $set = Example::Usage::Set->new;

is reftype $set->{$Example::Usage::HashSet::SET} => 'HASH';

ok ! $set->has(1);
$set->add(1);
ok $set->has(1);
