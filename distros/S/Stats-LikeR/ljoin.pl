#!/usr/bin/env perl

use 5.042.2;
no source::encoding;
use warnings FATAL => 'all';
use autodie ':default';
use DDP {output => 'STDOUT', array_max => 10, show_memsize => 1};
use Devel::Confess 'color';
use Stats::LikeR;
use Time::HiRes;

sub ljoin_pp {
	my ($h, $i) = @_;

	for my $row (keys %$h) {
		if (exists $i->{$row}) {
			# Ensure $h's row is a Hash
			if (ref($h->{$row}) eq 'HASH') {
				# Case A: $i's row is a Hash
				if (ref($i->{$row}) eq 'HASH') {
				  for my $col (keys %{ $i->{$row} }) {
						$h->{$row}{$col} = $i->{$row}{$col};
				  }
				} elsif (ref($i->{$row}) eq 'ARRAY') { # $i's row is an Array
				  my @arr = @{ $i->{$row} };
				  # Iterate in key-value pairs
				  for (my $idx = 0; $idx < @arr - 1; $idx += 2) {
						$h->{$row}{ $arr[$idx] } = $arr[$idx + 1];
				  }
				}
			}
		}
	}
}
my (@xs, @perl);
foreach my $n (0..9) {
	my $h = { 'Jack Smith' => { age => 30 } };
	my $i = { 'Jack Smith' => { dept => 'Engineering' }, 'Jane Doe' => { age => 25 } };
	my $t0 = Time::HiRes::time();
	ljoin($h, $i);
	my $t1 = Time::HiRes::time();
	push @xs, $t1-$t0;
}
foreach my $n (0..9) {
	my $h = { 'Jack Smith' => { age => 30 } };
	my $i = { 'Jack Smith' => { dept => 'Engineering' }, 'Jane Doe' => { age => 25 } };
	my $t0 = Time::HiRes::time();
	ljoin_pp($h, $i);
	my $t1 = Time::HiRes::time();
	push @perl, $t1-$t0;
	p $h if $n == 0;
}
summary(@xs);
summary(@perl);
my $tt = t_test(\@xs, \@perl, var_equal => false);
p $tt;
