#!/usr/bin/env perl
# Test the UNKNOWN modifier

use warnings;
use strict;
use utf8;

use Test::More;

use String::Print;

my $f = String::Print->new;
isa_ok($f, 'String::Print');

is $f->sprinti("A {text UNKNOWN}", text => 'this text is short'), 'A "this text is short"', 'short text';
is $f->sprinti("B {text UNKNOWN}", text => "newline\n and tab\t."), 'B "newline\n and tab\t."', 'newline and tab';
is $f->sprinti("C {text UNKNOWN(10)}", text => 'this text is short'), 'C "this tex⋯ "', 'shortened text';

is $f->sprinti("D {array UNKNOWN}", array => [1, 2]), 'D [1,2]', 'short array';
is $f->sprinti("E {array UNKNOWN(10)}", array => [1..10]), 'E [1,2,3,4,⋯ ]', 'shortened array';

is $f->sprinti("F {hash UNKNOWN}", hash => { a => 1 }), 'F {a => 1}', 'short hash';
is $f->sprinti("G {hash UNKNOWN(10)}", hash => {a => 1, b => 2, c => 3}), 'G {a => 1,b⋯ }', 'shortened hash';

is $f->sprinti("H {class UNKNOWN}", class => $f), 'H String::Print', 'class';
is $f->sprinti("I {class UNKNOWN(5)}", class => $f), 'I String::Print', 'class not trimmed';

$f->setDefaults(UNKNOWN => { trim => 'CHOP', width => 15 });
is $f->sprinti("J {text UNKNOWN}", text => 'this is a much longer line'),
	'J "this is a [+16]"', 'chop shortened text';

#XXX this needs testing for wide and zero-width strings

done_testing;
