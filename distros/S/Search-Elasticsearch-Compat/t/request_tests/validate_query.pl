#!perl

use Test::More;
use strict;
use warnings;
our $es;
my $r;

is $es->validate_query( query => { match_all => {} } )->{valid}, 1,
    ' - query ok';
is $es->validate_query( query => { foo => {} } )->{valid}, 0,
    ' - query not ok';

is $es->validate_query( queryb => { -all => 1 } )->{valid}, 1, ' - queryb ok';

is $es->validate_query( queryb => { -foo => 1 } )->{valid}, 0,
    ' - queryb not ok';

is $es->validate_query( q => '*' )->{valid},    1, ' - q ok';
is $es->validate_query( q => 'foo:' )->{valid}, 0, ' - q not ok';

ok $es->validate_query( q => 'foo:', explain => 1 )->{explanations},
    ' - with explanations';

throws_ok { $es->validate_query( query => 'foo', queryb => 'foo' ) }
qr/Cannot specify/, ' - query and queryb';

throws_ok { $es->validate_query( q => 'foo', queryb => 'foo' ) }
qr/Cannot specify/, ' - q and queryb';

throws_ok { $es->validate_query( q => 'foo', query => 'foo' ) }
qr/Cannot specify/, ' - q and query';
