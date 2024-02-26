#!/usr/bin/env perl

use warnings;
use strict;
use Util::H2O::More qw/ddd Getopt2h2o/;

# build and load subroutines
use OpenMP::Simple;
use OpenMP::Environment;

use Inline (
    C                 => 'DATA',
    with              => qw/OpenMP::Simple/,
);

my $P           = 5;
my $V           = undef;
my $ABSOLUTEMIN = 1;

my $o = Getopt2h2o \@ARGV, {
    eps     => 0.1,
    f       => q{./fort.14},
    minPts  => 5,
    threads => 2,
  },
  qw/eps=s f=s minPts=i threads=i/;

my $env = OpenMP::Environment->new();

$env->omp_num_threads( $o->threads );

# $sub_ref (user provided subroutine reference) to the longitudinal position, $y
sub process_f14 {
    my ($o) = @_;
    my $NODES = [];

    open my $F14, q{<}, $o->f or die $!;

    my $mesh_name = <$F14>;
    chomp $mesh_name;

    my $line = <$F14>;
    $line =~ m/(\d+)\s+(\d+)/;
    my $NE = $1;
    my $NN = $2;

    # collect node positions - 1D array, but every 3 items is
    # a "3-tuple" consisting of: node index, x position, y position; this
    # is done to make the Perl-to-C data conversions easier for
    # working with OpenMP friendly constructs like for loops
    my $NODES_array = [];
    foreach ( my $i = 1; $i <= $NN; ++$i ) {
        my $line = <$F14>;
        $line =~ m/^\s*(\d+)\s+([+\-]*\d+\.\d+)\s+([+\-]*\d+\.\d+)/;
        my $node = $1;
        my $x    = $2;
        my $y    = $3;
        push @$NODES, [ $x, $y ];
    }

    close $F14;

    my $c = 1;
    my $S = DBSCAN( $NODES, $o->eps, $o->minPts );
    foreach my $C ( sort { $a <=> $b } keys %$S ) {
        foreach my $n ( @{ $S->{$C} } ) {
            my $x = $NODES->[$n-1]->[0];
            my $y = $NODES->[$n-1]->[1];
            printf qq{%d %s %s %d\n}, $c++, $x, $y, $C;
        }
    }

    return;
}

sub DBSCAN {
    my ( $NODES, $eps, $minPts ) = @_;
    my $C        = 0;    # initialize cluster counter
    my $labels   = {};
    my $Clusters = {};
  NODE:
    foreach my $P ( 1 .. @$NODES ) {
        next NODE if $labels->{$P};                   # continue to next $P if node has been labeled
        my $N = rangeQuery( $NODES, 2, $P, $eps );    # get neighbors of $P
        if ( @$N < $o->minPts ) {                     # density check
            $labels->{$P} = q{noise};                 # mark $P as "noise"
            next NODE;                                # continue to next $P, not a "core" point
        }
        $C = $C + 1;                                  # increment cluster number
        printf STDERR qq{Cluster %d hash been initialized ... \n}, $C;
        $labels->{$P} = $C;                           # add $P to cluster $C
        my @S = @$N;                                  # use $P's neighbors ($N) as next candidate
      SEEDS:
        while (my $Q = pop @S) {                      # iterate over each neighbor of $P, in @N
            #printf qq{%d\n}, scalar @S;
            if ( $labels->{$Q} and $labels->{$Q} eq q{noise} ) {
                $labels->{$Q} = $C;
                push @{ $Clusters->{$C} }, $Q;        # capture nodes by $C
            }
            next SEEDS if defined $labels->{$Q};      # continue to next $Q if label is now defined (previously processed)
            $labels->{$Q} = $C;                       # set undefined label for $Q to be $C (current cluster)
            push @{ $Clusters->{$C} }, $Q;            # capture nodes by $C
            my $N = rangeQuery( $NODES, 2, $Q, $eps );# get neighbors of $P
            if ( scalar @$N >= $o->minPts ) {
               push @S, grep { ! $labels->{$_} } @$N; # if @N >= min number of nodes, push it onto @S for continued processing
            }
        }
    }
    return $Clusters;
}

sub rangeQuery {
    my ( $NODES, $rowSize, $A, $eps ) = @_;
    my $_k = omp_rangeQuery( $NODES, $rowSize, $A, $eps );
    return $_k;
}

process_f14($o);

__DATA__
__C__

/* Custom driver */

AV* omp_rangeQuery(SV *AoA, int dims, int A, float eps) {

  /* boilerplate */
  PerlOMP_UPDATE_WITH_ENV__NUM_THREADS
  PerlOMP_RET_ARRAY_REF_ret

  /* non-boilerplate */
  int num_nodes = av_count((AV*)SvRV(AoA));

  /* get 2d array ref into a 2d C array */
  float nodes[num_nodes][dims];
  PerlOMP_2D_AoA_TO_2D_FLOAT_ARRAY(AoA, num_nodes, dims, nodes);

  float A_x = nodes[A][0];
  float A_y = nodes[A][1];

  /* threaded section */
  int accumulator[num_nodes];
  float dist;

  #pragma omp parallel for shared(accumulator) private(dist)
  for(int i=0; i<num_nodes; i++) {
    float x = nodes[i][0];
    float y = nodes[i][1];
    dist = sqrt(pow(A_x-x,2)+pow(A_y-y,2));
    if (dist <= eps) {
      accumulator[i] = 1;
    }
  }

  for (int i = 0; i<num_nodes; i++) {
    int tid = omp_get_thread_num();
    if (accumulator[i] == 1) { 
      av_push(ret, newSViv(i+1));
    }
  }

  return ret;
}
