
package Stream::Aggregate::Stats;

use strict;
use warnings;
# use Scalar::Util;
require List::Util;
require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(percentile median mean largest smallest dominant dominantcount standard_deviation numeric_only);

our $ps;

sub numeric_only
{
	my ($field) = @_;
	die unless $ps;
	return $ps->{numeric}{$field} if $ps->{numeric}{$field};

	unless ($ps->{keep}->{$field}) {
		$ps->{numeric}{$field} = [];
	}

	no warnings;
	$ps->{numeric}{$field} = [ grep({defined($_) and ($_ <=> 0 or $_+0 eq $_) } @{$ps->{keep}->{$field}}) ];
}

sub percentile
{
	my ($field, $cutoff) = @_;
	die unless $cutoff >= 0 && $cutoff <= 100;

	return undef unless numeric_only($field);

	my @sorted = sort { $a <=> $b || $a cmp $b } @{$ps->{numeric}->{$field}};

	return $sorted[0] unless @sorted > 1;

	# count the fences, not the fence posts
	my $i = (@sorted -1) * $cutoff / 100;

	my $rem = $i - int($i);

	# my $c = @sorted; print "# i = $i, rem = $rem, sorted$c = @sorted\n";

	return $sorted[$i] unless $rem;

	return $sorted[$i] unless exists $sorted[$i+1];

	return $sorted[$i] unless $sorted[$i] > 0;
	return $sorted[$i] unless $sorted[$i+1] > 0;

	return $sorted[$i] * (1-$rem) + $sorted[$i+1] * $rem;
}

sub standard_deviation
{
	my ($field) = @_;
	return undef unless numeric_only($field);
	my $count = scalar(@{$ps->{numeric}->{$field}});
	return 0 unless $count;
	my $mean = List::Util::sum(@{$ps->{numeric}->{$field}}) / $count;
	my $x;
	for my $item (@{$ps->{numeric}->{$field}}) {
		my $diff = $item - $mean;
		$x += $diff * $diff;
	}
	return sqrt($x / $count);
}

sub median
{
	my ($field) = @_;
	return undef unless numeric_only($field);
	return percentile($field, 50);
}

sub mean
{
	my ($field) = @_;
	return undef unless numeric_only($field);
	my $data = $ps->{numeric}{$field};
	return undef unless $data && @$data;


	my $count = @$data;
	my $sum = List::Util::sum(@$data);
	my $side = $ps->{sidestats}{$field} || {};

	if ($side->{count}) {
		return ($sum + $side->{sum}) / ($count + $side->{count});
	} else {
		return $sum / $count;
	}
}

sub largest
{
	my ($field) = @_;
	return undef unless numeric_only($field);
	return List::Util::max(@{$ps->{numeric}->{$field}}, grep(defined $_, $ps->{sidestats}{$field}{max}));
}

sub smallest
{
	my ($field) = @_;
	return undef unless numeric_only($field);
	return List::Util::min(@{$ps->{numeric}->{$field}},grep(defined $_, $ps->{sidestats}{$field}{min}));
}

# stats "mode"
sub dominant
{
	my ($field) = @_;
	die unless $ps;
	return undef unless $ps->{keep}->{$field};
	my %counts;
	for my $d (@{$ps->{keep}->{$field}}) {
		next unless defined $d;
		$counts{$d}++;
	}
	my $maxcount = 0;
	my $max;
	for my $c (keys %counts) {
		next unless $counts{$c} > $maxcount;
		$maxcount = $counts{$c};
		$max = $c;
	}
	$ps->{sidestats}{$field}{dominantcount} = $maxcount;
	return ($max, $maxcount) if wantarray;
	return $max;
}

sub dominantcount
{
	my ($field) = @_;
	die unless $ps;
	my $data = $ps->{keep}{$field};
	return undef unless $data && @$data;
	my ($max, $maxcount);
	if (defined $ps->{sidestats}{$field}{dominantcount}) {
		$maxcount = $ps->{sidestats}{$field}{dominantcount}
	} else {
		($max, $maxcount) = dominant($field);
	}
	my $side = $ps->{sidestats}{$field};
	my $multiplier = (@$data + ($side->{count} || 0)) / @$data;  # for discarded data
	return $maxcount * $multiplier;
}

1;

__END__

=head1 NAME

Stream::Aggregate::Stats - some standard statistics functions

=head1 SYNOPSIS

 use Stream::Aggregate::Stats;

 $data = [ 1, 2, 3, 5, 9 ];
 $mydata = {
	keep => {
		fieldname	=> $data,
	},
	numeric => { },
 };

 local($Stream::Aggregate::Stats::ps) = $mydata;
 
 $mean = mean('fieldname');

=head1 DESCRIPTION

This module implements some standard statistics functions.  It has
an odd API: it expect the data to be inside a structure.  This is to
facilitate uses where the operations are found at runtime from
user input or configuration files.

The exact structure is:

 {
	keep => {
		field1 => [ @data ],
		field2 => [ @data ], 
		field3 => [ @data ],
	},
	numeric => {},
 }

where C<field1>, C<field2>, etc are names for the data.   You then ask
for functions by name: eg: C<mean('field1')>.

The functions available are:
C<percentile>,
C<standard_deviation>,
C<median>,
C<mean>,
C<largest> (numeric max),
C<smallest> (numeric min),
C<dominant> (the mode),
and
C<dominantcount>.
The C<percentile> function takes two arguments: the field name and the 
percentile: C<percentile(field1 =E<gt> 80)> gives you the 80th percentle
for the data in field1.   The 50th percentile is the same as the median.
The C<dominantcount> is the number of values that exactly matched the 
mode.

=head1 LICENSE

This package may be used and redistributed under the terms of either
the Artistic 2.0 or LGPL 2.1 license.

