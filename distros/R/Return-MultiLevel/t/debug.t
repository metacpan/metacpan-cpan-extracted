#!perl

use Test::More tests => 2;
use Test::Fatal;

use warnings FATAL => 'all';
use strict;

BEGIN { $ENV{RETURN_MULTILEVEL_DEBUG} = 1; }
use Return::MultiLevel qw(with_return);

sub foo {
    my $naughty;
    with_return { $naughty = $_[0]; };
    $naughty
}

sub bar {
    foo @_
}

sub baz {
    my $f = shift;
    $f->(@_)
}

my $ret = bar;
my $exc = exception { baz $ret, 'ducks'; };

like $exc, qr{
    .* \bwith_return\b .* \Q${\__FILE__}\E .* \b 14 \b .* \n
    .* \bfoo\b         .* \Q${\__FILE__}\E .* \b 19 \b .* \n
    .* \bbar\b         .* \Q${\__FILE__}\E .* \b 27 \b .* \n
}x;

like $exc, qr{
    .* \bReturn::MultiLevel\b .* \bducks\b .* \Q${\__FILE__}\E .* \b 24 \b .* \n
    .* \bbaz\b                .* \bducks\b .* \Q${\__FILE__}\E .* \b 28 \b .* \n
}x;
