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
$das = new Net::DAS( { 'modules' => ['no'], '_request' => \&my_request } );

##################################################

$RES = "test.no is available (0)";
$c   = $das->lookup('test.no')->{'test.no'};
is( $c->{'domain'},   'test.no',                  'domain ok' );
is( $c->{'label'},    'test',                     'label ok' );
is( $c->{'tld'},      "no",                       'tld ok' );
is( $c->{'module'},   'Net::DAS::NO',             'module ok' );
is( $c->{'query'},    'test.no',                  'query ok' );
is( $c->{'response'}, "test.no is available (0)", 'response ok' );
is( $c->{'avail'},    1,                          "avail ok (available)" );
is( $c->{'reason'},   'AVAILABLE',                "reason ok (available)" );
$a = $das->available('test.no');
is( $a, 1, 'available() ok' );

$RES = "test.no is delegated (0)";
$c   = $das->lookup('test.no')->{'test.no'};
is( $c->{'avail'}, 0, "avail ok (not available)" );
is( $c->{'reason'}, 'NOT AVAILABLE', "reason ok (not available)" );
$a = $das->available('test.no');
is( $a, 0, 'available() ok' );

exit 0;
