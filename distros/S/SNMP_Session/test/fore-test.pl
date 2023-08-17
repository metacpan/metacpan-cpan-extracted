#!/usr/local/bin/perl -w
###
### Small test program that uses GetNext requests to walk a table.
###

use strict;
use BER;
use SNMP_Session;

my $hostname = $ARGV[0] || '193.246.0.134';
my $community = $ARGV[1] || 'public';

my $session;

die unless ($session = SNMP_Session->open ($hostname, $community, 161));

my @nsapTopoLinkDestPort = split ('\.', '1.3.6.1.4.1.326.2.2.2.1.9.3.1.7');

my $destPortIndex = encode_oid (@nsapTopoLinkDestPort);

my @oids = ($destPortIndex);
my @next_oids;

my $oid;
my $i;
for (;;) {
    if ($session->getnext_request_response (@oids)) {
	my $response = $session->pdu_buffer;
	my ($bindings, $binding, $oid, $value);

	($bindings) = $session->decode_get_response ($response);
	@next_oids = ();

	## IP address
	($binding,$bindings) = decode_sequence ($bindings);
	($oid,$value) = decode_by_template ($binding, "%O%@");
	last
	    unless BER::encoded_oid_prefix_p ($destPortIndex, $oid);
	push @next_oids, $oid;
	print pretty_print ($value), ' [',pretty_print ($oid), "]\n";

    } else {
	die "No response received.\n";
    }
    @oids = @next_oids;
}

$session->close ();

1;
