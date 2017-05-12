#!perl

use Test::More tests => 1;

package foo;
use common::sense;

use Object::Event;
$Object::Event::ENABLE_METHODS_DEFAULT = $ENV{OE_METHODS_ENABLE};

our @ISA = qw/Object::Event/;

package main;
use common::sense;

my $f = foo->new;

my $a = 0;
$f->reg_cb (
   test => sub {
      my ($f) = @_;

      $a++;

      if ($a == 1) {
         $f->event ('test');
      } elsif ($a == 2) {
         $f->unreg_me;
      }
   }
);

$f->event ('test');
$f->event ('test');
$f->event ('test');

is ($a, 2, 'first callback was called twice');
