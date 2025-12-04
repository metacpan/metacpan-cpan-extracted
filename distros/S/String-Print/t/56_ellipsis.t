#!/usr/bin/env perl
# Test the ellipsis modifier

use warnings;
use strict;
use utf8;

use Test::More;

use String::Print;

my $f = String::Print->new;
isa_ok($f, 'String::Print');

my $text1 = "123456789012345678901234567890";
is $f->sprinti("Intro: {text}", text => $text1), "Intro: $text1", 'no modifier';

is $f->sprinti("Intro: {text EL(50)}", text => $text1), "Intro: $text1", 'fits in field easily';

### these are all examples from the manual page

is $f->sprinti("Intro: {text EL(10)}", text => $text1),
	"Intro: 12345678⋯ ", 'default ellipsis';

is $f->sprinti("Intro: {text EL(10,)}", text => $text1),
	"Intro: 12345678⋯ ", 'default ellipsis, empty replace';

is $f->sprinti("Intro: {text EL(1,)}", text => $text1),
	"Intro: ⋯ ", 'replace too large';

is $f->sprinti("Intro: {text EL(10,⋮)}", text => $text1),
	"Intro: 123456789⋮", 'vertical ellipsis';

is $f->sprinti("Intro: {text EL(10⋮)}", text => $text1),
	"Intro: 123456789⋮", 'vertical ellipsis without comma';

is $f->sprinti("Intro: {text EL(10,XY)}", text => $text1),
	"Intro: 12345678XY", 'longer replacement';

is $f->sprinti("Intro: {text EL(10XY)}", text => $text1),
	"Intro: 12345678XY", 'longer replacement without comma';

# Defaults

is $f->sprinti("Intro: {text EL}", text => $text1),
	"Intro: 123456789012345678⋯ ", 'defaults';

#XXX this needs testing for wide and zero-width strings

done_testing;
