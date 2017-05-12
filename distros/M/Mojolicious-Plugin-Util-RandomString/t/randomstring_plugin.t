#!/usr/bin/env perl
use strict;
use warnings;

BEGIN {
  our @INC;
  unshift(@INC, '../../lib', '../lib', '.', 't');
};

use Mojolicious::Lite;
use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new;
my $app = $t->app;

$app->plugin('TestRandomString');

my $full = qr/^[abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ]+$/;

my $r = $app->chiffre;
ok($r, 'Chiffre is fine');
like($r, $full, 'Chiffre has correct alphabet');

$r = $app->chiffre;
ok($r, 'Chiffre is fine again');
like($r, $full, 'Chiffre has again correct alphabet');

$t->get_ok('/testpath')->content_like($full);
ok($app->chiffre, 'Chiffre is created');
$t->get_ok('/testpath')->content_like($full);

done_testing;
