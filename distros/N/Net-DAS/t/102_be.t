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
    return "% .be Domain Availability Server 4.0\n" . "\n" . "%% RC=0\n" . $RES . "\n";
}

my ( $c, $a, $das );
$das = new Net::DAS( { 'modules' => ['be'], '_request' => \&my_request } );

##################################################

$RES = "Domain: test.be\nStatus: AVAILABLE";
$c   = $das->lookup('test.be')->{'test.be'};
is( $c->{'domain'}, 'test.be',      'domain ok' );
is( $c->{'label'},  'test',         'label ok' );
is( $c->{'tld'},    "be",           'tld ok' );
is( $c->{'module'}, 'Net::DAS::BE', 'module ok' );
is( $c->{'query'},  'test.be',      'query ok' );
is( $c->{'response'}, "% .be Domain Availability Server 4.0\n\n%% RC=0\nDomain: test.be\nStatus: AVAILABLE",
    'response ok' );
is( $c->{'avail'},  1,           "avail ok (available)" );
is( $c->{'reason'}, 'AVAILABLE', "reason ok (available)" );
$a = $das->available('test.be');
is( $a, 1, 'available() ok' );

$RES = "Domain: test.be\nStatus: NOT AVAILABLE";
$c   = $das->lookup('test.be')->{'test.be'};
is( $c->{'avail'}, 0, "avail ok (not available)" );
is( $c->{'reason'}, 'NOT AVAILABLE', "reason ok (not available)" );
$a = $das->available('test.be');
is( $a, 0, 'available() ok' );

exit 0;
