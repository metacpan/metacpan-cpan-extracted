# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Apache-Sling.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 12;
BEGIN { use_ok( 'Sakai::Nakamura' ); }
BEGIN { use_ok( 'Sakai::Nakamura::Authn' ); }

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# nakamura object:
my $nakamura = Sakai::Nakamura->new();
isa_ok $nakamura, 'Sakai::Nakamura', 'nakamura';
$nakamura->{'Verbose'} = 1;
$nakamura->{'Log'} = 'log.txt';

my $authn = new Sakai::Nakamura::Authn(\$nakamura);
ok( $authn->{ 'BaseURL' } eq 'http://localhost:8080', 'Check BaseURL set' );
ok( $authn->{ 'Log' }     eq 'log.txt',               'Check Log set' );
ok( $authn->{ 'Message' } eq '',                      'Check Message set' );
ok( $authn->{ 'Verbose' } == 1,                       'Check Verbosity set' );
ok( ! defined $authn->{ 'Username' },                 'Check user name not defined' );
ok( ! defined $authn->{ 'Password' },                 'Check password not defined' );
ok( defined $authn->{ 'Response' },                   'Check response defined' );

$authn->set_results( 'Test Message', undef );
ok( $authn->{ 'Message' } eq 'Test Message', 'Message now set' );
ok( ! defined $authn->{ 'Response' },        'Check response no longer defined' );
