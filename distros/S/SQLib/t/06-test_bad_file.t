#!perl -T
use 5.006;
use strict;
use Test::More 'no_plan';
use Test::More;

use_ok( 'SQLib' ) or die;
use SQLib;

my $SQLib = SQLib->new( './t/example-bad.sql' );
ok( $SQLib ) or warn "\$SQLib is not inititialized.";

my %sql_params =
(
 table    => 'a',
 login    => 'b',
 password => 'c',
);

my $check_auth_query;

$check_auth_query = $SQLib->get_query( 'CHECK_PASSWORD', \%sql_params );
ok( !$check_auth_query );

$check_auth_query = undef;
$check_auth_query = $SQLib->get_query( 'TEST1', \%sql_params );
like( $check_auth_query, qr/a:b:c/, '' );

$check_auth_query = undef;
$check_auth_query = $SQLib->get_query( 'TEST2', \%sql_params );
ok( !$check_auth_query );

$check_auth_query = undef;
$check_auth_query = $SQLib->get_query( 'TEST3', \%sql_params );
ok( !$check_auth_query );

$check_auth_query = undef;
$check_auth_query = $SQLib->get_query( 'TEST4', \%sql_params );
ok( !$check_auth_query );

$check_auth_query = undef;
$check_auth_query = $SQLib->get_query( 'TEST5', \%sql_params );
ok( !$check_auth_query );

$check_auth_query = undef;
$check_auth_query = $SQLib->get_query( 'TEST6', \%sql_params );
ok( !$check_auth_query );

$check_auth_query = undef;
$check_auth_query = $SQLib->get_query( 'TEST7', \%sql_params );
ok( !$check_auth_query );

$check_auth_query = undef;
$check_auth_query = $SQLib->get_query( 'TEST10', \%sql_params );
like( $check_auth_query, qr/\{email\}/, '' );



