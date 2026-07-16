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

# ─── Helper: login as a user

sub login_as {
    my ($username) = @_;
    $t->ua->cookie_jar->empty;
    $t->post_ok('/login' => form => { username => $username, password => 'pass' })
      ->status_is(302, "$username login redirects")
      ->header_like(Location => qr{/$}, 'Redirects to /');
}

# ─── 1. Unauthenticated - 403

subtest 'Unauthenticated - route conditions block access' => sub {
    $t->ua->cookie_jar->empty;

    $t->get_ok('/auth-status')
      ->status_is(200)
      ->json_is('/authenticated' => false, 'Not authenticated');

    $t->get_ok('/protected/perm')
      ->status_is(403, 'fondation.perm blocks unauthenticated')
      ->content_is('Forbidden');

    $t->get_ok('/protected/group')
      ->status_is(403, 'fondation.group blocks unauthenticated')
      ->content_is('Forbidden');
};

# ─── 2. Alice - has user_create AND admins

subtest 'Alice passes both route conditions' => sub {
    login_as('alice');

    $t->get_ok('/protected/perm')
      ->status_is(200, 'alice has user_create → 200')
      ->content_is('OK');

    $t->get_ok('/protected/group')
      ->status_is(200, 'alice is in admins → 200')
      ->content_is('OK');
};

# ─── 3. Bob - no user_create, not in admins

subtest 'Bob fails both route conditions' => sub {
    login_as('bob');

    $t->get_ok('/protected/perm')
      ->status_is(403, 'bob lacks user_create → 403')
      ->content_is('Forbidden');

    $t->get_ok('/protected/group')
      ->status_is(403, 'bob is not in admins → 403')
      ->content_is('Forbidden');
};

# ─── 4. Carol - no groups at all

subtest 'Carol has zero groups - blocked everywhere' => sub {
    login_as('carol');

    $t->get_ok('/auth-status')
      ->status_is(200)
      ->json_is('/authenticated' => true, 'Carol is authenticated');

    # Verify carol has no permissions and no groups
    $t->get_ok('/has-perm/user_create')
      ->status_is(200)
      ->json_is('/has_perm'  => false, 'carol - no user_create perm')
      ->json_is('/has_group' => false, 'carol - no groups at all');

    $t->get_ok('/has-perm/admins')
      ->status_is(200)
      ->json_is('/has_perm'  => false, 'carol - no perms')
      ->json_is('/has_group' => false, 'carol - not in admins');

    # Route conditions block carol
    $t->get_ok('/protected/perm')
      ->status_is(403, 'carol blocked by fondation.perm')
      ->content_is('Forbidden');

    $t->get_ok('/protected/group')
      ->status_is(403, 'carol blocked by fondation.group')
      ->content_is('Forbidden');
};

# ─── 5. Back to alice - route conditions still work

subtest 'Alice again - route conditions intact after other users' => sub {
    login_as('alice');

    $t->get_ok('/protected/perm')
      ->status_is(200, 'alice perm still works');

    $t->get_ok('/protected/group')
      ->status_is(200, 'alice group still works');
};

done_testing;
