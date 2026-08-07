#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Template::Stencil;

# STENCIL_RF_STRICT = 0x1
sub strict_r { Template::Stencil::_render($_[0], $_[1], 1) }
sub r        { Template::Stencil::_render(@_) }

# Missing/undef output values croak with the full path and location.
{
    eval { strict_r('x{% page.header %}y', {}) };
    like($@, qr/<string>:1: undef value for 'page\.header'/,
         'strict croaks with path');
    eval { strict_r("line1\nline2 {% missing %}", {}) };
    like($@, qr/<string>:2: undef value for 'missing'/,
         'strict error carries the line');
}

# Defined values do not croak.
is(strict_r('{% v %}', { v => 0 }), '0', 'defined 0 fine under strict');
is(strict_r('{% v %}', { v => '' }), '', "'' fine under strict");

# Conditionals and defined() may test missing values without croaking.
is(strict_r('{% if v %}T{% else %}F{% end %}', {}), 'F',
   'if on missing fine under strict');
is(strict_r('{% if defined(v) %}D{% else %}U{% end %}', {}), 'U',
   'defined() fine under strict');

# Loops over missing iterables are quiet even under strict.
is(strict_r('x{% for i in l %}!{% end %}y', {}), 'xy',
   'missing iterable fine under strict');

# Non-strict renders empty (contrast).
is(r('x{% page.header %}y', {}), 'xy', 'non-strict renders empty');

done_testing;
