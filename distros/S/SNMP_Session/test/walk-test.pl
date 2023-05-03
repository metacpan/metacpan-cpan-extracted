#!/usr/local/bin/perl -w
###
### Use map_table to list the ipAddrTable.

use strict;
use BER;
use SNMP_Session;

my $version = '1';

my $ifDescr		= [1,3,6,1,2,1,2,2,1,2];
my $ipAdEntAddr		= [1,3,6,1,2,1,4,20,1,1];
my $ipAdEntIfIndex	= [1,3,6,1,2,1,4,20,1,2];
my $ipAdEntNetmask	= [1,3,6,1,2,1,4,20,1,3];
my $ipAdEntBcastAddr	= [1,3,6,1,2,1,4,20,1,4];
my $ipAdEntReasmMaxSize = [1,3,6,1,2,1,4,20,1,5];

### If this is zero, the function pretty_net_and_mask will always
### print the prefix length in classless notation
### (e.g. 130.59.0.0/16), even if the prefix length is the classful
### default one for the address range in question.
###
my $use_classful_defaults = 0;

my $max_repetitions = 0;

while (defined $ARGV[0] && $ARGV[0] =~ /^-/) {
    if ($ARGV[0] =~ /^-v/) {
	if ($ARGV[0] eq '-v') {
	    shift @ARGV;
	    usage (1) unless defined $ARGV[0];
	} else {
	    $ARGV[0] = substr($ARGV[0], 2);
	}
	if ($ARGV[0] eq '1') {
	    $version = '1';
	} elsif ($ARGV[0] eq '2c') {
	    $version = '2c';
	} else {
	    usage (1);
	}
    } elsif ($ARGV[0] =~ /^-m/) {
	if ($ARGV[0] eq '-m') {
	    shift @ARGV;
	    usage (1) unless defined $ARGV[0];
	} else {
	    $ARGV[0] = substr($ARGV[0], 2);
	}
	if ($ARGV[0] =~ /^[0-9]+$/) {
	    $max_repetitions = $ARGV[0];
	} else {
	    usage (1);
	}
    } elsif ($ARGV[0] eq '-h') {
	usage (0);
	exit 0;
    } else {
	usage (1);
    }
    shift @ARGV;
}
my $host = $ARGV[0] || die "usage: $0 target [community]";
my $community = $ARGV[1] || 'public';
my $session =
    ($version eq '1' ? SNMPv1_Session->open ($host, $community, 161)
     : $version eq '2c' ? SNMPv2c_Session->open ($host, $community, 161)
     : die "Unknown SNMP version $version")
  || die "Opening SNMP_Session";
$max_repetitions = $session->default_max_repetitions
    unless $max_repetitions;
$session->default_max_repetitions ($max_repetitions);
my $if_descr = get_if_descrs ($session);

printf "%-18s %s\n", "IP address", "if#";
$session->map_table ([$ipAdEntIfIndex,
		      $ipAdEntNetmask, $ipAdEntBcastAddr,
		      $ipAdEntReasmMaxSize],
		     sub {
			 my ($index, $if_index, $netmask,
			     $bcast, $reasm) = @_;
			 map { defined $_ && ($_=pretty_print $_) }
			     ($if_index, $netmask,
			      $bcast, $reasm);
			 my $addr = $index;
			 printf "%-18s %-20s ",
				 pretty_net_and_mask ($addr, $netmask),
				 $if_descr->{$if_index} || '?';
			 if (defined $bcast) {
			     printf "%d", $bcast;
			 } else {
			     print "?";
			 }
			 print " ";
			 if (defined $reasm) {
			     printf "%6d", $reasm;
			 } else {
			     print "     ?";
			 }
			 print "\n";
		     });
$session->close ();

1;

sub netmask_to_prefix_length ($) {
    my ($mask) = @_;
    $mask = pack ("CCCC", split (/\./, $mask));
    $mask = unpack ("N", $mask);
    my ($k);
    for ($k = 0; $k < 32; ++$k) {
	if ((($mask >> (31-$k)) & 1) == 0) {
	    last;
	}
    }
    return $k;
}

sub pretty_net_and_mask ($$) {
    my ($net, $mask) = @_;
    my $prefix_length = netmask_to_prefix_length ($mask);
    my ($firstbyte) = split ('\.', $net);
    my $classful_prefix_length
	= $firstbyte < 128 ? 8
	    : $firstbyte < 192 ? 16
		: $firstbyte < 224 ? 24 : -1;
    ($use_classful_defaults
     && $prefix_length == $classful_prefix_length)
	? $net : $net.'/'.$prefix_length;
}

sub get_if_descrs ($) {
    my ($session) = @_;
    my %descrs = ();

    $session->map_table ([$ifDescr],
	 sub { my ($index, $descr) = @_;
	       $descrs{$index} = pretty_print ($descr);
	   });
    \%descrs;
}

sub usage ($) {
    warn <<EOM;
Usage: $0 [-v (1|2c)] [-m max] switch [community]
       $0 -h

  -h           print this usage message and exit.

  -v version   can be used to select the SNMP version.  The default
   	       is SNMPv1, which is what most devices support.  If your box
   	       supports SNMPv2c, you should enable this by passing "-v 2c"
   	       to the script.  SNMPv2c is much more efficient for walking
   	       tables, which is what this tool does.

  -m max       specifies the maxRepetitions value to use in getBulk requests
               (only relevant for SNMPv2c).

  switch       hostname or IP address of an LS1010 switch

  community    SNMP community string to use.  Defaults to "public".
EOM
    exit (1) if $_[0];
}
