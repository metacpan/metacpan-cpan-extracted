#
# Net::PcapUtils
#
# Some code to abstract away some of the messier parts of using the
# Net::Pcap library.  The idea is to be able to write "one-liner" type
# scripts for packet capture without getting bogged down in the
# initialisation code. 
#
# Please send comments/suggestions to tpot@acsys.anu.edu.au
#
# $Id: PcapUtils.pm,v 1.5 1999/04/07 01:33:24 tpot Exp $
#

package Net::PcapUtils;

#
# Copyright (c) 1995,1996,1997,1998,1999 ANU and CSIRO on behalf of
# the participants in the CRC for Advanced Computational Systems
# ('ACSys').
#
# ACSys makes this software and all associated data and documentation
# ('Software') available free of charge.  You may make copies of the 
# Software but you must include all of this notice on any copy.
#
# The Software was developed for research purposes and ACSys does not
# warrant that it is error free or fit for any purpose.  ACSys
# disclaims any liability for all claims, expenses, losses, damages
# and costs any user may incur as a result of using, copying or
# modifying the Software.
#

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

my $myclass;
BEGIN {
    $myclass = __PACKAGE__;
    $VERSION = "0.01";
}
sub Version () { "$myclass v$VERSION" }

BEGIN {
    @ISA = qw(Exporter);

# Items to export into callers namespace by default
# (move infrequently used names to @EXPORT_OK below)

    @EXPORT = qw(
    );

# Other items we are prepared to export if requested

    @EXPORT_OK = qw(
    );

# Tags:

    %EXPORT_TAGS = (
    ALL         => [@EXPORT, @EXPORT_OK],
);

}

use Net::Pcap 0.03;  # Not all functions implemented in previous Net::Pcap's

#
# Set up Net::Pcap to capture packets live from the wire, or play back
# packets from a savefile.  Call a Perl subroutine for each packet
# received.
#

sub loop {
    my($callback, @rest) = @_;
    my($errbuf, $bpf_prog);

    # Default arguments

    my %args = (
        SNAPLEN => 100,         # Num bytes to capture from packet
	PROMISC => 1,           # Operate in promiscuous mode?
        TIMEOUT => 1000,        # Read timeout (ms)
        NUMPACKETS => -1,       # Pkts to read (-1 = loop forever)
        FILTER => '',           # Filter string
	USERDATA => '',         # Passed as first arg to callback fn
	SAVEFILE => '',         # Default save file
        DEV => '',              # Network interface to open
	mode => '',             # Internal variable
        @rest);

    # Get pcap device if not specified

    if ($args{DEV} eq '') {
	$args{DEV} = Net::Pcap::lookupdev(\$errbuf);
	return $errbuf, unless $args{DEV};
    }

    # Get pcap network/netmask

    my($net, $mask);
    return $errbuf, if (Net::Pcap::lookupnet($args{DEV}, \$net, \$mask,
					     \$errbuf) == -1);    
    #
    # Open in specified mode
    #

    my $pcap_desc;

    if ($args{SAVEFILE} eq '') {

	# Open interface "live"

	$pcap_desc = Net::Pcap::open_live($args{DEV}, $args{SNAPLEN},
					  $args{PROMISC},
					  $args{TIMEOUT},
					  \$errbuf);

	return $errbuf, unless $pcap_desc;

    } else {

	# Open saved file

	$pcap_desc = Net::Pcap::open_offline($args{SAVEFILE}, \$errbuf);

	return $errbuf, unless $pcap_desc;

    }
    
    # Set up filter, if defined
    
    if ($args{FILTER} ne '') {
    	return(Net::Pcap::geterr($pcap_desc)), 
	  if ((Net::Pcap::compile($pcap_desc, \$bpf_prog, 
				  $args{FILTER}, 0, $mask) == -1) ||
	      (Net::Pcap::setfilter($pcap_desc, $bpf_prog) == -1));
    } 

    # Start looping

    if ($args{mode} ne "setup") {

	# Call loop function

	my $result = Net::Pcap::loop($pcap_desc, $args{NUMPACKETS}, 
				     \&$callback, $args{USERDATA});
        Net::Pcap::close($pcap_desc);

	if ($result == 0) {
	    return "";
	} else {
	    return(Net::Pcap::geterr($pcap_desc));
	}

    } else {

	# Just return the pcap descriptor is setup-only mode

	return $pcap_desc;
    }
}

# Open a live network interface or save file and return the pcap
# descriptor.  Takes the same arguments as Net::PcapUtils::loop()
# function.

sub open {
    return loop(undef, @_, mode => 'setup');
}

# Return the next packet available on the specified packet capture
# descriptor.

sub next {
    my($pcap_t) = @_;
    my($pkt, %hdr);

    while(!($pkt = Net::Pcap::next($pcap_t, \%hdr))) {
	# No packet available
    }

    return ($pkt, %hdr);
}

#
# Module initialisation
#

1;

# autoloaded methods go after the END token (&& pod) below

__END__

=head1 NAME

C<Net::PcapUtils> - Utility routines for Net::Pcap module

=head1 SYNOPSIS

  require Net::Pcap 0.03;
  use Net::PcapUtils;

  # Call function for all packets received

  Net::PcapUtils::loop(\&callbackfn, [optional args]);

  # Return the next packet available on the interface

  ($pkt, %hdr) = Net::PcapUtils::next($pcap_t);

  # Open a network device for processing

  $pcap_t = Net::PcapUtils::open([optional args]);

=head1 DESCRIPTION

Net::PcapUtils is a module to sit in front of Net::Pcap in order to
hide some of the pcap(3) initialisation by providing sensible
defaults.  This enables a programmer to easily write small, specific
scripts for a particular purpose without having to worry about too
many details.

The functions implemented in Net::PcapUtils are named after those in
Net::Pcap.  The B<loop> function sits in a loop and executes a
callback for each packet received, while B<next> retrieves the next
packet from the network device, and B<open> returns an opened packet
descriptor suitable for use with other Net::Pcap routines.

=head2 Functions

=over

=item B<Net::PcapUtils::loop(\&callback_fn, [ARG =E<gt> value]);>

Given a callback function and a list of optional named parameterss,
open a network interface, configure it, and execute the callback
function for each packet received on the interface.  If the SAVEFILE
parameter is present, a saved file of that name will be opened for
reading, else the network interface specified by the DEV parameter
will be opened.  If no saved file or device is specified, the
interface returned by Net::Pcap::lookupdev() is opened.

The optional arguments are those which are normally passed to the
pcap_open_live() function from the pcap(3) library.  Their defaults
are given below.

    my %args = (
        SNAPLEN => 100,         # Num bytes to capture from packet
	PROMISC => 1,           # Operate in promiscuous mode?
        TIMEOUT => 1000,        # Read timeout (ms)
        NUMPACKETS => -1,       # Pkts to read (-1 = loop forever)
        FILTER => '',           # Filter string
	USERDATA => '',         # Passed as first arg to callback fn
	SAVEFILE => '',         # Default save file
	DEV => '',              # Network interface to open
        );

Consult the documentation for the pcap(3) library for more details on
the nature of these parameters.

On error, this function returns an error string describing the error.
An empty string is returned upon success.

=item B<Net::PcapUtils::open([ARG =E<gt> value]);>

Return a packet capture descriptor.  The optional arguments passed to
this function are the same as those which can be passed to
Net::PcapUtils::loop().

If the open() command was successful, it returns a reference to a
packet capture descriptor, else a string containing an error message.

=item B<Net::PcapUtils::next($pcap_t);>

Return the next packet available on the interface specified by packet
capture descriptor $pcap_t.  This may be obtained from the
Net::PcapUtils::open() function, Net::Pcap::open_live() or
Net::Pcap::open_offline().

=back

=head1 EXAMPLE

The following script prints a message for each IP packet received.

  #!/usr/bin/perl -w

  use strict;
  use Net::PcapUtils;

  sub process_pkt {
      print("packet\n");
  }

  Net::PcapUtils::loop(\&process_pkt, FILTER => 'ip');

=head1 SEE ALSO

The C<Net::Pcap> module for XS bindings to the C<pcap(3)> library.

The pcap library is available from ftp://ftp.ee.lbl.gov/libpcap.tar.Z

=head1 COPYRIGHT

  Copyright (c) 1995,1996,1997,1998,1999 ANU and CSIRO on behalf of
  the participants in the CRC for Advanced Computational Systems
  ('ACSys').

  ACSys makes this software and all associated data and documentation
  ('Software') available free of charge.  You may make copies of the 
  Software but you must include all of this notice on any copy.

  The Software was developed for research purposes and ACSys does not
  warrant that it is error free or fit for any purpose.  ACSys
  disclaims any liability for all claims, expenses, losses, damages
  and costs any user may incur as a result of using, copying or
  modifying the Software.

=head1 AUTHOR

Tim Potter E<lt>tpot@acsys.anu.edu.auE<gt>

=cut

# any real autoloaded methods go after this line
