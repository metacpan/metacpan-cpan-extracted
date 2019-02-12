#!/usr/bin/env perl

use Mojolicious::Lite;

use Test::More;
use Test::Mojo;
use File::Basename;

use lib 'lib';
use lib '../lib';

use_ok 'Mojolicious::Plugin::MoreHTMLHelpers';

plugin('MoreHTMLHelpers');

my $t = Test::Mojo->new;

is $t->app->gradient( undef ), sprintf template(), ('#ffffff') x 13;
is $t->app->gradient( '#ffffff' ), sprintf template(), ('#ffffff') x 13;
is $t->app->gradient( '#affe00' ), sprintf template(), ('#affe00') x 13;

done_testing();

sub template {
    return q~
            background: %s !important;
            background: -moz-linear-gradient(top,  %s 0%%,%s 100%%) !important;
            background: -webkit-gradient(linear, left top, left bottom, color-stop(0%%, %s), color-stop(100%%,%s)) !important;
            background: -webkit-linear-gradient(top,  %s 0%%,%s 100%%) !important;
            background: -o-linear-gradient(top,  %s 0%%,%s 100%%) !important;
            background: -ms-linear-gradient(top,  %s 0%%,%s 100%%) !important;
            background: linear-gradient(to bottom,%s 0%%,%s 100%%) !important;
        ~;
}

