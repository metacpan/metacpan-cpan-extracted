#!perl

use Test::More tests => 5;

package foo;
use common::sense;

use Object::Event;
$Object::Event::ENABLE_METHODS_DEFAULT = $ENV{OE_METHODS_ENABLE};

our @ISA = qw/Object::Event/;

package main;
use common::sense;

my $f = foo->new;

my $called = 0;

my $id = $f->reg_cb (test => sub { $called += $_[1] });

$f->event (test => 10);

is ($called, 10, "first test called once");
ok ($f->handles ('test'), "got a handler");

$f->unreg_cb ($id);

$f->event (test => 20);

is ($called, 10, "second test still called once");

ok (!$f->handles ('test'), "no handler anymore");

$called = 0;
my $sub = sub { $called++ };
$id = $f->reg_cb (t => $sub);
$f->event ('t');
$id = $f->reg_cb (t => $sub);
$f->event ('t');
is ($called, 2, "guard removal on assignment correct");
