#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Template::Stencil;

plan tests => 1;

my $err = Template::Stencil::_arena_selftest();
is($err, undef, 'arena + intern C selftest')
    or diag "arena selftest: $err";
