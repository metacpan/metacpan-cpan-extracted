#!perl

use Test::More tests => 3;

package moh;
use common::sense;
use base qw/Object::Event/;

sub test : event_cb {
   push @{$_[0]->{x}}, 'moh'
}

sub xtest : event_cb(,test) {
   push @{$_[0]->{x}}, 'moh2'
}

package baz;
use common::sense;
use base qw/moh/;

sub test : event_cb(-100) {
   push @{$_[0]->{x}}, 'baz'
}

sub xtest : event_cb(-100,test) {
   push @{$_[0]->{x}}, 'baz2'
}

sub mtest : event_cb(-1000,test) {
   push @{$_[0]->{x}}, 'bazlast'
}

package foo;
use common::sense;
use base qw/moh/;

sub test : event_cb {
   push @{$_[0]->{x}}, 'foo'
}

package meh;
use common::sense;
use base qw/baz foo/;

sub test : event_cb {
   push @{$_[0]->{x}}, 'meh'
}

package main;
use common::sense;

my $f = foo->new;

$f->reg_cb (test => 100 => sub { push @{$_[0]->{x}}, 'first' });
$f->test;
is (join (',', @{$f->{x}}), 'first,moh,moh2,foo', 'foo class');

my $m = meh->new;
$m->reg_cb (test => -1 => sub { push @{$_[0]->{x}}, 'middle2' });
$m->test;
is (join (',', @{$m->{x}}),
    'moh,moh2,moh,moh2,foo,meh,middle2,baz,baz2,bazlast',
    'meh class diamond');

my $b = baz->new;
$b->test;
is (join (',', @{$b->{x}}), 'moh,moh2,baz,baz2,bazlast', 'baz class');
