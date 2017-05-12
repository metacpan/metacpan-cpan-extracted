use Test::More tests => 2;
BEGIN { $^W = 1 }
use strict;

my $module = 'Sub::Prepend';

require_ok($module);
use_ok($module);
