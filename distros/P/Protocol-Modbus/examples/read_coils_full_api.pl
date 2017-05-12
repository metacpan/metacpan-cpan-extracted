#!/usr/bin/env perl
#
# Modbus/TCP Server query
#
# Issues a read coils request on an IP address / port
# Here is demonstrated the full Modbus transaction API
#
# Cosimo  Feb 2st, 2007
#

use strict;
use warnings;
use lib '../blib/lib';
use Protocol::Modbus;

$| = 1;

my $modbus = Protocol::Modbus->new(driver=>'TCP', transport=>'TCP');

# Create transport class
my $trs = Protocol::Modbus::Transport->new(
    driver  => 'TCP',
    address => '192.168.11.99',
    port    => 502,
    timeout => 3,
);

# with explicit method name
my $req = $modbus->readCoilsRequest(
    address  => 512,
    quantity => 10,
);

# Open a new modbus transaction...
my $trn = $modbus->transaction($trs, $req);

while(1)
{
    # ... issue the request and get response
    my $res = $trn->execute();

    my $coils = $res->coils();

    print 'Coils status: (', join('', @$coils), ')', "\r";

    select(undef, undef, undef, 0.2);
}

