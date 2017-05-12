#!/usr/bin/perl -w

use strict;
#use ex::lib '../lib';
use Test::More tests => 10;
use Sub::Lvalue;

my ($set);
ok defined &set, 'imported set';
ok defined &get, 'imported get';

sub both1 : lvalue {
	get {
		'ok';
	}
	set {
		$set = shift;
	}
}

sub both2 : lvalue {
	set {
		$set = shift;
	}
	get {
		'ok';
	}
}

is(both1, 'ok', 'get first.get');
is(both2, 'ok', 'get last.get');
both2 = 'set2';
is($set, 'set2', 'set first.set');
both1 = 'set1';
is($set, 'set1', 'set last.set');

sub ro : lvalue {
	get {
		'ok';
	}
}
sub wo : lvalue {
	set {
		$set = shift;
	}
}

is (ro, 'ok', 'ro.get');
ok (!eval{ro = 'zz';1}, '!ro.set');

ok (!eval{my $x = wo;1}, '!wo.get');
wo = 'set3';
is ($set, 'set3', 'wo.set');

