#!perl -T

use strict;
use warnings;
use Test::More;

require_ok('Mojolicious::Plugin::HTMX');

done_testing();

diag("Mojolicious::Plugin::HTMX $Mojolicious::Plugin::HTMX::VERSION, Perl $], $^X");
