use Test::More tests => 16;

use strict;
use warnings;

use_ok('Sub::SingletonBuilder');

my $c = 1;
*ctor = build_singleton(sub { $c++ });

is($c, 1);
is(ctor(), 1);
is($c, 2);
is(ctor(), 1);
is($c, 2);
is(ctor(undef), 1);
is($c, 2);

(*ctor2, *dtor) = build_singleton(sub { $c++ }, sub { $c = 1 });
is(dtor(), undef);
is($c, 2);
is(ctor2(), 2);
is($c, 3);
is(dtor(), undef);
is($c, 1);
is(ctor2(), 1);
is($c, 2);

