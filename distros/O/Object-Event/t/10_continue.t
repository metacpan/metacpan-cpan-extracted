#!perl

use Test::More tests => 2;

package foo;
use common::sense;

use base qw/Object::Event/;
$Object::Event::ENABLE_METHODS_DEFAULT = $ENV{OE_METHODS_ENABLE};

sub test { }

package main;
use common::sense;

my $f = foo->new;

my $cont;
$f->reg_cb (test => sub {
   my ($f, $a) = @_;
   $f->{val} += $a * 1;
   $cont = $f->stop_event;
});

$f->reg_cb (test => sub {
   my ($ev, $a) = @_;
   $f->{val} *= $a * 2;
});

$f->{val} = 0;
$f->event ('test', 3);

is ($f->{val}, 3, 'event got captured okay');

$f->{val} = 1;
$cont->();

is ($f->{val}, 6, 'event got continued okay');
