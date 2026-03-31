use strict;
use warnings;
use Test::More tests => 5;

BEGIN { use_ok('Physics::Ellipsometry::VASE') }

# Constructor
my $vase = Physics::Ellipsometry::VASE->new(layers => 1);
isa_ok($vase, 'Physics::Ellipsometry::VASE');

# Load sample data
my $data = $vase->load_data('t/data/sample.dat');
ok(defined $data, 'load_data returns data');

use PDL;
is($data->getdim(1), 5, 'loaded 5 data points');

# Verify dimensions: 4 columns (wavelength, angle, psi, delta)
is($data->getdim(0), 4, 'data has 4 columns');
