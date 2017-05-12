#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 17;

use Sort::Key::Radix qw(ikeysort rikeysort isort risort
                        nkeysort rnkeysort rnsort nsort
                        ukeysort rukeysort usort rusort
                        isort_inplace risort_inplace
                        usort_inplace rusort_inplace);

my $unstable;
BEGIN {
    if ($] >= 5.008 ) {
	eval "use sort 'stable'";
    }
    else {
	$unstable = 1;
    }
}

my @data = map { rand(2**16) - (2**15) } 1..10000;

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

my @cp;
my @good;
@good = sort { int($a) <=> int($b)} @data;

is_deeply([isort @data], \@good, "isort");
is_deeply([ikeysort {$_} @data], \@good, 'i id 2');

@cp = @data;
isort_inplace @cp;
is_deeply(\@cp, \@good, 'isort_inplace');

@good = sort { int($b) <=> int($a)} @data;

is_deeply([risort @data], \@good, 'risort id 2');
is_deeply([rikeysort {$_} @data], \@good, 'ri id 2');

@cp = @data;
risort_inplace @cp;
is_deeply(\@cp,  \@good, 'risort_inplace');


@data = map { int rand(2**32) } 1..10000;

if ($unstable) {
    $_ = int $_ for @data;
}

@good = sort { int($a) <=> int($b)} @data;

is_deeply([usort @data], \@good, "usort");
is_deeply([ukeysort {$_} @data], \@good, 'u id 2');
@cp = @data;
usort_inplace @cp;
is_deeply(\@cp,  \@good, 'usort_inplace');

@good = sort { int($b) <=> int($a)} @data;

is_deeply([rusort @data], \@good, "rusort");
is_deeply([rukeysort {$_} @data], \@good, 'ru id 2');
@cp = @data;
rusort_inplace @cp;
is_deeply(\@cp,  \@good, 'rusort_inplace');

