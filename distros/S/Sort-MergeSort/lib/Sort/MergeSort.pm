
package Sort::MergeSort;

use strict;
use warnings;
use Sort::MergeSort::Iterator;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(mergesort);

our $VERSION = 0.31;

our $max_array = 64;

sub mergesort
{
	my ($compare, @inputs) = @_;

#printf "Number of inputs: %d\n", scalar(@inputs);

	#
	# Since we'll be using splice, don't use really wide arrays
	#

	if (@inputs > $max_array) {
		my @new_array;
		while (@inputs) {
			push(@new_array, mergesort($compare, splice(@inputs, 0, $max_array)));
		}
		return mergesort($compare, @new_array);
	}

	if (@inputs == 1) {
		return $inputs[0];
	} elsif (@inputs == 0) {
		return Sort::MergeSort::Iterator->new(sub { undef });
	}

	my @data;

	for my $i (@inputs) {
		my $first = <$i>;
		next unless defined $first;
		push(@data, [ $first, $i ]);
	}

	# Sort high to low so that the element we want can be
	# pop()ed off the end.  Cheaper than shift.

	@data = sort { $compare->($b->[0], $a->[0]) } @data;

#print join(", ", map { $_->[0] } @data)."\n";

	return Sort::MergeSort::Iterator->new(sub {
		return undef unless @data;

		my $popped = pop(@data);

		my $retval = $popped->[0];
		my $iter = $popped->[1];
		my $new = $popped->[0] = <$iter>;
		return $retval unless defined $new;

	#	if ($compare->($new, $retval) < 0) {
	#		die "Unsorted inputs $new $retval";
	#	}

		unless(@data) {
			@data = $popped;
			return $retval;
		}

		my $min = 0;
		my $max = $#data;

		while ($max - $min >= 2) {
			use integer;
			my $mid = ($min + $max) / 2; # rounds down
			my $c = $compare->($data[$mid][0], $new);
#print "new=$new [ $min, $mid, $max ] = $c\n";
			if ($c > 0) {
				$min = $mid;
			} elsif ($c < 0) {
				$max = $mid;
			} else {
				$max = $min = $mid;
			}
		}
		if ($compare->($data[$max][0], $new) > 0) {
			splice(@data, $max+1, 0, $popped);
		} elsif ($compare->($data[$min][0], $new) > 0) {
			splice(@data, $max, 0, $popped);
		} else {
			splice(@data, $min, 0, $popped);
		}

#print join(", ", map { $_->[0] } @data)."\n";
#die unless is_sorted(reverse map { $_->[0] } @data);

		return $retval;
	});
}

#sub is_sorted
#{
#	my $ok = 1;
#	for my $i (1..$#_) {
#		next if $_[$i] >= $_[$i-1];
#		$ok = 0;
#	}
#	return $ok;
#}

1;

__END__

=head1 NAME

Sort::MergeSort - merge pre-sorted input streams

=head1 SYNOPSIS

 use Sort::MergeSort;

 my $terator = mergesort($comparefunc, @iterators);

=head1 DESCRIPTION

Given a comparison function and a bunch of iterators that produce
data that is already sorted, C<mergesort()> will provide an 
iterator that produces sorted and merged data from all of the
input iterators.

Sort::MergeSort also works with filehandles.   It doesn't
care.   If it's only input is a filehandle, it will return a filehandle.
In all other situations it will return an iterator.

The C<$comparefunc> takes two arguments.  It does not use the
implicit C<$a> & C<$b> that perl sort uses.

The iterators are treated as file handles so any filehandle or
L<Sort::MergeSort::Iterator> will do as input.

=head1 EXAMPLE

 use Sort::MergeSort;

=head1 SEE ALSO

L<Sort::MergeSort::Iterator>

=head1 LICENSE

Copyright (C) 2008,2009 David Sharnoff.
Copyright (C) 2013 Google, Inc.

This package may be used and redistributed under the terms of either
the Artistic 2.0 or LGPL 2.1 license.

