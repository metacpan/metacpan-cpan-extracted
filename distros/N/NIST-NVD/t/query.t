#!perl -T

use strict;
use warnings;
use Test::More;
use Data::Dumper;
use FindBin qw($Bin);

( my $test_dir ) = $Bin =~ m:^(.*?/t)$:;

( my $data_dir )     = "$test_dir/data"                  =~ m:^(.*/data)$:;
( my $db_file )      = "$data_dir/nvdcve-1.1.db"         =~ /^(.*db)$/;
( my $cpe_idx_file ) = "$data_dir/nvdcve-1.1.idx_cpe.db" =~ /^(.*db)$/;
( my $cwe_idx_file ) = "$data_dir/nvdcve-1.1.idx_cwe.db" =~ /^(.*db)$/;
( my $cwe_file )     = "$data_dir/cwec_v1.1.db" =~ /^(.*db)$/;


BEGIN {
    use_ok('NIST::NVD::Query') || print "Bail out!";
}

# Verify that each function returns expected result

my $q;

$q = eval {
    NIST::NVD::Query->new(
        database => $db_file,
        idx_cpe  => $cpe_idx_file,
    );
};

ok( !$@, "no error" ) or diag $@;

is( ref $q, 'NIST::NVD::Query',
    'constructor returned an object of correct class' );

my $cve_id_list;

#$cve_id_list = $q->cve_for_cpe( cpe => 'cpe:/a:microsoft:ie:7.0.5730.11' );
$cve_id_list =
  $q->cve_for_cpe( cpe => 'cpe:2.3:a:bigantsoft:bigant_server:5.6.06:*:*:*:*:*:*:*' );

is( ref $cve_id_list, 'ARRAY', 'cve_for_cpe returned ARRAY ref' );

is( scalar(@$cve_id_list), 7, 'correct number of CVEs returned for this CPE' );

foreach my $cve_entry (@$cve_id_list) {
    like( $cve_entry, qr{^CVE-\d{4,}-\d+$}, 'format of CVE ID is correct' );
}

is_deeply(
    $cve_id_list,
    [
     'CVE-2022-23352',
     'CVE-2022-23350',
     'CVE-2022-23349',
     'CVE-2022-23348',
     'CVE-2022-23347',
     'CVE-2022-23346',
     'CVE-2022-23345'
     ],
    'Correct list of CVE IDs'
);

my $entry = $q->cve( cve_id => $cve_id_list->[0] );

is( ref $entry, 'HASH', 'CVE entry is a HASH ref' );

my $cvss = $entry->{impact}->{baseMetricV3}->{cvssV3};

is_deeply(
    $cvss,
	  {
	   'userInteraction' => 'NONE',
	   'confidentialityImpact' => 'NONE',
	   'attackVector' => 'NETWORK',
	   'version' => '3.1',
	   'baseScore' => '7.5',
	   'availabilityImpact' => 'HIGH',
	   'attackComplexity' => 'LOW',
	   'integrityImpact' => 'NONE',
	   'scope' => 'UNCHANGED',
	   'baseSeverity' => 'HIGH',
	   'vectorString' => 'CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H',
	   'privilegesRequired' => 'NONE'
    },
    'extracting cvss worked'
);

done_testing();

