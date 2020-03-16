#!perl

use strict;
use warnings;
use Test::More;

require_ok('Net::OpenVAS::OMP::Request');
require_ok('Net::OpenVAS::OMP::Response');

my $request = Net::OpenVAS::OMP::Request->new(
    command   => 'get_version',
    arguments => {}
);

cmp_ok( $request->command, 'eq', 'get_version', 'Request command' );

my $omp_response = '<get_version_response status="200" status_text="OK"><version>1.0</version></get_version_response>';

my $response = Net::OpenVAS::OMP::Response->new(
    request  => $request,
    response => $omp_response
);

cmp_ok( $response->status,      '==', 200,           'Response status' );
cmp_ok( $response->status_text, 'eq', 'OK',          'Response text' );
cmp_ok( $response->command,     'eq', 'get_version', 'Request command' );
cmp_ok( $response->raw,         'eq', $omp_response, 'RAW Response' );

ok( $response->is_ok,  'Response is OK ?' );
ok( !$response->error, 'Response is Error ?' );

done_testing();
