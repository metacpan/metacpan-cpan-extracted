#!perl

use Test::More tests => 3;

package moh;
use common::sense;
use base qw/Object::Event/;

sub xtest : event_cb(,test) {
   push @{$_[0]->{x}}, 'moh2'
}

sub ztest : event_cb(-10,test) {
   push @{$_[0]->{x}}, 'moh3'
}

package baz;
use common::sense;
use base qw/moh/;

sub xtest : event_cb(-100,test) {
   push @{$_[0]->{x}}, 'baz2'
}

sub mtest : event_cb(-1000,test) {
   push @{$_[0]->{x}}, 'bazlast'
}

package meh;
use common::sense;
use base qw/baz/;

sub test : event_cb {
   push @{$_[0]->{x}}, 'meh'
}

package main;
use common::sense;

my $f = baz->new;

$f->reg_cb (test => 100 => sub { push @{$_[0]->{x}}, 'first' });
$f->event ('test');
is (join (',', @{$f->{x}}), 'first,moh2,moh3,baz2,bazlast', 'foo class');

my $m = meh->new;
$m->reg_cb (test => -1 => sub { push @{$_[0]->{x}}, 'middle2' });
$m->test;
is (join (',', @{$m->{x}}),
    'moh2,meh,middle2,moh3,baz2,bazlast',
    'meh class diamond');

my $b = baz->new;
$b->event ('test');
is (join (',', @{$b->{x}}), 'moh2,moh3,baz2,bazlast', 'baz class');
