#!perl -T

use strict;
use warnings;
use Test::More tests => 9;
use Data::Dumper;
use FindBin qw($Bin);

( my $test_dir ) = $Bin =~ m:^(.*?/t)$:;

( my $data_dir ) = "$test_dir/data"          =~ m:^(.*/data)$:;
( my $db_file )  = "$data_dir/nvdcve-2.0.db" =~ /^(.*db)$/;

BEGIN {
    use_ok('NIST::NVD::Store::SQLite3') || print "Bail out!";
}

my $sqlite3 = NIST::NVD::Store::SQLite3->new(
    store    => 'SQLite3',
    database => $db_file,
);

ok( $sqlite3, 'constructor returned goodness' );
isa_ok( $sqlite3, 'NIST::NVD::Store::SQLite3', '$sqlite' );
my $cpe_urn = 'cpe:/a:opera:opera_browser:7.0:beta1_v2';

my $cpe_pkey_id = $sqlite3->_get_cpe_id($cpe_urn);

ok( $cpe_pkey_id, 'return value is defined' );

like( $cpe_pkey_id, qr/\d+/, 'cpe primary key is numeric' );

my $cve = $sqlite3->get_cve_for_cpe( cpe => $cpe_urn );

ok( $cve, 'get_cve_for_cpe returned defined value' );
isa_ok( $cve, 'ARRAY', '$cve' );

is( scalar @$cve, 7, 'cve list has correct number of elements' );

is_deeply(
    $cve,
    [   'CVE-2011-4681', 'CVE-2011-4682', 'CVE-2011-4683', 'CVE-2011-4684',
        'CVE-2011-4685', 'CVE-2011-4686', 'CVE-2011-4687'
    ],
    'cve list contains the right elements'
) or diag Data::Dumper::Dumper($cve);

