#!perl

use Test::More tests => 1;

package foo;
use common::sense;

use Object::Event;
$Object::Event::ENABLE_METHODS_DEFAULT = $ENV{OE_METHODS_ENABLE};

our @ISA = qw/Object::Event/;

package main;
use common::sense;

# obfuscation around update_test
my $oe = 'Object' . '::' . 'Event';
&{$oe. '::' . 'register_priority_alias'} ('first', 3000);
&{$oe. '::' . 'register_priority_alias'} ('last', -3000);

my $f = foo->new;

$f->reg_cb (
   first_test  => sub { push @{$f->{r}}, 1 },
   before_test => sub { push @{$f->{r}}, 2 },
   test        => sub { push @{$f->{r}}, 3 },
   last_test   => sub { push @{$f->{r}}, 4 },
);

$f->event ('test');
is (join (',', @{$f->{r}}), '1,2,3,4', 'all callbacks got correct order');
