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
$das = new Net::DAS( { 'modules' => ['it'], '_request' => \&my_request } );

##################################################

$RES = "Domain: test.it\nStatus: AVAILABLE";
$c   = $das->lookup('test.it')->{'test.it'};
is( $c->{'domain'},   'test.it',                            'domain ok' );
is( $c->{'label'},    'test',                               'label ok' );
is( $c->{'tld'},      "it",                                 'tld ok' );
is( $c->{'module'},   'Net::DAS::IT',                       'module ok' );
is( $c->{'query'},    'test.it',                            'query ok' );
is( $c->{'response'}, "Domain: test.it\nStatus: AVAILABLE", 'response ok' );
is( $c->{'avail'},    1,                                    "avail ok (available)" );
is( $c->{'reason'},   'AVAILABLE',                          "reason ok (available)" );
$a = $das->available('test.it');
is( $a, 1, 'available() ok' );

$RES = "Domain: test.it\nStatus: NOT AVAILABLE";
$c   = $das->lookup('test.it')->{'test.it'};
is( $c->{'avail'}, 0, "avail ok (not available)" );
is( $c->{'reason'}, 'NOT AVAILABLE', "reason ok (not available)" );
$a = $das->available('test.it');
is( $a, 0, 'available() ok' );

exit 0;
