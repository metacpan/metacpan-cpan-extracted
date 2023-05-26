#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 26;

require_ok( 'NOLookup::DAS::DASLookup' );

my $SERVER = $ENV{DAS_SERVICE} || "finger.test.norid.no";

# Registered/delegated
my $q = "norid.no";
my $das = NOLookup::DAS::DASLookup->new($q, $SERVER);
ok($das, "DAS object returned");
ok(!$das->errno, "No error was returned");
ok($das->delegated, "Domain $q is already registered");
ok(!$das->available, "Domain $q is not available");
ok(!$das->prohibited, "Domain $q is not prohibited");
ok(!$das->invalid, "Domain $q is not invalid");
is($das->raw_text, "$q is delegated (0)", "Raw text was returned and correct");

# Prohibited
$q = "sex.no";
$das = NOLookup::DAS::DASLookup->new($q, $SERVER);
ok($das, "DAS object returned");
ok(!$das->errno, "Error was not returned on $q");
ok(!$das->delegated, "Domain $q is not registered");
ok(!$das->available, "Domain $q is not available");
ok($das->prohibited, "Domain $q is prohibited");
ok(!$das->invalid, "Domain $q is not invalid");
is($das->raw_text, "This domain can currently not be registered (0)", "$q: Raw text was returned and correct");

# invalid zone/name
$q = "domain.mil.no";
$das = NOLookup::DAS::DASLookup->new($q, $SERVER);
ok($das, "DAS object returned");
ok(!$das->errno, "Error was not returned on $q");
ok(!$das->delegated, "Domain $q is not registered");
ok(!$das->available, "Domain $q is not available");
ok(!$das->prohibited, "Domain $q is not prohibited");
ok($das->invalid, "Domain $q is invalid");
ok($das->raw_text, "Raw text was returned");

# Invalid request "ERROR - Invalid request"
$q = "norid.com";
$das = NOLookup::DAS::DASLookup->new($q, $SERVER);
ok($das, "DAS object returned");
ok($das->errno, "Error was returned on $q, errno: " . $das->errno);
ok($das->raw_text, "Raw text was returned");
is($das->raw_text, "ERROR - Invalid request (0)", "Raw text was returned and correct");

#print $das->errno, "\n";
#print $das->raw_text, "\n";
