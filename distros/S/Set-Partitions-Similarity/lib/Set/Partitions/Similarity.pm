package Set::Partitions::Similarity;

use strict;
use warnings;
#use Data::Dump qw(dump);

BEGIN
{
  use Exporter ();
  use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
  $VERSION     = '0.54';
  @ISA         = qw(Exporter);
  @EXPORT      = qw();
  @EXPORT_OK   = qw(getAccuracy getAccuracyAndPrecision getDistance getPrecision areSubsetsDisjoint);
  %EXPORT_TAGS = ();
}

#Routines to measure similarity of partitions.
#012345678901234567890123456789012345678901234

=head1 NAME

C<Set::Partitions::Similarity> - Routines to measure similarity of partitions.

=head1 SYNOPSIS

  use Set::Partitions::Similarity qw(getAccuracyAndPrecision);
  use Data::Dump qw(dump);

  # set elements are Perl strings, sets are array references
  # partitions are nested arrays.
  dump getAccuracyAndPrecision ([[qw(a b)],[1,2]], [[qw(a b 1)],[2]]);
  # dumps:
  # ("0.5", "0.25")

  # a partition is equivalent to itself, even the empty partition.
  dump getAccuracyAndPrecision ([[1,2], [3,4]], [[2,1], [4,3]]);
  dump getAccuracyAndPrecision ([], []);
  # dumps:
  # (1, 1)
  # (1, 1)

  # accuracy and precision are symmetric functions.
  my ($p, $q) = ([[1,2,3], [4]], [[1], [2,3,4]]);
  dump getAccuracyAndPrecision ($p, $q);
  dump getAccuracyAndPrecision ($q, $p);
  # dumps:
  # ("0.333333333333333", "0.2")
  # ("0.333333333333333", "0.2")

  # checks partitions and throws an exception.
  eval { getAccuracyAndPrecision ([[1]], [[1,2]], 1); };
  warn $@ if $@;
  # dumps:
  # partitions are invalid, they have different set elements.

=head1 DESCRIPTION

A partition of a set is a collection of mutually disjoint subsets of the set
whose union is the set. C<Set::Partitions::Similarity> provides routines
that measure the I<accuracy> and I<precision> between two partitions of a set. The measures can
assess the performance of a binary clustering algorithm by comparing
the clusters the algorithm creates against the correct clusters of test data.

=head2 Accuracy and Precision

Let C<S> be a set of C<n> elements and let C<P> be a partition of C<S>. Let C<T(S)>
be the set of all sets of two distinct elements of C<S>; so C<T(S)> has C<n*(n-1)/2> sets.
The partition C<P> uniquely defines a partitioning of C<T(S)> into two sets, C<C(P)> and C<D(P)> where
C<C(P)> is the set of all pairs in C<T(S)> such that both elements of a pair
occur in the same set in C<P>, and define C<D(P)> as C<T(S)-C(P)>, the complement.

Given two partitions C<P> and C<Q> of the set C<S>, the I<accuracy> is defined as
C<(|C(P) ^ C(Q)| + |D(P) ^ D(Q)|) / (n*(n-1)/2)>, where | | gives the size of a set and
^ represents the intersection operator. The I<precision> is defined as
C<|C(P) ^ C(Q)| / (|C(P) ^ C(Q)| + |C(P) ^ D(Q)| + |D(P) ^ C(Q)|)>. The I<accuracy> and
I<precision> return values ranging from zero (no similarity) to one (equivalent partitions).
The I<distance> between two partitions is defined as I<1-accuracy>, and in mathematics is a metric.
The I<distance> returns values ranging from zero (equivalent partitions) to one (no similarity).

All the methods implemented that compute the I<accuracy>, I<precision>, and I<distance> run in time linear in the
number of elements of the set partitioned.

=head1 ROUTINES

=head2 C<areSubsetsDisjoint ($Partition)>

The routine C<areSubsetsDisjoint> returns true if the subsets of the partition are disjoint,
false otherwise. It can be used to check the validity of a partition.

=over

=item C<$Partition>

The partition is stored as a nested array reference of the form
C<[[],...[]]>. For example, the set partition C<{{a,b}, {1,2}}> of the set
C<{a,b,1,2}> should be stored as the nested array reference
C<[['a','b']],[1,2]]>. Note the elements
of a set are represented as Perl strings.

=back

An example:

  use Set::Partitions::Similarity qw(areSubsetsDisjoint);
  use Data::Dump qw(dump);
  dump areSubsetsDisjoint ([[1,2,3], [4]]);
  dump areSubsetsDisjoint ([[1,2,3], [4,1]]);
  # dumps:
  # "1"
  # "0"

=cut

# a valid partition has all the subsets mutually disjoint. this routine
# returns 0 if it finds two distinct subsets have an element in common.
# this is done in time linear in the number of elements by computing the
# prefix union of the sets in the partition using a hash.
sub areSubsetsDisjoint
{
  # the hash %prefixUnionOfSubsets holds the union of elements in each subset
  # as they are checked for elements that occur in more than one subset.
  my %prefixUnionOfSubsets;
  foreach my $subset (@{$_[0]})
  {
    # since it is possible that a subset could contain a repeating element,
    # first each element is checked without adding it to the hash.
    foreach my $element (@$subset)
    {
      if (exists $prefixUnionOfSubsets{$element})
      {
        # if the second parameter is true, throw and exception, otherwise return false.
        if (defined ($_[1]) && $_[1])
        {
          die "element '$element' occurs in two of the subsets.\n";
        }
        else
        {
          return 0;
        }
      }
    }

    # now we can add all the elements to the hash.
    foreach my $element (@$subset)
    {
      $prefixUnionOfSubsets{$element} = 1;
    }
  }

  # the subsets are disjoint, return true.
  return 1;
}

=head2 C<getAccuracy ($PartitionP, $PartitionQ, $CheckValidity)>

The routine C<getAccuracy> returns the I<accuracy> of the
two partitions.

=over

=item C<$PartitionP, $PartitionQ>

The partitions are stored as nested array references of the form
C<[[],...[]]>. For example, the set partition C<{{a,b}, {1,2}}> of the set
C<{a,b,1,2}> should be stored as the nested array references
C<[['a','b']],[1,2]]>. Note the elements
of a set are represented as Perl strings.

=item C<$CheckValidity>

If C<$CheckValidity> evaluates to true, then checks are performed to
ensure both partitions are valid and an exception is thrown if they
are not. The default is false.

=back

An example:

  use Set::Partitions::Similarity qw(getAccuracy);
  use Data::Dump qw(dump);
  dump getAccuracy ([[qw(a b)], [qw(c d)]], [[qw(a b c d)]]);
  dump getAccuracy ([[qw(a b c d)]], [[qw(a b)], [qw(c d)]]);
  # dumps:
  # "0.333333333333333"
  # "0.333333333333333"

=cut

sub getAccuracy
{
  my ($ReferencePartition, $ModelPartition, $CheckValidity) = @_;

  # get both similarities.
  my ($accuracy, $precision) = getAccuracyAndPrecision ($ReferencePartition, $ModelPartition, $CheckValidity);

  # return just the accuracy.
  return $accuracy;
}


=head2 C<getAccuracyAndPrecision ($PartitionP, $PartitionQ, $CheckValidity)>

The routine C<getAccuracyAndPrecision> returns the I<accuracy> and I<precision> of the
two partitions as an array C<(accuracy, precision)>.

=over

=item C<$PartitionP, $PartitionQ>

The partitions are stored as nested array references of the form
C<[[],...[]]>. For example, the set partition C<{{a,b}, {1,2}}> of the set
C<{a,b,1,2}> should be stored as the nested array references
C<[['a','b']],[1,2]]>. Note the elements
of a set are represented as Perl strings.

=item C<$CheckValidity>

If C<$CheckValidity> evaluates to true, then checks are performed to
ensure both partitions are valid and an exception is thrown if they
are not. The default is false.

=back

An example:

  use Set::Partitions::Similarity qw(getAccuracyAndPrecision);
  use Data::Dump qw(dump);
  dump getAccuracyAndPrecision ([[1,2], [3,4]], [[1], [2], [3], [4]]);
  dump getAccuracyAndPrecision ([[1], [2], [3], [4]], [[1,2], [3,4]]);
  # dumps:
  # ("0.666666666666667", 0)
  # ("0.666666666666667", 0)

=cut

sub getAccuracyAndPrecision
{
  my ($ReferencePartition, $ModelPartition, $CheckValidity) = @_;

  # get the base count of edge types.
  my ($sameRefSameModel, $sameRefDiffModel, $diffRefSameModel, $diffRefDiffModel) = getBaseEdgeCounts ($ReferencePartition, $ModelPartition, $CheckValidity);

  # get the total number of bases edges.
  my $baseEdges = $sameRefSameModel + $sameRefDiffModel + $diffRefSameModel;

  # if there are no base edges, the precision is one.
  my $precision = 1;

  # get the precision.
  $precision = $sameRefSameModel / $baseEdges if $baseEdges;

  # get the total number of edges.
  my $totalEdges = $sameRefSameModel + $sameRefDiffModel + $diffRefSameModel + $diffRefDiffModel;

  # if there are no edges, the accuracy is one.
  my $accuracy = 1;

  # get the accuracy.
  $accuracy = ($sameRefSameModel + $diffRefDiffModel) / $totalEdges if $totalEdges;

  return ($accuracy, $precision);
}


=head2 C<getDistance ($PartitionP, $PartitionQ, $CheckValidity)>

The routine C<getDistance> returns I<1-accuracy> of the
two partitions, or C<1-getAccuracy($PartitionP, $PartitionQ, $CheckValidity)>.

=over

=item C<$PartitionP, $PartitionQ>

The partitions are stored as nested array references of the form
C<[[],...[]]>. For example, the set partition C<{{a,b}, {1,2}}> of the set
C<{a,b,1,2}> should be stored as the nested array references
C<[['a','b']],[1,2]]>. Note the elements
of a set are represented as Perl strings.

=item C<$CheckValidity>

If C<$CheckValidity> evaluates to true, then checks are performed to
ensure both partitions are valid and an exception is thrown if they
are not. The default is false.

=back

An example:

  use Set::Partitions::Similarity qw(getDistance);
  use Data::Dump qw(dump);
  dump getDistance ([[1,2,3], [4]], [[1], [2,3,4]]);
  # dumps:
  # "0.666666666666667"

=cut

sub getDistance
{
  my $accuracy = getAccuracy (@_);
  return 1 - $accuracy if defined $accuracy;
  return undef;
}


=head2 C<getPrecision ($PartitionP, $PartitionQ, $CheckValidity)>

The routine C<getPrecision> returns the I<precision> of the
two partitions.

=over

=item C<$PartitionP, $PartitionQ>

The partitions are stored as nested array references of the form
C<[[],...[]]>. For example, the set partition C<{{a,b}, {1,2}}> of the set
C<{a,b,1,2}> should be stored as the nested array references
C<[['a','b']],[1,2]]>. Note the elements
of a set are represented as Perl strings.

=item C<$CheckValidity>

If C<$CheckValidity> evaluates to true, then checks are performed to
ensure both partitions are valid and an exception is thrown if they
are not. The default is false.

=back

An example:

  use Set::Partitions::Similarity qw(getPrecision);
  use Data::Dump qw(dump);
  dump getPrecision ([[1,2,3], [4]], [[1], [2,3,4]]);
  # dumps:
  # "0.2"

=cut

sub getPrecision
{
  my ($ReferencePartition, $ModelPartition, $CheckValidity) = @_;

  # get both Similarity.
  my ($accuracy, $precision) = getAccuracyAndPrecision ($ReferencePartition, $ModelPartition, $CheckValidity);

  # return just the precision.
  return $precision;
}


sub getBaseEdgeCounts
{
  my ($ReferencePartition, $ModelPartition, $CheckValidity) = @_;

  # validates the partitions or throws an exception.
  validatePartitionsOrDie ($ReferencePartition, $ModelPartition) if $CheckValidity;

  my ($sameRefSameModel, $sameRefDiffModel) = getPartitionsEdgeCounts ($ReferencePartition, $ModelPartition);
  my ($sameModelSameRef, $diffRefSameModel) = getPartitionsEdgeCounts ($ModelPartition, $ReferencePartition);

  # make sure the number of edges for
  if ($sameRefSameModel != $sameModelSameRef)
  {
    die "programming error: computed different values for number of edges in same partitions.\n";
  }

  # get the number of elements in the universe of the sets.
  my $totalElements;
  {
    my %universe = map { ($_, 1) } map { @$_ } @$ReferencePartition;
    $totalElements = scalar keys %universe;
  }

  # get the total edges.
  my $totalEdges = ($totalElements * ($totalElements - 1)) / 2;

  return ($sameRefSameModel, $sameRefDiffModel, $diffRefSameModel, $totalEdges - $sameRefSameModel - $sameRefDiffModel - $diffRefSameModel);
}


sub getPartitionsEdgeCounts
{
  my ($ReferencePartition, $ModelPartition) = @_;

  my %modelId;
  for (my $id = 0; $id < @$ModelPartition; $id++)
  {
    my $subset = $ModelPartition->[$id];
    foreach my $element (@$subset)
    {
      $modelId{$element} = $id;
    }
  }

  # count the number of edges in the same partitions and the number in the
  # same reference partitions but difference model partitions.
  my $samePartitions = 0;
  my $sameRefDiffModel = 0;
  foreach my $subset (@$ReferencePartition)
  {
    my %subsetModelPartitionCounts;

    # need to ensure the subset elements are unique.
    {
      my %elements;
      for (my $i = 0; $i < @$subset; $i++)
      {
        unless (exists ($elements{$subset->[$i]}))
        {
          $elements{$subset->[$i]} = 1;
          ++$subsetModelPartitionCounts{$modelId{$subset->[$i]}};
        }
      }
    }

    # get the sizes of the model partitions of the subset.
    my @subsetPartitionSizes = values %subsetModelPartitionCounts;

    # count the number of edges having nodes in the same partitions.
    foreach my $size (@subsetPartitionSizes)
    {
      $samePartitions += ($size * ($size - 1)) / 2;
    }

    # count the number of edges having nodes in the same reference partitions
    # but different model partitions.
    my $prefixSumOfSizes;
    $prefixSumOfSizes = $subsetPartitionSizes[0] if @subsetPartitionSizes;
    for (my $i = 1; $i < @subsetPartitionSizes; $i++)
    {
      $sameRefDiffModel += $prefixSumOfSizes * $subsetPartitionSizes[$i];
      $prefixSumOfSizes += $subsetPartitionSizes[$i];
    }
  }

  return ($samePartitions, $sameRefDiffModel);
}


# for the set partitions to be valid, the union of sets of each partition
# must be equal. the routine returns true of they are, false if not.
sub doPartitionsHaveSameUnion
{
  my ($ReferencePartition, $ModelPartition) = @_;

  # add all the reference elements to the hash.
  my %universe = map { ($_, 1) } map { @$_ } @$ReferencePartition;

  # now check each subset of the model partition.
  foreach my $subset (@$ModelPartition)
  {
    # return 0 if an element from the subset is missing.
    foreach my $element (@$subset)
    {
      return 0 unless exists $universe{$element};
    }

    # delete all the elements in the hash from the subset.
    foreach my $element (@$subset)
    {
      delete $universe{$element};
    }
  }

  # if there are any elements remaining return 0.
  return 0 if %universe;

  return 1;
}


# this routine checks that the two partitions have the same union and
# each partition is composed for sets that a mutually disjoint. the
# routine throws and exception is the partitions are invalid.
sub validatePartitionsOrDie
{
  my ($ReferencePartition, $ModelPartition) = @_;

  # make sure the reference partition is valid.
  unless (areSubsetsDisjoint ($ReferencePartition))
  {
    die "first partition is an invalid partition, an element occurs in two or more subsets.\n";
  }

  # make sure the model partition is valid.
  unless (areSubsetsDisjoint ($ModelPartition))
  {
    die "second partition is an invalid partition, an element occurs in two or more subsets.\n";
  }

  # make sure the partitions have the same universe.
  unless (doPartitionsHaveSameUnion ($ReferencePartition, $ModelPartition))
  {
    die "partitions are invalid, they have different set elements.\n";
  }

  return 1;
}

=head1 EXAMPLE

The code following measures the I<distance> of a set of 512 elements partitioned
equally into subsets of size C<$s> to the entire set.

  use Set::Partitions::Similarity qw(getDistance);
  my @p = ([0..511]);
  for (my $s = 1; $s <= 512; $s += $s)
  {
    my @q = map { [$s*$_..($s*$_+$s-1)] } (0..(512/$s-1));
    print join (', ', $s, getDistance (\@p, \@q, 1)) . "\n";
  }
  # dumps:
  # 1, 1
  # 2, 0.998043052837573
  # 4, 0.99412915851272
  # 8, 0.986301369863014
  # 16, 0.970645792563601
  # 32, 0.939334637964775
  # 64, 0.876712328767123
  # 128, 0.75146771037182
  # 256, 0.500978473581213
  # 512, 0

=head1 INSTALLATION

To install the module run the following commands:

  perl Makefile.PL
  make
  make test
  make install

If you are on a windows box you should use 'nmake' rather than 'make'.

=head1 BUGS

Please email bugs reports or feature requests to C<bug-set-partitions-similarities@rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Set-Partitions-Similarity>.  The author
will be notified and you can be automatically notified of progress on the bug fix or feature request.

=head1 AUTHOR

 Jeff Kubina<jeff.kubina@gmail.com>

=head1 COPYRIGHT

Copyright (c) 2009 Jeff Kubina. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 KEYWORDS

accuracy, clustering, measure, metric, partitions, precision, set, similarity

=head1 SEE ALSO

=begin html

<p>Concise explainations of many cluster validity measures (including set partition measures) are available on
the <a href="http://machaon.karanagai.com/validation_algorithms.html">Cluster validity algorithms</a> page
of the <a href="http://machaon.karanagai.com/">Machaon Clustering and Validation Environment</a> web site
 by Nadia Bolshakova.</p>

<p>The Wikipedia article <a href="http://en.wikipedia.org/wiki/Accuracy_and_precision">Accuracy and precision</a> has a good explaination
of the <em>accuracy</em> and <em>precision</em> measures when applied to
<a href="http://en.wikipedia.org/wiki/Accuracy_and_precision#Accuracy_and_precision_in_binary_classification">binary classifications</a>.</p>

<p>The report <a href="http://bit.ly/fXWIgb">Objective Criteria for the Evaluation of Clustering Methods</a> (1971)
by W.M. Rand in the Journal of the American Statistical Association provides an excellent analysis of the <em>accuracy</em>
measure of partitions.</p>

=end html

=cut

1;
# The preceding line will help the module return a true value

