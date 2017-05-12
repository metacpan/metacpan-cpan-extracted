#!/usr/bin/perl -w

use strict;
use warnings;

use Test::Exception;
use Test::More tests => 23;

my $sling_host = 'http://localhost:8080';
my $super_user = 'admin';
my $super_pass = 'admin';
my $verbose    = 0;
my $log;

BEGIN { use_ok( 'Sakai::Nakamura' ); }
BEGIN { use_ok( 'Sakai::Nakamura::Authn' ); }
BEGIN { use_ok( 'Sakai::Nakamura::Group' ); }
BEGIN { use_ok( 'Sakai::Nakamura::GroupRole' ); }
BEGIN { use_ok( 'Sakai::Nakamura::User' ); }

# test user name:
my $test_user = "user_test_user_$$";
# test user pass:
my $test_pass = "pass";
# test group name:
my $test_group = "g-user_test_group_$$";
# test email:
my @test_properties = ( "email=test\@example.com" );

# sling object:
my $sling = Sakai::Nakamura->new();
isa_ok $sling, 'Sakai::Nakamura', 'sling';
$sling->{'URL'}     = $sling_host;
$sling->{'User'}    = $super_user;
$sling->{'Pass'}    = $super_pass;
$sling->{'Verbose'} = $verbose;
$sling->{'Log'}     = $log;
# authn object:
my $authn = Sakai::Nakamura::Authn->new( \$sling );
isa_ok $authn, 'Sakai::Nakamura::Authn', 'authentication';
ok( $authn->login_user(), "Log in successful" );
# group object:
my $group = Sakai::Nakamura::Group->new( \$authn, $verbose, $log );
isa_ok $group, 'Sakai::Nakamura::Group', 'group';
# group role object:
my $group_role = Sakai::Nakamura::GroupRole->new( \$authn, $verbose, $log );
isa_ok $group_role, 'Sakai::Nakamura::GroupRole', 'group_role';
# user object:
my $user = Sakai::Nakamura::User->new( \$authn, $verbose, $log );
isa_ok $user, 'Sakai::Nakamura::User', 'user';

ok( defined $group,
    "Group Role Test: Sling Group Object successfully created." );
ok( defined $group_role,
    "Group Role Test: Sling Group Role Object successfully created." );
ok( defined $user,
    "Group Role Test: Sling User Object successfully created." );

# add user:
ok( $user->add( $test_user, $test_pass. \@test_properties ),
    "Group Role Test: User \"$test_user\" added successfully." );

# Check can update properties after addition of user to group:
# http://jira.sakaiproject.org/browse/KERN-270
# create group:
ok( $group->add( $test_group ),
    "Group Role Test: Group \"$test_group\" added successfully." );
ok( $group->check_exists( $test_group ),
    "Group Role Test: Group \"$test_group\" exists." );

throws_ok { $group_role->add() } qr{No group name defined to add to!}, 'Check add function croaks with no values specified';
ok( $group_role->add( $test_group, 'manager', $test_user ),
    "Test add function completes successfully." );
throws_ok { $group_role->add( '__bad__group__', '__bad__role__', '__bad__user__'); } qr{}, "Test add function with non-existent group and role.";

# Cleanup Group:
ok( $group->del( $test_group ),
    "Group Role Test: Group \"$test_group\" deleted successfully." );
ok( ! $group->check_exists( $test_group ),
    "Group Role Test: Group \"$test_group\" should no longer exist." );

# Check user deletion:
ok( $user->del( $test_user ),
    "Group Role Test: User \"$test_user\" deleted successfully." );
