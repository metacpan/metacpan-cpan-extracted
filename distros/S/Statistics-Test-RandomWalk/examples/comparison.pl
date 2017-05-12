#!/usr/bin/perl
use strict;
use warnings;
use lib 'lib';
use Statistics::Test::RandomWalk;
use Data::Dumper;
use Math::Random::MT;
my $t = Statistics::Test::RandomWalk->new();

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
        return $x/$m;
    }
}

my $num = 100000;
foreach (
    [ 'rand', sub {map rand(), 1..10000}, $num/10000 ],
    [ 'MT',   sub {map $gen->rand(), 1..10000}, $num/10000 ],
    [ 'lin',  \&lin_kong, $num ],
) {
    my $name = shift @$_;
    $t->set_data(@$_);
    print "Testing $name...\n";
    my ($alpha, $got, $expected) = $t->test(100);

    print $t->data_to_report($alpha, $got, $expected);

}

