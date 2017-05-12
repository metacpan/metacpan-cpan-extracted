#!/usr/bin/perl
use warnings;
use strict;
use Test::More   tests=>2;
use Sort::Merge;
use Data::Dumper;

sub make_count_by {
  my $i=0;
  my $step=shift;
  my $max=shift;
  my $tag=shift;
  
  return sub {
	my $n=$i++*$step;
	return if $n>$max;
	return ($n, $tag);
  }
}

{
  my @accum;
  Sort::Merge::sort_coderefs
	  ([
		make_count_by('1', '10', 'a'),
		make_count_by('5', '10', 'b')
	   ],
	   sub {push @accum, $_[0][1], $_[0][2]}
	  );
  #print Dumper \@accum;
  is_deeply(\@accum, 
			[
			 0,  'a',
			 0,  'b',
			 1,  'a',
			 2,  'a',
			 3,  'a',
			 4,  'a',
			 5,  'a',
			 5,  'b',
			 6,  'a',
			 7,  'a',
			 8,  'a',
			 9,  'a',
			 10, 'a',
			 10, 'b'
			], '0..10, 0..10:5')
}

{
  my @accum;
  Sort::Merge::sort_coderefs
	  ([
		make_count_by('1', '10', 'a'),
		make_count_by('1', '10', 'b'),
		make_count_by('1', '10', 'c')
	   ],
	   sub {push @accum, $_[0][1], $_[0][2]}
	  );
  #print Dumper \@accum;
  is_deeply(\@accum, 
			[
			 map {$_, 'a', $_, 'b', $_, 'c'} 0..10
			], '3-source round-robin')
}
