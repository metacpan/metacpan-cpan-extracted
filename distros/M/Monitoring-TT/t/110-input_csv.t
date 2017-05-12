use strict;
use warnings;
use Data::Dumper;
use Test::More tests => 4;

use_ok('Monitoring::TT');
use_ok('Monitoring::TT::Input::CSV');

my $dir       = 't/data/110-input_csv';
my $csv       = Monitoring::TT::Input::CSV->new();
my $types     = $csv->get_types([$dir]);
my $types_exp = ['hosts'];

is_deeply($types, $types_exp, 'nagios input types') or diag(Dumper($types));

my $hosts = $csv->read($dir, 'hosts');
my $num   = scalar @{$hosts};
is($num, 2, 'read 2 hosts from csv');
