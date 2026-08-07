#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Template::Stencil;

plan tests => 3;

# Growth across many small writes from a tiny initial hint, plus the
# 8-byte-store short write (advances 4 of the 8 written bytes).
my $got = Template::Stencil::_buf_selftest();
is(length $got, 3000 + 4, 'buffer length after growth and write8');
is($got, ('abc' x 1000) . '1234', 'buffer content exact');

# The returned SV is a plain terminated string usable as-is.
ok($got =~ /4\z/ && $got !~ /\x00/, 'NUL-terminated cleanly, no stray bytes');
