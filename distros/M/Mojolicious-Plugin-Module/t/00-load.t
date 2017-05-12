use strict;
use warnings FATAL => 'all';
use Test::More;
use lib './lib';

plan tests => 1;

BEGIN { use_ok('Mojolicious::Plugin::Module') }

diag "Testing Mojolicious::Plugin::Module $Mojolicious::Plugin::Module::VERSION, Perl $], $^X";