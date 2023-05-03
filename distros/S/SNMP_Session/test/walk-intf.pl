#!/usr/local/bin/perl -w
###
### Small test program that uses GetNext requests to walk the
### interfaces table.

use strict;
use BER;
use SNMP_Session;

### Prototypes
sub usage($ );

my $hostname = $ARGV[0] || usage (1);
my $community = $ARGV[1] || usage (1);

my $session;

## Set this if you want to see the OID for all printed values.
my $print_oids_p = 0;

die unless ($session = SNMP_Session->open ($hostname, $community, 161));

my @base_oids =
(
 encode_oid (split ('\.', '1.3.6.1.2.1.2.2.1.2')), # ifDescr
 encode_oid (split ('\.', '1.3.6.1.2.1.2.2.1.3')), # ifType
 encode_oid (split ('\.', '1.3.6.1.2.1.2.2.1.4')), # ifMtu
 encode_oid (split ('\.', '1.3.6.1.2.1.2.2.1.5')), # ifSpeed
# encode_oid (split ('\.', '1.3.6.1.2.1.2.2.1.6')), # ifPhysAddress
 encode_oid (split ('\.', '1.3.6.1.2.1.2.2.1.7')), # ifAdminStatus
 encode_oid (split ('\.', '1.3.6.1.2.1.2.2.1.8')), # ifOperStatus
 encode_oid (split ('\.', '1.3.6.1.2.1.2.2.1.9')), # ifLastChange
 encode_oid (split ('\.', '1.3.6.1.2.1.2.2.1.10')), # ifInOctets
# encode_oid (split ('\.', '1.3.6.1.2.1.2.2.1.11')), # ifInUcastPkts
# encode_oid (split ('\.', '1.3.6.1.2.1.2.2.1.12')), # ifInNUcastPkts
# encode_oid (split ('\.', '1.3.6.1.2.1.2.2.1.13')), # ifInDiscards
# encode_oid (split ('\.', '1.3.6.1.2.1.2.2.1.14')), # ifInErrors
# encode_oid (split ('\.', '1.3.6.1.2.1.2.2.1.15')), # ifInUnknownProtos
 encode_oid (split ('\.', '1.3.6.1.2.1.2.2.1.16')), # ifOutOctets
# encode_oid (split ('\.', '1.3.6.1.2.1.2.2.1.17')), # ifOutUcastPkts
# encode_oid (split ('\.', '1.3.6.1.2.1.2.2.1.18')), # ifOutNUcastPkts
# encode_oid (split ('\.', '1.3.6.1.2.1.2.2.1.19')), # ifOutDiscards
# encode_oid (split ('\.', '1.3.6.1.2.1.2.2.1.20')), # ifOutErrors
# encode_oid (split ('\.', '1.3.6.1.2.1.2.2.1.21')), # ifOutQLen
# encode_oid (split ('\.', '1.3.6.1.2.1.2.2.1.22')), # ifSpecific
);


my $oid;
my $i;
my @next_oids = @base_oids;
ROW_LOOP:
for (;;) {
    if ($session->getnext_request_response (@next_oids)) {
	my $response = $session->pdu_buffer;
	my ($bindings, $binding, $oid, $value);
	my ($base_oid);

	($bindings) = $session->decode_get_response ($response);
	@next_oids = ();

	foreach $base_oid (@base_oids) {
	    ($binding,$bindings) = decode_sequence ($bindings);
	    ($oid,$value) = decode_by_template ($binding, "%O%@");
	    last ROW_LOOP
		unless BER::encoded_oid_prefix_p ($base_oid, $oid);
	    push @next_oids, $oid;
	    print pretty_print ($value);
	    print ' [',pretty_print ($oid), "]" if $print_oids_p;
	    print "\n";
	}
    } else {
	die "No response received.\n";
    }
}

$session->close ();

1;

sub usage ($ )
{
    print STDERR "Usage: $0 hostname community\n";
    exit (1) if $_[0];
}
