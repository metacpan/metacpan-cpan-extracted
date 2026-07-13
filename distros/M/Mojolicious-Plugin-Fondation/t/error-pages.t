#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Mojo;
use File::Temp 'tempdir';
use FindBin;
use Cwd 'abs_path';

use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/lib";

use Mojolicious::Plugin::Fondation::TestHelper qw(create_test_app);

my $dev_share = abs_path("$FindBin::Bin/../share")
    or die "Cannot resolve dev share dir";

$ENV{MOJO_MODE} = 'production';

subtest '404 uses not_found.production template in production mode' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $app = create_test_app($tempdir);

    $app->plugin('Fondation' => { share_dir => $dev_share });

    my $t = Test::Mojo->new($app);
    $t->get_ok('/nonexistent/route')
      ->status_is(404)
      ->content_like(qr/Page Not Found/);
};

subtest '500 uses exception.production template in production mode' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $app = create_test_app($tempdir);

    $app->routes->get('/crash')->to(cb => sub { die "Test explosion" });

    $app->plugin('Fondation' => { share_dir => $dev_share });

    my $t = Test::Mojo->new($app);
    $t->get_ok('/crash')
      ->status_is(500)
      ->content_like(qr/Internal Server Error/);
};

subtest 'development mode uses Mojo default debug pages' => sub {
    local $ENV{MOJO_MODE} = 'development';

    my $tempdir = tempdir(CLEANUP => 1);
    my $app = create_test_app($tempdir);

    $app->plugin('Fondation' => { share_dir => $dev_share });

    my $t = Test::Mojo->new($app);
    $t->get_ok('/nonexistent')
      ->status_is(404);
    # Mojo's debug page, not our custom one
};

done_testing();
