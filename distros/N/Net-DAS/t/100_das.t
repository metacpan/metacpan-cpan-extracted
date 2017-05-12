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
    my ( $das, $query ) = @_;
    our $RES;
    return "% DAS Server\n" . $RES . "\n";
}

##################################################
#### INITALIZE DAS WITH DUMMY
my ( $c, $a, $das );
$das = new Net::DAS( { 'modules' => [], '_request' => \&my_request } );
$das->{'Net::DAS::DUMMY'} = { tlds => [qw(dummy eu co.uk)], public => { host => 'das.nic.dummy', port => 4343, } };
$das->{tlds}->{'dummy'} = 'Net::DAS::DUMMY';
$das->{tlds}->{'eu'}    = 'Net::DAS::DUMMY';
$das->{tlds}->{'co.uk'} = 'Net::DAS::DUMMY';

##################################################
#### METHOD TESTS
is_deeply( [ $das->_split_domain('test.eu') ],    [ 'test', 'eu' ],    'split_domain test.eu' );
is_deeply( [ $das->_split_domain('test.co.uk') ], [ 'test', 'co.uk' ], 'split_domain test.co.uk' );

##################################################
#### LOOKUP TESTS
$RES = "Domain: test.dummy\nStatus: Available";
$c   = $das->lookup('test.dummy')->{'test.dummy'};
is( $c->{'domain'},   'test.dummy',                                          'domain ok' );
is( $c->{'label'},    'test',                                                'label ok' );
is( $c->{'tld'},      "dummy",                                               'tld ok' );
is( $c->{'module'},   'Net::DAS::DUMMY',                                     'module ok' );
is( $c->{'query'},    'test.dummy',                                          'query ok' );
is( $c->{'response'}, "% DAS Server\nDomain: test.dummy\nStatus: Available", 'response ok' );
is( $c->{'avail'},    1,                                                     "avail ok (available)" );
is( $c->{'reason'},   'AVAILABLE',                                           "reason ok (available)" );
$a = $das->available('test.dummy');
is( $a, 1, 'available() ok' );

$RES = "Domain: test.dummy\nStatus: Not Available";
$c   = $das->lookup('test.dummy')->{'test.dummy'};
is( $c->{'avail'}, 0, "avail ok (not available)" );
is( $c->{'reason'}, 'NOT AVAILABLE', "reason ok (not available)" );
$a = $das->available('test.dummy');
is( $a, 0, 'available() ok' );

$RES = "Something wrong";
$c   = $das->lookup('test.dummy')->{'test.dummy'};
is( $c->{'avail'}, -100, "avail ok (unable to parse)" );
is( $c->{'reason'}, 'UNABLE TO PARSE RESPONSE', "reason ok (unable to parse)" );
$a = $das->available('test.dummy');
is( $a, -100, 'available() ok' );

exit 0;
