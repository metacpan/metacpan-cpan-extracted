#!perl

use Test::More tests => 5;

package foo;
use common::sense;

use base qw/Object::Event/;

sub test : event_cb {
   my ($self, $a, $b) = @_;
   $self->{res} = $a + $b;
}

sub reset { (shift)->{res} = 0 }

package main;
use common::sense;

my $f = foo->new;

$f->test (10, 20);

is ($f->{res}, 30, 'calling method simply works');

$f->reset;

my $id1 = $f->reg_cb (test => sub {
   my ($self, $a, $b) = @_;
   $self->{res} *= 2;
   $self->{res} += $a + $b;
});

$f->test (10, 20);

is ($f->{res}, 90, 'simple chaining works');

$f->reset;

my $id2 = $f->reg_cb (before_test => sub {
   my ($self, $a, $b) = @_;
   $self->{res} = $a * $b;
});

$f->test (10, 20);

is ($f->{res}, 90, 'special events work');

$f->reset;

$f->unreg_cb ($id1);
$f->unreg_cb ($id2);

$f->test (20, 30);

is ($f->{res}, 50, 'unreg_cb works');

$f->reset;

$f->event (test => 30, 40);

is ($f->{res}, 70, 'calling event() works too');
