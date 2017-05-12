package Statistics::Table::F;

use strict;
use vars qw($VERSION @ISA @EXPORT);

require Exporter;
require AutoLoader;

@ISA = qw(Exporter AutoLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(F anova);

$VERSION = '0.01';

my %F;

$F{.05} = [[1,     2,     3,     4,     5,     6,     7,     8,     9,     10,    12,    15,    20,    24,    30,    40,    60, 120, "infinity"],
	   [161.4, 199.5, 215.7, 224.6, 230.2, 234.0, 236.8, 238.9, 240.5, 241.9, 243.9, 245.9, 248.0, 249.1, 250.1, 251.1, 252.2, 253.3, 254.3],
	   [18.51, 19.00, 19.16, 19.25, 19.30, 19.33, 19.35, 19.37, 19.38, 19.40, 19.41, 19.42, 19.45, 19.45, 19.46, 19.47, 19.48, 19.49, 19.50], 
	   [10.13, 9.55,  9.28,  9.12,  9.01,  8.94,  8.89,  8.85,  8.81,  8.79,  8.74,  8.70,  8.66,  8.64,  8.62,  8.59,  8.57,  8.55,  8.53],
	   [7.71,  6.94,  6.59,  6.39,  6.26,  6.16,  6.09,  6.04,  6.00,  5.96,  5.91,  5.86,  5.80,  5.77,  5.75,  5.72,  5.69,  5.66,  5.63],
	   [6.61,  5.79,  5.41,  5.19,  5.05,  4.95,  4.88,  4.82,  4.77,  4.74,  4.68,  4.62,  4.56,  4.53,  4.50,  4.46,  4.43,  4.40,  4.36],
	   [5.99,  5.14,  4.76,  4.53,  4.39,  4.28,  4.21,  4.15,  4.10,  4.06,  4.00,  3.95,  3.87,  3.84,  3.81,  3.77,  3.74,  3.70,  3.67],
	   [5.59,  4.74,  4.35,  4.12,  3.97,  3.87,  3.79,  3.73,  3.68,  3.64,  3.57,  3.51,  3.44,  3.41,  3.38,  3.34,  3.30,  3.27,  3.23],
	   ];

sub F {
    my ($degrees_col, $degrees_row, $significance_level) = @_;
    if ($significance_level != .05) {
	warn "Only the 0.05 significance level is available.  Let orwant\@media.mit.edu know if you want other levels";
	return undef;
    }
    my (@f) = @{$F{.05}};
    if (!defined $f[$degrees_col]) {
	warn "There's no entry in this F table for $degrees_col degrees of freedom.  Let orwant\@media.mit.edu know.";
	return undef;
	
    }
    my (@row) = @ {$f[$degrees_col]};
    for (my $i = 0; $i < @row-1; $i++) {
	if ($f[0]->[$i+1] > $degrees_row) {
	    return $row[$i];
	}
    }
    return $row[$#row-1];
}

sub mean {
    my ($arrayref) = @_;
    my $result;
    foreach (@$arrayref) { $result += $_ }
    return $result / @$arrayref;
}

sub estimate_variance {
    my ($arrayref) = @_;
    my ($mean) = mean($arrayref);
    my ($result);
    foreach (@$arrayref) {
        $result += ($_ - $mean) ** 2;
    }
    return $result / $#{$arrayref};
}

sub square_sum {
    my ($arraysref) = shift;
    my (@arrays) = @$arraysref;
    my ($result, $arrayref);
    foreach $arrayref (@arrays) {
        foreach (@$arrayref) { $result += $_ ** 2 }
    }
    return $result;
}

sub sum {
    my ($arraysref) = shift;
    my (@arrays) = @$arraysref;
    my ($result, $arrayref);
    foreach $arrayref (@arrays) {
        foreach (@$arrayref) { $result += $_ }
    }
    return $result;
}

sub square_groups {
    my ($arraysref) = shift;
    my (@arrays) = @$arraysref;
    my ($result, $arrayref);
    foreach $arrayref (@arrays) {
        my $sum = 0;
        foreach (@$arrayref) { $sum += $_ }
        $result += ($sum ** 2) / @$arrayref;
    }
    return $result;
}

sub count_elements {
    my ($arraysref) = shift;
    my $result;
    foreach (@$arraysref) { $result += @$_ }
    return $result;
}

# Performs a one-way analysis of variance, returning the F-ratio.
sub anova {
    my ($all) = shift;
    my $num_of_elements = count_elements($all);
    my $square_of_everything = square_sum($all);
    my $sum_of_everything = sum($all);
    my $sum_of_groups = square_groups($all);
    my $degrees_of_freedom_within  = $num_of_elements - @$all;
    my $degrees_of_freedom_between = @$all - 1;
    my $sum_of_squares_within = $square_of_everything - $sum_of_groups;
    my $mean_of_squares_within = $sum_of_squares_within /
        $degrees_of_freedom_within;
    my $sum_of_squares_between = $sum_of_groups -
        ($sum_of_everything ** 2)/$num_of_elements;
    my $mean_of_squares_between = $sum_of_squares_between /
        $degrees_of_freedom_between;
    return $mean_of_squares_between / $mean_of_squares_within;
}


1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Statistics::Table::F - Perl module for computing the statistical F-ratio

=head1 SYNOPSIS

  use Statistics::Table::F;

  if (($F = anova($list_of_lists)) >= F(@$list_of_lists - 1,
					count_elements($list_of_lists - @$list_of_lists),
					0.05)) {
      print "F is $F; the difference between your data sets is significant.\n";
  } else {
      print "F is $F; the difference between your data sets is not significant.\n";
  }
						       

=head1 DESCRIPTION

See Orwant, Hietaniemi, and Macdonald, I<Mastering Algorithms in
Perl>, O'Reilly 1999.  From Chapter 15:

The significance tests covered so far can only pit one group against
another.  Sure, we could do a t-test of every possible pair of web
design firms, but we'd have trouble integrating the results.

An analysis of variance, or ANOVA, is necessary when you need to
consider not just the variance of one data set but the variance
between data sets.  The sign, ChiSquare, and t-tests all involved
computing intrasample descriptive statistics; we'd speak of the means
and variances of individual samples.  Now we can jump up a level of
abstraction and start thinking of entire data sets as elements in a
larger data set -- a data set of data sets.

For our test of web designs, our null hypothesis is that the design
has no effect on the size of the average sale.  Our alternative is
simply that some design is different from the rest.  This isn't a very
strong statement; we'd like a little matrix that show us how each
design compares to one another and to no design at all.
Unfortunately, ANOVA can't do that.

The key to the particular analysis of variance we'll study here, a
one-way ANOVA, is computing the F-ratio.  The F-ratio is defined as
the mean square between (the variance between the means of each data
set) divided by the mean square within (the mean of the variance
estimates).  This is the most complex significance test we've seen so
far.  Here's a Perl program that computes the analysis of variance for
all four designs.  Note that since ANOVA is ideal for multiple data
sets with varying numbers of elements, we choose a data structure to
reflect that: $designs, a list of lists.

=head1 AUTHOR

Jon Orwant, orwant@media.mit.edu

=head1 SEE ALSO

Statistics::ChiSquare, Statistics::Table::t

=cut
