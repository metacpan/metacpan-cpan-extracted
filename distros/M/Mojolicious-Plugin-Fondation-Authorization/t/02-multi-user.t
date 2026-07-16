#!/usr/bin/env perl
use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use FindBin;
use Mojo::JSON qw(true false);

use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/../lib";

my $t = Test::Mojo->new('MyApp');
$t->app->log->level('error');

# --- Helper: login as a user

sub login_as {
    my ($username) = @_;
    $t->ua->cookie_jar->empty;
    $t->post_ok('/login' => form => { username => $username, password => 'pass' })
      ->status_is(302, "$username login redirects")
      ->header_like(Location => qr{/$}, 'Redirects to /');
}

# --- Helper: check a perm and group

sub check_perm {
    my ($perm, $expected_perm, $expected_group, $desc) = @_;
    $desc //= $perm;
    $t->get_ok("/has-perm/$perm")
      ->status_is(200)
      ->json_is('/has_perm'  => $expected_perm  ? true : false, "$desc - has_perm")
      ->json_is('/has_group' => $expected_group ? true : false, "$desc - has_group");
}

# --- 1. Alice login

subtest 'Alice login and grants' => sub {
    login_as('alice');

    $t->get_ok('/auth-status')
      ->status_is(200)
      ->json_is('/authenticated' => true, 'Alice is authenticated');

    # Permissions from admins group
    check_perm('user_create',  1, 0, 'user_create perm');
    check_perm('user_list',    1, 0, 'user_list perm');

    # Permission from editors group
    check_perm('group_create', 1, 0, 'group_create perm (editors)');

    # Permission alice does NOT have
    check_perm('admin_panel',  0, 0, 'admin_panel - not granted');

    # Group membership
    check_perm('admins',  0, 1, 'admins group');
    check_perm('editors', 0, 1, 'editors group');
    check_perm('guests',  0, 0, 'guests - not a member');
};

# --- 2. Bob login - different grants

subtest 'Bob login - different grants than alice' => sub {
    login_as('bob');

    $t->get_ok('/auth-status')
      ->status_is(200)
      ->json_is('/authenticated' => true, 'Bob is authenticated');

    # Bob is only in editors → only group_create
    check_perm('group_create', 1, 0, 'group_create perm (editors)');

    # Bob is NOT in admins → no user_create, no user_list
    check_perm('user_create', 0, 0, 'user_create - bob does not have it');
    check_perm('user_list',   0, 0, 'user_list - bob does not have it');

    # Group membership
    check_perm('admins',  0, 0, 'admins - bob is not a member');
    check_perm('editors', 0, 1, 'editors - bob is a member');
};

# --- 3. Back to alice - grants are per-user, not corrupted

subtest 'Alice again - grants intact after bob session' => sub {
    login_as('alice');

    $t->get_ok('/auth-status')
      ->status_is(200)
      ->json_is('/authenticated' => true, 'Alice is authenticated again');

    # All alice's permissions still present
    check_perm('user_create',  1, 0, 'user_create - still there');
    check_perm('user_list',    1, 0, 'user_list - still there');
    check_perm('group_create', 1, 0, 'group_create - still there');
    check_perm('admin_panel',  0, 0, 'admin_panel - still not granted');

    # All alice's groups still present
    check_perm('admins',  0, 1, 'admins - still a member');
    check_perm('editors', 0, 1, 'editors - still a member');
    check_perm('guests',  0, 0, 'guests - still not a member');
};

# --- 4. Back to bob - grants still isolated

subtest 'Bob again - grants unchanged by alice re-login' => sub {
    login_as('bob');

    # Bob still only has group_create
    check_perm('group_create', 1, 0, 'group_create - still there');
    check_perm('user_create',  0, 0, 'user_create - still not granted');
    check_perm('user_list',    0, 0, 'user_list - still not granted');
};

# --- 5. No user - helpers return 0

subtest 'No user authenticated - helpers return 0' => sub {
    $t->ua->cookie_jar->empty;

    $t->get_ok('/auth-status')
      ->status_is(200)
      ->json_is('/authenticated' => false, 'Not authenticated');

    check_perm('user_create',  0, 0, 'no user - has_perm false');
    check_perm('admins',       0, 0, 'no user - has_group false');
};

done_testing;
