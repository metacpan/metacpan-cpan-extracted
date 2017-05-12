#!/usr/bin/perl

use 5.010;
use strict;
use warnings;
use Test::More tests => 12;

use Net::DAS;

##################################################
#### TESTING REQUEST METHOD
our $RES;

sub my_request {
    our $RES;
    return $RES . "\n";
}

my ( $c, $a, $das );
$das = new Net::DAS( { 'modules' => ['NU'], '_request' => \&my_request } );

##################################################

$RES = "HTTP/1.1 200 OK
Server: nginx/0.7.65
Date: Thu, 22 Jan 2015 12:47:23 GMT
Content-Type: text/html
Transfer-Encoding: chunked
Connection: close

10
free test.nu
0
";
$c = $das->lookup('test.nu')->{'test.nu'};
is( $c->{'domain'}, 'test.nu',                                           'domain ok' );
is( $c->{'label'},  'test',                                              'label ok' );
is( $c->{'tld'},    "nu",                                                'tld ok' );
is( $c->{'module'}, 'Net::DAS::NU',                                      'module ok' );
is( $c->{'query'},  "GET /free?q=test.nu HTTP/1.1\nhost: free.iis.nu\n", 'query ok' );
is( $c->{'response'},
    "HTTP/1.1 200 OK\nServer: nginx/0.7.65\nDate: Thu, 22 Jan 2015 12:47:23 GMT\nContent-Type: text/html\nTransfer-Encoding: chunked\nConnection: close\n\n10\nfree test.nu\n0\n",
    'response ok'
);
is( $c->{'avail'},  1,           "avail ok (available)" );
is( $c->{'reason'}, 'AVAILABLE', "reason ok (available)" );
$a = $das->available('test.nu');
is( $a, 1, 'available() ok' );

$RES = "HTTP/1.1 200 OK
Server: nginx/0.7.65
Date: Thu, 22 Jan 2015 12:47:23 GMT
Content-Type: text/html
Transfer-Encoding: chunked
Connection: close

10
occupied test.nu
0
";
$c = $das->lookup('test.nu')->{'test.nu'};
is( $c->{'avail'}, 0, "avail ok (not available)" );
is( $c->{'reason'}, 'NOT AVAILABLE', "reason ok (not available)" );
$a = $das->available('test.nu');
is( $a, 0, 'available() ok' );

exit 0;
