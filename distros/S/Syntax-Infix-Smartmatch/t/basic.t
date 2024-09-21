#!perl

use strict;
use warnings;

use Test::More;

use Syntax::Infix::Smartmatch;

package overloaded;

use overload "~~" => sub { $_[1] == 1 };

package main;

ok 1 ~~ 1;
ok !("1.0" ~~ 1);
ok (1 ~~ [1, 2, 3]);
ok !([1, 2, 3] ~~ [1, 2, 3]);
ok 1 ~~ sub { $_[0] };
ok 1 ~~ qr/1/;
ok !(1 ~~ undef);
ok !({ a => 1 } ~~ { a => 2 });

my $foo = bless {}, "overloaded";
ok 1 ~~ $foo;

done_testing;
