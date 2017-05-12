# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Apache-Sling.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 10;
use Test::Exception;
BEGIN { use_ok( 'Sakai::Nakamura::AuthnUtil' ); }
BEGIN { use_ok( 'HTTP::Response' ); }

my $res = HTTP::Response->new( '200' );

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
ok( Sakai::Nakamura::AuthnUtil::form_login_setup( 'http://localhost:8080', 'admin', 'admin') eq
  q(post http://localhost:8080/system/sling/formlogin $post_variables = ['sakaiauth:un','admin','sakaiauth:pw','admin','sakaiauth:login','1']),
  'Check form_login_setup function' );

ok( Sakai::Nakamura::AuthnUtil::form_logout_setup( 'http://localhost:8080' ) eq
  q(get http://localhost:8080/system/sling/logout?resource=/index), 'Check form_logout_setup function' );

ok( Sakai::Nakamura::AuthnUtil::form_login_eval( \$res ), 'Check form_login_eval function' );
ok( Sakai::Nakamura::AuthnUtil::form_logout_eval( \$res ), 'Check form_logout_eval function' );

throws_ok { Sakai::Nakamura::AuthnUtil::form_login_setup() } qr/No base url defined!/, 'Check form_login_setup function croaks without base url';
throws_ok { Sakai::Nakamura::AuthnUtil::form_login_setup( 'http://localhost:8080' ) } qr/No username supplied to attempt logging in with!/, 'Check form_login_setup function croaks without username';
throws_ok { Sakai::Nakamura::AuthnUtil::form_login_setup( 'http://localhost:8080', 'username' ) } qr/No password supplied to attempt logging in with for user name: username!/, 'Check form_login_setup function croaks without password';

throws_ok { Sakai::Nakamura::AuthnUtil::form_logout_setup() } qr/No base url defined!/, 'Check form_logout_setup function croaks without base url';
