#!/usr/bin/perl
use 5.016;
use strict;

use Test::More;

use Slackware::SBoKeeper::Home;

plan tests => 2;

ok(defined $HOME, '$HOME was defined');
ok(-d $HOME,      '$HOME points to a directory');
