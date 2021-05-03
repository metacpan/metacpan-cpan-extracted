use strict;
use warnings;
use feature 'state';

use Test::More;

use_ok q{Sub::Genius};

# NOTE: subs are implemented such that the end result is
# the same for any ordering of execution

my $pre = q{
begin           # this is a comment
(               # another comment

# blank line above ^, full length comment
  J &           # and yet another
    A &         # foo bar whiz bang
      P &       # and another
        H       # another
)
end             # this is the end
};

# Load PRE describing concurrent semantics
my $sq = Sub::Genius->new(preplan => $pre );

# 'compile' PRE
$sq->init_plan;

my $GLOBAL = {};
while ( $sq->next ) {

    # run loop-ish
    my $final_scope = $sq->run_once(
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

    is_deeply $final_scope->{japh}, $expected_final_scope->{japh}, q{final scope returned after execution properly};
    is_deeply $final_scope->{curr}, $expected_final_scope->{curr}, q{final scope returned after execution properly};
    $GLOBAL = {};
}

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

__END__
