#!/usr/bin/perl
use strict;
use warnings;
use lib 'lib';
use Statistics::Test::Sequence;
use Data::Dumper;
use Math::Random::MT;
my $t = Statistics::Test::Sequence->new();

my $rnd;
open my $fh, '<', '/dev/random' or die $!;
read($fh, $rnd, 32);
$rnd = unpack('%L', $rnd);
my $gen = Math::Random::MT->new($rnd);

{
    my $x = 4711;
    my $a = 421;
    my $c = 64773;
    my $m = 259200;
    sub lin_kong {
        $x = ($a*$x + $c) % $m;
        return $x;
    }
}

my $num = 10000000;
foreach (
    [ 'rand', sub {map rand(), 1..10000}, $num/10000 ],
    [ 'MT',   sub {map $gen->rand(), 1..10000}, $num/10000 ],
    [ 'lin',  \&lin_kong, $num ],
) {
    my $name = shift @$_;
    $t->set_data(@$_);
    print "Testing $name...\n";
    my ($resid, $bins, $expected) = $t->test();
    print Dumper $resid;
    print Dumper $bins;
    print Dumper $expected;
}


