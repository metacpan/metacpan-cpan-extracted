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
 table    => 'cms_users',
 login    => 'someuser',
 password => 'somepass',
);

my $check_auth_query;

for ( my $i = 0; $i <= 100; $i++ )
{
 my $q = join'', map +(0..9,'a'..'z','A'..'Z')[rand(10+26*2)], 1..10;
 $check_auth_query = $SQLib->get_query( $q, \%sql_params );
 ok( !$check_auth_query ) or warn "Strange... $q exists?";
}

$check_auth_query = undef;
$check_auth_query = $SQLib->get_query( 'CHECK_PASSWORD', \%sql_params );
ok( $check_auth_query ) or warn "Strange... CHECK_PASSWORD doesn't exist but it should...";
