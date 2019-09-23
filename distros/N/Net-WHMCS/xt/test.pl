#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use Net::WHMCS;
use Data::Dumper;
use Digest::MD5 'md5_hex';

my $whmcs = Net::WHMCS->new(
	WHMCS_URL => 'http://example.com/whmcs/includes/api.php',
	api_identifier => 'D4j1dKYE3g40VROOPCGyJ9zRwP0ADJIv',
    api_secret => 'F1CKGXRIpylMfsrig3mwwdSdYUdLiFlo',
);

my $user = $whmcs->client->getclientsdetails({
	clientid => 1,
	stats => 'true',
});

print Dumper(\$user);

1;