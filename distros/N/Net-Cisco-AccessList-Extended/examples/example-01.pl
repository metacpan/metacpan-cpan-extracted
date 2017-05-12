#!/usr/bin/perl

use strict;
use Net::Cisco::AccessList::Extended;

my $l = Net::Cisco::AccessList::Extended->new('INCOMING_LIST');

$l->push({
    access => 'permit',
    proto  => 'ip',
});
$l->push({
    access => 'permit',
    proto  => 'ip',
    src_og => 'srcnet',
    dst_og => 'dstnet',
});
$l->push({
    access     => 'permit',
    proto      => 'ip',
    src_svc_og => 'sourceservices',
    dst_svc_og => 'destservices',
});
$l->push({
    access  => 'deny',
    proto   => 'icmp',
    icmp_og => 'icmptypes',
});
$l->push({
    access => 'deny',
    proto  => 'icmp',
    icmp   => 'echo-request',
});
$l->push({
    access     => 'deny',
    proto      => 'ip',
    src_svc_op => 'range',
    src_svc    => '21',
    src_svc_hi => 'smtp',
});

print $l->dump ."\n";

# access-list INCOMING_LIST extended permit ip any any
# access-list INCOMING_LIST extended permit ip object-group srcnet object-group dstnet
# access-list INCOMING_LIST extended permit ip any object-group sourceservices any object-group destservices
# access-list INCOMING_LIST extended deny icmp any any object-group icmptypes
# access-list INCOMING_LIST extended deny icmp any any echo-request
# access-list INCOMING_LIST extended deny ip any range 21 smtp any
