#!/usr/bin/perl -w
#
# test registering of extensions in the session

use 5.010;
use strict;

use Test::More;

use XML::EPP;
use SRS::EPP::Session::Extensions;

# Register extension uris
XML::EPP::register_ext_uri(
	'urn:ietf:params:xml:ns:secDNS-1.1' => 'dnssec',
	'some_other_uri' => 'ext1',
	'another_uri' => 'ext2',
);

# Create an Session Extensions object
my $extensions = SRS::EPP::Session::Extensions->new();

# Set the uris this session wants to use
$extensions->set(
	'urn:ietf:params:xml:ns:secDNS-1.1',
	'another_uri'
);

# Check to see which URIs are enabled
is($extensions->enabled->{dnssec}, 1, "DNS sec extension enabled");
is($extensions->enabled->{ext1}, undef, "ext1 not enabled");
is($extensions->enabled->{ext2}, 1, "ext2 enabled");

done_testing();