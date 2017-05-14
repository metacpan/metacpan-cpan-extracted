#!/usr/bin/perl -W -T

use strict;
use Test::Simple tests => 2;

package Some_Class;
use parent qw(
	Object::By::Array);

sub P_THIS() { 0 }
sub _init {
	$_[P_THIS][0] = 'Hello World.';
	$_[P_THIS][1] = [4..6];
	return;
}

package main;
my $obj1 = Some_Class->constructor;

ok(ref($obj1) eq 'Some_Class', 'T001: right class');
ok($obj1->[0] eq 'Hello World.', 'T002: initialized');

exit(0);
