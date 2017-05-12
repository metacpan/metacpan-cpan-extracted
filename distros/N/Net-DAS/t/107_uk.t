#!/usr/bin/perl

use 5.010;
use strict;
use warnings;
use Test::More tests => 17;

use Net::DAS;

##################################################
#### TESTING REQUEST METHOD
our $RES;

sub my_request {
    our $RES;
    return $RES . "\n";
}

my ( $c, $a, $das );
$das = new Net::DAS( { 'modules' => ['uk'], '_request' => \&my_request } );

##################################################

$RES = "test.co.uk,N";
$c   = $das->lookup('test.co.uk')->{'test.co.uk'};
is( $c->{'domain'},   'test.co.uk',   'domain ok' );
is( $c->{'label'},    'test',         'label ok' );
is( $c->{'tld'},      "co.uk",        'tld ok' );
is( $c->{'module'},   'Net::DAS::UK', 'module ok' );
is( $c->{'query'},    'test.co.uk',   'query ok' );
is( $c->{'response'}, "test.co.uk,N", 'response ok' );
is( $c->{'avail'},    1,              "avail ok (available)" );
is( $c->{'reason'},   'AVAILABLE',    "reason ok (available)" );
$a = $das->available('test.co.uk');
is( $a, 1, 'available() ok' );

$RES = "test.co.uk,Y,N,N,,,0,NOMINET";
$c   = $das->lookup('test.co.uk')->{'test.co.uk'};
is( $c->{'avail'}, 0, "avail ok (not available)" );
is( $c->{'reason'}, 'NOT AVAILABLE', "reason ok (not available)" );
$a = $das->available('test.co.uk');
is( $a, 0, 'available() ok' );

$RES = "test.co.uk,B";
$c   = $das->lookup('test.co.uk')->{'test.co.uk'};
is( $c->{'avail'},  -3,           "avail ok (blocked)" );
is( $c->{'reason'}, 'IP BLOCKED', "reason ok (blocked)" );
$a = $das->available('test.co.uk');
is( $a, -3, 'available() ok' );

$RES = "IP address 127.0.0.1 not registered.  Closing...";
$c   = $das->lookup('test.co.uk')->{'test.co.uk'};
is( $c->{'avail'}, -2, "avail ok (not auth)" );
is( $c->{'reason'}, 'NOT AUTHORIZED', "reason ok (not auth)" );

exit 0;
