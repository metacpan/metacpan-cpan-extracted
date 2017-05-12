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
$das = new Net::DAS( { 'modules' => ['si'], '_request' => \&my_request } );

##################################################

$RES = "test.si is available";
$c   = $das->lookup('test.si')->{'test.si'};
is( $c->{'domain'},   'test.si',              'domain ok' );
is( $c->{'label'},    'test',                 'label ok' );
is( $c->{'tld'},      "si",                   'tld ok' );
is( $c->{'module'},   'Net::DAS::SI',         'module ok' );
is( $c->{'query'},    'test.si',              'query ok' );
is( $c->{'response'}, "test.si is available", 'response ok' );
is( $c->{'avail'},    1,                      "avail ok (available)" );
is( $c->{'reason'},   'AVAILABLE',            "reason ok (available)" );
$a = $das->available('test.si');
is( $a, 1, 'available() ok' );

$RES = "test.si is registered";
$c   = $das->lookup('test.si')->{'test.si'};
is( $c->{'avail'}, 0, "avail ok (not available)" );
is( $c->{'reason'}, 'NOT AVAILABLE', "reason ok (not available)" );
$a = $das->available('test.si');
is( $a, 0, 'available() ok' );

exit 0;
