#!/usr/bin/env perl

use Test::Most;
use Math::Round qw(nearest);
use Config;

my $ITERATIONS         = 10;     # How many random numbers to generate and test
my $STD_DEV_ITERATIONS = 1000;
my $STD_DEV_TOLERANCE  = 0.25;

{

    package Random::Tester;
    use Moose;
    with 'Role::Random::PerInstance';
}

subtest 'deterministic rand' => sub {
    my $tester = Random::Tester->new( random_seed => 666 );
    my @random = map { $tester->deterministic_rand } 1 .. 10;
    my @expected =
      $Config{use64bitint}
      ? (
        0.1758241, 0.9477076, 0.1737542, 0.9684752, 0.8679786, 0.7183419,
        0.5307398, 0.3145728, 0.6171654, 0.2489800,
      )
      : (
        0.1758241, 0.947707,  0.309703,  0.9450766, 0.5234088, 0.7476995,
        0.4378216, 0.0626313, 0.8473208, 0.164287
      );

    eq_or_diff \@random, \@expected,
      'Our deterministic_rand() function should be predictably random';

    my $tester2 = Random::Tester->new( random_seed => 666 );
    @random = map { $tester2->deterministic_rand } 1 .. 10;
    eq_or_diff \@random, \@expected,
'... and calling it more than once with the same random seed should generate the same random numbers';

    my $tester3 = Random::Tester->new( random_seed => 667 );
    @random = map { $tester3->deterministic_rand } 1 .. 10;
    @expected =
      $Config{use64bitint}
      ? (
        0.5273486, 0.7003167, 0.1432552, 0.3984599, 0.6295701, 0.0363987,
        0.0005728, 0.2589195, 0.700002,  0.0867783,
      )
      : (
        0.1758241, 0.947707,  0.309703,  0.9450766, 0.5234088, 0.7476995,
        0.4378216, 0.0626313, 0.8473208, 0.164287,
      );
    eq_or_diff \@random, \@expected,
      '... and using a different seed should generate different random numbers';
};

subtest 'attempt' => sub {
    my $tester = Random::Tester->new();

    ok $tester->attempt(1), 'Chance of 1 allways succeeds';
    ok !$tester->attempt(0), 'Chance of 1 allways fails';

    # Test 1000 times and make sure that our distributions is consistent
    my %seen;
    $seen{ $tester->attempt(0.75) }++ for ( 1 .. 1000 );

    is $seen{0} + $seen{1}, 1000, "we have the correct number of results";
    ok $seen{0} > 200 && $seen{0} < 300,
      "we should fail between 200 and 300 times";
    ok $seen{1} > 700 && $seen{1} < 800,
      "we should succeed between 700 and 800 times";

    subtest 'Using deterministic random numbers' => sub {
        my $tester2 = Random::Tester->new( random_seed => 777 );
        my %seen2;
        $seen2{ $tester2->attempt(0.75) }++ for ( 1 .. 1000 );
        is $seen2{0} + $seen2{1}, 1000,
          "we have the correct number of results for 'deterministic' random";
        ok $seen2{0} > 200 && $seen2{0} < 300,
          "we should fail between 200 and 300 times";
        ok $seen2{1} > 700 && $seen2{1} < 800,
          "we should succeed between 700 and 800 times";

        my $tester3 = Random::Tester->new( random_seed => 777 );
        my %seen3;
        $seen3{ $tester3->attempt(0.75) }++ for ( 1 .. 1000 );
        eq_or_diff \%seen2, \%seen3,
'attempt() should return deterministic random values if instantiated with a random seed';
    };
};

subtest 'random with step' => sub {
    my $tester = Random::Tester->new();

    my @data = (
        [ 50, 60, 2, [ 50, 52, 54, 56, 58, 60 ] ],
        [ 0.1, 0.5, 0.1, [ 0.1, 0.2, 0.3, 0.4, 0.5 ] ],
        [ 0.1, 0.5, 0.15, [ 0.1, 0.25, 0.4 ] ],
    );
    foreach my $args (@data) {
        my ( $min, $max, $step, $set ) = @$args;
        my $passed = 0;
      ATTEMPT:
        for ( 1 .. 3 ) {    # try three times to make this work (need to rethink
            my %seen;
            for ( 1 .. $STD_DEV_ITERATIONS ) {
                my $result = $tester->random( $min, $max, $step );
                $seen{$result}++;
            }

            # Give a 20% tolerance for chance distribution
            my $min_expected =
              ( $STD_DEV_ITERATIONS / scalar(@$set) ) *
              ( 1 - $STD_DEV_TOLERANCE );
            my $max_expected =
              ( $STD_DEV_ITERATIONS / scalar(@$set) ) *
              ( 1 + $STD_DEV_TOLERANCE );

            # Ensure we have an even distribution of values
            is( scalar( keys(%seen) ),
                scalar(@$set), "We have the correct number of results" );
            foreach my $value (@$set) {
                my $within_tolerance = $seen{$value} > $min_expected
                  && $seen{$value} < $max_expected;
                unless ($within_tolerance) {
                    diag
"$min_expected < $seen{value} < $max_expected did not hold. Retrying/";
                    next ATTEMPT;
                }
                ok( $seen{$value}, "We have results for $value" );
                ok( $within_tolerance,
                        "... and "
                      . $seen{$value}
                      . " is within the 20% tolerance" );
            }
            $passed = 1;
        }
        unless ($passed) {
            explain "This can still fail, but it's much less likely.";
            fail "We were not within our tolerance level within three tries";
        }
    }
};

subtest 'random without step' => sub {
    my $tester = Random::Tester->new();

    my @data = ( [], [ 0, 10 ], [ 50, 60 ], );
    foreach my $args (@data) {
        my ( $min, $max ) = @$args;
        my %seen;
        for ( 1 .. $ITERATIONS ) {
            my $result = $tester->random( $min, $max );

            # Grab defaults for testing
            $min //= 0;
            $max //= 1;
            cmp_ok $result , '>=', $min,
              "random returned $result which is greater than or equal to $min";
            cmp_ok $result , '<=', $max, "... and is less than $max";
        }
    }

};

subtest 'random int' => sub {
    my $tester = Random::Tester->new();

    my @data = ( [ 0, 5 ], [ 50, 55 ], [ 1, 2 ], );

    foreach my $args (@data) {
        my ( $min, $max ) = @$args;
        my %seen;
        for ( 1 .. $STD_DEV_ITERATIONS ) {
            my $result = $tester->random_int( $min, $max );
            $seen{$result}++;

            # Grab defaults for testing
            $min //= 0;
            $max //= 1;
        }

        # Give a 20% tolerance for chance distribution
        my $total_set = $max - $min + 1;
        my $min_expected =
          ( $STD_DEV_ITERATIONS / $total_set ) * ( 1 - $STD_DEV_TOLERANCE );
        my $max_expected =
          ( $STD_DEV_ITERATIONS / $total_set ) * ( 1 + $STD_DEV_TOLERANCE );

        # Ensure we have an even distribution of values
        is( scalar( keys(%seen) ),
            $total_set, "We have the correct number of results" );
        foreach my $value ( $min .. $max ) {
            ok( $seen{$value}, "We have results for $value" );
            ok(
                (
                         $seen{$value} > $min_expected
                      && $seen{$value} < $max_expected
                ),
                "... and " . $seen{$value} . " is within the 20% tolerance"
            );
        }
    }

};

subtest 'weighted pick' => sub {
    my %choices = (
        uncommon => 1,
        common   => 5,
        never    => 0,
    );

    my $tester = Random::Tester->new( random_seed => 12345 );

    my %times_chosen;
    $times_chosen{ $tester->weighted_pick( \%choices ) }++ for 1 .. 1000;
    my %expected =
      $Config{use64bitint}
      ? ( common => 817, uncommon => 183 )
      : ( common => 842, uncommon => 158 );
    eq_or_diff \%times_chosen, \%expected,
      'Our weighted_pick() chooses sensible values';
    %times_chosen = ();
    my $index = 0;
    %choices =
      map { $_ => ++$index } qw/ red orange yellow green indigo blue violet /;
    $times_chosen{ $tester->weighted_pick( \%choices ) }++ for 1 .. 1000;
    %expected =
      $Config{use64bitint}
      ? (
        blue   => 209,
        green  => 137,
        indigo => 185,
        orange => 62,
        red    => 39,
        violet => 255,
        yellow => 113
      )
      : (
        blue   => 216,
        green  => 140,
        indigo => 181,
        orange => 69,
        red    => 33,
        violet => 245,
        yellow => 116
      );
    eq_or_diff \%times_chosen, \%expected,
      '... and can do so deterministically';
};

done_testing;
