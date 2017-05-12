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
    return "% Domain Availability Server 1.0\n" . "%\n" . "% by OpenRegistry\n" . "%%RC=0\n" . $RES . "\n";
}

my ( $c, $a, $das );
$das = new Net::DAS( { 'modules' => ['gent'], '_request' => \&my_request } );

##################################################

$RES = "Domain: test.gent\nStatus: AVAILABLE";
$c   = $das->lookup('test.gent')->{'test.gent'};
is( $c->{'domain'}, 'test.gent',      'domain ok' );
is( $c->{'label'},  'test',           'label ok' );
is( $c->{'tld'},    "gent",           'tld ok' );
is( $c->{'module'}, 'Net::DAS::GENT', 'module ok' );
is( $c->{'query'},  'test.gent',      'query ok' );
is( $c->{'response'},
    "% Domain Availability Server 1.0\n%\n% by OpenRegistry\n%%RC=0\nDomain: test.gent\nStatus: AVAILABLE",
    'response ok' );
is( $c->{'avail'},  1,           "avail ok (available)" );
is( $c->{'reason'}, 'AVAILABLE', "reason ok (available)" );
$a = $das->available('test.gent');
is( $a, 1, 'available() ok' );

$RES = "Domain: test.gent\nStatus: NOT AVAILABLE";
$c   = $das->lookup('test.gent')->{'test.gent'};
is( $c->{'avail'}, 0, "avail ok (not available)" );
is( $c->{'reason'}, 'NOT AVAILABLE', "reason ok (not available)" );
$a = $das->available('test.gent');
is( $a, 0, 'available() ok' );

exit 0;
