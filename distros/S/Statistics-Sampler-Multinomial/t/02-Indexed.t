use strict;
use warnings;
use 5.010;
use English qw /-no_match_vars/;

use Test::Most;


use rlib;
use Statistics::Sampler::Multinomial::Indexed;
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



sub test_draw {
    my $probs = [
        1, 5, 2, 6, 3, 8, 1, 4, 9
    ];
    
    my $prng1  = Math::Random::MT::Auto->new (seed => 2345);
    my $object = Statistics::Sampler::Multinomial::Indexed->new (
        prng => $prng1,
        data => $probs,
    );
    my $prng2  = Math::Random::MT::Auto->new (seed => 2345);
    my $object_non_indexed = Statistics::Sampler::Multinomial->new (
        prng => $prng2,
        data => $probs,
    );

    my $sum = sum @$probs;
    #my $max_depth_idx = 1 + logb scalar @$probs;
    my $max_depth_idx = 1;
    my $n = scalar @$probs;
    $max_depth_idx++ while $n >>= 1;
    my $index = $object->{index};
    is_deeply ($index->[0], [$sum], 'top level of index');
    is_deeply ($index->[-1], $probs, 'bottom level of index');
    is ($#$index, $max_depth_idx, 'index depth');

    #  we should have the same result as the non-indexed draw method
    my $expected_draws = [map {$object_non_indexed->draw()} (1..5)];
    my @draws = map {$object->draw()} (1..5);
    
    is_deeply \@draws, $expected_draws, 'got expected draws using draw method';    
}


sub test_update_large_index {
    my @probs1 = (
        1, 5, 2, 6, 3, 5, 10
    );
    my @probs2 = (
        1, 5, 2, 6, 3, 5, 10, undef, undef, undef, undef, 3
    );
    #update 11 => 3
    
    my $prng1  = Math::Random::MT::Auto->new (seed => 2345);
    my $obj_indexed1 = Statistics::Sampler::Multinomial::Indexed->new (
        prng => $prng1,
        data => \@probs1,
    );
    my $prng2  = Math::Random::MT::Auto->new (seed => 2345);
    my $obj_indexed2 = Statistics::Sampler::Multinomial::Indexed->new (
        prng => $prng2,
        data => \@probs2,
    );
    
    $obj_indexed1->update_values (11 => 3);
    is_deeply
        $obj_indexed1->{index},
        $obj_indexed2->{index},
        'same index structures';
    
}

sub test_update_values {
    my $probs = [
        1, 5, 2, 6, 3, 5, 10
    ];
    
    my $prng1  = Math::Random::MT::Auto->new (seed => 2345);
    my $obj_indexed = Statistics::Sampler::Multinomial::Indexed->new (
        prng => $prng1,
        data => $probs,
    );
    my $prng2  = Math::Random::MT::Auto->new (seed => 2345);
    my $obj_no_index = Statistics::Sampler::Multinomial->new (
        prng => $prng2,
        data => $probs,
    );

    my $update_count
      = $obj_indexed->update_values (
        1 => 10,
        5 => 0,
    );

    is $update_count, 2, 'got correct update count';

    my $expected = [@$probs];
    @{$expected}[1,5] = (10, 0);

    my $exp_sum = 0;
    $exp_sum += $_ foreach @$probs;
    $exp_sum -= ($probs->[1] + $probs->[5]);
    $exp_sum += 10;

    my $data = $obj_indexed->get_data;

    is_deeply
      $data,
      $expected,
      'got expected data after modifying values';

    is $obj_indexed->get_sum, $exp_sum, 'got expected sum';
    is $obj_indexed->{index}[0][0], $exp_sum, 'updated index sum correct';
    
    $obj_no_index->update_values (
        1 => 10,
        5 => 0,
    );
    $expected = [map {$obj_no_index->draw} (1..10)];
    my $got   = [map {$obj_indexed->draw}  (1..10)];
    is_deeply $got, $expected, 'draws match after updates - indexed and not';
    
    my $idata = $obj_indexed->{data};
    my $prng3 = Math::Random::MT::Auto->new (seed => 2345);
    my $object3 = Statistics::Sampler::Multinomial::Indexed->new (
        prng => $prng3,
        data => [@$idata],
    );
    is_deeply $obj_indexed->{index}, $object3->{index}, 'updated index same as new index with same data';

    #  get $object3 to the same point in the PRNG sequence
    for (1..10) {$object3->draw};
    $expected = [map {$obj_indexed->draw} (1..10)];
    $got      = [map {$object3->draw}     (1..10)];
    is_deeply $got, $expected, 'same results for updated and "clean" index';
}

#  should be same as non-indexed
sub test_draw_n_samples_with_mask {
    my $probs = [
        1, 5, 2, 6, 3, 5, 10
    ];
    
    my $prng   = Math::Random::MT::Auto->new (seed => 2345);
    my $object = Statistics::Sampler::Multinomial::Indexed->new (
        prng => $prng,
        data => $probs,
    );

    my $mask = [1,2];  #  mask second and third items
    my $expected_draws = [20, 0, 0, 122, 64, 111, 183];
    my $draws = $object->draw_n_samples_with_mask(500, $mask);

    SKIP: {
        use Config;
        skip 'prng sequence differs under 32 bit ints', 2
          if $Config{ivsize} == 4;
        is_deeply
          $draws,
          $expected_draws,
          'got expected draws using draw_n_samples_with_mask method';
    }
    
}

sub test_clone {
    my $probs = [
        1, 5, 2, 6, 3, 5, 10
    ];
    
    my $prng   = Math::Random::MT::Auto->new (seed => 2345);
    my $object = Statistics::Sampler::Multinomial::Indexed->new (
        prng => $prng,
        data => $probs,
    );
    
    my $clone = $object->clone;
    
    is_deeply $clone, $object, 'clone matches original';
}


1;
