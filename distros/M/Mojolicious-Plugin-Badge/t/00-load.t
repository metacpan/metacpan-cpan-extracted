#!perl -T

use strict;
use warnings;
use Test::More;

require_ok('Mojolicious::Plugin::Badge');

done_testing();

diag("Mojolicious::Plugin::Badge $Mojolicious::Plugin::Badge::VERSION, Perl $], $^X");
