package Net::DNS::Utility;

use 5.006001;
use strict;
use warnings;
use Debug;
use Net::IPv6Address;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Net::DNS::Utility ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.02';

# Preloaded methods go here.

my $package = __PACKAGE__;
my $logger = new Debug();

my $prefixlen = undef;
my $length = undef;
my $type = "ip6.arpa";
my $maxsections = 8;
my $debug = 0;
my $dnsserver = "bind";
my $ttl = 3600;
my $serialno = 0;
my $refresh = "1H";
my $retry = "15M";
my $expiry = "1D";
my $minimum = "12H";
my $nameserver = "ns1.example.com.";
my $emailaddr = "root.example.com";
my $allowtransfer = "any"; 
my $allowupdate = "none";

sub new {
	my $class = shift;
	my $self = {};
	my $addressLength = shift;
	
	# $logger->initialize();
	
	$self->{'ADDRESSLENGTH'} = $addressLength if defined $addressLength;

	bless $self, $class;
	return $self;
}

# addressLength() - use this function to set the address/length attibute of this object.  This would be used to override the address/length attribute that is set when
#			  constructed or if no address/length was supplied when the object was constructed.  Address/length passed in or if no argument specified currently
#			  set address/length attribute is returned.
sub addressLength() {
	my $self = shift;
	my $addressLength = shift || $self->{'ADDRESSLENGTH'};
	
	$self->{'ADDRESSLENGTH'} = $addressLength if defined $addressLength;
		
	return $self->{'ADDRESSLENGTH'};
}

# loadDebug() - this routine accepts a Debug.pm object to facilitate initialization of the debugging
sub loadDebug() {
	my $self = shift;
	my $debug = shift;
	
	$logger = bless $debug, "Debug";
}

# createIp6ReverseZone() - accepts two strings one prefix and one prefix length.  A string representation of the valid reverse zone is returned as a string.
#						   The prefix must be fully uncompressed to ensure creation of a proper IPv6 reverse zone.
sub createIp6ReverseZone() {
		my $self = shift;
        my $prefix = shift;
        my $prefixlen = shift;
        my $revprefix = undef;
        my $revprefixlen = undef;
        my @revprefixarray = undef;
        my $revzonename = undef;
	
        $prefix =~ s/://g;
		
        $logger->message("Processing prefix $prefix");
		
		$revprefix = reverse($prefix);
        $logger->message("Prefix reversed $revprefix");
		
		$revprefixlen = length($revprefix);
        @revprefixarray = split(//, $revprefix);
		
        foreach my $x (@revprefixarray) {
                # $logger->message("$x");
                $revzonename .= $x;
                $revzonename .= ".";
        }
		
        $revzonename .= "ip6.arpa";
        $logger->message("Reverse zone $revzonename");
		
        if($dnsserver eq "bind") {
				# $logger->message("$revzonename, $prefix, $prefixlen");
				# $logger->message("$revzonename, $prefix, $prefixlen");
        } else {
			$logger->message("Unsupported implementation of DNS");
		}
							
		return $revzonename;
}

# createBindNamedConf() - used to create the stanza required for the provided IPv6 reverze zone.
sub createBindNamedConf() {
		my $self = shift;
        my $ip6arpa = shift;
        my $strippedprefix = shift;
        my $prefixlen = shift;

        print STDOUT "########################################################\n";
        print STDOUT "\; copy the following lines and paste into named.conf\n";
        print STDOUT "zone \"$ip6arpa\" IN \{ \n";
        print STDOUT "\ttype master\;\n";
        print STDOUT "\tallow-transfer \{ $allowtransfer\; \}\;\n";
        print STDOUT "\tallow-update \{ $allowupdate\; \}\;\n";
        print STDOUT "\tfile \"db.$strippedprefix-$prefixlen\"\;\n";
        print STDOUT "\}\;\n";
        print STDOUT "########################################################\n";
}

# createBindNamedDb() - used to create an exmaple ISC BIND DB file for the supplied IPv6 reverse zone.
sub createBindNamedDb() {
		my $self = shift;
        my $ip6arpa = shift;
        my $strippedprefix = shift;
        my $prefixlen = shift;
        my $dbfile = "db.$strippedprefix-$prefixlen";

        $logger->message("[create_nameddb]:dbfile=$dbfile");

        open(NDB, ">$dbfile") || &log("[create_nameddb]:error opening $dbfile:$1");
        print NDB "\; named zone file for $dbfile\n";
        print NDB "\$TTL $ttl\n";
        print NDB "\$ORIGIN $ip6arpa.\n";
        print NDB "\@   IN      SOA     $nameserver $emailaddr \( \n";
        print NDB "\t\t$serialno \; serial number\n";
        print NDB "\t\t$refresh \; refresh\n";
        print NDB "\t\t$retry \; retry\n";
        print NDB "\t\t$expiry \; expiry\n";
        print NDB "\t\t$minimum \) \; minimum\n";
        print NDB "\tIN NS\t$nameserver\n";
        print NDB "\$ORIGIN $ip6arpa.\n";
        print NDB "\; insert PTR records here, for example\n";
        print NDB "\; e.f.a.c.f.e.e.b.d.a.e.d.d.c.b.a   IN      PTR     foo.example.com.\n";
        close(NDB);
}

# createPtrData() - used to generate the interface portion of a PTR record based on prefix and prefix length that have been provided.
#					A string is returned.
sub createPtrData() {
	# returns two values reversed portion of IPv6 address that is required based on prefix length and FQDN
	my $self = shift;
	my $interface = shift;
	my $s_rInterface = undef;
	my $s_rInterfaceFormatted = undef;
	my $i_interfaceLen = undef;
	my @a_interface = undef;
	
	$s_rInterface = reverse($interface);
	$logger->message("Interface reversed $s_rInterface");
	
	$i_interfaceLen = length($s_rInterface);
	@a_interface = split(//, $s_rInterface);
							
	foreach my $x (@a_interface) {
		$s_rInterfaceFormatted .= $x;
		$s_rInterfaceFormatted .= ".";
	}
	
	return $s_rInterfaceFormatted;
}

# parse() -
sub parse() {
		my $self = shift;
        my $prefixlen = shift;
		
		$logger->message("Processing $prefixlen");
		
        (my $p, my $l) = split(/\//,$prefixlen);
			
		$logger->message("Returning prefix=$p, length=$l");
		
        return $p, $l;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Net::DNS::Utility - Perl extension that provides some basic DNS utility functions.  At this time most are related to IPv6.

=head1 SYNOPSIS

  use Net::DNS::Utility;
  
=head1 DESCRIPTION

Net-DNS-Utility provides some basic functionality for the creation and management of DNS data.
Many of the routines at this time are focused on IPv6.

new()
Create a new Net::DNS::Utility object.

my $dnsUtil = new Net::DNS::Utility();

new(STRING)
Create a new Net::DNS::Utility object.

my $dnsUtil = new Net::DNS::Utility("2001:0db8:abcd:1234::1/64");

STRING is an IPv6 address and prefix length.

addressLength()
This function is used to set the address/length attibute of this object.  This would be used to override the address/length attribute that is set when
constructed or if no address/length was supplied when the object was constructed.  Address/length passed in or if no argument specified currently
set address/length attribute is returned as a string.

my $dnsUtil = new Net::DNS::Utility();
$dnsUtil->addressLength("2001:0db8::/32");

loadDebug()
Accepts a Debug.pm object to facilitate initializa-
tion of the debugging

use Debug;
use Net:DNS::Utility;

my $debug = new Debug; my $IPv6Address = new Net::IPv6Address();
$IPv6Address->loadDebug($debug);

Debug.pm is a copy of valid Debug.pm object

createIp6ReverseZone(STRING1, STRING2)
Accepts two strings one prefix and one prefix length.  A string representation of the valid reverse zone is returned as a string.
The prefix must be fully uncompressed to ensure creation of a proper IPv6 reverse zone.

Net::IPv6Address can be used to facilitate the generation of a properly formatted prefix and prefix length for use with this function.

use Net::IPv6Address;
use Net::DNS::Utility;
use Debug;

my $prefix = "2001:0db8:1234:5678:90ef:0000:0000:ffff";
my $prefixlen = 64;

my $debug = new Debug();
my $dnsUtil = new Net::DNS::Utility();
my $IPv6address = new Net::IPv6Address($prefix, $prefixlen);

$dnsUtil->loadDebug($debug);
my $ip6reverse = $dnsUtil->createIp6ReverseZone($IPv6address->prefix, $IPv6address->addressLength);

createBindNamedConf(STRING1, STRING2, STRING3)
Used to create the stanza required for the provided IPv6 reverze zone.
Output is written to STDOUT.

STRING1 is the IPv6 reverse zone, STRING2 is the prefix, and STRING3 is the prefix length.

my $prefix = "2001:0db8:1234:5678:90ef:0000:0000:ffff";
my $prefixlen = 64;

my $debug = new Debug();
my $dnsUtil = new Net::DNS::Utility();
my $IPv6address = new Net::IPv6Address($prefix, $prefixlen);

my $ip6reverse = $dnsUtil->createIp6ReverseZone($IPv6address->prefix, $IPv6address->addressLength);
$dnsUtil->createBindNamedConf($ip6reverse, $IPv6address->prefix, $IPv6address->addressLength);

createBindNamedDb(STRING1, STRING2, STRING3)
Used to create an exmaple BIND DB file for the supplied IPv6 reverse zone.
A file is created with an automatically generated file name based on prefix and prefix length.

STRING1 is the IPv6 reverse zone, STRING2 is the prefix, and STRING3 is the prefix length.

my $prefix = "2001:0db8:1234:5678:90ef:0000:0000:ffff";
my $prefixlen = 64;

my $debug = new Debug();
my $dnsUtil = new Net::DNS::Utility();
my $IPv6address = new Net::IPv6Address($prefix, $prefixlen);

my $ip6reverse = $dnsUtil->createIp6ReverseZone($IPv6address->prefix, $IPv6address->addressLength);
$dnsUtil->createBindNamedDb($ip6reverse, $IPv6address->prefix, $IPv6address->addressLength);

createPtrData(STRING1)
Used to generate the interface portion of a PTR record based on prefix and prefix length that have been provided.
A string is returned.

STRING1 is the interface identifier portion of the IPv6 address.

my $prefix = "2001:0db8:1234:5678:90ef:0000:0000:ffff";
my $prefixlen = 64;

my $debug = new Debug();
my $dnsUtil = new Net::DNS::Utility();
my $IPv6address = new Net::IPv6Address($prefix, $prefixlen);

$dnsUtil->createPtrData($IPv6address->interface);

=head2 EXPORT

None by default.

=head1 SEE ALSO

N/A

=head1 AUTHOR

JJMB, E<lt>jjmb@jjmb.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by JJMB

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
