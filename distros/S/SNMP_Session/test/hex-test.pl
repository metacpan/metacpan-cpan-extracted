#!/usr/local/bin/perl -w
######################################################################
### Name:	  hex-test.pl
### Date Created: Mon Sep 22 21:15:06 1997
### Author:	  Simon Leinen  <simon@switch.ch>
### RCS $Id: hex-test.pl,v 1.1 1997-09-22 19:25:19 simon Exp $
######################################################################
### Test the new `hex_string' subroutine.
######################################################################

require 5;

require 'SNMP_Session.pm';
use BER;

$hostname = shift @ARGV || &usage;
$community = shift @ARGV || 'public';
&usage if $#ARGV >= 0;

%ugly_oids = qw(sysDescr.0	1.3.6.1.2.1.1.1.0
		sysContact.0	1.3.6.1.2.1.1.4.0
		ipForwarding.0	1.3.6.1.2.1.4.1.0
		);
foreach (keys %ugly_oids) {
    $ugly_oids{$_} = encode_oid (split (/\./, $ugly_oids{$_}));
    $pretty_oids{$ugly_oids{$_}} = $_;
}

srand();
die "Couldn't open SNMP session to $hostname"
    unless ($session = SNMP_Session->open ($hostname, $community, 161));
snmp_get ($session, qw(sysDescr.0 sysContact.0 ipForwarding.0));
$session->close ();
1;

sub snmp_get
{
    my($session, @oids) = @_;
    my($response, $bindings, $binding, $value, $oid);

    grep ($_ = $ugly_oids{$_}, @oids);

    if ($session->get_request_response (@oids)) {
	$response = $session->pdu_buffer;
	($bindings) = $session->decode_get_response ($response);

	while ($bindings ne '') {
	    ($binding,$bindings) = decode_sequence ($bindings);
	    ($oid,$value) = decode_by_template ($binding, "%O%@");
	    print $pretty_oids{$oid}," => ",
	          &hex_string ($value), "\n";
	}
    } else {
	warn "Response not received.\n";
    }
}

sub usage
{
    die "usage: $0 hostname [community]";
}
