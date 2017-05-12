# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use strict;
use warnings;
use Test::More tests => 2;

BEGIN { use_ok ('Set::Partitions::Similarity' ); }
use Set::Partitions::Similarity qw(getAccuracy);
ok (toRandomPartitionTest(), 'Testing random partitions.');

# generate randomly partitions and modify them in specific ways so that there
# accuracy can be computed independent of the partitions.
sub toRandomPartitionTest
{
  my $machineEpsilon = getMachineEpsilon ();

  for (my $testNo = 0; $testNo < 15; $testNo++)
  {
    my $TotalSubsets = 2 + int rand 1000;
    my $SubsetSize = 1 + int rand 100;
    my $partition1 = getRandomPartition ($TotalSubsets, $SubsetSize);
    my $errorFactor = sqrt ($TotalSubsets * $SubsetSize);

    # merge two clusters into one.
    {
      my $partition2 = jointTwoSubsets ($partition1);
      my $computedAccuracy = getAccuracy ($partition1, $partition2, 1);
      my $expectedAccuracy = (($TotalSubsets * $TotalSubsets - 2) * $SubsetSize - $TotalSubsets) / ($TotalSubsets * ($TotalSubsets * $SubsetSize - 1));
      my $relativeError = getRelativeError ($expectedAccuracy, $computedAccuracy);
      return 0 if ($relativeError > $errorFactor * $machineEpsilon);
    }

    # split one cluster into singletons.
    {
      my $partition2 = splitOneSubsetIntoSingletons ($partition1);
      my $computedAccuracy = getAccuracy ($partition1, $partition2, 1);
      my $expectedAccuracy = (($TotalSubsets * $TotalSubsets - 1) * $SubsetSize - $TotalSubsets + 1) / ($TotalSubsets * ($TotalSubsets * $SubsetSize - 1));
      my $relativeError = getRelativeError ($expectedAccuracy, $computedAccuracy);
      return 0 if ($relativeError > $errorFactor * $machineEpsilon);
    }
  }
  return 1;
}


# returns a random partition.
sub getRandomPartition
{
  my ($TotalSubsets, $SubsetSize) = @_;
  my @partition;
  my $startIndex = 0;
  for (my $i = 0; $i < $TotalSubsets; $i++)
  {
    my @subset = ($startIndex..($startIndex + $SubsetSize - 1));
    push @partition, \@subset;
    $startIndex += $SubsetSize;
  }
  return \@partition;
}


# creates a new partition by randomly merging two.
sub jointTwoSubsets
{
  my $newPartitions = copyShuffle ($_[0]);
  if (@$newPartitions > 1)
  {
    my $rightList = pop @$newPartitions;
    my $leftList = pop @$newPartitions;
    push @$newPartitions, [(@$rightList, @$leftList)];
  }
  return $newPartitions;
}


# creates a new partition my randomly splitting a subset into singletons.
sub splitOneSubsetIntoSingletons
{
  my $newPartitions = copyShuffle ($_[0]);
  my $rightList = pop @$newPartitions;
  my @singletons = map {[$_]} @$rightList;
  push @$newPartitions, @singletons;
  return $newPartitions;
}


# makes a copy then suffles a partition.
sub copyShuffle
{
  my $List = [@{$_[0]}];
  my $listSize = scalar @$List;
  for (my $i = 0; $i < @$List; $i++)
  {
    my $j = int rand $listSize;
    ($List->[$i], $List->[$j]) = ($List->[$j], $List->[$i]);
  }
  return $List;
}


# get the value of machine epsilon, sort of, really
# the unit roundoff value.
sub getMachineEpsilon
{
  my $one = 1;
  my $epsilon = 2;
  my $halfOfepsilon = 1;
  my $powerOf2 = 0;
  my $sum;
  do
  {
    $epsilon = $halfOfepsilon;
    $halfOfepsilon = $epsilon / 2;
    $sum = 1 + $halfOfepsilon;
    ++$powerOf2;
  }
  until (($sum == $one) || ($powerOf2 > 2048)) ;
  return $epsilon;
}


# returns relative error of two numbers.
sub getRelativeError
{
  my ($CorrectValue, $Approximation) = @_;
  return abs $Approximation unless $CorrectValue;
  return abs (($CorrectValue - $Approximation) / $CorrectValue);
}

