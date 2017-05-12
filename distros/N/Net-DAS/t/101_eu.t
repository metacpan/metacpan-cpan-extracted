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
          "% \"\"\n" . "%\n"
        . "% .eu Domain Availability Server\n" . "%\n"
        . "% (c) 2005 (http://www.eurid.eu)\n" . "%\n" . "\n"
        . "%RC=0\n"
        . $RES . "\n";
}

my ( $c, $a, $das );
$das = new Net::DAS( { 'modules' => ['eu'], '_request' => \&my_request } );

##################################################

$RES = "Domain: test.eu\nStatus: AVAILABLE";
$c   = $das->lookup('test.eu')->{'test.eu'};
is( $c->{'domain'}, 'test.eu',      'domain ok' );
is( $c->{'label'},  'test',         'label ok' );
is( $c->{'tld'},    "eu",           'tld ok' );
is( $c->{'module'}, 'Net::DAS::EU', 'module ok' );
is( $c->{'query'},  'test.eu',      'query ok' );
is( $c->{'response'},
    "% \"\"\n%\n% .eu Domain Availability Server\n%\n% (c) 2005 (http://www.eurid.eu)\n%\n\n%RC=0\nDomain: test.eu\nStatus: AVAILABLE",
    'response ok'
);
is( $c->{'avail'},  1,           "avail ok (available)" );
is( $c->{'reason'}, 'AVAILABLE', "reason ok (available)" );
$a = $das->available('test.eu');
is( $a, 1, 'available() ok' );

$RES = "Domain: test.eu\nStatus: NOT AVAILABLE";
$c   = $das->lookup('test.eu')->{'test.eu'};
is( $c->{'avail'}, 0, "avail ok (not available)" );
is( $c->{'reason'}, 'NOT AVAILABLE', "reason ok (not available)" );
$a = $das->available('test.eu');
is( $a, 0, 'available() ok' );

exit 0;
