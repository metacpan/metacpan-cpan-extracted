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
    return
          "% Domain Availability Server 1.0 - whois.rotld.ro:4343\n"
        . "%\n%(c)2010 http://www.rotld.ro\n" . "%\n\n"
        . $RES . "\n";
}

my ( $c, $a, $das );
$das = new Net::DAS( { 'modules' => ['RO'], '_request' => \&my_request } );

##################################################

$RES = "Domain: test.ro\nStatus: AVAILABLE";
$c   = $das->lookup('test.ro')->{'test.ro'};
is( $c->{'domain'}, 'test.ro',      'domain ok' );
is( $c->{'label'},  'test',         'label ok' );
is( $c->{'tld'},    "ro",           'tld ok' );
is( $c->{'module'}, 'Net::DAS::RO', 'module ok' );
is( $c->{'query'},  "test.ro",      'query ok' );
is( $c->{'response'},
    "% Domain Availability Server 1.0 - whois.rotld.ro:4343\n%\n%(c)2010 http://www.rotld.ro\n%\n\nDomain: test.ro\nStatus: AVAILABLE",
    'response ok'
);
is( $c->{'avail'},  1,           "avail ok (available)" );
is( $c->{'reason'}, 'AVAILABLE', "reason ok (available)" );
$a = $das->available('test.ro');
is( $a, 1, 'available() ok' );

$RES = "Domain: test.ro\nStatus: NOT AVAILABLE";
$c   = $das->lookup('test.ro')->{'test.ro'};
is( $c->{'avail'}, 0, "avail ok (not available)" );
is( $c->{'reason'}, 'NOT AVAILABLE', "reason ok (not available)" );
$a = $das->available('test.ro');
is( $a, 0, 'available() ok' );

exit 0;
