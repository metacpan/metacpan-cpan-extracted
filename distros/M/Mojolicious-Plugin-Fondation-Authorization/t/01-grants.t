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

# - 1. Without login - check_perm and check_group return 0 -──

subtest 'No user authenticated - helpers return 0' => sub {
    $t->ua->cookie_jar->empty;

    $t->get_ok('/auth-status')
      ->status_is(200)
      ->json_is('/authenticated' => false, 'Not authenticated');

    $t->get_ok('/has-perm/user_create')
      ->status_is(200)
      ->json_is('/has_perm'  => false, 'check_perm returns false')
      ->json_is('/has_group' => false, 'check_group returns false');
};

# - 2. Login via Auth's route

subtest 'Login as alice' => sub {
    $t->ua->cookie_jar->empty;

    $t->post_ok('/login' => form => { username => 'alice', password => 'pass' })
      ->status_is(302, 'Login redirects')
      ->header_like(Location => qr{/$}, 'Redirects to /');
};

# - 3. After login - grants loaded

subtest 'After login - grants are loaded' => sub {
    $t->get_ok('/auth-status')
      ->status_is(200)
      ->json_is('/authenticated' => true, 'Authenticated');

    $t->get_ok('/has-perm/user_create')
      ->status_is(200)
      ->json_is('/has_perm'  => true,  'Has user_create permission')
      ->json_is('/has_group' => false, 'user_create is not a group');

    $t->get_ok('/has-perm/user_list')
      ->status_is(200)
      ->json_is('/has_perm' => true, 'Has user_list permission');

    $t->get_ok('/has-perm/group_create')
      ->status_is(200)
      ->json_is('/has_perm' => true, 'Has group_create permission');

    $t->get_ok('/has-perm/admin_panel')
      ->status_is(200)
      ->json_is('/has_perm' => false, 'No admin_panel permission');
};

# - 4. Group check

subtest 'After login - group membership checks' => sub {
    $t->get_ok('/has-perm/admins')
      ->status_is(200)
      ->json_is('/has_group' => true, 'Alice is in admins');

    $t->get_ok('/has-perm/editors')
      ->status_is(200)
      ->json_is('/has_group' => true, 'Alice is in editors');

    $t->get_ok('/has-perm/guests')
      ->status_is(200)
      ->json_is('/has_group' => false, 'Alice is not in guests');
};

# - 5. Fast path - grants cached, no reload

subtest 'Grants cached - second request uses session' => sub {
    for my $i (1 .. 3) {
        $t->get_ok('/has-perm/user_create')
          ->status_is(200)
          ->json_is('/has_perm' => true, "Request $i: permission still valid");
    }
};

# - 6. Logout clears grants

subtest 'After logout - grants cleared' => sub {
    $t->get_ok('/logout')
      ->status_is(302, 'Logout redirects')
      ->header_like(Location => qr{/$}, 'Redirects to /');

    $t->ua->cookie_jar->empty;

    $t->get_ok('/auth-status')
      ->status_is(200)
      ->json_is('/authenticated' => false, 'Not authenticated after logout');

    $t->get_ok('/has-perm/user_create')
      ->status_is(200)
      ->json_is('/has_perm'  => false, 'No permission after logout')
      ->json_is('/has_group' => false);
};

# - 7. New login - grants reloaded

subtest 'New login - grants reloaded' => sub {
    $t->post_ok('/login' => form => { username => 'alice', password => 'pass' })
      ->status_is(302, 'Login redirects')
      ->header_like(Location => qr{/$}, 'Redirects to /');

    $t->get_ok('/auth-status')
      ->status_is(200)
      ->json_is('/authenticated' => true, 'Authenticated again');

    $t->get_ok('/has-perm/user_create')
      ->status_is(200)
      ->json_is('/has_perm' => true, 'Permission restored after re-login');
};

done_testing;
