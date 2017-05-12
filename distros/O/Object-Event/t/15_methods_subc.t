#!perl

use Test::More tests => 5;

package first;
use common::sense;
use base qw/Object::Event/;

sub test2 : event_cb {
   my ($self, $a) = @_;
   push @{$self->{chain}}, 'first::test2';
}

sub test3 : event_cb {
   my ($self) = @_;
   push @{$self->{chain}}, 'first::test3';
}

package pre;
use common::sense;
use base qw/first/;

sub test2 : event_cb {
   my ($self, $a) = @_;
   push @{$self->{chain}}, 'pre::test2';
}

package foo;
use common::sense;
use base qw/Object::Event/;

sub test : event_cb {
   my ($self, $a, $b) = @_;
   push @{$self->{chain}}, 'foo::test';
}

package bar;
use common::sense;
use base qw/foo pre/;

sub test : event_cb {
   my ($self, $a, $b) = @_;
   push @{$self->{chain}}, 'bar::test';
}

sub test2 : event_cb {
   my ($self, $a) = @_;
   push @{$self->{chain}}, 'bar::test2';
}

package main;
use common::sense;

my $f = foo->new;
my $b = bar->new;

$b->test2 (100);
is ((join ",", @{delete $b->{chain}}), 'first::test2,pre::test2,bar::test2', 'bar first class works.');

$b->test3 (200);
is ((join ",", @{delete $b->{chain}}), 'first::test3', 'bar first undecl class works.');

$f->reg_cb (before_test => sub {
   my ($f) = @_;
   push @{$f->{chain}}, 'f::before_test';
});

$b->reg_cb (before_test => sub {
   my ($f) = @_;
   push @{$f->{chain}}, 'b::before_test';
});

$b->reg_cb (test2 => sub {
   my ($f) = @_;
   push @{$f->{chain}}, 'b::test2';
});

$f->test (10, 20);
is ((join ",", @{delete $f->{chain}}), 'f::before_test,foo::test', 'foo class works.');
$b->test (10, 20);
is ((join ",", @{delete $b->{chain}}), 'b::before_test,foo::test,bar::test', 'bar class works.');
$b->test2 (100);
is ((join ",", @{delete $b->{chain}}), 'first::test2,pre::test2,bar::test2,b::test2', 'bar class works.');
