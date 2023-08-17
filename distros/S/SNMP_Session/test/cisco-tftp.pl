#!/usr/local/bin/perl -w

require 5.002;
use strict;
use SNMP_Session;
use BER;

my %OIDS = (
	    'netConfigSet' => '1.3.6.1.4.1.9.2.1.50',
	    'WriteNet'	   => '1.3.6.1.4.1.9.2.1.55',
	    'WriteMem'	   => '1.3.6.1.4.1.9.2.1.54.0',
	 );

my $key;
foreach $key (keys %OIDS) {
    my @oid;

    @oid = split (/\./,$OIDS{$key});
    $OIDS{$key} = \@oid;
}

my ($router,$community) = ($ARGV[0] || 'popo', $ARGV[1] || "asdjkfhagk");

my $tftphost = "130.59.1.30";
my $filename = "snmp-test";

sub write_net ($ $ $ ) {
    my ($session, $tftphost, $filename) = @_;

    my $write_net_oid = encode_oid (@{$OIDS{WriteNet}}, split (/\./,$tftphost));
    my @enoid = ([$write_net_oid, encode_string ($filename)]);

    #print (join(".",$write_net_oid), "\n");
    if ($session->set_request_response(@enoid)) {
	my $response = $session->pdu_buffer;
	my ($bindings) = $session->decode_get_response ($response);
	$session->close ();
	while ($bindings) {
	    my ($binding, $oid, $value);
	    ($binding,$bindings) = decode_sequence ($bindings);
	    ($oid,$value) = decode_by_template ($binding, "%O%@");
	}
    } else {
	return (-1,-1);
    }
}

my $session = SNMP_Session->open ($router , $community, 161);
&write_net ($session, $tftphost, $filename);
1;
