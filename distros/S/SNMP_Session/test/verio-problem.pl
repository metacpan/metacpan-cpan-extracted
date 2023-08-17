#!/usr/bin/perl

use BER;
require 'SNMP_Session.pm';

# Set $host to the name of the host whose SNMP agent you want
# to talk to.  Set $community to the community name under
# which you want to talk to the agent.  Set port to the UDP
# port on which the agent listens (usually 161).

$host = "vcp-nt.cp.verio.net";
$community = "public";
$port = "161";

$session = SNMP_Session->open ($host, $community, $port)
    || die "couldn't open SNMP session to $host";

# Set $oid1, $oid2... to the BER-encoded OIDs of the MIB
# variables you want to get.
$oid = "1.3.6.1.2.1.1.1.0";

%pretty_oids = ( encode_oid(1,3,6,1,2,1,1,1,0), "sysDescr.0" );

if ($session->get_request_response (encode_oid (split '\.',$oid))) {
    ($bindings) = $session->decode_get_response ($session->{pdu_buffer});

    while ($bindings ne '') {
        ($binding,$bindings) = &decode_sequence ($bindings);
        ($oid,$value) = &decode_by_template ($binding, "%O%@");
        print $pretty_oids{$oid}," => ",
              &pretty_print ($value), "\n";
    }
} else {
    die "No response from agent on $host";
}
