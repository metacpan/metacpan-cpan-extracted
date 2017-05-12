#! /usr/bin/env perl -w
use Test::More;
use Test::Mojo;
use FindBin;
use File::Path qw/remove_tree/;

use lib "$FindBin::Bin/apps/my_app/lib";
use_ok('MyApp');

my $t = Test::Mojo->new('MyApp');
$t->get_ok('/')->status_is(200)->content_like(qr/Welcome to the Mojolicious/)->or(sub { diag "$!" });
$t->get_ok('/test1')->status_is(200)->content_like(qr/test1/)->or(sub { diag "$!" });
$t->get_ok('/test2')->status_is(200)->content_like(qr/test2/)->or(sub { diag "$!" });
$t->get_ok('/test3')->status_is(404)->or(sub { diag "$!" });
$t->get_ok('/assets/css/style.css')->status_is(200)->content_like(qr/Global rules/)->or(sub { diag "$!" });
$t->get_ok('/assets/vendor/module/css/style.css')->status_is(200)->content_like(qr/style for Vendor::Module/)->or(sub { diag "$!" });
$t->get_ok('/mods')->status_is(200)->content_is('ok');
$t->get_ok('/mods_fail')->status_is(200)->content_is('fail');

cleanup();
done_testing();

sub cleanup {
  remove_tree "$FindBin::Bin/apps/my_app/public/assets";
}