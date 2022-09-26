use strict;
use warnings;
use 5.010;
use English qw /-no_match_vars/;


use Config;

use rlib;
#use Test::Most tests => 19;
use Test::Most;
if ($Config{ivsize} == 4) {
    plan skip_all
      => 'PRNG sequence used in tests is only valid for 64 bit ints';
}
#else {
#    plan tests => 19;
#}

use Statistics::Sampler::Multinomial::AliasMethod;
use Math::Random::MT::Auto;
use List::Util qw /sum/;
use Scalar::Util qw /looks_like_number/;

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
        Statistics::Sampler::Multinomial::AliasMethod->new (data => undef);
    };
    $e = $EVAL_ERROR;
    ok $e, 'error when data arg not passed or is undef';

    $object = eval {
        Statistics::Sampler::Multinomial::AliasMethod->new (data => {});
    };
    $e = $EVAL_ERROR;
    ok $e, 'error when data arg not an array ref';

    $object = eval {
        Statistics::Sampler::Multinomial::AliasMethod->new (
            data => [1,2],
            prng => $prng,
        );
    };
    $e = $EVAL_ERROR;
    ok !$e, 'no error when prng arg passed';
    
    $result = eval {$object->draw};
    $e = $EVAL_ERROR;
    ok !$e, 'no error when draw called before _initialise_alias_tables';

    $object = eval {
        Statistics::Sampler::Multinomial::AliasMethod->new (
            data => {a => 2},
            prng => $prng,
        );
    };
    $e = $EVAL_ERROR;
    ok $e, 'error when passed a hash ref as the data arg';

    $object = eval {
        Statistics::Sampler::Multinomial::AliasMethod->new (
            data => 'some scalar',
            prng => $prng,
        );
    };
    $e = $EVAL_ERROR;
    ok $e, 'error when passed a scalar as the data arg';
    
    $object = eval {
        Statistics::Sampler::Multinomial::AliasMethod->new (
            data => [-1, 2, 4],
            prng => $prng,
        );
    };
    $e = $EVAL_ERROR;
    ok $e, 'error when passed a negative value in the data';
}

sub test_prob_generation {
    SKIP: {
        skip 'expected values for these tests are not valid on x86 or long double builds', 2
          if $Config{ivsize} == 4
            or $Config{archname} =~ /-ld$/;  #  clunky?

        my $prng = Math::Random::MT::Auto->new;
        my @probs = (2, 3, 5, 10);
        
        my $object = Statistics::Sampler::Multinomial::AliasMethod->new(
            prng => $prng,
            data => \@probs,
        );
    
        my %result = $object->_initialise_alias_tables;
        
        my $expected = {
            J => [3, 3, 0, 0],
            q => [0.4, 0.6, 1, 1],
        };
    
        is_deeply (\%result, $expected, 'got expected J and q for 2,3,5,10')
          or diag 'J:' . join (',', @{$result{J}}) . 'q: ' . join (',', @{$result{q}});
    
        @probs = (1..9);
        $object = Statistics::Sampler::Multinomial::AliasMethod->new (
            prng => $prng,
            data => \@probs,
        );
        %result = $object->_initialise_alias_tables;
    
        $expected = {
            J => [7,   8,   8,   8,   0, 0, 5,   6,   7  ],
            q => [0.2, 0.4, 0.6, 0.8, 1, 1, 0.8, 0.4, 0.6],
        };
    
        is_deeply (\%result, $expected, 'got expected J and q for 1..9');
    };
}

sub test_draw {
    my $prng = Math::Random::MT::Auto->new (seed => 2345);

    my $object = Statistics::Sampler::Multinomial::AliasMethod->new (
        data => [1..10],
        prng => $prng,
    );

    subtest 'draw 3 vals from 1..10' => sub {
        my $val;
        foreach my $expected (5, 7, 4) {
            $val = $object->draw;
            is ($val, $expected, "got $expected");
        }
    };

    #  restart the prng and get them in one pass
    $prng->set_seed (2345);

    my $draws = $object->draw_n_samples (3);
    #is_deeply $draws, [5, 7, 4], 'got expected draws';
    my $expected = [(0) x 10];
    @$expected[5, 7, 4] = (1) x 3;
    is_deeply $draws, $expected, 'got expected draws from draw_n_samples';
}

#  use a default PRNG - we only care that the values are defined in these cases
#  partly due to laziness
sub test_draw_default_prng {
    my $object = Statistics::Sampler::Multinomial::AliasMethod->new (
        prng => undef,
        data => [1..10],
    );

    subtest 'draw 3 vals from 1..10' => sub {
        my $val;
        foreach my $expected (5, 7, 4) {
            $val = $object->draw;
            ok (defined $val, "got defined value");
        }
    };

    my $draws = $object->draw_n_samples (3);
    my $have_undef = grep {!defined $_} @$draws; 
    ok !$have_undef, 'all values defined for default PRNG';

}

sub test_draw_with_zeroes {
    my $prng = Math::Random::MT::Auto->new (seed => 2345);
    my $object = Statistics::Sampler::Multinomial::AliasMethod->new (
        prng => $prng,
        data => [1..10,0,0],
    );

    subtest 'draw 3 vals from 1..10,0,0' => sub {
        my $val;
        foreach my $expected (6, 8, 5) {
            $val = $object->draw;
            is ($val, $expected, "got $expected");
        }
    };

    #  restart the prng
    $prng->set_seed (2345);
    my $draws = $object->draw_n_samples (3);
    my $expected = [(0) x 12];
    @$expected[6, 8, 5] = (1) x 3;
    is_deeply $draws, $expected, 'got expected draws with zeroes';
    
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
    my $expected = {
        J => [ qw / 0  0  1  2  3  4  5  6  7  8  9  0  0  0  0  0
                    0  0  0  0  0  1  1  2  3  3  4  4  5  6  7 10/],
        q => [ 1,           0.82744144,  0.84250739,  0.24112969,  0.57302752,  0.94121977,
               0.85139608,  0.92000916,  0.98862225,  0.56310538,  0.2963485,   0.78417474,
               0.78417474,  0.61607792,  0.61607792,  0.43875805,  0.43875805,  0.24987191,
               0.24987191,  0.24987191,  0.24987191,  0.06672447,  0.06672447,  0.06672447,
               0.06672447,  0.06672447,  0.06672447,  0.1888463,   0.1888463,   0.1888463,
               0.1888463,   0.1888463,],
    };
    
    my $prng   = Math::Random::MT::Auto->new (seed => 2345);
    #  need to update expected results if this is removed/commented
    my @waste_three_vals = map {$prng->rand} (0..2);
    my $object = Statistics::Sampler::Multinomial::AliasMethod->new (
        prng => $prng,
        data => $probs,
    );
    #  messy - should not know about internals
    my %result = $object->_initialise_alias_tables;

    subtest 'got expected initialisation from iNextPD data for J array' => sub {
        my $key = 'J';
        for my $i (0 .. $#$probs) {
            my $got = $result{$key}[$i];
            my $exp = $expected->{$key}[$i];
            is ($got, $exp, "result->{$key}[$i] matches");
        }
    };


    my $tolerance = 1E-7;  #  we get precision effects with these data
    subtest "got expected initialisation from iNextPD data for q array at tolerance $tolerance" => sub {
        my $key = 'q';
        for my $i (0 .. $#$probs) {
            my $got = $result{$key}[$i];
            my $exp = $expected->{$key}[$i];
            is_numeric_within_tolerance_or_exact_text (
                got       => $got,
                expected  => $exp,
                tolerance => $tolerance,
                message   => "result{$key}[$i] is within tolerance $tolerance ($got vs $exp)"
            );
        }
    };

    #  reset to ensure we call _initialise_alias_tables internally
    $prng   = Math::Random::MT::Auto->new (seed => 2345);
    #  need to update expected results if this is removed/commented
    @waste_three_vals = map {$prng->rand} (0..2);
    $object = Statistics::Sampler::Multinomial::AliasMethod->new (
        prng => $prng,
        data => $probs,
    );
    my $expected_draws = [
        8, 5, 3, 2, 1, 1, 0, 2, 3, 0, 0, 1, 0, 2, 0, 0,
        1, 0, 0, 1, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    ];
    my $draws = $object->draw_n_samples (scalar @$probs);
    is_deeply $draws, $expected_draws, 'got expected draws for iNextPD data';
    is (sum (@$draws), scalar @$probs, 'got expected number of draws for iNextPD data')
}

sub test_clone {
    
    my $prng1   = Math::Random::MT::Auto->new (seed => 2345);
    my $object1 = Statistics::Sampler::Multinomial::AliasMethod->new (
        prng => $prng1,
        data => [1, 2, 3, 4, 5],
    );
    my $clone = $object1->clone;
    
    is_deeply $object1, $clone, 'cloned object';

}

