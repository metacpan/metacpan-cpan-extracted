# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Apache-Sling.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 12;
BEGIN { use_ok( 'Sakai::Nakamura' ); }
BEGIN { use_ok( 'Sakai::Nakamura::Authn' ); }
BEGIN { use_ok( 'Sakai::Nakamura::GroupMember' ); }

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# nakamura object:
my $nakamura = Sakai::Nakamura->new();
isa_ok $nakamura, 'Sakai::Nakamura', 'nakamura';
$nakamura->{'Verbose'} = 1;
$nakamura->{'Log'} = 'log.txt';

my $authn = new Sakai::Nakamura::Authn(\$nakamura);
my $group_member = new Sakai::Nakamura::GroupMember(\$authn,'1','log.txt');

ok( $group_member->{ 'BaseURL' } eq 'http://localhost:8080', 'Check BaseURL set' );
ok( $group_member->{ 'Log' }     eq 'log.txt',               'Check Log set' );
ok( $group_member->{ 'Message' } eq '',                      'Check Message set' );
ok( $group_member->{ 'Verbose' } == 1,                       'Check Verbosity set' );
ok( defined $group_member->{ 'Authn' },                      'Check authn defined' );
ok( defined $group_member->{ 'Response' },                   'Check response defined' );

$group_member->set_results( 'Test Message', undef );
ok( $group_member->{ 'Message' } eq 'Test Message', 'Message now set' );
ok( ! defined $group_member->{ 'Response' },        'Check response no longer defined' );
