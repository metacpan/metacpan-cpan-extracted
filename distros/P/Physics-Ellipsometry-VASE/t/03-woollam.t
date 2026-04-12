use strict;
use warnings;
use Test::More tests => 10;
use PDL;

use Physics::Ellipsometry::VASE;

# Test Woollam VASE format loading
my $vase = Physics::Ellipsometry::VASE->new(layers => 1);
my $data = $vase->load_data('t/data/woollam_sample.dat');

ok(defined $data, 'load_data returns data for Woollam file');

# Should still produce 4-column output (wavelength, angle, psi, delta)
is($data->getdim(0), 4, 'Woollam data has 4 columns after parsing');
is($data->getdim(1), 5, 'loaded 5 data points from Woollam file');

# Verify header metadata is stored
is($vase->{sample_name}, 'test_sample', 'sample name parsed');
is($vase->{units}, 'nm', 'units parsed');
like($vase->{vase_method}, qr/EllipsometerType=4/, 'VASE method metadata parsed');
is($vase->{original_file}, 'woollam_sample.dat', 'original filename parsed');

# Verify sigma (uncertainties) extracted
ok(defined $vase->{sigma}, 'sigma data extracted');
is($vase->{sigma}->getdim(0), 2, 'sigma has 2 columns (psi, delta)');
is($vase->{sigma}->getdim(1), 5, 'sigma has same number of points as data');
