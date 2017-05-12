
BEGIN {

  $DB::single = 1;

  unless ( $ENV{ AUTHOR_TESTING } ) {

    require Test::More;
    Test::More::plan( skip_all => 'these tests are for testing by the author' );

  }

  unless ( exists $ENV{ GITLAB_EMAIL }
    && exists $ENV{ GITLAB_PASSWORD }
    && exists $ENV{ GITLAB_BASEURL } ) {

    require Test::More;
    Test::More::plan(
      skip_all => 'Environment variables GITLAB_EMAIL, GITLAB_PASSWORD and GITLAB_BASEURL must be set to run this test' )

  }

} ## end BEGIN

use strict;
use warnings;

use Test::More tests => 4;

use_ok( 'Net::Gitlab' );

my $test_object = Net::Gitlab->new;
isa_ok( $test_object, 'Net::Gitlab', 'object instantiated' );

my $test_login = Net::Gitlab->new( base_url => $ENV{ GITLAB_BASEURL } );
isa_ok( $test_login, 'Net::Gitlab', 'object instantiated with base_url' );
ok( $test_login->base_url, $ENV{ GITLAB_BASEURL } );

#my $user = $session->login( email => $ENV{ GITLAB_EMAIL }, password => $ENV{ GITLAB_PASSWORD } );
