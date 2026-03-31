#!/usr/bin/env perl
use strict;
use warnings;
use PDL;
use PDL::NiceSlice;
use Physics::Ellipsometry::VASE;

my $vase = Physics::Ellipsometry::VASE->new(layers => 1);
$vase->load_data('t/data/sample.dat');

sub model {
    my ($params, $x) = @_;

    my $a = $params->(0);
    my $b = $params->(1);
    my $c = $params->(2);
    my $d = $params->(3);

    my $wavelength = $x->(:,0);

    my $psi   = $a - $b * $wavelength;
    my $delta = $c + $d * $wavelength;

    return cat($psi, $delta)->flat;
}

$vase->set_model(\&model);

my $initial_params = pdl [65, 0.05, 80, 0.1];
my $fit_params = $vase->fit($initial_params);

my ($a, $b, $c, $d) = list $fit_params;
print "Fit results:\n";
print "  Psi   = $a - $b * wavelength\n";
print "  Delta = $c + $d * wavelength\n";
