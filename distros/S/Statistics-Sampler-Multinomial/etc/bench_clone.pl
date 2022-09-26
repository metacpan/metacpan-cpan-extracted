
use Benchmark qw {:all};
use 5.016;
use Data::Dumper;
use Test::More;
use Clone qw //;

use rlib '../lib';

use Math::Random::MT::Auto;
use Statistics::Sampler::Multinomial;
use Statistics::Sampler::Multinomial::Indexed;


my $nreps = $ARGV[0] || -5;
my $run_benchmarks = !!$nreps;


srand 1534390472;

my @data = (1..10000);
my $prng = Math::Random::MT::Auto->new;
my $base_object = Statistics::Sampler::Multinomial->new(
    data => \@data,
    prng => $prng,
);
my $indexed_object = Statistics::Sampler::Multinomial::Indexed->new(
    data => \@data,
    prng => $prng,
);
$indexed_object->build_index;


my $l1 = lu_clone();
my $l2 = xs_clone();
my $l3 = idx_clone();
my $l4 = xsi_clone();
$l1->{prng} = $prng;  # underhanded
$l2->{prng} = $prng;  # underhanded
$l3->{prng} = $prng;  # underhanded
$l4->{prng} = $prng;  # underhanded


is_deeply $l1, $base_object, 'method call';
is_deeply $l2, $base_object, 'Clone';
is_deeply $l3, $indexed_object, 'indexed';
is_deeply $l4, $indexed_object, 'indexed Clone';


done_testing();

exit if !$run_benchmarks;


cmpthese (
    $nreps,
    {
        xs_clone  => sub {xs_clone()},
        lu_clone  => sub {lu_clone()},
        idx_clone => sub {idx_clone()},
        xsi_clone => sub {xsi_clone()},
    }
);

sub lu_clone {
    my $c;
    for my $i (1..100) {
        $c = $base_object->clone;
    }
    return $c;
}

sub idx_clone {
    my $c;
    for my $i (1..100) {
        $c = $indexed_object->clone;
    }
    return $c;
}

sub xs_clone {
    my $c;
    for my $i (1..100) {
        my $p = delete local $base_object->{prng};
        $c = Clone::clone $base_object;
        $c->{prng} = $p->clone;
    }
    return $c;
}

sub xsi_clone {
    my $c;
    for my $i (1..100) {
        my $p = delete local $indexed_object->{prng};
        $c = Clone::clone $indexed_object;
        $c->{prng} = $p->clone;
    }
    return $c;
}
