use strict;
use warnings;
use Test::More tests => 5;
use PDL;
use PDL::NiceSlice;

use Physics::Ellipsometry::VASE;

my $vase = Physics::Ellipsometry::VASE->new(layers => 1);
$vase->load_data('t/data/sample.dat');

sub linear_model {
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

$vase->set_model(\&linear_model);

my $initial_params = pdl [65, 0.05, 80, 0.1];
my $fit_params = $vase->fit($initial_params);

ok(defined $fit_params, 'fit returns parameters');

my ($a, $b, $c, $d) = list $fit_params;

my $tol = 1e-4;
ok(abs($a - 65)   < $tol, "a = 65 (got $a)");
ok(abs($b - 0.05) < $tol, "b = 0.05 (got $b)");
ok(abs($c - 80)   < $tol, "c = 80 (got $c)");
ok(abs($d - 0.1)  < $tol, "d = 0.1 (got $d)");
