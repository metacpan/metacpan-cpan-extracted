#!/usr/bin/perl -W -T

use strict;
use Test::Simple tests => 2;

package Some_Class;
use parent qw(
	Object::By::Hash);

sub P_THIS() { 0 }
sub _init {
	$_[P_THIS]{'msg'} = 'Hello World.';
	$_[P_THIS]{'data'} = [4..6];
	return;
}

package main;
my $obj1 = Some_Class->constructor;

ok(ref($obj1) eq 'Some_Class', 'T001: right class');
ok($obj1->{'msg'} eq 'Hello World.', 'T002: initialized');

exit(0);
