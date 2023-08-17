#!/usr/local/bin/perl -w
use strict;
use BER;
use SNMP_Session;
use Socket;

my $bad_trap
    = "\x30\x82\x00\x3a"
    ."\x02\x01\x00\x04\x06\x64\x63\x72\x32\x73\x62\xa4\x2d\x06\x07\x2b"
    ."\x06\x01\x04\x01\x82\x3e\x40\x04\xce\xaf\x3b\x0e\x02\x01\x04\x02"
    ."\x01\x00\x43\x04\x36\xfb\x79\x93\x30\x10\x30\x82\x00\x0c\x06\x08"
    ."\x2b\x06\x01\x02\x01\x01\x01\x00\x05\x00";

my $session = SNMP_Session->open ('localhost', 'public', 1162)
    || die "open SNMP session: $SNMP_Session::errmsg";
print_trap ($session, $bad_trap);
$session->close ()
    || warn "close SNMP session: $SNMP_Session::errmsg";
1;

sub print_trap ($$) {
    my ($this, $trap) = @_;
    my ($encoded_pair, $oid, $value);
    my ($community, $ent, $agent, $gen, $spec, $dt, $bindings)
	= $this->decode_trap_request ($trap);
    my ($binding, $prefix);
    print "    community: ".$community."\n";
    print "   enterprise: ".BER::pretty_oid ($ent)."\n";
    print "   agent addr: ".inet_ntoa ($agent)."\n";
    print "   generic ID: $gen\n";
    print "  specific ID: $spec\n";
    print "       uptime: ".BER::pretty_uptime_value ($dt)."\n";
    $prefix = "     bindings: ";
    while ($bindings) {
	($binding,$bindings) = decode_sequence ($bindings);
	($oid,$value) = decode_by_template ($binding, "%O%@");
	print $prefix.BER::pretty_oid ($oid)." => ".pretty_print ($value)."\n";
	$prefix = "               ";
    }
}
