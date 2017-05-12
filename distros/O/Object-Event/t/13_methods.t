#!perl

use Test::More tests => 12;

package foo;
use common::sense;

use base qw/Object::Event/;

sub test : event_cb {
   my ($f, $a) = @_;
   $f->{a} += $a;
}

sub after : event_cb(after) { $_[0]->{x} = 10 }

sub noafter : event_cb { $_[0]->{y} = 10 }

sub pt : event_cb { push @{$_[0]->{a}}, 20 }

sub foobar : event_cb;

sub foozzz : event_cb(, foobar);

package foo2;
use base qw/foo/;

sub pt : event_cb(-1000) { push @{$_[0]->{a}}, 30 }

package foo3;
use base qw/foo2/;

sub pt : event_cb(1000) { push @{$_[0]->{a}}, 10 }

package main;
use common::sense;

my $f  = foo->new;
my $f2 = foo->new;

$f->reg_cb  (test => sub { $_[0]->{a} += 3 });
$f2->reg_cb (test => sub { $_[0]->{a} += 9 });

$f->test (10);
is ($f->{a}, 13, 'first object got event');
is ($f2->{a}, undef, 'second object got no event');

$f2->event (test => 20);
is ($f->{a}, 13, 'first object got no event');
is ($f2->{a}, 29, 'second object got event');

$f->reg_cb (foobar => sub { $_[0]->{b} = 10 });
$f->foobar;
$f2->foobar;
is ($f->{b}, 10, 'first object got method with event callback');
is ($f2->{b}, undef, 'second object doesn\'t have method with event callback');

$f->{b} = 0;
$f->foozzz;
is ($f->{b}, 10, 'first object got method with event callback with alias method');

ok ($f->event ('test'), 'event returns true for methods');

my $g = foo3->new;

$g->reg_cb (after   => sub { $_[0]->{x} = 20 });
$g->reg_cb (noafter => sub { $_[0]->{y} = 20 });
$g->after;
is ($g->{x}, 10, "priorities work");
$g->event ('after');
is ($g->{x}, 10, "priorities work 2");
$g->noafter;
is ($g->{y}, 20, "priorities work");

$g->pt;
is (join (',', @{$g->{a}}), '10,20,30', "priorities of event methods");
