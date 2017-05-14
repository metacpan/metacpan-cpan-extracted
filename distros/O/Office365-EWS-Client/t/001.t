#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Data::Dumper;

my $ews;
my $user = 'skip';
my $pass = 'skip';

if ( $ENV{EWS_USER} and $ENV{EWS_PASS} ) {
    $user = $ENV{EWS_USER};
    $pass = $ENV{EWS_PASS};
    plan tests => 8;
}
else {
    print "set EWS_USER and EWS_PASS in your ENV for more thorough tests\n";
    plan tests => 10;
}

use_ok 'Office365::EWS::Client';

# test with bad version
ok($ews = Office365::EWS::Client->new({
    server         => 'outlook.office365.com',
    username       => $user,
    password       => $pass,
    server_version => 'junk',
}), 'constructor');
ok( ! eval { return $ews->contacts->retrieve }, "failed due to bad server_version" );
like( $@, qr/server_version/, 'warning about server_version' );

# test simple auth and fetch
ok($ews = Office365::EWS::Client->new({
    server         => 'outlook.office365.com',
    username       => $user,
    password       => $pass,
    server_version => 'Exchange2013_SP1',
}), 'constructor');

if ( $pass eq 'skip' ) {
    ok( ! eval { return $ews->contacts->retrieve }, "authentication failed" );
    # TODO find a better way to detect authentication failures
    like( $@, qr/Can't use an undefined value as an ARRAY reference/, 'warning about authentication failure' );
}
else {
    ok( eval { return $ews->contacts->retrieve }, "successful query" );
}

# test different version
ok($ews = Office365::EWS::Client->new({
    server         => 'outlook.office365.com',
    username       => $user,
    password       => $pass,
    server_version => 'Exchange2010_SP2',
}), 'constructor');

if ( $pass eq 'skip' ) {
    ok( ! eval { return $ews->contacts->retrieve }, "authentication failed" );
    # TODO find a better way to detect authentication failures
    like( $@, qr/Can't use an undefined value as an ARRAY reference/, 'warning about authentication failure' );
}
else {
    ok( eval { return $ews->contacts->retrieve }, "successful query" );
}
