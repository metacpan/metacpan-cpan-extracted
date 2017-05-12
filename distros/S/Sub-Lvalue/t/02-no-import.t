#!/usr/bin/perl -w

use strict;
#use ex::lib '../lib';
use Test::More tests => 4;
use Sub::Lvalue ();

my ($set);
ok !defined &set, '!imported set';
ok !defined &get, '!imported get';

sub both : lvalue {
	Sub::Lvalue::get {
		'ok';
	}
	Sub::Lvalue::set {
		$set = shift;
	}
}

is(both, 'ok', 'get');
both = 'set1';
is($set, 'set1', 'set');

