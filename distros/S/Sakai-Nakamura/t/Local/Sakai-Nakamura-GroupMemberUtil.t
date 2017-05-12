# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Apache-Sling.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 8;
use Test::Exception;
BEGIN { use_ok( 'Sakai::Nakamura::GroupMemberUtil' ); }
BEGIN { use_ok( 'HTTP::Response' ); }

my $res = HTTP::Response->new( '200' );

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
my @properties = '';
ok( Sakai::Nakamura::GroupMemberUtil::add_setup( 'http://localhost:8080', 'group', 'role', 'member' ) eq
  "post http://localhost:8080/system/userManager/group/group-role.update.json \$post_variables = [':member','member',':viewer','member']", 'Check add_setup function' );

throws_ok { Sakai::Nakamura::GroupMemberUtil::add_setup() } qr/No base url defined to add against!/, 'Check add_setup function croaks without base url';
throws_ok { Sakai::Nakamura::GroupMemberUtil::add_setup( 'http://localhost:8080' ) } qr/No group name defined to add member to!/, 'Check add_setup function croaks without group';
throws_ok { Sakai::Nakamura::GroupMemberUtil::add_setup( 'http://localhost:8080', 'group' ) } qr/No role defined to add member to!/, 'Check add_setup function croaks without role';
throws_ok { Sakai::Nakamura::GroupMemberUtil::add_setup( 'http://localhost:8080', 'group', 'role' ) } qr/No member name defined to add!/, 'Check add_setup function croaks without member';

ok( Sakai::Nakamura::GroupMemberUtil::add_eval( \$res ), 'Check add_eval function' );
