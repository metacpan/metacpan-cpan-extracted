package Mnet::IP;

=head1 NAME

Mnet::IP - Parse ipv4 and ipv6 addresses

=head1 SYNOPSIS

 # refer to Mnet::IP::parse for all valid address input formats
 $address = "127.0.0.1"
 $address = "127.0.0.1/32"
 $address = "127.0.0.1/255.255.255.255"
 $address = "::1"
 $address = "::1/128"
 $address = "::127.0.0.1/96"
 $address = "/32"
 $address = "/255.255.255.255"

 # return sting of binary digits for input ipv4 or ipv6 address
 $binary = Mnet::IP::binary($address)

 # return cidr from input address, /mask is converted
 $cidr = Mnet::IP::cidr($address)

 # return ipv4 or ipv6 portion of address, removing any /cidr or /mask
 $ip = Mnet::IP::ip($address)

 # return ipv4 portion of input address, removing any /cidr or /mask
 $ipv4 = Mnet::IP::ipv4($address)

 # return ipv6 portion of input address, removing any /cidr
 $ipv6 = Mnet::IP::ipv6($address)

 # return mask from input address, /cidr is converted
 $mask = Mnet::IP::mask($address)

 # return network ip/cidr for input address
 $network = Mnet::IP::network($address)

 # return ipv4, ipv6, cidr and mask values for input address
 ($ipv4, $ipv6, $cidr, $mask) = Mnet::IP::parse($address)

 # return wildcard mask for /mask or /cidr of input address
 $wildcard = Mnet::IP::wildcard($address)

=head1 DESCRIPTION

The following terms are used in this module:

 address    ipv4 or ipv6 address, see below
 cidr       count of network bits, such as 32 for an ipv4 host
 ip         ipv4 or ipv6 address
 ipv4       ipv4 address, see below
 ipv6       ipv6 address, see below
 network    network ip/cidr, such as 192.168.1.0/24
 mask       ipv4 dotted decimal mask, such as 255.255.255.0
 wildcard   ipv4 acl wildcard mask, such as 0.0.0.255

Refer to the parse function below for examples of valid address values.

The Socket::inet_pton function used in this module requires perl 5.12 or newer.

=cut

# required modules
#   Socket::inet_pton requires perl 5.12
#       update Mnet.pm and this perldoc if changed
use warnings;
use strict;
use Mnet;
use Socket;
use 5.012;



sub binary {

=head2 $binary = Mnet::IP::binary($address)

Return binary string of zeros and ones for a valid input ipv4 or ipv6 address,
or undefined.

=cut

    # read input address
    my $address = shift // return undef;

    # init binary output value
    my $binary = undef;

    # parse input ipv4 or ipv6 address
    my ($ipv4, $ipv6) = Mnet::IP::parse($address);

    # return binary output for ipv4 addresses
    #   inet_pton failed on linux 5.12 and 5.14 tests, returning ipv6 binary
    $binary = unpack("B*", Socket::inet_aton("$ipv4")) if $ipv4;

    # return binary output for ipv6 addresses
    $binary = unpack("B*", Socket::inet_pton(AF_INET6, "$ipv6")) if $ipv6;

    # finished binary function, return binary
    return $binary;

}



sub cidr {

=head2 $cidr = Mnet::IP::cidr($address)

Return cidr from a valid input address containing a /cidr or /mask, or
undefined if no /cidr or /mask was specified.

=cut

    # read and parse address, return cidr value
    my $address = shift // return undef;
    my ($ipv4, $ipv6, $cidr, $mask) = Mnet::IP::parse($address);
    return $cidr;

}



sub ip {

=head2 $boolean = Mnet::IP::ip($address)

Return ipv4 or ipv6 portion from a valid input address, or undefined.

=cut

    # read and parse address, return ipv4 or ipv6 if present
    my $address = shift // return undef;
    my ($ipv4, $ipv6, $cidr, $mask) = Mnet::IP::parse($address);
    return undef if $ipv4 and $ipv6;
    return $ipv4 // $ipv6;

}



sub ipv4 {

=head2 $ipv4 = Mnet::IP::v4($address)

Return ipv4 portion from a valid input the address, or undefined.



=cut

    # read and parse address, return ipv4
    my $address = shift // return undef;
    my ($ipv4, $ipv6, $cidr, $mask) = Mnet::IP::parse($address);
    return $ipv4;

}



sub ipv6 {

=head2 $boolean = Mnet::IP::v6($address)

Return ipv6 fportion from a valid input address, or undefined.

=cut

    # read and parse address, return ipv6
    my $address = shift // return undef;
    my ($ipv4, $ipv6, $cidr, $mask) = Mnet::IP::parse($address);
    return $ipv6;

}



sub mask {

=head2 $mask = Mnet::IP::mask($address)

Return dotted decimal mask from a valid input ipv4 address containing a /cidr
or /mask, or undefined.

=cut

    # read and parse address, return mask
    my $address = shift // return undef;
    my ($ipv4, $ipv6, $cidr, $mask) = Mnet::IP::parse($address);
    return $mask

}



sub network {

=head2 $network = Mnet::IP::network($address)

Return ipv4/cidr or ipv6/cidr network address from a valid input ipv4/cidr,
ipv4/mask, or ipv6/cidr address, or undefined.

=cut

    # read input address
    my $address = shift;

    # parse input ipv4 or ipv6 address
    #   note that /cidr is calculated from input ipv4 /mask
    my ($ipv4, $ipv6, $cidr, $mask) = Mnet::IP::parse($address);

    # init output ip/cidr network address
    my $network = undef;

    # calculate output ipv4/cidr network
    #   convert ipv4 to binary, zero-out masked bits at end based on cidr
    if ($ipv4 and $cidr) {
        my $binary = substr(Mnet::IP::binary($ipv4), 0, $cidr);
        $binary .= "0" x (32 - $cidr);
        $network = join('.', unpack("C4", pack("B*", $binary)));

    # calculate output ipv6/cidr network
    } elsif ($ipv6 and $cidr) {

        # convert ipv6 to binary, zero-out masked bits at end based on cidr
        my $binary = substr(Mnet::IP::binary($ipv6), 0, $cidr);
        $binary .= "0" x (128 - $cidr);

        # convert ipv6 hextets to hex
        #   remove extra leading zeros in each hextet
        #   remove extra trailing colon when done with look
        while ($binary =~ s/^(\d{16})//) {
          my $hextet = unpack("H*", pack("B*", $1));
          $hextet =~ s/^0+(\d)/$1/;
          $network .= "$hextet:";
        }
        $network =~ s/:$//;

        # add double colon to eliminate extra hextets with only zeroes
        $network =~ s/(^|:)0:(0:)+/::/;
        $network =~ s/(:0)+:0$/::/;

        # zero in first and/or last hextet can be removed
        $network =~ s/(^0:|:0$)/:/g;

    # finished setting output network address
    }

    # finished network function
    return $network;

}



sub parse {

=head2 ($ipv4, $ipv6, $cidr, $mask) = Mnet::IP::parse($address)

Parse input address and return separate ipv4, ipv6, cidr and mask values.

The following are examples of valid ipv4 addresses:

 127.0.0.1
 127.0.0.1/32
 127.0.0.1/255.255.255.255

The following are examples of valid ipv6 addresses:

 ::1
 ::1/128

The following are examples of valid ipv6 addresses having embedded dotted
decimal text ipv4 addresses, as per rfc 6502 section 2:

 ::127.0.0.1
 ::127.0.0.1/96

The following are examples of valid /cidr and /mask values by themselves:

 /32
 /255.255.255.255

All output values are undefined if there were any errors.

=cut

    # read input address
    my $address = shift;

    # init outputs, also undefined outputs for errors
    #   return an error if input address not defined
    my ($ipv4, $ipv6, $cidr, $mask) = ();
    my @error = (undef, undef, undef, undef);
    return @error if not defined $address;

    # parse optional /cidr or /mask from end of address, validate them later
    $cidr = $1 if $address =~ s/\/(\d+)$//;
    $mask = $1 if $address =~ s/\/(\S*)$//;

    # ipv6 addresses have colons
    #   error if embedded ipv4 used with invalid /cidr, see rfc 6502 section 2
    if ($address =~ /:.*:/) {
        return @error if $address =~ /\./ and defined $cidr and $cidr !~ 96;
        $ipv6 = $address if Socket::inet_pton(AF_INET6, $address);

    # ipv4 addresses have dots
    } elsif ($address =~ /\./) {
        $ipv4 = $address if Socket::inet_pton(AF_INET, $address);

    # otherwise address is invalid
    } elsif ($address =~ /\S/) {
      return @error;
    }

    # return error if /cidr input is invalid
    #   /cidr max value is 32 for ipv4 and 128 for ipv6
    if (defined $cidr) {
        return @error if $ipv4 and $cidr > 32;
        return @error if $cidr > 128;
    }

    # return error if /mask set for ipv6 or /mask is invalid
    #   binary version should not have 0's before 1's
    if (defined $mask) {
        return @error if $ipv6 or not Socket::inet_pton(AF_INET, $mask);
        my $binary = unpack("B*", Socket::inet_aton($mask));
        return @error if $binary =~ /0.*1/;
    }

    # set mask from input ipv4/cidr or ipv4-sized /cidr only
    #   we don't want to try convert ipv6-sized /cidr to a mask
    if (not $ipv6 and not defined $mask and defined $cidr) {
        if ($cidr <= 32) {
          my $binary = '1' x $cidr . '0' x (32 - $cidr);
          $mask = Socket::inet_ntoa(pack("B*", $binary));
        }
    }

    # set cidr from input /mask
    if (not defined $cidr and defined $mask) {
        my $binary = unpack("B*", Socket::inet_aton($mask));
        $cidr = length($1) if $binary =~ /^(1*)/;
    }

    # finished _parse function, return outputs
    return ($ipv4, $ipv6, $cidr, $mask);

}



sub wildcard {

=head2 $wildcard = Mnet::IP::wildcard($mask)

Return dotted decimal wildcard mask for a valid input ipv4 address contianing a
/cidr or /mask, , or undefined.

=cut

    # read and parse address, return wildcard
    my $address = shift // return undef;
    my ($ipv4, $ipv6, $cidr, $mask) = Mnet::IP::parse($address);
    my $wildcard = undef;
    if (not $ipv6 and defined $cidr and $cidr <= 32) {
      my $binary = '0' x $cidr . '1' x (32 - $cidr);
      $wildcard = Socket::inet_ntoa(pack("B*", $binary));
    }
    return $wildcard;

}



=head1 SEE ALSO

L<Mnet>

=cut


# normal end of package
1;

