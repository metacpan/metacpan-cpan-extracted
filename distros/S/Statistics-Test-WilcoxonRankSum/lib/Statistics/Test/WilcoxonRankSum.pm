package Statistics::Test::WilcoxonRankSum;

use warnings;
use strict;
use Carp;
use Carp::Assert;

use version; our $VERSION = qv('0.0.7');

use Contextual::Return;
use List::Util qw(sum);
use Set::Partition;
use Math::BigFloat;
use Math::Counting ':big';
use Statistics::Distributions;

use Class::Std;

{
  ############ Data ######################################################################

  my %EXACT_UPTO  : ATTR( :init_arg<exact_upto> :default<20> );
  my %dataset1_of : ATTR( :get<dataset1> ); # array of numbers
  my %dataset2_of : ATTR( :get<dataset2> ); # array of numbers
  my %n1_of       : ATTR( :get<n1> );       # number of elements in dataset 1
  my %n2_of       : ATTR( :get<n2> );       # number of elements in dataset 2
  my %N_of        : ATTR( :get<N>  );       # overall number of elements (ranks)
  my %MaxSum_of   : ATTR( :get<max_rank_sum> ); # biggest possible ranksum
  my %ranks_of    : ATTR( :get<ranks>    :set<ranks>  ); # hash with ranked data
  my %rank_array_of : ATTR( :get<rank_array> ); # rank array from %ranks
  my %rankSum1_of : ATTR( :get<rankSum_dataset1> ); # rank sum for dataset 1
  my %expected_rank_sum_1_of : ATTR( :get<expected_rank_sum_dataset1>); # expected rank sum for dataset 1
  my %expected_rank_sum_2_of : ATTR( :get<expected_rank_sum_dataset2>); # expected rank sum for dataset 2
  my %rankSum2_of : ATTR( :get<rankSum_dataset2> ); # rank sum for dataset 2
  my %smaller_rank_sum_of : ATTR;
  my %smaller_ranks_count_of : ATTR;
  my %expected_rank_count_for_smaller_ranks_count_of : ATTR( :get<expected_rank_count_for_smaller_ranks_count>);
  my %smaller_rank_sums_count_of : ATTR;            # number of possible arrangements with lesser rank sum
                                                    # than the smaller rank sum
  my %rank_sums_other_than_expected_count_of : ATTR; # number of possible arrangements with rank sum
                                                    # other than the smaller rank sum
  my %probability_of : ATTR;                   # probability for the ranking with smaller rank sum
  my %probability_normal_approx_of : ATTR;
  
  ############ Utility subroutines #######################################################

  sub _check_dataset {
    my ($dataset_ref) = @_;

    croak "Need array ref to dataset\n"
      unless ($dataset_ref);

    croak "Datasets must be passed as array references\n"
      unless (ref($dataset_ref) eq 'ARRAY');
    
    my @dataset = grep { $_ > 0 } @{ $dataset_ref };
    croak "dataset has no element greater 0\n" unless (@dataset);

    return \@dataset;

  }

  sub _compute_N_MaxSum {
    my ($id) = @_;

    my $N;
    unless ($N_of{$id}) {
      $N = $n1_of{$id} + $n2_of{$id};
      $N_of{$id} = $N;
    }

    unless ($MaxSum_of{$id}) {
      $MaxSum_of{$id} = $N*($N+1)/2;
    }

    unless ($expected_rank_sum_1_of{$id}) {
      $expected_rank_sum_1_of{$id} = $n1_of{$id}*$N/2;
    }

    unless ($expected_rank_sum_2_of{$id}) {
      $expected_rank_sum_2_of{$id} = $n2_of{$id}*$N/2;
    }

    return;
  }

  

  sub _reset_dependant_datastructures {
    my ($id) = @_;

    delete $ranks_of{$id};
    delete $rank_array_of{$id};
    delete $rankSum1_of{$id};
    delete $rankSum2_of{$id};
    delete $N_of{$id};
    delete $MaxSum_of{$id};
    delete $smaller_rank_sum_of{$id};
    delete $smaller_rank_sums_count_of{$id};
    delete $probability_of{$id};
    delete $probability_normal_approx_of{$id};
    delete $expected_rank_sum_1_of{$id};
    delete $expected_rank_sum_2_of{$id};
    
    return;
  }

  sub _rank_sum_for {
    my ($self, $dataset) = @_;

    my $id = ident $self;
    
    my @rank_array;

    if ($rank_array_of{$id} and @{ $rank_array_of{$id} }) {
      @rank_array = @{ $rank_array_of{$id} };
    } else {
      @rank_array = $self->compute_rank_array();
    }
    
    return sum map { $_->[0] } grep { $_->[1] eq $dataset } @rank_array;
  }


  sub _set_smaller_rank_for {
    my ($id, $rank_sum_1, $rank_sum_2) = @_;
    if ($rank_sum_1 <= $rank_sum_2) {
      $smaller_rank_sum_of{$id} = $rank_sum_1;
      $smaller_ranks_count_of{$id} = $n1_of{$id};
      $expected_rank_count_for_smaller_ranks_count_of{$id} = $expected_rank_sum_1_of{$id};
    } else {
      $smaller_rank_sum_of{$id} = $rank_sum_2;
      $smaller_ranks_count_of{$id} = $n2_of{$id};
      $expected_rank_count_for_smaller_ranks_count_of{$id} = $expected_rank_sum_2_of{$id};
    };
    return;
  };

  sub _NormalZ {  # ($Z) -> $p
    my ($x) = @_;
    #
    # P(x) = 1 - Z(x)(b1*t+b2*t**2+b3*t**3+b4*t**4+b5*t**5)
    # Z(x) = exp(-$x*$x/2.0)/(sqrt(2*3.14159265358979323846))
    # t = 1/(1+p*x)
    #
    # Parameters
    my @b = (0.319381530, -0.356563782, 1.781477937, -1.821255978, 1.330274429);
    my $p = 0.2316419;
    my $t = 1/(1+$p*$x);
    # Initialize variables
    my $fact = $t;
    my $Sum;
    # Sum polynomial
    foreach  my $bi (@b) { 
      $Sum += $bi*$fact;
      $fact *= $t;
    };
    # Calculate probability
    $p = 2*$Sum*exp(-$x*$x/2.0)/(sqrt(2*3.14159265358979323846));
    #
    return $p;
  };
  
  ############ Methods ###################################################################

  sub set_dataset1 {
    my ($self, $dataset1_ref) = @_;

    $dataset1_ref = _check_dataset($dataset1_ref);
    
    my $id = ident $self;
    $dataset1_of{$id} = $dataset1_ref;
    $n1_of{$id} = scalar(@{ $dataset1_ref });
    
    _reset_dependant_datastructures($id);

    return;
  }

  sub set_dataset2 {
    my ($self, $dataset2_ref) = @_;
    
    $dataset2_ref = _check_dataset($dataset2_ref);
    
    my $id = ident $self;
    $dataset1_of{$id} = $dataset2_ref;
    $n2_of{$id} = scalar(@{ $dataset2_ref });
    
    _reset_dependant_datastructures($id);

    return;
  }

  sub load_data {
    my ($self, $dataset1_ref, $dataset2_ref) = @_;

    $dataset1_ref = _check_dataset($dataset1_ref);
    $dataset2_ref = _check_dataset($dataset2_ref);
    
    my $id = ident $self;

    $dataset1_of{$id} = $dataset1_ref;
    $dataset2_of{$id} = $dataset2_ref;
    $n1_of{$id} = scalar(@{ $dataset1_ref });
    $n2_of{$id} = scalar(@{ $dataset2_ref });
    
    _reset_dependant_datastructures($id);

    _compute_N_MaxSum($id);
    
    return;
  }

  sub compute_ranks {
    my ($self) = @_;
    my $id = ident $self;

    croak "Please set/load datasets before computing ranks\n" unless ($dataset1_of{$id} and $dataset2_of{$id});
    
    my @dataset1 = @{ $dataset1_of{$id} };
    my @dataset2 = @{ $dataset2_of{$id} };

    # at this point we are sure we have both data sets, so we may as well compute N and MaxSum - if not already computed
    _compute_N_MaxSum($id);
    
    my %ranks;

    foreach my $el (@dataset1) {
      $ranks{$el}->{in_dataset}->{ds1}++;
    }
    foreach my $el (@dataset2) {
      $ranks{$el}->{in_dataset}->{ds2}++;
    }

    my $rank=0;
    foreach my $value (sort { $a <=> $b } keys %ranks) {

      my $tied_ranks;

      foreach my $ds (keys %{ $ranks{$value}->{in_dataset} }) {
        $tied_ranks += $ranks{$value}->{in_dataset}->{$ds};
      }

      assert $tied_ranks if DEBUG;

      my $rs;
      for my $r ($rank+1 .. $rank+$tied_ranks) {
        $rs += $r;
      }
      $ranks{$value}->{rank} = $rs/$tied_ranks;
      $ranks{$value}->{tied} = $tied_ranks;

      $rank+=$tied_ranks;
    }
    
    $ranks_of{$id} = \%ranks;

    return $ranks_of{$id};
  }

  sub compute_rank_array {
    my ($self) = @_;
    my $id = ident $self;

    my @rank_array;
    if ($rank_array_of{$id} and @{ $rank_array_of{$id} } ) {
      @rank_array = @{ $rank_array_of{$id} };
    } else {

      my %ranks;

      if ($ranks_of{$id} and %{ $ranks_of{$id} } ) {
        %ranks = %{ $ranks_of{$id} };
      } else {
        %ranks = %{ $self->compute_ranks() };
      }

      foreach my $value (sort { $a <=> $b } keys %ranks) {
        foreach my $ds (keys %{ $ranks{$value}->{in_dataset} }) {
          for (1..$ranks{$value}->{in_dataset}->{$ds}) {
            push(@rank_array, [ $ranks{$value}->{rank}, $ds ]);
          }
        }
      }

      $rank_array_of{$id} = \@rank_array;

    }
    
    return (
            SCALAR { scalar @rank_array }      # How many?
            LIST   { @rank_array        }      # What are they?
           );
  }

  sub rank_sum_for {
    my ($self, $for_dataset) = @_;

    my $id = ident $self;

    my $rankSum;
    if ($for_dataset =~ m{1}) {
      if ($rankSum1_of{$id}) {
        return $rankSum1_of{$id};
      } else {
        $rankSum1_of{$id} = $self->_rank_sum_for('ds1');
        return $rankSum1_of{$id};
      }
    } elsif ($for_dataset =~ m{2}) {
      if ($rankSum2_of{$id}) {
        return $rankSum2_of{$id};
      } else {
        $rankSum2_of{$id} = $self->_rank_sum_for('ds2');
        return $rankSum2_of{$id};
      }
    } else {
      croak "Argument must match `1' or `2' (meaning dataset 1 or 2)\n";
    }

    return;

  }

  sub get_smaller_rank_sum {
    my ($self) = @_;

    my $id = ident $self;

    if ($smaller_rank_sum_of{$id} and $smaller_ranks_count_of{$id}) {

      return (
              SCALAR { $smaller_rank_sum_of{$id} }                                  # only the rank sum itselt
              LIST   { ($smaller_rank_sum_of{$id}, $smaller_ranks_count_of{$id} ) } # also the size of the corresponding ds
             );
    }
    
    my $rank_sum_1 = $rankSum1_of{$id};
    my $rank_sum_2 = $rankSum2_of{$id};

    if (not($rank_sum_1) and not($rank_sum_2)) {
      $rank_sum_1 = $self->rank_sum_for('ds1');
    }

    
    if ($rank_sum_1 and $rank_sum_2) {

      _set_smaller_rank_for($id, $rank_sum_1, $rank_sum_2);
      
    } elsif ($rank_sum_1) {
      $rank_sum_2 = $MaxSum_of{$id} - $rank_sum_1;
      $rankSum2_of{$id} = $rank_sum_2;

      _set_smaller_rank_for($id, $rank_sum_1, $rank_sum_2);

    } elsif ($rank_sum_2) {
      $rank_sum_1 = $MaxSum_of{$id} - $rank_sum_2;
      $rankSum1_of{$id} = $rank_sum_1;

      _set_smaller_rank_for($id, $rank_sum_1, $rank_sum_2);

    }

    return (
            SCALAR { $smaller_rank_sum_of{$id} }                                  # only the rank sum itselt
            LIST   { ($smaller_rank_sum_of{$id}, $smaller_ranks_count_of{$id} ) } # also the size of the corresponding ds
           );

    
    return $smaller_rank_sum_of{$id};
  }
  
  sub smaller_rank_sums_count {
    my ($self) = @_;
    my $id = ident $self;

    if ($smaller_rank_sums_count_of{$id}) {
      return $smaller_rank_sums_count_of{$id};
    };
    
    my ($W, $nA) = $self->get_smaller_rank_sum();
    my $N = $N_of{$id};
    my $nB = $N - $nA;
    my $MaxSum = $MaxSum_of{$id};

    my @ranks = map { $_->[0] } $self->compute_rank_array();

    # let's do some checks before starting the big counting
    if ($W > $MaxSum) { croak "Rank sum bound $W is bigger than the maximum possible rank sum $MaxSum\n" };
    if ($N != scalar(@ranks))
      { croak "Sum of $nA and $nB must be equal to number of ranks: ".scalar(@ranks)."\n" }; 

    # compute all possible partitions
    my $s = Set::Partition->new(
                                list => \@ranks,
                                partition => [$nA, $nB],
                               );

    my $count_less_W = 0;
    
    while (my $p = $s->next()) {
      my @pA = @{ $p->[0] };
      my $sumA = sum @pA;
      if ($sumA <= $W) {
        $count_less_W++;
      }
    }
    
    return $count_less_W;
    
  };

  sub rank_sums_other_than_expected_counts {
    my ($self) = @_;
    my $id = ident $self;

    if ($rank_sums_other_than_expected_count_of{$id}) {
      return $rank_sums_other_than_expected_count_of{$id};
    };

    my ($W, $nA) = $self->get_smaller_rank_sum();
    my $W_exp = $self->get_expected_rank_count_for_smaller_ranks_count();

    my $N = $N_of{$id};
    my $nB = $N - $nA;
    my $MaxSum = $MaxSum_of{$id};

    my @ranks = map { $_->[0] } $self->compute_rank_array();

    # let's do some checks before starting the big counting
    if ($W > $MaxSum) { croak "Rank sum bound $W is bigger than the maximum possible rank sum $MaxSum\n" };
    if ($N != scalar(@ranks))
      { croak "Sum of $nA and $nB must be equal to number of ranks: ".scalar(@ranks)."\n" }; 

    # compute all possible partitions
    my $s = Set::Partition->new(
                                list => \@ranks,
                                partition => [$nA, $nB],
                               );

    my $count_other_W = 0;

    if ($W >= $W_exp) { 
    
      while (my $p = $s->next()) {
	my @pA = @{ $p->[0] };
	my $sumA = sum @pA;
	if ($sumA >= $W) {
	  $count_other_W++;
	}
      }

    } else {
    
      while (my $p = $s->next()) {
	my @pA = @{ $p->[0] };
	my $sumA = sum @pA;
	if ($sumA <= $W) {
	  $count_other_W++;
	}
      }

    }
    
    return $count_other_W;
    
  };


  sub probability :NUMERIFY {
    my ($self) = @_;
    my $id = ident $self;

    if ($probability_of{$id}) {
      return $probability_of{$id};
    }

    my ($W, $nA) = $self->get_smaller_rank_sum();
    my $N = $N_of{$id};

    my $p;
    if ($N <= $EXACT_UPTO{$id}) {
      $p = $self->probability_exact();
    } else {
      $p = $self->probability_normal_approx();
    }

    $probability_of{$id} = $p;

    return $probability_of{$id};
  }

  sub probability_exact {
    my ($self) = @_;
    my $id = ident $self;
    
    my ($W, $nA) = $self->get_smaller_rank_sum();
    my $N = $N_of{$id};

    my $partition_count = bcomb($N, $nA);
    my $have_smaller_rank_sums = $self->rank_sums_other_than_expected_counts();
    my $p = Math::BigFloat->new($have_smaller_rank_sums) * 2.0 / Math::BigFloat->new($partition_count);

    if ($p > 1) { $p = 1 };

    return $p;
  }

  sub probability_normal_approx {
    my ($self) = @_;
    my $id = ident $self;
    
    my ($W, $nA) = $self->get_smaller_rank_sum();
    my $N = $N_of{$id};
    my $nB = $N - $nA;
    my $mean = $nA*($N+1)/2;
    my $deviation = sqrt($nA*$nB*($N+1)/12.0);
    my $continuity = (($W - $mean) >= 0) ? -0.5 : +0.5;
    my $z = ($W - $mean + $continuity)/$deviation;
    @{ $probability_normal_approx_of{$id} }{'mean', 'std deviation', 'z'} = ($mean, $deviation, $z);
    
    my $p = 2*Statistics::Distributions::uprob(abs($z));

    return $p;
    
  }
  

  sub probability_status {
    my ($self) = (@_);
    my $id = ident $self;

    my $return_string;
    if ($probability_of{$id}) {
      if ($probability_normal_approx_of{$id}) {
        $return_string = sprintf "Probability: %10f, normal approx w. mean: %10f, std deviation: %10f, z: %10f", $probability_of{$id}, map { $probability_normal_approx_of{$id}->{$_} } ('mean', 'std deviation', 'z');
      } else {
        $return_string = sprintf "Probability: %10f, exact", $probability_of{$id};
      }
    } else {
      $return_string = "Probability not yet computed";
    }

    return (
            STR    { "$return_string" }
            VOID   { print $return_string."\n" }
           );
  }

  sub as_hash :HASHIFY {
    my ($self) = @_;
    my $id = ident $self;

    return {
            dataset_1 => $dataset1_of{$id},
            dataset_2 => $dataset2_of{$id},
            n1 => $n1_of{$id},
            n2 => $n2_of{$id},
            N => $N_of{$id},
            rank_array => $rank_array_of{$id},
            rank_sum_1 => $rankSum1_of{$id},
            rank_sum_2 => $rankSum2_of{$id},
            rank_sum_1_expected => $expected_rank_sum_1_of{$id},
            rank_sum_2_expected => $expected_rank_sum_2_of{$id},
            probability => $probability_of{$id},
            probability_normal_approx => $probability_normal_approx_of{$id},
           };

  }

  
  sub summary :STRINGIFY {
    my ($self) = (@_);
    my $id = ident $self;

    my $hash = $self->as_hash();

    my $return_string;
    if (not($hash->{dataset_1})) {
      $return_string = "Dataset 1 is not yet initialised, no computations could be done\n";
    } elsif (not($hash->{dataset_2})) {
      $return_string = "Dataset 2 is not yet initialised, no computations could be done\n";
    } else {
      my $format = <<END_FORMAT;
----------------------------------------------------------------
dataset |    n      | rank sum: observed / expected 
----------------------------------------------------------------
   1    |%7d    |           %7d      /%7d
----------------------------------------------------------------
   2    |%7d    |           %7d      /%7d
----------------------------------------------------------------
N (size of both datasets): %7d
%s
END_FORMAT
      my $prob = $self->probability_status();
      $return_string = sprintf $format, @{ $hash }{'n1', 'rank_sum_1', 'rank_sum_1_expected', 'n2', 'rank_sum_2', 'rank_sum_2_expected', 'N'}, $prob;
      if ($hash->{probability} >= 0.05) {
        $return_string.="Not significant (at 0.05 level)\n";
      } else {
        $return_string.="Significant (at 0.05 level)\n";
        $return_string.= $hash->{rank_sum_1} > $hash->{rank_sum_1_expected} ?
          "Ranks of dataset 1 are higher than expected\n"
            : "Ranks of dataset 1 are lower than expected\n";
          
      }
      if ($hash->{N} < 5) {
        $return_string.="Warning: sample size ($hash->{N}) too small (<5)!\n";
      }
    }

    return (
            STR    { "$return_string" }
            VOID   { print $return_string }
           );
  }
  
}

1; # Magic true value required at end of module


__END__

=head1 NAME

Statistics::Test::WilcoxonRankSum - perform the Wilcoxon (aka Mann-Whitney) rank sum test on two sets of numeric data.


=head1 VERSION

This document describes Statistics::Test::WilcoxonRankSum version 0.0.1


=head1 SYNOPSIS

    use Statistics::Test::WilcoxonRankSum;

    my $wilcox_test = Statistics::Test::WilcoxonRankSum->new();

    my @dataset_1 = (4.6, 4.7, 4.9, 5.1, 5.2, 5.5, 5.8, 6.1, 6.5, 6.5, 7.2);
    my @dataset_2 = (5.2, 5.3, 5.4, 5.6, 6.2, 6.3, 6.8, 7.7, 8.0, 8.1);

    $wilcox_test->load_data(\@dataset_1, \@dataset_2);
    my $prob = $wilcox_test->probability();

    my $pf = sprintf '%f', $prob; # prints 0.091022

    print $wilcox_test->probability_status();

    # prints something like:
    # Probability:   0.002797, exact
    # or
    # Probability:   0.511020, normal approx w. mean: 104.000000, std deviation:  41.840969, z:   0.657251

    my $pstatus = $wilcox_test->probability_status();
    # $pstatus is like the strings above

    $wilcox_test->summary();

    # prints something like:

    # ----------------------------------------------------------------
    # dataset |    n      | rank sum: observed / expected 
    # ----------------------------------------------------------------
    #   1    |     10    |               533      /    300
    # ----------------------------------------------------------------
    #   2    |     50    |              1296      /   1500
    # ----------------------------------------------------------------
    # N (size of both datasets):      60
    # Probability:   0.000006, normal approx w. mean: 305.000000, std deviation:  50.414945, z:   4.522468
    # Significant (at 0.05 level)
    # Ranks of dataset 1 are higher than expected

=head1 DESCRIPTION

In statistics, the Mann-Whitney U test (also called the Mann-Whitney-Wilcoxon (MWW), Wilcoxon rank-sum test, or Wilcoxon-Mann-Whitney test) is a non-parametric test for assessing whether two samples of observations come from the same distribution. The null hypothesis is that the two samples are drawn from a single population, and therefore that their probability distributions are equal. See the Wikipedia entry L<http://en.wikipedia.org/wiki/Mann-Whitney_U> (for eg.) or statistic textbooks for further details.

When the sample sizes are small the probability can be computed directly. For larger samples usually a normal approximation is used.

=head2 The Mechanics

Input to the test are two sets (lists) of numbers. The values of both lists are ranked from the smallest to the largest, while remembering which set the items come from. When the values are the same, they get an average rank. For each of the sample sets, we compute the rank sum. Under the assumption that the two samples come from the same population, the rank sum of the first set should be close to the value B<n1 * (n1 + n2 + 1)/2>, where n1 and n2 are the sample sizes. The test computes the (exact, resp. approximated) probability of the actual rank sum against the expected value (which is the one given above). So, when the computed probability is below I<0.05>, we can reject the null hypothesis at level 0.05 and conclude that the two samples are significantly different.

=head2 Implementation

The implementation follows the mechanics described above. The exact probability is computed for sample sizes less than B<20>, but this threshold can be set with `new'. For larger samples the probability is computed by normal approximation.

=head1 INTERFACE 

=head2 Constructor

=over

=item new()

Builds a new Statistics::Test::WilcoxonRankSum object.

When called like this:

 Statistics::Test::WilcoxonRankSum->new( { exact_upto => 30 }

the exact probability will be computed for sample sizes lower than 30 (instead of 20, which is the default).

=back

=head2 Providing the Data

=over

=item load_data(\@dataset_1, \@dataset_2)

=item set_dataset1(\@dataset_1)

=item set_dataset2(\@dataset_2)

=back

When calling these methods, all previously computed rank sums and probabilities are reset. 



=head2 Computations

=head3 Ranks

=over

=item compute_ranks()

The two datasets are put together and ranked (taking care of ties). The method returns a hash reference to a hash, with the data values as keys, looking like this:

                      '3' => {
                              'tied' => 2,
                              'in_dataset' => {
                                               'ds2' => 2
                                              },
                              'rank' => '1.5'
                             },
                      '24' => {
                               'tied' => 1,
                               'in_dataset' => {
                                                'ds1' => 1
                                               },
                               'rank' => '7'
                              },


=item compute_rank_array

Returns the ranks computed above in a differen form (depending on the context, an array of or the reference to array references):

 [ [ '1.5', 'ds2' ], [ '1.5', 'ds2' ], [ '3', 'ds1' ], ...]

The first item in the second level arrays is the rank and the second marks the data set the ranked item came from.
I<ds1> --> first dataset, I<ds2> --> second dataset.

In scalar context returns the number of elements (ie. the size of the two samples).

=item rank_sum_for

Computes rank sum for dataset given as argument. If the argument matches I<1>, this will be dataset 1, else dataset 2.

=item get_smaller_rank_sum

Checks which of the two rank sums is the smaller one.

=item smaller_rank_sums_count

For the set with the smaller rank sum, counts the number of partitions (of the ranks) giving a smaller rank sum than the observed one. Needed to compute the exact probability.

=item rank_sums_other_than_expected_counts

For the set with the smaller rank sum, counts the number of partitions (of the ranks) giving a rank sum other than the observed one (For example if the rank sum is larger than expected, counts the number of partitions giving a rank sum larger than the observed one). Needed to compute the exact probability.

=back

=head3 Probabilities

=over

=item probability

Computes (and returns) the probability of the given outcome under the assumption that the two data samples come from the same population. When the size of the two samples taken together is less than I<exact_upto>, L</"probability_exact"> is called, else L</"probability_normal_approx">. The parameter I<exact_upto> can be passed to L</"new"> as argument and defaults to I<20>.

When the size of the two samples taken together is less than 5, it makes not much sense to compute the probability. Currently, only the L</summary> method issues a warning.

This method is also called whenever an object of this class needs to be coerced to a number.

=item probability_exact

Compute the probability by counting.

=item probability_normal_approx

Compute the probability by normal approximation.

=back

=head2 Display and Notification

=over

=item probability_status

Tells if the probability has been or can be computed. If it has been computed shows the value and how it has been computed (by the direct method or by normal approximation).

=item summary

Prints or returns a string with diagnostics like this:

    # ----------------------------------------------------------------
    # dataset |    n      | rank sum: observed / expected 
    # ----------------------------------------------------------------
    #   1    |     10    |               533      /    300
    # ----------------------------------------------------------------
    #   2    |     50    |              1296      /   1500
    # ----------------------------------------------------------------
    # N (size of both datasets):      60
    # Probability:   0.000006, normal approx w. mean: 305.000000, std deviation:  50.414945, z:   4.522468
    # Significant (at 0.05 level)
    # Ranks of dataset 1 are higher than expected

This method also issues a warning, when the size of the 2 samples taken together is less than 5.

B<summary> is called whenever an object of this class needs to be coerced to a string.

=item as_hash

Returns a hash reference with the gathered data, needed to compute the probabilities, with the following keys:

=over

=item dataset_1

The first dataset (array ref)

=item dataset_2

The second dataset (also array ref)

=item n1

size of first dataset

=item n2

size of second dataset

=item N

 n1 + n2

=item rank_array

the array returned by L</compute_rank_array>, see there.

=item rank_sum_1, rank_sum_2

rank sum of first and second dataset respectively.

=item rank_sum_1_expected rank_sum_2_expected

the expected rank sums, if the two samples came from the same population. For the first dataset this is:

  n1 * (N+1) / 2

=item probability

=item probability_normal_approx

data used for computing the probability by normal approximation, when the sample size is too large. A hash reference with the following keys: B<mean>, B<std deviation>, B<z>.

=back

=back

=head2 Getter

The following methods are provided by the I<Class::Std> I<:get> facility and return the corresponding object data:

=over

=item get_dataset1, get_dataset2

=item get_n1

=item get_n2

=item get_N

=item get_max_rank_sum

=item get_rank_array

=item get_rankSum_dataset1, get_rankSum_dataset2

=item expected_rank_sum_dataset1, expected_rank_sum_dataset2

=back

=head1 DIAGNOSTICS

=over

=item C<< Need array ref to dataset >>

=item C<< Datasets must be passed as array references >>

When a L</"Providing the Data"> method is called without enough arguments, or when the arguments are not array references.

=item C<< dataset has no element greater 0 >>

It makes no sense to compute the probability when all the items are 0.

=item C<< Please set/load datasets before computing ranks >>

Maybe you called a L</compute_ranks> method, and didn't hand in both datasets?

=item C<< Argument must match `1' or `2' (meaning dataset 1 or 2) >>

The method L</rank_sum_for> must know what dataset to compute the rank for: dataset 1, if the argument matches 1, dataset 2 if the argument matches 2.

=item C<< Rank sum bound %i is bigger than the maximum possible rank sum %i >>

=item C<< Sum of %i and %i must be equal to number of ranks: %i >>

Plausibility checks before doing the rank sum counts (L</smaller_rank_sums_count>). Something's terribly broken when this occurs.

=back


=head1 CONFIGURATION AND ENVIRONMENT

Statistics::Test::WilcoxonRankSum requires no configuration files or environment variables.


=head1 DEPENDENCIES

=over

=item Carp

=item Carp::Assert

=item Class::Std

=item Contextual::Return

=item Set::Partition

=item List::Util qw(sum)

=item Math::BigFloat

=item Math::Counting

=item Statistics::Distributions

=back


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-statistics-test-wilcoxonranksum@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 TO DO

=over

=item a sort function as argument (maybe at construction time)

such that float data within a given interval can be considered equal

=item a more obvious warning the sample sizes are definitely too small

=back

=head1 AUTHOR

Ingrid Falk  C<< <ingrid dot falk at loria dot fr> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, Ingrid Falk C<< <ingrid dot falk at loria dot fr> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
