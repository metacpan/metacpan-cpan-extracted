#!/usr/bin/env perl
#
# Modbus/TCP Server query
#
# Issues a read inputs request on an IP address / port
# Here is demonstrated the full Modbus transaction API
#
# Cosimo  Feb 5st, 2007
#

use strict;
use warnings;
use lib '../blib/lib';
use Protocol::Modbus;

$| = 1;

my $modbus = Protocol::Modbus->new(driver=>'TCP');

# Create transport class
my $trs = Protocol::Modbus::Transport->new(
    driver  => 'TCP',
    address => '192.168.11.99',
    port    => 502,
    timeout => 3,
);

# with explicit method name
my $req = $modbus->readInputsRequest(
    address  => 0,
    quantity => 64,
);

# Open a new modbus transaction...
my $trn = $modbus->transaction($trs, $req);

while(1)
{
    # ... issue the request and get response
    my $res = $trn->execute();

    my @inputs = @{ $res->inputs() };

    print 'Inputs status: (', join('', @inputs), ')', "\r";

    select(undef, undef, undef, 0.2);
}


