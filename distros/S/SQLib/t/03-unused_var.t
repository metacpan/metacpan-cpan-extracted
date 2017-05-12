#!perl -T
use 5.006;
use strict;
use Test::More 'no_plan';
use Test::More;

use_ok( 'SQLib' ) or die;
use SQLib;

my $SQLib = SQLib->new( './t/example-good.sql' );
ok( $SQLib ) or warn "\$SQLib is not inititialized.";

### Too many vars
my %sql_params =
(
 table    => 'cms_users',
 login    => 'someuser',
 password => 'somepass',
);

my %tab;

for ( my $i = 0; $i <= 100; $i++ )
{
 my $x = join'', map +(0..9,'a'..'z','A'..'Z')[rand(10+26*2)], 1..10;
 my $q = join'', map +(0..9,'a'..'z','A'..'Z')[rand(10+26*2)], 1..10;
 $sql_params{ $x } = $q;
 $tab{ $x } = $q;
}

my $check_auth_query = $SQLib->get_query( 'CHECK_PASSWORD', \%sql_params );

ok( $check_auth_query ) or warn "Something is wrong with \$check_auth_query...";

like( $check_auth_query, qr/cms_users/, '.. checking for cms_users in replaced query' ) 
 or warn "The replaced cms_users var not founded." ;

like( $check_auth_query, qr/someuser/, '.. checking for someuser in replaced query' ) 
 or warn "The replaced someuser var not founded." ;

like( $check_auth_query, qr/somepass/, '.. checking for somepass in replaced query' ) 
 or warn "The replaced somepass var not founded." ;

foreach my $key ( keys( %tab ) )
{
 unlike( $check_auth_query, qr/$tab{ $key }/, '.. checking for the invalid value '.$tab{ $key }.' in replaced query' ) 
  or warn 'The replaced invalid value '.$tab{ $key }.' founded!' ;
}

