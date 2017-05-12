#!/usr/bin/perl -w

use strict;
use warnings;

use Test::Exception;
use Test::More tests => 12;

my $sling_host = 'http://localhost:8080';
my $super_user = 'admin';
my $super_pass = 'admin';
my $verbose    = 0;
my $log;

BEGIN { use_ok( 'Sakai::Nakamura' ); }
BEGIN { use_ok( 'Sakai::Nakamura::Authn' ); }
BEGIN { use_ok( 'Sakai::Nakamura::Group' ); }

# test group name:
my $test_group = "g-user_test_group_$$";

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

ok( defined $group,
    "Group Test: Sling Group Object successfully created." );

# Check can update properties after addition of user to group:
# http://jira.sakaiproject.org/browse/KERN-270
# create group:
ok( $group->add( $test_group ),
    "Group Test: Group \"$test_group\" added successfully." );
ok( $group->check_exists( $test_group ),
    "Group Test: Group \"$test_group\" exists." );

# Cleanup Group:
ok( $group->del( $test_group ),
    "Group Test: Group \"$test_group\" deleted successfully." );
ok( ! $group->check_exists( $test_group ),
    "Group Test: Group \"$test_group\" should no longer exist." );
