#!perl

use Test::More tests => 6;

package foo;
use common::sense;

use Object::Event;
$Object::Event::ENABLE_METHODS_DEFAULT = $ENV{OE_METHODS_ENABLE};

our @ISA = qw/Object::Event/;

package main;
use common::sense;

my $f = foo->new;

my $a = 0;
my $b = 0;
$f->reg_cb (
   test => sub {
      my ($f) = @_;

      $a++;

      $f->unreg_me;
      $f->event ('test2');
   },
   test2 => sub {
      my ($f) = @_;
      $b++;
      $f->unreg_me;
   }
);

ok ($f->handles ('test'),  "handles 'test'");
ok ($f->handles ('test2'), "handles 'test2'");

$f->event ('test');
$f->event ('test');
$f->event ('test2');
$f->event ('test2');

ok (!$f->handles ('test'),  "doesn't handle 'test'");
ok (!$f->handles ('test2'), "doesn't handle 'test2'");

is ($a, 1, 'first callback was called once');
is ($b, 1, 'second callback was called once');
