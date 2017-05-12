# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Apache-Sling.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 23;
use Test::Exception;
BEGIN { use_ok( 'Sakai::Nakamura' ); }
BEGIN { use_ok( 'Sakai::Nakamura::Authn' ); }
BEGIN { use_ok( 'Sakai::Nakamura::Content' ); }

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# nakamura object:
my $nakamura = Sakai::Nakamura->new();
isa_ok $nakamura, 'Sakai::Nakamura', 'nakamura';
$nakamura->{'Verbose'} = 1;
$nakamura->{'Log'} = 'log.txt';

my $authn   = new Sakai::Nakamura::Authn(\$nakamura);
throws_ok { my $content = new Sakai::Nakamura::Content() } qr/no authn provided!/, 'Check new function croaks without authn';

my $content = new Sakai::Nakamura::Content(\$authn,'1','log.txt');
ok( $content->{ 'BaseURL' } eq 'http://localhost:8080', 'Check BaseURL set' );
ok( $content->{ 'Log' }     eq 'log.txt',               'Check Log set' );
ok( $content->{ 'Message' } eq '',                      'Check Message set' );
ok( $content->{ 'Verbose' } == 1,                       'Check Verbosity set' );
ok( defined $content->{ 'Authn' },                      'Check authn defined' );
ok( defined $content->{ 'Response' },                   'Check response defined' );

$content->set_results( 'Test Message', undef );
ok( $content->{ 'Message' } eq 'Test Message', 'Message now set' );
ok( ! defined $content->{ 'Response' },          'Check response no longer defined' );

throws_ok { $content->upload_file() } qr/No local file to upload defined!/, 'Check upload_file croaks without local file';
throws_ok { $content->upload_from_file() } qr/File to upload from not defined/, 'Check upload_from_file function croaks without file specified';
ok( $content->upload_from_file('/dev/null'), 'Check upload_from_file function with blank file' );

my $file = "\n";
throws_ok { $content->upload_from_file() } qr/File to upload from not defined/, 'Check upload_from_file function croaks without file';
throws_ok { $content->upload_from_file(\$file) } qr/Problem parsing content to add: ''/, 'Check upload_from_file function croaks with blank file';
throws_ok { $content->upload_from_file('/tmp/__non__--__tnetsixe__') } qr{Problem opening file: '/tmp/__non__--__tnetsixe__'}, 'Check upload_from_file function croaks with non-existent file specified';

ok( my $content_config = Sakai::Nakamura::Content->config($nakamura), 'check content config function' );
ok( defined $content_config );
throws_ok { Sakai::Nakamura::Content->run( $nakamura ) } qr/No content config supplied!/, 'Check run function croaks without config';
ok( Sakai::Nakamura::Content->run( $nakamura, $content_config ) );

