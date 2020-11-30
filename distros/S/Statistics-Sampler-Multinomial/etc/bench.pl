use 5.010;
use strict;
use warnings;


BEGIN {
    if ($^O eq 'MSWin32') {
        use Path::Tiny qw /path/;
        use Env qw /@PATH/;
        push @PATH, path($^X)->parent->parent->parent->child ('c/bin')->stringify;
    }
}


my $iters = 200;


use Benchmark qw {:all};

use List::Util qw /sum/;
use Statistics::Sampler::Multinomial;
use Statistics::Sampler::Multinomial::AliasMethod;
use Math::Random qw/random_multinomial/;
use Math::GSL::Randist qw /gsl_ran_multinomial/;
use Math::GSL::RNG qw /gsl_rng_uniform $gsl_rng_mt19937/;
use Math::Random::MT::Auto;
#use Math::Random::MTwist;

srand(2345);
my $boss_prng = Math::Random::MT::Auto->new (seed => 2345);
my $max = 100;
my $nsamples = 1000;
#my @data = reverse map {int (rand() * $_)} (1 .. $nsamples);
#my @data = map {$boss_prng->poisson ($_*10)} (1..$nsamples);
my @data = map {int ($_ ** 1.3)} (1..$nsamples);

#foreach my $K (10, 100, 1000) {
#foreach my $K (10, 50, 100) {
foreach my $K (10) {
    my @subset = @data[0..($K-1)];
    my $sum = sum @subset;
    my $scaled_data = [map {$_ / $sum} @subset];

    say "Data are:\n" . join ' ', @subset;

    my $gsl_rng = Math::GSL::RNG->new($gsl_rng_mt19937);

    my $SSM = Statistics::Sampler::Multinomial->new (
        prng => $boss_prng->clone,
        data => $scaled_data,
    );
    $SSM->draw;  # trigger initialisation
    my $SSMa = Statistics::Sampler::Multinomial::AliasMethod->new (
        prng => $boss_prng->clone,
        data => $scaled_data,
    );
    $SSMa->draw;  # trigger initialisation

    my $N = $K * 10;
    $N = $sum;

    say "Repeatedly drawing $N samples from $sum items across $K classes";
    
    #randist($gsl_rng, $N, $scaled_data);
    #SSMA_draw($SSMa, $N, $scaled_data);
    #math_random(undef, $N, $scaled_data);

    cmpthese (
        -3,
        {
            #  all get the same number of args
            randist => sub {randist($gsl_rng, $N, $scaled_data)},
            #SSMA    => sub {SSMA_draw($SSMa, $N, $scaled_data)},  
            SSM     => sub {SSM_draw($SSM, $N, $scaled_data)},
            math_random => sub {math_random(undef, $N, $scaled_data)},
        }
    );
     
}

sub SSMA_draw {
    my ($object, $n) = @_;
    for (1..$iters) {
        my $res = $object->draw_n_samples($n);
    }
    my $x;
}

sub SSM_draw {
    my ($object, $n) = @_;
    #state $done = 0;
    for (1 .. $iters) {
        my $res = $object->draw_n_samples($n);
        #if ($done <= 10) {
        #    say join ' ', @$res
        #}
        #$done++;
    }
    my $x;
}


sub randist {
    my ($object, $n, $data) = @_;
    
    for (1..$iters) {
        my $res = gsl_ran_multinomial ($object->raw, $data, $n);
    }
}

sub math_random {
    my ($object, $n, $data) = @_;
    for (1..$iters) {
        my @res = random_multinomial ($n, @$data);
    }
}

