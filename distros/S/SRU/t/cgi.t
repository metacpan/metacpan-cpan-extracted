use strict;
use warnings;
use Test::More qw( no_plan );
use CGI;

$ENV{ SCRIPT_NAME } = '/cgi-bin/sru.cgi';
$ENV{ SERVER_NAME } = 'www.inkdroid.org';
$ENV{ SCRIPT_FILENAME } = '/usr/local/inkdroid/apache/cgi-bin/sru.cgi';
$ENV{ QUERY_STRING } = 'operation=scan&version=1.1';
$ENV{ SERVER_PORT } = '80';
$ENV{ SERVER_PROTOCOL } = 'HTTP/1.1';
$ENV{ REQUEST_URI } = '/cgi-bin/sru.cgi?operation=scan&version=1.1';
$ENV{ HTTP_HOST } = 'www.inkdroid.org';
$ENV{ REQUEST_METHOD } = 'GET';
 
my $cgi = CGI->new();
isa_ok( $cgi, 'CGI', 'CGI mock object' );

use_ok( 'SRU::Request' );

ok( ! $SRU::Error, 'no error' );
my $request = SRU::Request->newFromCGI( $cgi );

ok( ! $SRU::Error, 'no error' );
isa_ok( $request, 'SRU::Request::Scan' );

is( $request->version(), '1.1', 'got version' );

1;
