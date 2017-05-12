# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Apache-Sling.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 12;
use Test::Exception;
BEGIN { use_ok( 'Sakai::Nakamura::UserUtil' ); }
BEGIN { use_ok( 'HTTP::Response' ); }

my $res = HTTP::Response->new( '200' );

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
my @properties = '';
ok( Sakai::Nakamura::UserUtil::me_setup( 'http://localhost:8080' ) eq
  "get http://localhost:8080/system/me", 'Check me_setup function' );
ok( Sakai::Nakamura::UserUtil::profile_update_setup( 'http://localhost:8080', 'field', 'value', 'user', 'section' ) eq
  q{post http://localhost:8080/~user/public/authprofile/section.profile.json $post_variables = [':content','{"elements":{"field":{"value":"value"}}}',':contentType','json',':operation','import',':removeTree','true',':replace','true',':replaceProperties','true']}, 'Check profile_update_setup function' );
# Check section defaults to basic:
ok( Sakai::Nakamura::UserUtil::profile_update_setup( 'http://localhost:8080', 'field', 'value', 'user' ) eq
  q{post http://localhost:8080/~user/public/authprofile/basic.profile.json $post_variables = [':content','{"elements":{"field":{"value":"value"}}}',':contentType','json',':operation','import',':removeTree','true',':replace','true',':replaceProperties','true']}, 'Check profile_update_setup function' );

throws_ok { Sakai::Nakamura::UserUtil::me_setup() } qr/No base url to run me against!/, 'Check me_setup function croaks without base url';
throws_ok { Sakai::Nakamura::UserUtil::profile_update_setup() } qr/No base url to run profile update against!/, 'Check profile_update_setup function croaks without base url';
throws_ok { Sakai::Nakamura::UserUtil::profile_update_setup('http://localhost:8080') } qr/No profile field to update specified!/, 'Check profile_update_setup function croaks without field';
throws_ok { Sakai::Nakamura::UserUtil::profile_update_setup('http://localhost:8080', 'field') } qr/No value specified to set profile field to!/, 'Check profile_update_setup function croaks without value';
throws_ok { Sakai::Nakamura::UserUtil::profile_update_setup('http://localhost:8080', 'field', 'value') } qr/No user specified to update profile for!/, 'Check profile_update_setup function croaks without user';

ok( Sakai::Nakamura::UserUtil::me_eval( \$res ), 'Check me_eval function' );
ok( Sakai::Nakamura::UserUtil::profile_update_eval( \$res ), 'Check profile_update_eval function' );
