#!perl

use strict;
use warnings;

use Module::Locate qw/ mod_to_path /;
use Test::More 0.88 tests => 3;

is(mod_to_path('strict'),     'strict.pm',    'Path to strict pragam');
is(mod_to_path('Test::More'), 'Test/More.pm', 'Path to Test::More');

my $path;
eval { $path = mod_to_path('02packages') };
ok($@ && $@ =~ /Invalid package name/, "invalid package name should croak");
