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
    return "% .lt registry DAS service\n" . $RES . "\n";
}

my ( $c, $a, $das );
$das = new Net::DAS( { 'modules' => ['lt'], '_request' => \&my_request } );

##################################################

$RES = "Domain: test.lt\nStatus: available";
$c   = $das->lookup('test.lt')->{'test.lt'};
is( $c->{'domain'},   'test.lt',                                                        'domain ok' );
is( $c->{'label'},    'test',                                                           'label ok' );
is( $c->{'tld'},      "lt",                                                             'tld ok' );
is( $c->{'module'},   'Net::DAS::LT',                                                   'module ok' );
is( $c->{'query'},    'get 1.0 test.lt',                                                'query ok' );
is( $c->{'response'}, "% .lt registry DAS service\nDomain: test.lt\nStatus: available", 'response ok' );
is( $c->{'avail'},    1,                                                                "avail ok (available)" );
is( $c->{'reason'},   'AVAILABLE',                                                      "reason ok (available)" );
$a = $das->available('test.lt');
is( $a, 1, 'available() ok' );

$RES = "Domain: test.lt\nStatus: registered";
$c   = $das->lookup('test.lt')->{'test.lt'};
is( $c->{'avail'}, 0, "avail ok (not available)" );
is( $c->{'reason'}, 'NOT AVAILABLE', "reason ok (not available)" );
$a = $das->available('test.lt');
is( $a, 0, 'available() ok' );

exit 0;
