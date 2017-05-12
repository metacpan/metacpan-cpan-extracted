#!/usr/local/bin/perl

use Net::UPnP::ControlPoint;

Net::UPnP->SetDebug(1);

my $obj = Net::UPnP::ControlPoint->new();

@dev_list = $obj->search();

exit 0;

