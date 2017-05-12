#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 9;
use Sort::Key qw(nkeysort rnkeysort nsort rnsort
		 ikeysort rikeysort isort risort
		 ukeysort rukeysort usort rusort);

my $unstable;
BEGIN {
    if ($] >= 5.008 ) {
	eval "use sort 'stable'";
    }
    else {
	$unstable = 1;
    }
}

my @data=map { rand(2**16) - (2**15) } 1..10000;

if ($unstable) {
    $_ = int abs $_ for @data;
}

{
    use integer;
    is_deeply([nkeysort {$_} @data], [sort { int($a) <=> int($b)} @data], 'i id');
    is_deeply([nkeysort {$_*$_} @data], [sort { int($a*$a) <=> int($b*$b) } @data], 'i sqr');
    is_deeply([rnkeysort {$_*$_} @data], [sort { int($b*$b) <=> int($a*$a) } @data], 'ri sqr');
    is_deeply([rnsort @data], [sort { int($b) <=> int($a) } @data], 'i rnsort');
    is_deeply([nsort @data], [sort { int($a) <=> int($b) } @data], 'i nsort');
}
is_deeply([ikeysort {$_} @data], [sort { int($a) <=> int($b)} @data], 'i id 2');
is_deeply([rikeysort {$_} @data], [sort { int($b) <=> int($a)} @data], 'ri id 2');

@data = map { int rand(2**32) } 1..10000;

if ($unstable) {
    $_ = int $_ for @data;
}

is_deeply([ukeysort {$_} @data], [sort { int($a) <=> int($b)} @data], 'u id 2');
is_deeply([rukeysort {$_} @data], [sort { int($b) <=> int($a)} @data], 'ru id 2');
