#!perl

use Test::More tests => 4;

package foo;
use common::sense;

use Object::Event;
$Object::Event::ENABLE_METHODS_DEFAULT = $ENV{OE_METHODS_ENABLE};

our @ISA = qw/Object::Event/;

package main;
use common::sense;

my $f = foo->new;

$f->reg_cb (
   test            => sub { push @{$f->{a}}, 3 },

   before_test     => sub { push @{$f->{a}}, 1 },
   after_test      => sub { push @{$f->{a}}, 5 },

   ext_before_test => sub { push @{$f->{a}}, 2 },
   ext_after_test  => sub { push @{$f->{a}}, 4 },
);

$f->event ('test');
is (join (',', @{$f->{a}}), '1,2,3,4,5', 'priorities called in correct order');

my $idg = $f->reg_cb (
   test => 2000  => sub { push @{$f->{a}}, -1   },
   test => -100  => sub { push @{$f->{a}},  3.5 },
   test => 100   => sub { push @{$f->{a}},  2.5 },
   test => -2000 => sub { push @{$f->{a}},  6   }
);

my $idg2 = $f->reg_cb (
   test => 2000  => sub { push @{$f->{a}}, -1   },
   test => -100  => sub { push @{$f->{a}},  3.5 },
   test => 100   => sub { push @{$f->{a}},  2.5 },
   test => -2000 => sub { push @{$f->{a}},  6   }
);

@{$f->{a}} = ();
$f->event ('test');
is (join (',', @{$f->{a}}), '-1,-1,1,2,2.5,2.5,3,3.5,3.5,4,5,6,6', 'custom priorities called in correct order');

$idg = undef;

@{$f->{a}} = ();
$f->event ('test');
is (join (',', @{$f->{a}}), '-1,1,2,2.5,3,3.5,4,5,6', 'priorities called in correct order after remove');

$f->unreg_cb ($idg2);

@{$f->{a}} = ();
$f->event ('test');
is (join (',', @{$f->{a}}), '1,2,3,4,5', 'priorities called in correct order after remove');
