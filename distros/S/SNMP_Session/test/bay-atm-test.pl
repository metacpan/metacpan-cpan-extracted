#!/usr/local/bin/perl -w

require 5;

use SNMP_Session;
use BER;

$SNMP_Session::suppress_warnings = 1;

$hostname = shift @ARGV || &usage;
$community = shift @ARGV || 'public';
&usage if $#ARGV >= 0;

%ugly_oids = qw(u1	1.3.6.1.4.1.930.2.2.2.1.1.1.6.4.2
		u2	1.3.6.1.4.1.930.2.2.2.1.1.1.8.4.2
		);
foreach (keys %ugly_oids) {
    $ugly_oids{$_} = encode_oid (split (/\./, $ugly_oids{$_}));
    $pretty_oids{$ugly_oids{$_}} = $_;
}

srand();
die "Couldn't open SNMP session to $hostname: $SNMP_Session::errmsg"
    unless ($session = SNMP_Session->open ($hostname, $community, 161));
snmp_get ($session, qw(u1 u2));
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
	    pretty_print ($value), "\n";
	}
    } else {
	warn "SNMP problem: $SNMP_Session::errmsg\n";
    }
}

sub usage
{
    die "usage: $0 hostname [community]";
}
