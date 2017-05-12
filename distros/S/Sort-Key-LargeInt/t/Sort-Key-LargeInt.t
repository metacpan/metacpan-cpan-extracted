# -*- Mode: Perl -*-

use strict;
use warnings;

use Test::More tests => 4;

use Sort::Key::LargeInt qw(largeintsort);
use Sort::Key::Multi qw(is_keysort);

for my $l (20, 500) {

    for my $n (100, 20000) {

	my @data;
	for (0..$n) {
	    my $len = int rand 50;
	    push @data, join('', ('+', '-', '')[rand 3], map { my $d = int rand 11; $d >= 9 ? '_' : $d } 1..$len);
	}

	my @good = is_keysort {
	    my $s = $_;
	    my $sign = ($s =~ s/^\-// ? -1 : 1);
	    $s =~ s/_//g;
	    $s =~ s/^\+?0*//;
	    $s =~ tr/0123456789/9876543210/ if $sign < 0;
	    $sign * length $s, $s
	} @data;

	my @sorted = largeintsort @data;

	#use Data::Dumper;
	#print STDERR Dumper(\@sorted);
	#for (@good) {
	#    my $s = $_;
	#    my $sign = ($s =~ s/^\-// ? -1 : 1);
	#    $s =~ s/_//g;
	#    $s =~ s/^\+?0*//;
	#    $s =~ tr/0123456789/9876543210/ if $sign < 0;
	#    printf STDERR "%s => %d, %s : %s\n", $_, $sign * length $s, $s, encode_largeint_hex $_;
	#}

	is_deeply(\@sorted, \@good);
    }
}

