# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Apache-Sling.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 8;
use Test::Exception;
BEGIN { use_ok( 'Sakai::Nakamura::WorldUtil' ); }
BEGIN { use_ok( 'HTTP::Response' ); }

my $res = HTTP::Response->new( '200' );

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
my @properties = '';
ok( Sakai::Nakamura::WorldUtil::add_setup( 'http://localhost:8080', 'id', 'username', 'title', 'description', 'tags', 'visibility', 'joinability', 'worldTemplate') eq
  q(post http://localhost:8080/system/world/create $post_variables = ['data','{"id":"id","title":"title","tags":["tags"],"description":"description","visibility":"visibility","joinability":"joinability","worldTemplate":"worldTemplate","message":{"body":"Hi ${firstName}\n\n ${creatorName} has added you as a ${role} to the group \"${groupName}\"\n\n You can find it here ${link}","subject":"${creatorName} has added you as a ${role} to the group \"${groupName}\"","creatorName":"","groupName":"title","system":"Sakai","link":"http://localhost:8080/~id","toSend":[]},"usersToAdd":[{"userid":"username","role":"manager"}]}']),
  'Check add_setup function' );

ok( Sakai::Nakamura::WorldUtil::add_setup( 'http://localhost:8080', 'id', 'username') eq
  q(post http://localhost:8080/system/world/create $post_variables = ['data','{"id":"id","title":"id","tags":["id"],"description":"id","visibility":"public","joinability":"yes","worldTemplate":"/var/templates/worlds/group/simple-group","message":{"body":"Hi ${firstName}\n\n ${creatorName} has added you as a ${role} to the group \"${groupName}\"\n\n You can find it here ${link}","subject":"${creatorName} has added you as a ${role} to the group \"${groupName}\"","creatorName":"","groupName":"id","system":"Sakai","link":"http://localhost:8080/~id","toSend":[]},"usersToAdd":[{"userid":"username","role":"manager"}]}']),
  'Check add_setup function' );

throws_ok { Sakai::Nakamura::WorldUtil::add_setup() } qr/No base url defined to add against!/, 'Check add_setup function croaks without base url';
throws_ok { Sakai::Nakamura::WorldUtil::add_setup( 'http://localhost:8080' ) } qr/No id defined to add!/, 'Check add_setup function croaks without id';
throws_ok { Sakai::Nakamura::WorldUtil::add_setup( 'http://localhost:8080', 'id' ) } qr/No user id defined to add!/, 'Check add_setup function croaks without user id';

ok( Sakai::Nakamura::WorldUtil::add_eval( \$res ), 'Check add_eval function' );
