#!/usr/bin/env perl

use strict;
use warnings;
use feature 'state';

use FindBin qw/$Bin/;
use lib qq{$Bin/../lib};

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

my $GLOBAL = {};

# Load PRE describing concurrent semantics

my $final_scope = Sub::Genius->new(preplan => $pre )->run_any(
    verbose => $ARGV[0],
    scope => {
        japh    => [ qw/just Another perl/, q{Hacker,} ],
        curr    => 0,
        contrib => [],
    }
);

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
    return $scope;
}

sub A {
    my $scope = shift;
    state $persist = { akctual => $scope->{japh}->[ $scope->{curr} ], };    # gives subroutine memory, also 'private'
                                                                            # sub's killroy
    $GLOBAL->{A} = $persist->{akctual};

    ++$scope->{curr};
    my $private = {};                                                       # reset after each call
    push @{ $scope->{contrib} }, $persist->{akctual};
    return $scope;
}

sub H {
    my $scope = shift;
    state $persist = { akctual => $scope->{japh}->[ $scope->{curr} ], };    # gives subroutine memory, also 'private'
                                                                            # sub's killroy
    $GLOBAL->{H} = $persist->{akctual};

    ++$scope->{curr};
    my $private = {};                                                       # reset after each call
    push @{ $scope->{contrib} }, $persist->{akctual};
    return $scope;
}

sub P {
    my $scope = shift;
    state $persist = { akctual => $scope->{japh}->[ $scope->{curr} ], };    # gives subroutine memory, also 'private'
                                                                            # sub's killroy
    $GLOBAL->{P} = $persist->{akctual};

    ++$scope->{curr};
    my $private = {};                                                       # reset after each call
    push @{ $scope->{contrib} }, $persist->{akctual};
    return $scope;
}

sub end {
    my $scope = shift;
    state $persist = {};                                                    # gives subroutine memory, also 'private'
    my $private = {};                                                       # reset after each call
    printf( "%s\n", join( q{ }, @{ $scope->{contrib} } ) );
    return $scope;
}

exit;
