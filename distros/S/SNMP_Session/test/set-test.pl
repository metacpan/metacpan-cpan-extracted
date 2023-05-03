#!/usr/local/bin/perl -w

#
#  set-test: simple script to show usage of snmpget(), snmpset(), and
#            snmpgetnext() functions.
#
#
#					matter	9 July 1997
# a few changes by Simon Leinen  <simon@switch.ch>, 16 August 1997

require 5.002;
use strict;
use SNMP_Session;
use BER;

#
#  OIDs we know by name.
#
my %OIDS = (
            'system'       => '1.3.6.1.2.1.1',
            'sysDescr'     => '1.3.6.1.2.1.1.1',
            'sysUptime'    => '1.3.6.1.2.1.1.3',
            'sysContact'   => '1.3.6.1.2.1.1.4',
            'sysLocation'  => '1.3.6.1.2.1.1.6',

	 );

my ($host, $oid, $community,$response);
($host = shift) or die "usage: $0 <hostname> [<community>]";
$community = shift || 'public';
#
#  First a simple SNMP Get
#
$oid = "sysUptime.0";
print "Getting $oid from $host\n";
($response) = &snmpget($host, $community, $oid);
if ($response) {
	print "$oid : $response\n";
} else {
	print "$host did not respond to SNMP query\n";
	exit;
}

#
#  Now a set
#
print "Before set:\n";
$oid = "sysContact.0";
($response) = &snmpget($host, $community, $oid);
if ($response) {
	print "$oid : $response\n";
} else {
	print "$host did not respond to SNMP query\n";
	exit;
}
my $oldContact = $response;
print "Setting contact to \"NecSys\"...\n";
($response) = &snmpset($host, $community, $oid, 'string', 'NeCSys');
($response) = &snmpget($host, $community, $oid);
if ($response) {
	print "$oid : $response\n";
} else {
	print "$host did not respond to SNMP query\n";
	exit;
}
print "Resetting contact to \"$oldContact\"...\n";
($response) = &snmpset($host, $community, $oid, 'string', $oldContact);
($response) = &snmpget($host, $community, $oid);
if ($response) {
	print "$oid : $response\n";
} else {
	print "$host did not respond to SNMP query\n";
	exit;
}

#
#  This is a simple implementation of snmpwalk using snmpgetnext.
#  Note that snmpgetnext expects the OID to be encoded.
#
$oid = 'system';
$oid = toOID($oid);
my $firstoid = $oid;
my $prefixLength = length(BER::pretty_oid($oid))+1;
my ($result,$value);
print "Now we use SNMP GetNext to walk the system MIB\n";
while(1) {
	($oid,$value) = &snmpgetnext($host, $community, $oid);
	last unless BER::encoded_oid_prefix_p($firstoid,$oid);
	next unless $value;
	$result = BER::pretty_oid($oid);
	#
	#  This line truncates to OID to be relative to the starting OID
	#
	$result = substr($result,$prefixLength);
	print "system.$result: $value\n";
}

sub snmpget {
	my($host,$community,@varList) = @_;
	my(@enoid, $var,$response, $bindings, $binding, $value, $inoid,
		$outoid, $upoid,$oid,@retvals);
	grep ($_=toOID($_), @varList);
	srand();
	my $session = SNMP_Session->open ($host , $community, 161);
	if ($session->get_request_response(@varList)) {
		$response = $session->pdu_buffer;
		($bindings) = $session->decode_get_response ($response);
		$session->close ();
		while ($bindings) {
			($binding,$bindings) = decode_sequence ($bindings);
			($oid,$value) = decode_by_template ($binding, "%O%@");
			my $tempo = pretty_print($value);
			$tempo=~s/\t/ /g;
			$tempo=~s/\n/ /g;
			$tempo=~s/^\s+//;
			$tempo=~s/\s+$//;
			push @retvals,  $tempo;
		}
		return (@retvals);
	} else {
		return (-1,-1);
	}
}

#
#  Unlike snmpget() and snmpset(), snmpgetnext() expects the OID to be
#  encoded.
#
sub snmpgetnext {
	my($host,$community,$var) = @_;
	my($response, $bindings, $binding, $value, $inoid,
	   $outoid, $upoid,$oid,@retvals);
	srand();
	my $session = SNMP_Session->open ($host , $community, 161);
	if ($session->getnext_request_response($var)) {
		$response = $session->pdu_buffer;
		($bindings) = $session->decode_get_response ($response);
		$session->close ();
		while ($bindings) {
			($binding,$bindings) = decode_sequence ($bindings);
			($oid,$value) = decode_by_template ($binding, "%O%@");
			my $tempo = pretty_print($value);
			$tempo=~s/\t/ /g;
			$tempo=~s/\n/ /g;
			$tempo=~s/^\s+//;
			$tempo=~s/\s+$//;
			push @retvals,  $oid,$tempo;
		}
		return (@retvals);
	} else {
		return (-1,-1);
	}
}

sub snmpset {
	my($host,$community,@varList) = @_;
	my(@enoid, $response, $bindings, $binding, $inoid,$outoid,
		$upoid,$oid,@retvals);
  	my ($type,$value);
	while (@varList) {
		$oid   = toOID(shift @varList);
		$type  = shift @varList;
		$value = shift @varList;
		($type eq 'string') && do {
			$value = encode_string($value);
			push @enoid, [$oid,$value];
			next;
		};
		($type eq 'int') && do {
			$value = encode_int($value);
			push @enoid, [$oid,$value];
			next;
		};
		die "Unknown SNMP type: $type";
	}
	srand();
	my $session = SNMP_Session->open ($host , $community, 161);
	if ($session->set_request_response(@enoid)) {
		$response = $session->pdu_buffer;
		($bindings) = $session->decode_get_response ($response);
		$session->close ();
		while ($bindings) {
			($binding,$bindings) = decode_sequence ($bindings);
			($oid,$value) = decode_by_template ($binding, "%O%@");
			my $tempo = pretty_print($value);
			$tempo=~s/\t/ /g;
			$tempo=~s/\n/ /g;
			$tempo=~s/^\s+//;
			$tempo=~s/\s+$//;
			push @retvals,  $tempo;
		}
		return (@retvals);
	} else {
		return (-1,-1);
	}
}

#
#  Given an OID in either ASN.1 or mixed text/ASN.1 notation, return an
#  encoded OID.
#
sub toOID {
	my $var = shift;
	if ($var =~ /^([a-z]+[^\.]*)/i) {
		my $oid = $OIDS{$1};
		if ($oid) {
			$var =~ s/$1/$oid/;
		} else {
			die "Unknown SNMP var $var\n"
		}
	}
	encode_oid((split /\./, $var));
}

