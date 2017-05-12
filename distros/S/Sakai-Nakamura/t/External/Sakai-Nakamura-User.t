#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 33;
use Test::Exception;

my $sling_host = 'http://localhost:8080';
my $super_user = 'admin';
my $super_pass = 'admin';
my $verbose    = 0;
my $log;

BEGIN { use_ok( 'Sakai::Nakamura' ); }
BEGIN { use_ok( 'Sakai::Nakamura::Authn' ); }
BEGIN { use_ok( 'Sakai::Nakamura::User' ); }
BEGIN { use_ok( 'Sakai::Nakamura::Group' ); }

# test user name:
my $test_user = "user_test_user_$$";
# test user pass:
my $test_pass = "pass";
# test properties:
my @test_properties = ( "email=test\@example.com" );

# test group name:
my $test_group = "g-user_test_group_$$";

# sling object:
my $nakamura = Sakai::Nakamura->new();
isa_ok $nakamura, 'Sakai::Nakamura', 'sling';
$nakamura->{'URL'}     = $sling_host;
$nakamura->{'User'}    = $super_user;
$nakamura->{'Pass'}    = $super_pass;
$nakamura->{'Verbose'} = $verbose;
$nakamura->{'Log'}     = $log;
# authn object:
my $authn = Sakai::Nakamura::Authn->new( \$nakamura );
isa_ok $authn, 'Sakai::Nakamura::Authn', 'authentication';
ok( $authn->login_user(), "Log in successful" );
# user object:
my $user = Sakai::Nakamura::User->new( \$authn, $verbose, $log );
isa_ok $user, 'Sakai::Nakamura::User', 'user';
# group object:
my $group = Sakai::Nakamura::Group->new( \$authn, $verbose, $log );
isa_ok $group, 'Sakai::Nakamura::Group', 'group';

# Run tests:
ok( defined $user,
    "User Test: Sling User Object successfully created." );
ok( defined $group,
    "User Test: Sling Group Object successfully created." );

# add user:
ok( $user->add( $test_user, $test_pass, \@test_properties ),
    "User Test: User \"$test_user\" added successfully." );
ok( $user->check_exists( $test_user ),
    "User Test: User \"$test_user\" exists." );

# Check can update properties:
@test_properties = ( "user_test_editor=$super_user" );
ok( $user->update( $test_user, \@test_properties ),
    "User Test: User \"$test_user\" updated successfully." );

# Check can update profile:
ok( $user->profile_update( 'preferredName', $test_user, $test_user, 'basic' ),
    "User Test: Profile field 'preferredName' successfully updated to '$test_user' for '$test_user' in section 'basic'." );
ok( ! $user->profile_update( '_bad_field_', '_bad_value_', '_bad_user_', '_bad_section_' ),
    "User Test: Can not update profile for non-existent user, section, and field." );

# Check can update properties after addition of user to group:
# http://jira.sakaiproject.org/browse/KERN-270
# create group:
ok( $group->add( $test_group, \@test_properties ),
    "User Test: Group \"$test_group\" added successfully." );
ok( $group->check_exists( $test_group ),
    "User Test: Group \"$test_group\" exists." );
# Check can still update properties:
@test_properties = ( "user_test_edit_after_group_join=true" );
ok( $user->update( $test_user, \@test_properties ),
    "User Test: User \"$test_user\" updated successfully." );
# Cleanup Group:
ok( $group->del( $test_group ),
    "User Test: Group \"$test_group\" deleted successfully." );
ok( ! $group->check_exists( $test_group ),
    "User Test: Group \"$test_group\" should no longer exist." );

# Switch to test_user
ok( $authn->switch_user( $test_user, $test_pass ),
    "User Test: Successfully switched to user: \"$test_user\" with basic auth" );

# Check can update properties:
@test_properties = ( "user_test_editor=$test_user" );
ok( $user->update( $test_user, \@test_properties ),
    "User Test: User \"$test_user\" updated successfully." );

# switch back to admin user:
ok( $authn->switch_user( $super_user, $super_pass ),
    "User Test: Successfully switched to user: \"$super_user\" with basic auth" );

# Check user deletion:
ok( $user->del( $test_user ),
    "User Test: User \"$test_user\" deleted successfully." );

# check me service:
ok( $user->me(), "" );

ok( ! $user->check_exists( $test_user ),
    "User Test: User \"$test_user\" should no longer exist." );

ok( my $user_config = Sakai::Nakamura::User->config($nakamura), 'check user config function' );
ok( defined $user_config );
throws_ok { Sakai::Nakamura::User->run( $nakamura ) } qr/No user config supplied!/, 'Check user_run function croaks without config';
ok( Sakai::Nakamura::User->run( $nakamura, $user_config ) );
my $me = 1;
$user_config->{'me'} = \$me;
ok( Sakai::Nakamura::User->run( $nakamura, $user_config ) );
$user_config->{'me'} = undef;
my $profile_update = $super_user;
$user_config->{'profile-update'} = \$profile_update;
throws_ok { Sakai::Nakamura::User->run( $nakamura, $user_config ) } qr/No profile field to update specified!/, 'Check user_run function croaks for profile_update without sufficient values.';
