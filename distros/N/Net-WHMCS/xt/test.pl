#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use Net::WHMCS;
use Data::Dumper;
use Digest::MD5 'md5_hex';

my $whmcs = Net::WHMCS->new(
    WHMCS_URL      => 'http://example.com/whmcs/includes/api.php',
    WHMCS_USERNAME => 'admin_user',
    WHMCS_PASSWORD => md5_hex('admin_pass'),

# WHMCS_API_ACCESSKEY => 'faylandtest', # optional, to pass the IP, http://docs.whmcs.com/API:Access_Keys
);

my $user = $whmcs->client->getclientsdetails(
    {
        clientid => 1,
        stats    => 'true',
    }
);

print Dumper( \$user );

1;
