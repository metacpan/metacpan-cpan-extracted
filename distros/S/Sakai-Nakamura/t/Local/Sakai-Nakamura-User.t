# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Apache-Sling.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 17;
use Test::Exception;
BEGIN { use_ok( 'Sakai::Nakamura' ); }
BEGIN { use_ok( 'Sakai::Nakamura::Authn' ); }
BEGIN { use_ok( 'Sakai::Nakamura::User' ); }

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# nakamura object:
my $nakamura = Sakai::Nakamura->new();
isa_ok $nakamura, 'Sakai::Nakamura', 'nakamura';
$nakamura->{'Verbose'} = 1;
$nakamura->{'Log'} = 'log.txt';

my $authn   = new Sakai::Nakamura::Authn(\$nakamura);
my $user = new Sakai::Nakamura::User(\$authn,'1','log.txt');
ok( $user->{ 'BaseURL' } eq 'http://localhost:8080', 'Check BaseURL set' );
ok( $user->{ 'Log' }     eq 'log.txt',               'Check Log set' );
ok( $user->{ 'Message' } eq '',                      'Check Message set' );
ok( $user->{ 'Verbose' } == 1,                       'Check Verbosity set' );
ok( defined $user->{ 'Authn' },                      'Check authn defined' );
ok( defined $user->{ 'Response' },                   'Check response defined' );

$user->set_results( 'Test Message', undef );
ok( $user->{ 'Message' } eq 'Test Message', 'Message now set' );
ok( ! defined $user->{ 'Response' },          'Check response no longer defined' );
throws_ok { $user->profile_update() } qr/No profile field to update specified!/, 'Check profile_update function croaks without field specified';

ok( my $user_config = Sakai::Nakamura::User->config($nakamura), 'check user config function' );
ok( defined $user_config );
throws_ok { Sakai::Nakamura::User->run( $nakamura ) } qr/No user config supplied!/, 'Check run function croaks without config';
ok( Sakai::Nakamura::User->run( $nakamura, $user_config ) );
