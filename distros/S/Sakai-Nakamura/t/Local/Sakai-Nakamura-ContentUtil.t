# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Apache-Sling.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 12;
use Test::Exception;
BEGIN { use_ok( 'Sakai::Nakamura::ContentUtil' ); }
BEGIN { use_ok( 'HTTP::Response' ); }

my $res = HTTP::Response->new( '200' );

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
my @properties = '';

ok( Sakai::Nakamura::ContentUtil::add_file_metadata_setup( 'http://localhost:8080', '/p/abc123', 'filename', 'extension') eq
  q(post http://localhost:8080/system/batch $post_variables = ['requests','[{"url":"/p/abc123","method":"POST","parameters":{"sakai:pooled-content-file-name":"filename","sakai:description":"","sakai:permissions":"public","sakai:copyright":"creativecommons","sakai:allowcomments":"true","sakai:showcomments":"true","sakai:fileextension":"extension","_charset_":"utf-8"},"_charset_":"utf-8"},{"url":"/p/abc123.save.json","method":"POST","_charset_":"utf-8"}]']),
  'Check add_file_metadata_setup function' );

ok( Sakai::Nakamura::ContentUtil::add_file_perms_setup( 'http://localhost:8080', '/p/abc123') eq
  q(post http://localhost:8080/system/batch $post_variables = ['requests','[{"url":"/p/abc123.members.html","method":"POST","parameters":{":viewer":["everyone","anonymous"]}},{"url":"/p/abc123.modifyAce.html","method":"POST","parameters":{"principalId":["everyone"],"privilege@jcr:read":"granted"}},{"url":"/p/abc123.modifyAce.html","method":"POST","parameters":{"principalId":["anonymous"],"privilege@jcr:read":"granted"}}]']),
  'Check add_file_perms_setup function' );

throws_ok { Sakai::Nakamura::ContentUtil::add_file_metadata_setup() } qr/No base url defined to add against!/, 'Check add_file_metadata_setup function croaks without base url';
throws_ok { Sakai::Nakamura::ContentUtil::add_file_metadata_setup( 'http://localhost:8080' ) } qr/No content path to add file meta data to!/, 'Check add_file_metadata_eval_setup function croaks without content path';
throws_ok { Sakai::Nakamura::ContentUtil::add_file_metadata_setup( 'http://localhost:8080', '/p/abc123' ) } qr/No content filename provided when attempting to add meta data!/, 'Check add_file_metadata_eval_setup function croaks without content file name';
throws_ok { Sakai::Nakamura::ContentUtil::add_file_metadata_setup( 'http://localhost:8080', '/p/abc123', 'filename' ) } qr/No content file extension provided when attempting to add meta data!/, 'Check add_file_metadata_eval_setup function croaks without content file extension';

throws_ok { Sakai::Nakamura::ContentUtil::add_file_perms_setup() } qr/No base url defined to add against!/, 'Check add_file_perms_setup function croaks without base url';
throws_ok { Sakai::Nakamura::ContentUtil::add_file_perms_setup( 'http://localhost:8080' ) } qr/No content path to add file perms to!/, 'Check add_file_perms_eval_setup function croaks without content path';

ok( Sakai::Nakamura::ContentUtil::add_file_metadata_eval( \$res ), 'Check add_file_metadata_eval function' );
ok( Sakai::Nakamura::ContentUtil::add_file_perms_eval( \$res ), 'Check add_file_perms_eval function' );
