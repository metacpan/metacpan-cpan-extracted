#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 28;
use Test::Exception;

my $sling_host = 'http://localhost:8080';
my $super_user = 'admin';
my $super_pass = 'admin';
my $verbose    = 0;
my $log;

BEGIN { use_ok( 'Sakai::Nakamura' ); }
BEGIN { use_ok( 'Sakai::Nakamura::Authn' ); }
BEGIN { use_ok( 'Sakai::Nakamura::User' ); }

# test user name, pass and email:
my $test_user = "user_test_user_$$";
my $test_pass = "pass";
my @test_properties = ( "email=test\@example.com" );

# sling object:
my $sling = Sakai::Nakamura->new();
isa_ok $sling, 'Sakai::Nakamura', 'sling';
$sling->{'URL'}     = $sling_host;
$sling->{'Verbose'} = $verbose;
$sling->{'Log'}     = $log;
# authn object:
my $authn = Sakai::Nakamura::Authn->new( \$sling );
isa_ok $authn, 'Sakai::Nakamura::Authn', 'authentication';
ok( $authn->login_user(), "Log in successful" );
# user object:
my $user = Sakai::Nakamura::User->new( \$authn, $verbose, $log );
isa_ok $user, 'Sakai::Nakamura::User', 'user';

# Set password to something that won't work to start with:
$authn->{'Username'}    = $super_user;
$authn->{'Password'}    = '__bad__password__';

# Test form login fail:
throws_ok { $authn->login_user() } qr{Form Auth log in for user "admin" at URL "http://localhost:8080" was unsuccessful}, 'Check login_user function (form) croaks with invalid password';
$authn->{'Verbose'} = '0';
throws_ok { $authn->login_user() } qr{Form Auth log in for user "admin" at URL "http://localhost:8080" was unsuccessful}, 'Check login_user function (form) croaks with invalid password';

# Check no login is attempted with base url undefined:
$authn->{'BaseURL'} = undef;
ok( $authn->login_user(), 'Check login_user function skips successfully with undefined base url' );

# Check no login is attempted with password undefined:
$authn->{'BaseURL'} = $sling_host;
$authn->{'Password'} = undef;
ok( $authn->login_user(), 'Check login_user function skips successfully with undefined password' );

$authn->{'Password'}= $super_pass;
$authn->{'BaseURL'} = undef;
ok( $authn->login_user(), 'Check login_user function skips successfully with undefined base url' );

$authn->{'BaseURL'} = $sling_host;
$authn->{'Verbose'} = '2';
ok( $authn->form_login(), 'Check form_login function works successfully' );

$authn->{'Verbose'} = '0';
ok( $user->add( $test_user, $test_pass, \@test_properties ),
    "Authn Test: User \"$test_user\" added successfully." );
ok( $user->check_exists( $test_user ),
    "Authn Test: User \"$test_user\" exists." );

$authn->{'Verbose'} = '2';
throws_ok { $authn->switch_user() } qr{New username to switch to not defined}, 'Check switch_user croaks without username';
throws_ok { $authn->switch_user($super_user) } qr{New password to use in switch not defined}, 'Check switch_user croaks without password';
ok( $authn->switch_user($super_user, $super_pass), 'Check switch_user function to same user works successfully' );
ok( $authn->switch_user($test_user, $test_pass), 'Check switch_user function to test user works successfully' );
ok( $authn->switch_user($super_user, $super_pass), 'Check switch_user function to super user works successfully' );
ok( $authn->form_logout(), 'Check form_logout function works successfully' );
$authn->{'Username'} = $super_user;

$authn->{'Verbose'} = '2';
ok( $authn->login_user(), 'Check login_user function with form auth, verbose > 1 works successfully' );
# Check user deletion:
ok( $user->del( $test_user ),
    "Authn Test: User \"$test_user\" deleted successfully." );
ok( $authn->form_logout(), 'Check form_logout function works successfully' );

# Check form_logout:
$authn->{'Verbose'} = '1';
ok( $authn->form_logout(), 'Check form_logout function works successfully' );

$authn->{'Verbose'} = '0';
ok( $authn->login_user(), 'Check login_user function with form auth works successfully' );
ok( $authn->form_logout(), 'Check form_logout function works successfully' );

ok( ! $user->check_exists( $test_user ),
    "Authn Test: User \"$test_user\" should no longer exist." );
