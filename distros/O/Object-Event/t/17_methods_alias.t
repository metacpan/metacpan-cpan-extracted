#!perl

use Test::More tests => 2;

package foo;
use common::sense;

use base qw/Object::Event/;

sub test : event_cb { push @{$_[0]->{x}}, 'middle' }

sub after : event_cb(after, test) {
   push @{$_[0]->{x}}, 'after'
}

sub xtest : event_cb( , test) {
   push @{$_[0]->{x}}, 'aftermiddle'
}

package meh;
use common::sense;
use base qw/Object::Event/;

sub test : event_cb {
   push @{$_[0]->{x}}, 'middle'
}

sub test_last : event_cb(-1, test) {
   push @{$_[0]->{x}}, 'after'
}

sub test_first : event_cb(1, test) {
   push @{$_[0]->{x}}, 'before'
}

package main;
use common::sense;

my $f = foo->new;

$f->reg_cb (test => 100 => sub { push @{$_[0]->{x}}, 'first' });

$f->xtest;

is (join (',', @{$f->{x}}), 'first,middle,aftermiddle,after',
    'event aliases work');

my $f2 = meh->new;

$f2->reg_cb (test => -0.5 => sub { push @{$_[0]->{x}}, 'shortaftermiddle' });

$f2->event ('test');

is (join (',', @{$f2->{x}}), 'before,middle,shortaftermiddle,after',
    'event aliases with prios work');

eval "package meh; sub test_xx :event_cb :xx { }";
