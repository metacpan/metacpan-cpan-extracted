use strict;
use warnings;
use 5.010;
use English qw /-no_match_vars/;

use Test::Most;


use rlib;
use Statistics::Sampler::Multinomial;
use Math::Random::MT::Auto;
use List::Util qw /sum/;

use Devel::Symdump;
my $functions_object = Devel::Symdump->rnew(__PACKAGE__); 
my @subs = grep {$_ =~ 'main::test_'} $functions_object->functions();

my @alias_keys = qw /J q/;

exit main( @ARGV );

sub main {
    my @args  = @_;

    if (@args) {
        for my $name (@args) {
            die "No test method test_$name\n"
                if not my $func = (__PACKAGE__->can( 'test_' . $name ) || __PACKAGE__->can( $name ));
            $func->();
        }
        done_testing;
        return 0;
    }


    foreach my $sub (sort @subs) {
        no strict 'refs';
        $sub->();
    }

    done_testing;
    return 0;
}


sub is_numeric_within_tolerance_or_exact_text {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my %args = @_;
    my ($got, $expected) = @args{qw /got expected/};

    if (looks_like_number ($expected) && looks_like_number ($got)) {
        my $result = ($args{tolerance} // 1e-10) > abs ($expected - $got);
        if (!$result) {
            #  sometimes we get diffs above the default due to floating point issues
            #  even when the two numbers are identical but only have 9dp
            $result = $expected eq $got;
        }
        ok ($result, $args{message});
    }
    else {
        is ($got, $expected, $args{message});
    }
}


sub test_croakers {
    my $prng = Math::Random::MT::Auto->new;
    my ($result, $e, $object);

    $object = eval {
        Statistics::Sampler::Multinomial->new (data => undef);
    };
    $e = $EVAL_ERROR;
    ok $e, 'error when data arg not passed or is undef';

    $object = eval {
        Statistics::Sampler::Multinomial->new (data => {});
    };
    $e = $EVAL_ERROR;
    ok $e, 'error when data arg not an array ref';

    $object = eval {
        Statistics::Sampler::Multinomial->new (
            data => [1,2],
            prng => $prng,
        );
    };
    $e = $EVAL_ERROR;
    ok !$e, 'no error when prng arg passed';
    
    $result = eval {$object->draw};
    $e = $EVAL_ERROR;
    ok !$e, 'no error when draw called before _initialise';

    $object = eval {
        Statistics::Sampler::Multinomial->new (
            data => {a => 2},
            prng => $prng,
        );
    };
    $e = $EVAL_ERROR;
    ok $e, 'error when passed a hash ref as the data arg';

    $object = eval {
        Statistics::Sampler::Multinomial->new (
            data => 'some scalar',
            prng => $prng,
        );
    };
    $e = $EVAL_ERROR;
    ok $e, 'error when passed a scalar as the data arg';
    
    $object = eval {
        Statistics::Sampler::Multinomial->new (
            data => [-1, 2, 4],
            prng => $prng,
        );
    };
    $e = $EVAL_ERROR;
    ok $e, 'error when passed a negative value in the data';
}

sub test_draw_real_data {
    #  data from iNextPD
    my $probs = [
        0.202970297029703,  0.0891089099789782, 0.0792079135924584, 0.0792079135924584,
        0.0742574058050749, 0.0594055434175576, 0.0544543942902742, 0.0544543942902742,
        0.044547402121497,  0.0395861524290977, 0.0346094438864318, 0.0245054606625901,
        0.0245054606625901, 0.0192524351078994, 0.0192524351078994, 0.0137111891577485,
        0.0137111891577485, 0.00780849703229859, 0.00780849703229859, 0.00780849703229859,
        0.00780849703229859, 0.00208513958272084, 0.00208513958272084, 0.00208513958272084,
        0.00208513958272084, 0.00208513958272084, 0.00208513958272084, 0.00590144681683984,
        0.00590144681683984, 0.00590144681683984, 0.00590144681683984, 0.00590144681683984,
    ];
    
    my $prng   = Math::Random::MT::Auto->new (seed => 2345);
    #  need to update expected results if this is removed/commented
    my @waste_three_vals = map {$prng->rand} (0..2);
    my $object = Statistics::Sampler::Multinomial->new (
        prng => $prng,
        data => $probs,
    );

    my $expected_draws = [
        6, 3, 3, 3, 3, 3, 1, 2, 2, 0, 1, 1, 0, 0, 0, 2,
        0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0,
    ];
    my $draws = $object->draw_n_samples (scalar @$probs);

    SKIP: {
        use Config;
        skip 'prng sequence differs under 32 bit ints', 2
          if $Config{ivsize} == 4;
        is_deeply $draws, $expected_draws, 'got expected draws for iNextPD data';
        is (sum (@$draws), scalar @$probs, 'got expected number of draws for iNextPD ')
    }
}

sub test_draw {
    my $probs = [
        1, 5, 2, 6
    ];
    
    my $prng   = Math::Random::MT::Auto->new (seed => 2345);
    my $object = Statistics::Sampler::Multinomial->new (
        prng => $prng,
        data => $probs,
    );

    my $expected_draws = [1, 3, 2, 2, 0];
    my @draws = map {$object->draw()} (1..5);

    SKIP: {
        use Config;
        skip 'prng sequence differs under 32 bit ints', 2
          if $Config{ivsize} == 4;
        is_deeply \@draws, $expected_draws, 'got expected draws using draw method';
    }
}
