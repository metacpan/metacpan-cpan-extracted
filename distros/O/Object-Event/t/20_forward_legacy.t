#!perl

use Test::More tests => 6;

package foo;
use common::sense;

use base qw/Object::Event/;

our @ISA = qw/Object::Event/;

package main;
use common::sense;

my $f = foo->new;

my $x = foo->new;

my @ev;
$f->add_forward ($x, sub {
   my ($f, $x, $ev, @args) = @_;
   (@ev) = ($f, $x, $ev, @args);
});

$f->event ('test', 1, 2, 3);

is (ref ($ev[0]), "foo", "first object ok");
is ("$ev[1]", "$x", "second object ok");
is ($ev[2], "test", "event name ok");
is ($ev[3], 1, "event name ok");
is ($ev[4], 2, "event name ok");
is ($ev[5], 3, "event name ok");
