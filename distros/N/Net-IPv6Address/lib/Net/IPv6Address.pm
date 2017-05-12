package Net::IPv6Address;

use 5.006001;
use strict;
use warnings;
use Debug;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Net::IPv6Address ':all';
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

sub new {
	my $class = shift;
	my $address = shift || undef;
	my $length = shift || 64;
	my $self = {};
	
	$self->{'ADDRESS'} = $address if defined $address;
	$self->{'ADDRESSLENGTH'} = $length if defined $length;
	
	# $logger->initialize();
	
	bless $self, $class;
	
	if(($self->{'ADDRESS'})&&($self->{'ADDRESSLENGTH'})) {
		$self->decompressAddress();
	}
	
	return $self;
}

# loadDebug() - this routine accepts a Debug.pm object to facilitate initialization of the debugging
sub loadDebug() {
	my $self = shift;
	my $debug = shift;
	
	$logger = bless $debug, "Debug";
	# $logger->initialize();
}

# decompressAddress() - fully uncompresses an IPv6 address so that all 128 bits are displayed and returned.
sub decompressAddress() {
	my $self = shift;
	my @address = undef;
	my @uAddress = undef;
	my $s_uAddress = undef;
	my $tmp = undef;
	
	@address = split(/:/,$self->{'ADDRESS'});
	my $address_len = scalar(@address);
	
	$logger->message("Decompressing $self->{'ADDRESS'}");
	
	if($address_len < 8) {
		
		my $iteration = 0;
		my @t_address = undef;
		my $found_empty = 0;
		$logger->message("Address provided is abbreviated, performing additional processing");
		foreach my $a (@address) {
			# $logger->message("address_len = $address_len, iteration = $iteration, a = $a");
			if($iteration < 7) {
				if((!$found_empty)&&($a ne "")) {
					# $logger->message("Found no empties, copying data to temporary array");
					$t_address[$iteration] = $a;
					$iteration++;
					next;
				}
				# handle the first missing portion of the address
				if($a eq "") {
					# $logger->message("Found first empty");
					$found_empty = 1;
					$t_address[$iteration] = 0;
					# $logger->message("Setting chunk to 0");
					$iteration++;
					next;
				}
				# handle when a non-empty portion follows and missing portions
				if(($found_empty)&&($a)) {
					# $logger->message("Already found an empty, but the chunk contains data");
					$t_address[7] = $a;
					$iteration++;
					next;
				}
			}
			$iteration++;
		}
		
		my $t_address_len = scalar(@t_address);
		my $need_to_pad = 8 - $t_address_len;
		my $pad_counter = undef;
		# $logger->message("t_address_len = $t_address_len, need_to_pad = $need_to_pad, pad_counter = $pad_counter");
		if($need_to_pad > 0) {
		$logger->message("Still need to pad $need_to_pad positions");
			for($pad_counter = 0; $pad_counter < $need_to_pad; $pad_counter++) {
				# $logger->message("pad_counter = $pad_counter, need_to_pad = $need_to_pad");
				$tmp = $t_address_len+$pad_counter;
				$t_address[$tmp] = 0;
				# $logger->message("Set t_address[$tmp] to 0");
			}
		}
		
		@address = @t_address;
		$logger->message("Unabbreviation is complete");
	}
	
	$logger->message("Decompressing address...");
	
	$tmp = undef;
	my $chunk_len = undef;
	my $c = 0;
	my $x = undef;
	
	foreach my $y (@address) {
		if(!$y) {
			$y = 0;
		}
		$x = $self->trim($y);
		# $x = $y;
		$chunk_len = length($x);	
		# $logger->message("original data $x, length $chunk_len, iteration $c");
		
		if((length($x)) < 4) {
			# $tmp = printf("%04S", $x);
			$tmp = sprintf("%04s", $x);
		} else {
			# $logger->message("chunk is uncompressed already") if ($verbose);
			$tmp = $x;
			# $logger->message("chunk is uncompressed already");
		}
		
		# $logger->message("[debug]:uncompressed chunk $tmp");
		# $logger->message("setting uAddress[$c] -> $tmp");
		$uAddress[$c] = $tmp;
		$c++;
	}

	my $uAddress_len = scalar(@uAddress);
	# $logger->message("uAddress_len, $uAddress_len");
	
	my $buf = undef;
	foreach my $z(@uAddress) {
		$s_uAddress .= $z;
		# $logger->message("contents of z, $z");
	}
	
	# $logger->message("uncomressed address, $s_uAddress");
	$logger->message("Decompressed address, @uAddress($s_uAddress)");
	
	$self->{'D_ADDRESS'} = $s_uAddress;
	
	return $self->{'D_ADDRESS'};
}

# address() - use this function to set the address attibute of this object.  This would be used to override the address attribute that is set when
#			  constructed or if no address was supplied when the object was constructed.  Address passed in or if no argument specified currently
#			  set address attribute is returned.
sub address() {
	my $self = shift;
	my $address = shift;
	
	$self->{'ADDRESS'} = $address if defined $address;
		
	$self->decompressAddress();
	
	return $self->{'D_ADDRESS'};
}

# addrressLength() -  use this function to set the length attibute of this object.  This would be used to override the length attribute that is set when
#			  constructed or if no length was supplied when the object was constructed.  Length passed in or if no argument specified currently
#			  set length attribute is returned.
sub addressLength() {
	my $self = shift;
	my $addressLength = shift || $self->{'ADDRESSLENGTH'};
	
	$self->{'ADDRESSLENGTH'} = $addressLength if defined $addressLength;
		
	return $self->{'ADDRESSLENGTH'};	
}

# prefix() - use this function to retrieve the prefix for the supplied address given the prefix length that has been povided.
sub prefix() {
	my $self = shift;
	my $maxPrefixLength = 128;
	my $diffLength = undef;
	
	$diffLength = $maxPrefixLength - $self->{'ADDRESSLENGTH'};
	
	$logger->message("Prefix length = $self->{'ADDRESSLENGTH'}");
	
	$self->hexToBin();
	
	$self->{'PREFIXBITS'} = substr $self->{'B_ADDRESS'}, 0, $self->{'ADDRESSLENGTH'};
	$self->{'PREFIX'} = $self->binToHex($self->{'PREFIXBITS'});
	$self->{'INTERFACEBITS'} = substr $self->{'B_ADDRESS'}, $self->{'ADDRESSLENGTH'}, $diffLength;
	# $self->{'INTERFACE'} = $self->binToHex($self->{'INTERFACEBITS'});
	
	return $self->{'PREFIX'};
}

# interface() - use this function to retrieve the interface identifier for the supplied address given the prefix length that has been povided.
sub interface() {
	my $self = shift;
	my $maxPrefixLength = 128;
	my $diffLength = undef;
	
	$diffLength = $maxPrefixLength - $self->{'ADDRESSLENGTH'};
	
	$logger->message("Prefix length = $diffLength");
	
	$self->hexToBin();
	
	$self->{'PREFIXBITS'} = substr $self->{'B_ADDRESS'}, 0, $self->{'ADDRESSLENGTH'};
	# $self->{'PREFIX'} = $self->binToHex($self->{'PREFIXBITS'});
	$self->{'INTERFACEBITS'} = substr $self->{'B_ADDRESS'}, $self->{'ADDRESSLENGTH'}, $diffLength;
	$self->{'INTERFACE'} = $self->binToHex($self->{'INTERFACEBITS'});
	
	return $self->{'INTERFACE'};	
}

# formatAddress() - properly formats an IPv6 address, if the address is compressed or abbreviated it will be uncompressed and unabbreviated
#					then formatted and returned.
sub formatAddress() {
	my $self = shift;
	my $s_unformattedAddressLen = undef;
	my @a_unformattedAddress = undef;
	my $s_formattedAddress = undef;
	
	$logger->message("Formatting $self->{'D_ADDRESS'}");
		
	$s_unformattedAddressLen = length($self->{'D_ADDRESS'});
    @a_unformattedAddress = split(//, $self->{'D_ADDRESS'});
		
	my $i = 0;
	my $c = 0;
	foreach my $x (@a_unformattedAddress) {
			# $logger->message("Processing $x($i)[$c]");
			if($i eq 3) {
				$s_formattedAddress .= $x;
				$s_formattedAddress .= ":" unless ($c >= 7);
				$i = 0;
				$c++;
			# $logger->message("Added colon, reset counter to 1, c = $c");
			} else {
				$s_formattedAddress .= $x;
				$i++;
			}
			# $i++;
	}
								  
	$self->{'F_ADDRESS'} = $s_formattedAddress;
	
	return $self->{'F_ADDRESS'};
}

# toString() - converts an IPv6 address array to a string.  The string is returned.
sub toString() {
	my $self = shift;
	my @a_address = shift;
	my $s_address = undef;
	
	my $i = 0;
	my $c = 0;
	foreach my $x (@a_address) {
		# $logger->message("Processing $x($i)[$c]");
		if($i eq 3) {
			$s_address .= $x;
			$s_address .= ":" unless ($c >= 7);
			$i = 0;
			$c++;
			# $logger->message("Added colon, reset counter to 1, c = $c");
		} else {
			$s_address .= $x;
			$i++;
		}
		# $i++;
	}
	
	return $s_address;
}

# hexToBin() - converts a hexidecimal representation of an IPv6 address to its binary form.  The binary representation is returned.
sub hexToBin() {
	my $self = shift;
	my $address = shift;
    my $i = 0;
    my $j = 0;
    my $binaryprefix = undef;
	
	if($address) {
		$logger->message("Converting hex to binary, $address");
		
		my @zzz = split(//, $address);
		for my $y (@zzz) {
			# $logger->message("Processing 4 bit element[$j] -> $y");
			# my $buf = sprintf("%04i", $y);
			my $buf = hex($y);
			# $logger->message("Hex representation of $y -> $buf");
			my $buf2 = sprintf("%04b", $buf);
			$binaryprefix .= $buf2;
			# $logger->message("Binary representation of $buf -> $buf2");
			$j++;
		}
		$i++;
						
		# my $binaryprefixlen = length($binaryprefix);
		# $logger->message("Length of binary data, $binaryprefixlen");
						
		$logger->message("Returning binary representation, $binaryprefix");
		
		return $binaryprefix;		
	} else {
		$logger->message("Converting hex to binary, $self->{'D_ADDRESS'}");
		
		my @zzz = split(//, $self->{'D_ADDRESS'});
		for my $y (@zzz) {
			# $logger->message("Processing 4 bit element[$j] -> $y");
			# my $buf = sprintf("%04i", $y);
			my $buf = hex($y);
			# $logger->message("Hex representation of $y -> $buf");
			my $buf2 = sprintf("%04b", $buf);
			$binaryprefix .= $buf2;
			# $logger->message("Binary representation of $buf -> $buf2");
			$j++;
		}
		$i++;
		
		# my $binaryprefixlen = length($binaryprefix);
		# $logger->message("Length of binary data, $binaryprefixlen");
			
		$logger->message("Returning binary representation, $binaryprefix");
							
		$self->{'B_ADDRESS'} = $binaryprefix;
						
		return $self->{'B_ADDRESS'};
	}
}

# binToHex() - converts the binary representation of an IPv6 address to it hexidecimal form.  The uncompresse and unabbbreviated hexidecimal
#		       representation is returned.
sub binToHex() {
	my $self = shift;
	my $bAddress = shift;
    my $i = 0;
    my $j = 0;
    my $hex = undef;
	
	if($bAddress) {
		my @bits = split(//, $bAddress);
						 
		my $bitslen = length($bAddress);
		my $offset = 0;
		my $length = 4;
		my $buf1 = undef;
		my $buf2 = undef;
						 
		$logger->message("Converting binary to hex, $bAddress");
						 
		while($offset < ($bitslen)) {
			# $logger->message("($i)offset = $offset, bitslen = $bitslen");
			$buf1 = substr($bAddress, $offset, $length);
			$buf2 = sprintf('%x', oct("0b$buf1"));
			$hex .= $buf2;
			# $logger->message("buf1 = $buf1, buf2 = $buf2");
			$offset = $offset+4;
			$i++
		}
						 				 
		$logger->message("Returning hexidecimal representation, $hex");
						 
		return $hex;
	} else {
		my @bits = split(//, $self->{'B_ADDRESS'});
		
		my $bitslen = length($self->{'B_ADDRESS'});
		my $offset = 0;
		my $length = 4;
		my $buf1 = undef;
		my $buf2 = undef;
		
		$logger->message("Converting binary to hex, $self->{'B_ADDRESS'}");
		
		 while($offset < ($bitslen)) {
			# $logger->message("($i)offset = $offset, bitslen = $bitslen");
			$buf1 = substr($self->{'B_ADDRESS'}, $offset, $length);
			$buf2 = sprintf('%x', oct("0b$buf1"));
			$hex .= $buf2;
			# $logger->message("buf1 = $buf1, buf2 = $buf2");
			$offset = $offset+4;
			$i++
		}
						 
		$self->{'H_ADDRESS'} = $hex;

		$logger->message("Returning hexidecimal representation, $self->{'H_ADDRESS'}");
		
		return $self->{'H_ADDRESS'};
	}
}

# trim() - removes leading whitespace, tabs, spaces, carriage returns, and line feeds.  The trimmed data is returned.
sub trim() {
		my $self = shift;
        my $buf = shift;
		
		if($buf) {
			$buf =~ s/\+s//;
			$buf =~ s/\r\n//;
			$buf =~ s/\t//;
			$buf =~ s/\s+//;
		}
		
        return $buf;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Net::IPv6Address - Perl extension that provides a variety of use IPv6 address functions

=head1 SYNOPSIS

  use Net::IPv6Address;

=head1 DESCRIPTION

Net::IPv6Address provide a number of routines that allow for the manipulation and presentation of IPv6 addresses.

new()
Create a new Net::IPv6Address object.
	
my $IPv6Address = new Net::IPv6Address();

new(STRING1, INTEGER)
Create a new Net::IPv6Address object.
	
my $IPv6Address = new Net::IPv6Address("2001:0db8:abcd::1", 64);

STRING1 is an IPv6 address, INTEGER is the length of the prefix

loadDebug(Debug.pm)
Accepts a Debug.pm object to facilitate initialization of the debugging

use Debug;
use Net:IPv6Address;

my $debug = new Debug;
my $IPv6Address = new Net::IPv6Address();
$IPv6Address->loadDebug($debug);

Debug.pm is a copy of valid Debug.pm object

decompressAddress()
Processes the address supplied when constructing a Net::IPv6Address object.  Returns a STRING representing the fully decompressed
and unabbeviated address in an unformatted state, ie no colons just hexidecimal characters.

my $unformattedAddress = $IPv6Address->decompressAddress();

address(STRING)
Accepts a STRING representing the IPv6 address that the rest of the module operating on; the address is automatically decompressed.
With no arguments this function will return the address that was last set.

my $address = $IPv6Address->address();

$IPv6Address->address("2001:db8:1234::1");

addressLength(INTEGER)
Accepts a INTEGER representing the IPv6 prefix length for the supplied address.
With no arguments this function will return the prefix length that was last set.

my $length = $IPv6Address->addressLength();

$IPv6Address->addressLength(48);

prefix()
This function retrieves the prefix for the supplied address given the prefix length.
A string will be returned.

my $IPv6Address = new Net::IPv6Address("2001:0db8:abcd::1", 64);
my $prefix = $IPv6Address->prefix();

interface()
This function retrieves the interface identifier for the supplied address given the prefix length.
A string will be returned.

my $IPv6Address = new Net::IPv6Address("2001:0db8:abcd::1", 64);
my $interface = $IPv6Address->interface();

formatAddress()
Properly formats the IPv6 address, if the address is compressed or abbreviated it will be uncompressed and unabbreviated then formatted and returned.
A string is returned.

my $IPv6Address = new Net::IPv6Address("2001:0db8:abcd::1", 64);
my $formattedAddress = $IPv6Address->formatAddress();

hexToBin()
Converts a hexidecimal representation of an IPv6 address to its binary form.
The binary representation is returned in string format.

my $IPv6Address = new Net::IPv6Address("2001:0db8:abcd::1", 64);
my $binaryAddress = $IPv6Address->hexToBin();

binToHex()
converts the binary representation of an IPv6 address to it hexidecimal form.
The uncompresse and unabbbreviated hexidecimal representation is returned as a string.

my $IPv6Address = new Net::IPv6Address("2001:0db8:abcd::1", 64);
my $hexAddress = $IPv6Address->binToHex();

trim()
Removes leading whitespace, tabs, spaces, carriage returns, and line feeds.  The trimmed data is returned.

my $IPv6Address = new Net::IPv6Address("2001:0db8:abcd::1", 64);
my $tString = $IPv6Address->trim(" 2001:0db8:: ");

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
