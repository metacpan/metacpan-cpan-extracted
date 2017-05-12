#!/usr/bin/perl
use warnings;
use strict;
package Foo;
sub add { return $_[1] + $_[2] };

package main;
use lib ('lib');
use Test::More 'no_plan';
use Petal;

$Petal::BASE_DIR = './t/data/';
$Petal::DISK_CACHE = 0;
$Petal::MEMORY_CACHE = 0;
$Petal::TAINT = 1;

my $template = new Petal ('string.xml');
my $string = $template->process (
	user => { name => 'Bruno Postle' },
	number => 2,
	math => bless {}, 'Foo'
);

like ($string, '/Hello, Bruno Postle, 2 \\+ 2 = 4/', "found");
