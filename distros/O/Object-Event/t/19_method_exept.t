#!perl

use Test::More tests => 3;

package foo;
use common::sense;
use base qw/Object::Event/;

sub test : event_cb { }

package foo2;
use base qw/foo/;

sub test : event_cb(-1000) { die }

package foo3;
use base qw/foo2/;

sub test : event_cb(1000) { }

package main;
use common::sense;

my $f  = foo3->new;

my $died;
$f->set_exception_cb (sub {
  $died++;
});

$f->test;

ok ($died, "got exception from method");

my $warn;
$SIG{__WARN__} = sub {
   $warn = $_[0];
};
$f->set_exception_cb (sub {
  $f->test;
});

$f->test;

ok ($warn =~ /recursion/, "got exception callback recursion");

$warn = undef;
$f->set_exception_cb (sub {
  $f->event ('test');
});

$f->event ('test');

ok ($warn =~ /recursion/, "got exception callback recursion via event method");
