#!/usr/bin/env perl

use strict;
use feature 'say';
use warnings FATAL => 'all';
use autodie ':default';
use DDP {output => 'STDOUT', array_max => 10, show_memsize => 1};
use Devel::Confess 'color';
use Stats::LikeR;
use Time::HiRes;
use List::Util 'shuffle';

sub perl_sample {
	my $ref = shift;
	my $n = 1;
	if (defined $_[0]) {
		$n = shift;
	}
	my $ref_type = ref $ref;
	if ($ref_type eq 'HASH') {
		my %return;
		my @keys = shuffle( keys %{ $ref } );
		foreach my $k (@keys) {
			$return{$k} = $ref->{$k};
			last if (scalar keys %return) == $n;
		}
		return \%return;
	} elsif ($ref_type eq 'ARRAY') {
		my @shuffled = shuffle( @{ $ref } );
		return \@shuffled[0..$n-1];
	}
}

my %h = (a => 1, b => 2, c => 3, d => 4);

my (@xs, @perl);
foreach my $s (1..3) {
	foreach my $n (1..4) {
		my $t0 = Time::HiRes::time();
		my $sa = sample(\%h, $s);
		p $sa;
		my $t1 = Time::HiRes::time();
		push @xs, $t1-$t0;
	#-----
		$t0 = Time::HiRes::time();
		$sa = perl_sample(\%h, $s);
		$t1 = Time::HiRes::time();
		push @perl, $t1-$t0;
	}
}
say 'hashes:';
my $tt = t_test( \@xs, \@perl, var_equal => 0);
p $tt;
undef @perl;
undef @xs;
my @arr = qw(apple banana cherry date elderberry);
foreach my $n (1..4) {
	my $t0 = Time::HiRes::time();
	my $n = sample(\@arr, 1);
	my $t1 = Time::HiRes::time();
	push @xs, $t1-$t0;
#	p $n;
#-----
	$t0 = Time::HiRes::time();
	$n = perl_sample(\@arr, 1);
	$t1 = Time::HiRes::time();
	push @perl, $t1-$t0;
}
say 'arrays:';
$tt = t_test( \@xs, \@perl, var_equal => 0);
p $tt;
