# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Apache-Sling.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 24;
use Test::Exception;
BEGIN { use_ok( 'Sakai::Nakamura' ); }
BEGIN { use_ok( 'Sakai::Nakamura::Authn' ); }
BEGIN { use_ok( 'Sakai::Nakamura::World' ); }

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# nakamura object:
my $nakamura = Sakai::Nakamura->new();
isa_ok $nakamura, 'Sakai::Nakamura', 'nakamura';
$nakamura->{'Verbose'} = 1;
$nakamura->{'Log'} = 'log.txt';

my $authn = new Sakai::Nakamura::Authn(\$nakamura);
throws_ok { my $world = new Sakai::Nakamura::World() } qr/no authn provided!/, 'Check new function croaks without authn';

my $world = new Sakai::Nakamura::World(\$authn,'1','log.txt');
isa_ok $world, 'Sakai::Nakamura::World', 'world';
ok( $world->{ 'BaseURL' } eq 'http://localhost:8080', 'Check BaseURL set' );
ok( $world->{ 'Log' }     eq 'log.txt',               'Check Log set' );
ok( $world->{ 'Message' } eq '',                      'Check Message set' );
ok( $world->{ 'Verbose' } == 1,                       'Check Verbosity set' );
ok( defined $world->{ 'Authn' },                      'Check authn defined' );
ok( defined $world->{ 'Response' },                   'Check response defined' );

$world->set_results( 'Test Message', undef );
ok( $world->{ 'Message' } eq 'Test Message', 'Message now set' );
ok( ! defined $world->{ 'Response' }, 'Check response no longer defined' );

throws_ok { $world->add() } qr/No id defined to add!/, 'Check add function croaks without id';

my $file = "\n";
throws_ok { $world->add_from_file() } qr/Problem adding from file!/, 'Check add_from_file function croaks without id';
throws_ok { $world->add_from_file(\$file) } qr/First CSV column must be the world ID, column heading must be "id". Found: ""/, 'Check add_from_file function croaks with wrong headings';
$file = "id\n";
ok ( $world->add_from_file(\$file), 'Check add_from_file function returns ok with just headings' );
$file = "id\n1,2";
throws_ok { $world->add_from_file(\$file) } qr/Found "2" columns. There should have been "1"./, 'Check add_from_file function croaks with wrong number of columns';
$file = "id,title,description,tags,visibility,joinability,worldtemplate,badheader\n1,2,3,4,5,6,7,8";
throws_ok { $world->add_from_file(\$file,0,1) } qr/Unsupported column heading "badheader" - please use: "id", "title", "description", "tags", "visibility", "joinability", "worldtemplate"/, 'Check add_from_file function croaks with bad column heading';

ok( my $world_config = Sakai::Nakamura::World->config($nakamura), 'check world config function' );
ok( defined $world_config );
throws_ok { Sakai::Nakamura::World->run( $nakamura ) } qr/No world config supplied!/, 'Check run function croaks without config';
ok( Sakai::Nakamura::World->run( $nakamura, $world_config ) );
