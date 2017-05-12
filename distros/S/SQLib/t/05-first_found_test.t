#!perl -T
use 5.006;
use strict;
use Test::More 'no_plan';
use Test::More;

use_ok( 'SQLib' ) or die;
use SQLib;

my $SQLib = SQLib->new( './t/example-good.sql' );
ok( $SQLib ) or warn "\$SQLib is not inititialized.";

my %sql_params =
(
 table    => 'a',
 login    => 'b',
 password => 'c',
);

my $check_auth_query = $SQLib->get_query( 'CHECK_PASSWORD', \%sql_params );
cmp_ok( $check_auth_query, 'ne', 'a:b:c', '' );
