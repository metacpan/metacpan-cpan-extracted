#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Mojo;
use File::Temp 'tempdir';
use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/lib";

use Mojolicious::Plugin::Fondation::TestHelper qw(create_test_app);

# ==========================================================================
# Route conditions must NOT render during the route tree walk (see the
# around_dispatch hook in Mojolicious::Plugin::Fondation). A failed
# condition sets the 'fondation.denied' stash marker; the hook renders it
# once, AFTER the walk. Without this, a condition rendered on a
# prefix-matching route (/secret matching /secret/1) is evaluated again on
# the full-match route and dies with "A response has already been
# rendered", killing the worker.
# ==========================================================================

{
    my $tempdir = tempdir(CLEANUP => 1);
    my $app     = create_test_app($tempdir);

    $app->plugin('Fondation' => { dependencies => [] });

    # Make the permissive fallback check_perm fail
    $app->helper(check_perm => sub { 0 });

    $app->routes->get('/secret')->requires('fondation.perm' => 'x')
        ->to(cb => sub { shift->render(text => 'ok') });
    $app->routes->get('/secret/:id')->requires('fondation.perm' => 'x')
        ->to(cb => sub { shift->render(text => 'ok') });

    my $t = Test::Mojo->new($app);

    $t->get_ok('/secret/1')->status_is(403,
        'failed condition on {id} route -> 403, no double render');
    $t->get_ok('/secret/1')->status_is(403,
        'worker alive after denied request');
    $t->get_ok('/secret')->status_is(403,
        'failed condition on list route -> 403');
}

done_testing;
