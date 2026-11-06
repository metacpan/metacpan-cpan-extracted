use strict;
use warnings;

use Test::More;

use File::Temp qw(tempfile);
use FindBin;
use PDL;
use PDL::NiceSlice;
use Physics::Ellipsometry::VASE;

my $vase = Physics::Ellipsometry::VASE->new(layers => 1);
$vase->load_data("$FindBin::Bin/data/sample.dat");

my $model = sub {
    my ($params, $x) = @_;

    my $a = $params->(0);
    my $b = $params->(1);
    my $c = $params->(2);
    my $d = $params->(3);

    my $wavelength = $x->(:,0);

    my $psi   = $a - $b * $wavelength;
    my $delta = $c + $d * $wavelength;

    return cat($psi, $delta)->flat;
};

ok $vase->set_model($model), 'set_model works';

my $initial_params = pdl [65, 0.05, 80, 0.1];
my $fit_params = $vase->fit($initial_params);

my @expected_fit_params = (65.0, 0.05, 80.0, 0.10);
my $fit_tolerance = 1e-6;
for my $i (0 .. $#expected_fit_params) {
    ok abs($fit_params->at($i) - $expected_fit_params[$i]) < $fit_tolerance,
        "fit parameter $i within tolerance";
}

subtest 'find MSE' => sub {
    my $mse = $vase->mse($fit_params, nparams => 4);
    ok $mse < 0.000001, 'Mean Squared Error very small';
    is $mse, 0, 'Mean Squared Error is zero';
    ok $vase->{iters} > 0, 'Iterations positive';
};

my ($fh1, $test_plot_png) = tempfile(SUFFIX => '.png', UNLINK => 1);
my ($fh2, $test_plot_pdf) = tempfile(SUFFIX => '.pdf', UNLINK => 1);

subtest 'Save plot to PNG' => sub {
    ok $vase->plot($fit_params, output => $test_plot_png),
        'can plot a png image';
    ok -e $test_plot_png, "test image $test_plot_png exists";
    ok -s $test_plot_png, "test image $test_plot_png not empty";
};
close $fh1;

subtest 'Save plot to PDF' => sub {
    ok $vase->plot($fit_params,
            output => $test_plot_pdf,
            title => 'Linear Model Fit'),
        'can plot a pdf file';
    ok -e $test_plot_pdf, "test image $test_plot_pdf exists";
    ok -s $test_plot_pdf, "test image $test_plot_pdf not empty";
};
close $fh2;

done_testing();
