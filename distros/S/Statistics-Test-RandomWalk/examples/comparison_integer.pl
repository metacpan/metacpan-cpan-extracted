#!/usr/bin/perl
use strict;
use warnings;
use lib 'lib';
use Statistics::Test::RandomWalk;
use Data::Dumper;
use Math::Random::MT;
my $t = Statistics::Test::RandomWalk->new();

# If you have rng's that provide an integer in the range [0, $nmax),
# then this is how you can test them:

my $rnd;
open my $fh, '<', '/dev/urandom' or die $!;
read($fh, $rnd, 32);
$rnd = unpack('%L', $rnd);
my $gen = Math::Random::MT->new($rnd);

my $nmax = 13; # the maximum integer returned
$t->set_rescale_factor($nmax);
my $num = 20000;
foreach (
    [ 'rand', sub {map int($nmax*rand()), 1..10000}, int($num/10000)+1 ],
    [ 'MT',   sub {map int($nmax*$gen->rand()), 1..10000}, int($num/10000)+1 ],
) {
    my $name = shift @$_;
    $t->set_data(@$_);
    print "Testing $name...\n";
    # If $nmax is too large for your convenience, you can
    # instead test $nmax/$something.
    # (the result of which needs to be an integer...)
    my ($alpha, $got, $expected) = $t->test($nmax); 

    print $t->data_to_report($alpha, $got, $expected);
}

