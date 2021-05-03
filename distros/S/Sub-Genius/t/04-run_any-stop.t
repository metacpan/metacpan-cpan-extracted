use strict;
use warnings;
use feature 'state';

use Test::More;

use_ok q{Sub::Genius};

# NOTE: subs are implemented such that the end result is
# the same for any ordering of execution

my $pre = q{
[begin]
(
  J &
    A &
      P &
        H
)
[end]
};

my $GLOBAL = {};

# Load PRE describing concurrent semantics
my $final_scope = Sub::Genius->new(preplan => $pre, preprocess => 0 )->run_any(
    scope => {
        japh    => [ qw/just Another perl/, q{Hacker,} ],
        curr    => 0,
        contrib => [],
    }
);

my $expected_final_scope = {
    'japh'    => [ 'just', 'Another', 'perl', 'Hacker,' ],
    'curr'    => 4,
    'contrib' => [ 'just', 'Another', 'perl', 'Hacker,' ]
};

is_deeply $final_scope, $expected_final_scope, q{final scope returned after execution properly};

#                                     #
## S T A T E  S U B S  P O N S O R S ##
#                                     #

# noop
sub begin {
    my $scope = shift;
    state $persist = {};    # gives subroutine memory, also 'private'
    my $private = {};       # reset after each call
    return $scope;
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
    return $scope;
}

done_testing();

exit;
