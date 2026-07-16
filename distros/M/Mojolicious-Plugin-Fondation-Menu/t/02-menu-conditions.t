use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use FindBin;

use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/../lib";

my $t = Test::Mojo->new('TestMenuApp');
$t->app->log->level('error');

sub login_as {
    my ($username) = @_;
    $t->ua->cookie_jar->empty;
    $t->post_ok('/login' => form => { username => $username, password => 'pass' })
      ->status_is(302);
}

# -- 1. Not logged in ----------------------------------------------------

subtest 'Not logged in' => sub {
    $t->get_ok('/menu-conditions')
      ->status_is(200)
      ->json_is('/authenticated' => 0, 'not authenticated')
      ->json_is('/auth_required' => 0, 'auth fails when not logged in')
      ->json_is('/not_auth'      => 1, '!auth passes when not logged in')
      ->json_is('/public_menu'   => 1, 'empty condition always passes')
      ->json_is('/admin_only'    => 0, 'group:admin fails (not authenticated)')
      ->json_is('/perm_required' => 0, 'perm:menu_read fails (not authenticated)')
      ->json_is('/mode_dev'      => 1, 'mode:development passes (app is in dev)')
      ->json_is('/mode_prod'     => 0, 'mode:production fails (app is in dev)')
      ->json_is('/mode_not_prod' => 1, 'mode:!production passes (app is in dev)')
      ->json_is('/compound'      => 0, 'compound group:admin,mode:dev fails (no auth)');
};

# -- 2. Logged in as guest (no group, no perms) --------------------------

subtest 'Guest (no group, no perms)' => sub {
    login_as('guest');

    $t->get_ok('/menu-conditions')
      ->status_is(200)
      ->json_is('/authenticated' => 1, 'guest is authenticated')
      ->json_is('/auth_required' => 1, 'auth passes when logged in')
      ->json_is('/not_auth'      => 0, '!auth fails when logged in')
      ->json_is('/public_menu'   => 1, 'empty condition always passes')
      ->json_is('/admin_only'    => 0, 'group:admin fails (guest not in admin group)')
      ->json_is('/perm_required' => 0, 'perm:menu_read fails (guest has no perms)')
      ->json_is('/mode_dev'      => 1, 'mode:development passes (app is in dev)')
      ->json_is('/mode_prod'     => 0, 'mode:production fails (app is in dev)')
      ->json_is('/mode_not_prod' => 1, 'mode:!production passes (app is in dev)')
      ->json_is('/compound'      => 0, 'compound fails (guest not admin)');
};

# -- 3. Logged in as reader (in readers group, has menu_read, NOT in admin) -

subtest 'Reader (has menu_read, not in admin group)' => sub {
    login_as('reader');

    $t->get_ok('/menu-conditions')
      ->status_is(200)
      ->json_is('/authenticated' => 1, 'reader is authenticated')
      ->json_is('/auth_required' => 1, 'auth passes')
      ->json_is('/not_auth'      => 0, '!auth fails')
      ->json_is('/public_menu'   => 1, 'empty condition always passes')
      ->json_is('/admin_only'    => 0, 'group:admin fails (reader not in admin group)')
      ->json_is('/perm_required' => 1, 'perm:menu_read passes (reader has menu_read)')
      ->json_is('/mode_dev'      => 1, 'mode:development passes')
      ->json_is('/compound'      => 0, 'compound fails (reader not admin)');
};

# -- 4. Logged in as admin (in admin group, has menu_read) ---------------

subtest 'Admin (in admin group, has menu_read)' => sub {
    login_as('admin');

    $t->get_ok('/menu-conditions')
      ->status_is(200)
      ->json_is('/authenticated' => 1, 'admin is authenticated')
      ->json_is('/auth_required' => 1, 'auth passes')
      ->json_is('/not_auth'      => 0, '!auth fails')
      ->json_is('/public_menu'   => 1, 'empty condition always passes')
      ->json_is('/admin_only'    => 1, 'group:admin passes (admin is in admin group)')
      ->json_is('/perm_required' => 1, 'perm:menu_read passes (admin has menu_read)')
      ->json_is('/mode_dev'      => 1, 'mode:development passes')
      ->json_is('/compound'      => 1, 'compound group:admin,mode:dev passes');
};

# -- 5. Back to anonymous — grants cleared -------------------------------

subtest 'Anonymous after logout' => sub {
    $t->get_ok('/logout')->status_is(302);

    $t->get_ok('/menu-conditions')
      ->status_is(200)
      ->json_is('/authenticated' => 0, 'not authenticated after logout')
      ->json_is('/auth_required' => 0, 'auth fails')
      ->json_is('/not_auth'      => 1, '!auth passes')
      ->json_is('/mode_dev'      => 1, 'mode:development still passes');
};

done_testing;
