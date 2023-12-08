#!/usr/bin/env perl

use strict;
use warnings;
use feature 'state';

use Sub::Genius ();

#
# Implements classic JAPH, perl hacker hackerman benchmark
# sequentially consistent, yet oblivious, way - that's right!
# This is a Sequential Consistency Oblivious Algorithm (in the
# same vein as 'cache oblivious' algorithms
#
# paradigm below is effective 'fork'/'join'
#
my $pre = q{
begin
(
  J &
    A &
      P &
        H
)
end
};

# Load PRE describing concurrent semantics
my $sq = Sub::Genius->new(preplan => $pre );

my $GLOBAL = {};

# 'compile' PRE

$sq->init_plan;

# run loop-ish
$sq->run_once(
    verbose => $ARGV[0],

    # 'scope' is passed as reference to all calls, effectively
    # acts as shared memory, federated only among subroutine
    # participating in the serialized excecution plan
    scope => {
        japh    => [ qw/just Another perl/, q{Hacker,} ],
        curr    => 0,
        contrib => [],
    }
);

# Dump $GLOBAL that's now been changed
if ( $ARGV[0] ) {
    print qq{\n... actual contributions of each sub ...\n};
    foreach my $k ( keys %$GLOBAL ) {
        printf( qq{  %s() => %s\n}, $k, $GLOBAL->{$k} );
    }
}

#                      #
## S T A T E  S U B S ##
#                      #

# noop
sub begin {
    my $scope = shift;
    state $persist = {};    # gives subroutine memory, also 'private'
    my $private = {};       # reset after each call
    return;
}

sub J {
    my $scope = shift;
    state $persist = { akctual => $scope->{japh}->[ $scope->{curr} ], };    # gives subroutine memory, also 'private'
                                                                            # sub's killroy
    $GLOBAL->{J} = $persist->{akctual};

    ++$scope->{curr};
    my $private = {};                                                       # reset after each call
    push @{ $scope->{contrib} }, $persist->{akctual};
    return;
}

sub A {
    my $scope = shift;
    state $persist = { akctual => $scope->{japh}->[ $scope->{curr} ], };    # gives subroutine memory, also 'private'
                                                                            # sub's killroy
    $GLOBAL->{A} = $persist->{akctual};

    ++$scope->{curr};
    my $private = {};                                                       # reset after each call
    push @{ $scope->{contrib} }, $persist->{akctual};
    return;
}

sub H {
    my $scope = shift;
    state $persist = { akctual => $scope->{japh}->[ $scope->{curr} ], };    # gives subroutine memory, also 'private'
                                                                            # sub's killroy
    $GLOBAL->{H} = $persist->{akctual};

    ++$scope->{curr};
    my $private = {};                                                       # reset after each call
    push @{ $scope->{contrib} }, $persist->{akctual};
    return;
}

sub P {
    my $scope = shift;
    state $persist = { akctual => $scope->{japh}->[ $scope->{curr} ], };    # gives subroutine memory, also 'private'
                                                                            # sub's killroy
    $GLOBAL->{P} = $persist->{akctual};

    ++$scope->{curr};
    my $private = {};                                                       # reset after each call
    push @{ $scope->{contrib} }, $persist->{akctual};
    return;
}

sub end {
    my $scope = shift;
    state $persist = {};                                      # gives subroutine memory, also 'private'
    my $private = {};                                                       # reset after each call
    printf( "%s\n", join( q{ }, @{ $scope->{contrib} } ) );
    return;
}

exit;
