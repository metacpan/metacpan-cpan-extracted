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
 tablex    => 'cms_users',
 loginx    => 'someuser',
 passwordx => 'somepass',
);

my $check_auth_query = $SQLib->get_query( 'CHECK_PASSWORD', \%sql_params );

unlike( $check_auth_query, qr/somepass/ ) ;
unlike( $check_auth_query, qr/someuser/ ) ;
unlike( $check_auth_query, qr/cms_users/ ) ;

like( $check_auth_query, qr/\{table\}/ ) ;
like( $check_auth_query, qr/\{login\}/ ) ;
like( $check_auth_query, qr/\{password\}/ ) ;
