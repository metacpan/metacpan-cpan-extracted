#!perl

use Test::More tests => 2;

package foo;
use common::sense;

use Object::Event;
$Object::Event::ENABLE_METHODS_DEFAULT = $ENV{OE_METHODS_ENABLE};

our @ISA = qw/Object::Event/;

package main;
use common::sense;

my $f = foo->new;

$f->reg_cb (test1 => sub { });

ok ($f->event ('test1'),  "event returns true for reg_cb cb.");
ok (!$f->event ('test2'), "event returns false for non cb.");
