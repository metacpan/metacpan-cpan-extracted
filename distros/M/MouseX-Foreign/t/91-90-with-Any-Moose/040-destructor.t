#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 4;

my $destroyed = 0;
my $demolished = 0;
package Foo;

sub new { bless {}, shift }

sub DESTROY { $destroyed++ }

package Foo::Sub;
use Mouse;
use Any::Moose 'X::NonMoose';
extends 'Foo';

sub DEMOLISH { $demolished++ }

package main;
{ Foo::Sub->new }
is($destroyed, 1, "non-Mouse destructor called");
is($demolished, 1, "Mouse destructor called");
Foo::Sub->meta->make_immutable;
($destroyed, $demolished) = (0, 0);
{ Foo::Sub->new }
is($destroyed, 1, "non-Mouse destructor called (immutable)");
is($demolished, 1, "Mouse destructor called (immutable)");
