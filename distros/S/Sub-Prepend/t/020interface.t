use Test::More tests => 1+1+2;
BEGIN { $^W = 1 }
use strict;

my $module = 'Sub::Prepend';

require_ok($module);
{
    package Foo;
    ::use_ok($module, 'prepend');
}
{
    package Bar;
    ::use_ok($module, ':ALL');
    ::ok(defined &prepend);
}
