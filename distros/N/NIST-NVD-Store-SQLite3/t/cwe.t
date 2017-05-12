#!perl -T

use strict;
use warnings;
use Data::Dumper;
use Test::More tests => 22;
use FindBin qw($Bin);

( my $test_dir ) = $Bin =~ m:^(.*?/t)$:;

( my $data_dir ) = "$test_dir/data"          =~ m:^(.*/data)$:;
( my $db_file )  = "$data_dir/nvdcve-2.0.db" =~ /^(.*db)$/;

BEGIN {
    use_ok('NIST::NVD::Query') || print "Bail out!";
}

# Verify that each function returns expected result

my $q;

$q = eval {
    NIST::NVD::Query->new( store => 'SQLite3', database => $db_file, );
};

ok( !$@, "no error" ) or diag $@;

is( ref $q, 'NIST::NVD::Query',
    'constructor returned an object of correct class' );

my ( $cve_id_list, $cwe_id_list );

#my $cpe_urn = 'cpe:/a:microsoft:ie:7.0.5730.11';
my $cpe_urn = 'cpe:/a:apple:safari:4.0';

my $cpe_pkid = $q->{store}->_get_cpe_id($cpe_urn);

my $int_re = qr{^\d+$};

ok( defined $cpe_pkid, 'cpe pk id is defined' );

like( $cpe_pkid, $int_re, "cpe pk id is an integer for cpe urn [$cpe_urn]" );

my $cve_id = $q->{store}->get_cve_for_cpe( cpe => $cpe_pkid );

my $query_ref = $q->{store}->_get_query();

my %result_count = (
    cve_for_cpe => 2,
    cwe_for_cpe => 42,
);

my %pkid_field_name = (
    cve_for_cpe => 'cve_id',
    cwe_for_cpe => 'cwe_id',
);

my $query_name = 'get_cpe_id_select';
ok( exists $query_ref->{$query_name}, "query [$query_name] exists" );
my $query = $query_ref->{$query_name};

my $sth = $q->{store}->_get_sth($query_name);

$sth->execute($cpe_urn);

my $count = 0;
my $direct_cpe_pkid;
my @row;
while ( my $row = $sth->fetchrow_hashref() ) {
    $count++;
    $direct_cpe_pkid = $row->{id};
}

is( $count, 1, 'one and only one result for the query' )
    or diag Data::Dumper::Dumper {
    query => $query_ref->{$query_name},
    id    => $cpe_urn,
    };

is( $direct_cpe_pkid, $cpe_pkid,
    'direct query and query via API result in same primary key for this cpe urn'
    )
    or diag Data::Dumper::Dumper {
    direct => $direct_cpe_pkid,
    api    => $cpe_pkid
    };

my $results = {};

foreach my $method (qw{cve_for_cpe cwe_for_cpe}) {

    $query_name = "${method}_select";

    ok( exists $query_ref->{$query_name}, "query [$query_name] exists" );

    $query = $query_ref->{$query_name};

    ok( $query, "query [$query_name] is defined" ) or diag $query_name;

    $sth = $q->{store}->_get_sth($query_name);

    $sth->execute($cpe_pkid);

    my $direct_object_list = [];
    @row = ();
    while ( my $row = $sth->fetchrow_hashref() ) {
        push( @row,                 $row );
        push( @$direct_object_list, $row->{ $pkid_field_name{$method} } );
    }

    ok( int(@row) != 0, 'direct query returned > 0 results' )
        or diag Data::Dumper::Dumper {
        query => $query_ref->{$query_name},
        id    => $cpe_pkid
        };

    my $object_list = $q->$method( cpe => $cpe_urn );

    is( ref $object_list, 'ARRAY', "[$method] returned ARRAY ref" )
        or diag $query;

    ok( int(@$object_list) > 0, "more than 0 results for method [$method]" )
        or diag "\$->$method( cpe => $cpe_urn )";

    is_deeply( $object_list, $direct_object_list,
        'indirect and direct results are the same' );

    $results->{$method}->{direct}   = $direct_object_list;
    $results->{$method}->{indirect} = $object_list;
}

my $data = $q->cwe( cwe_id => $results->{cwe_for_cpe}->{direct}->[0] );

is( ref $data, 'HASH', 'CWE data is a HASH ref' );

is_deeply(
    $data,
    {   'ID'        => 'CWE-264',
        'Status'    => 'Incomplete',
        'Languages' => [
            { 'Language_Class' => { 'Language_Class_Description' => 'All' } }
        ],
        'Name'        => 'Permissions, Privileges, and Access Controls',
        'Description' => [
'Weaknesses in this category are related to the management of
					permissions, privileges, and other security features that are used to perform
					access control.'
        ]
    },
    'cwe data is right',
) or diag Data::Dumper::Dumper( $data );

