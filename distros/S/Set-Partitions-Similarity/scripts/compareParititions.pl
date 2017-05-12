#!/usr/bin/env perl

=head1 NAME

comparePartitions.pl - Script to compare set partitions.

=head1 SYNOPSIS

  comparePartitions.pl [-f fileP fileQ -t ',' -h -c]

=head1 DESCRIPTION

The script C<comparePartitions.pl> computes the I<accuracy> and I<precision> of the
set partitions stored in the files C<fileP> and C<fileQ>.

=head1 OPTIONS

=head2 C<-f fileP fileQ>

The option C<-f> specifies the two files containing the partitions to be compared.
Each line of a file is treated as a subset of the partition whose elements are stored as comma separated values.
The module L<Text::CSV> is used to parse each line.
The files must in UTF-8 format.

The set of elements comprizing each partition must be equal to properly compare them. Set
elements missing from either partition are added to the other partition as singleton subsets.
For example, if C<fileP> and C<fileQ> contained the lines indicated below

             fileP      fileQ
             -----      -----
  line 1     a,b,c      a,b
  line 2     d,e,f      c,d
  line 3                g,h

then the singleton sets C<{g}> and C<{h}> are added to partition C<P> making it equal
C<{{a,b,c}, {d,e,f}, {g}, {h}}> and similarly, the sets C<{e}> and C<{f}> are added to C<Q>
making it equal C<{{a,b}, {c,d}, {e}, {f}, {g,h}}>.

=head2 C<-t ','>

Use option C<-t> to set the delimiter to use in the CSV files C<fileP> and C<fileQ>; the default
delimiter is a comma. 

=head2 C<-c>

If option C<-c> is present, the subsets in each partition are checked to ensure they are disjoint. If
they are not, an exception is thrown.

=head2 C<-h>

Causes this documentation to be printed.

=head1 OUTPUT

If there are no errors, the output is the comma separated line C<accuracy,precision,fileP,fileQ>.

=head1 ERRORS

If option C<-c> is present, the subsets in each partition are checked to ensure they are disjoint. If
they are not, an exception is thrown.

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

L<Math::Set::Partitions::Similarity>, L<Text::CSV>

=cut

use strict;
use warnings;
use Set::Partitions::Similarity qw(getAccuracyAndPrecision areSubsetsDisjoint);
use Getopt::Long;
use List::MoreUtils qw{uniq};
use Text::CSV;
use Data::Dump qw(dump);
use Pod::Usage;

my $totalArguments = @ARGV;
my @partitionInputFiles;
my $delimiter = ',';
my $helpMessage = 0;
my $checkValidity = 0;

GetOptions ("f=s{2}" => \@partitionInputFiles, "t:s" => \$delimiter, "h|help" => \$helpMessage, 'c!' => $checkValidity);

# print info message
if ($helpMessage || ($totalArguments == 0))
{
  pod2usage ({-verbose => 1, -output => \*STDOUT});
  exit 0;
}

# set the $delimiter to undef if it has length zero, this
# makes Text::CSV default the delimiter to a comma.
$delimiter = ',' if (length ($delimiter) == 0);

# read in the first partition.
my @partitions;
for (my $i = 0; $i < 2; $i++)
{
  $partitions[$i] = getPartitionFromCsvFile ($partitionInputFiles[$i], $delimiter);

  # make sure the partition is valid.
  if ($checkValidity && !areSubsetsDisjoint ($partitions[$i]))
  {
    die "partition in file '$partitionInputFiles[0]' is invalid: subsets are not disjoint.\n";
  }
}

# ensure the partitions have the same union of elements by added
# missing elements as singletons sets to the partitions.
addMissingElementsToPartitions (@partitions);

# compute the accuracy and precision of the partitions.
my ($accuracy, $precision) = getAccuracyAndPrecision (@partitions);

# write the results to stdout.
my $csvWriter = Text::CSV->new ({sep_char => $delimiter});
unless (defined ($csvWriter))
{
  die "call Text::CSV->new failed: " . Text::CSV->error_diag ();
}
$csvWriter->combine ($accuracy, $precision, @partitionInputFiles);
print $csvWriter->string () . "\n";

sub getPartitionFromCsvFile # ($File, $Delimiter)
{
  my ($File, $Delimiter) = @_;

  # make sure the file exists and is a file.
  die "file '$File' does not exist.\n" unless (-e $File);
  die "'$File' is not a file.\n" unless (-f $File);

  # open the file for reading only.
  my $fileHandle;
  unless (open ($fileHandle, '<:utf8', $File))
  {
    die "could not open file '$File' for reading: $!\n";
  }

  # use Text::CSV to parse the values from each line.
  my $csvParser = Text::CSV->new ({sep_char => $Delimiter});
  unless (defined ($csvParser))
  {
    close $fileHandle;
    die "call Text::CSV->new failed: " . Text::CSV->error_diag ();
  }

  # parse each line into a subset of the partition.
  my @partition;
  my $subset;
  while (defined (my $subset = $csvParser->getline ($fileHandle)))
  {
    # ensure each element of the subset is unique.
    my @uniqueSubset = uniq @$subset;

    # skip the subset if it is empty.
    push @partition, \@uniqueSubset if @uniqueSubset;
  }

 $csvParser->eof;
 close $fileHandle;

 return \@partition;
}


# let U(P) and U(Q) be the set of all elements in partitions P and Q respectively. 
# this routine adds the elements of U(Q)-U(P) to the partition P as singleton sets and,
# likewise to Q for U(P)-U(Q).
sub addMissingElementsToPartitions # ($PartitionP, $PartitionQ)
{
  my ($PartitionP, $PartitionQ) = @_;

  # put the elements in $PartitionP into a hash.
  my %elementsInP;
  foreach my $subset (@$PartitionP)
  {
    foreach my $element (@$subset)
    {
      $elementsInP{$element} = 1;
    }
  }

  # compute the elements missing from each set.
  my @missingFromP;
  foreach my $subset (@$PartitionQ)
  {
    foreach my $element (@$subset)
    {
      if (exists ($elementsInP{$element}))
      {
        # the element is in P and Q, so delete it, if is not
        # missing from either partition.
        delete $elementsInP{$element};
      }
      else
      {
        # element is in Q but not in P, so add it as missing from P.
        push @missingFromP, [$element];
      }
    }
  }

  # elements remaining in %elementsInP are those not in Q, so add them to Q.
  push @$PartitionQ, map { ([$_]) } keys %elementsInP;

  # add the missing elements of P to @$PartitionP.
  push @$PartitionP, @missingFromP;

  return undef;
}

