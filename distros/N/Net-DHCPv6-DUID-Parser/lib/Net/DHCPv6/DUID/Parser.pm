package Net::DHCPv6::DUID::Parser;

# Copyright 2010 Tom Wright. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification, are
# permitted provided that the following conditions are met:
#
#    1. Redistributions of source code must retain the above copyright notice, this list of
#       conditions and the following disclaimer.
#
#    2. Redistributions in binary form must reproduce the above copyright notice, this list
#       of conditions and the following disclaimer in the documentation and/or other materials
#       provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY TOM WRIGHT ``AS IS'' AND ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
# FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL TOM WRIGHT OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
# ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# The views and conclusions contained in the software and documentation are those of the
# authors and should not be interpreted as representing official policies, either expressed
# or implied, of Tom Wright.

our $VERSION = "1.01";

use strict;
use warnings;
use Carp;

=head1 NAME

Net::DHCPv6::DUID::Parser - Parse DHCPv6 Unique Identifiers

=head1 SYNOPSIS

  use Net::DHCPv6::DUID::Parser;

  my $p = new Net::DHCPv6::DUID::Parser;

  # Decode an example DUID
  $p->decode('000300010004ED9F7622');
  
  # Print the type
  print "TYPE: ".$p->type(format => 'text')."\n";

  ### prints 'TYPE: DUID-LL'

  if ($p->type == 1 || $p->type == 3) {

    # Format this like a MAC address if the link type was Ethernet
    if ($p->iana_hw_type == 1) {
      print "MAC ADDRESS: ".$p->local_link_address(format => 'ethernet_mac')."\n";
    } else {
      print "LOCAL LINK ADDRESS: ".$p->local_link_address."\n";
    }

  }

  ### prints 'MAC ADDRESS: 00-04-ed-9f-76-22'

=head1 DESCRIPTION

Object oriented interface to parse RFC3315 
compliant DHCPv6 Unique Identifiers (DUIDs)

This module was written for the purpose of
splitting the DUID into its constituent parts,
and shared here for convenience.  It does
some textual conversions that may save you
some time.

=cut

## Accept the following DUID input formats
my %pack_templates = (
  'hex' => 'H*',
  'bin' => 'B*',
);

## Decoders registered for each DUID type
my %decoders = (
  1 => \&_decode_type_1,
  2 => \&_decode_type_2, 
  3 => \&_decode_type_3,
);

## IETF DUID types
my %duid_types = (
  1 => 'DUID-LLT',
  2 => 'DUID-EN',
  3 => 'DUID-LL',
);

## IANA hardware types
my %iana_hw_types = (
  0 => 'Reserved',
  1 => 'Ethernet (10Mb)',
  2 => 'Experimental Ethernet (3Mb)',
  3 => 'Amateur Radio AX.25',
  4 => 'Proteon ProNET Token Ring',
  5 => 'Chaos',
  6 => 'IEEE 802 Networks',
  7 => 'ARCNET',
  8 => 'Hyperchannel',
  9 => 'Lanstar',
  10 => 'Autonet Short Address',
  11 => 'LocalTalk',
  12 => 'LocalNet (IBM PCNet or SYTEK LocalNET)',
  13 => 'Ultra link',
  14 => 'SMDS',
  15 => 'Frame Relay',
  16 => 'Asynchronous Transmission Mode (ATM)',
  17 => 'HDLC',
  18 => 'Fibre Channel',
  19 => 'Asynchronous Transmission Mode (ATM)',
  20 => 'Serial Line',
  21 => 'Asynchronous Transmission Mode (ATM)',
  22 => 'MIL-STD-188-220',
  23 => 'Metricom',
  24 => 'IEEE 1394.1995',
  25 => 'MAPOS',
  26 => 'Twinaxial',
  27 => 'EUI-64',
  28 => 'HIPARP',
  29 => 'IP and ARP over ISO 7816-3',
  30 => 'ARPSec',
  31 => 'IPsec tunnel',
  32 => 'InfiniBand (TM)',
  33 => 'TIA-102 Project 25 Common Air Interface (CAI)',
  34 => 'Wiegand Interface',
  35 => 'Pure IP',
  36 => 'HW_EXP1',
  37 => 'HFI',
  256 => 'HW_EXP2',
);

=head1 USAGE

=head2 Methods

=head3 Constructor

=over 4

=item * Net::DHCPv6::DUID::Parser->new(..)

  my $p = new Net::DHCPv6::DUID::Parser (decode => 'hex');

The constructor class method accepts two parameters.

The 'decode' parameter tells the parser the format of the 
DUID you're intending to parse using the 'decode' object method.  
Valid attributes are 'hex' and 'bin'. The default value is 'hex'.

The 'warnings' parameter can be set to 0 to disable
output to STDERR.  The default value is 1.

=back

=cut

sub new {

  my $invocant = shift;

  my $class    = ref($invocant) || $invocant;

  my $self = {
    decode => 'hex',
    warnings => 1,
    @_,
  };

  my %params = ( 'decode' => 1, warnings => 1 );

  foreach (keys %$self) {
    croak "valid parameters are '". (join "' OR '", keys %params) ."'"
      unless $params{$_};
  }

  croak "valid attributes for parameter 'decode' are '" 
    . (join "' OR '", keys %pack_templates) ."'"
    unless $pack_templates{$self->{decode}};

  return bless $self, $class;

}

=head3 Object Methods

Each method returns undef if it encounters a failure, or if a requested DUID component wasn't 
relevant to the decoded DUID type.

Warnings are emitted by default, unless turned off in the object constructor.

=over 4

=item * $p->decode($duid)

Accepts a single scalar, which should contain the DUID in the
format indicated by the constructor.

Returns 1 on success.

=back

=cut

sub decode {

  my ($self, $duid) = @_; 

  $self->{type} = $self->_decode_type($duid);

  foreach (qw/iana_hw_type local_link_address enterprise_number identifier time/) {
    $self->{$_} = undef;
  }

  if ($decoders{$self->{type}} && $duid_types{$self->{type}}) {

    ## type 1
    if ($self->{type} == 1) {
      ( $self->{iana_hw_type}, 
        $self->{local_link_address}, 
        $self->{time}
      ) = &{$decoders{$self->{type}}}($self, $duid);
      return 1;

    ## type 2
    } elsif ($self->{type} == 2) {
      ( $self->{enterprise_number}, 
        $self->{identifier}
      ) = &{$decoders{$self->{type}}}($self, $duid);
      return 1;

    ## type 3
    } elsif ($self->{type} == 3) {
      ( $self->{iana_hw_type}, 
        $self->{local_link_address}
      ) = &{$decoders{$self->{type}}}($self, $duid);
      return 1;
    } else {
      ## should never get here
      die "ERROR: ".__PACKAGE__."->decoder registered, but not instructed to do anything! ".
          "don't know how to decode type $self->{type}";
    }
   
  } else {
    carp "don't know how to decode type $self->{type}" if ($self->{warnings});
  }

  return undef;
}

=over 4

=item * $p->type(..)

Applies to: DUID-LL, DUID-LLT and DUID-EN.

Returns the DUID type.

Specify "format => 'text'" to return the textual representation
of the DUID type.  The default return value is numeric.

=back

=cut

sub type {
  my ($self, %opts) = @_;

  if ($self->{type} && !($duid_types{$self->{type}})) {
    carp "type $self->{type} is not valid" if ($self->{warnings});
    return undef;
  } elsif ($self->{type} && $opts{format} && $opts{format} eq 'text') {
    return $duid_types{$self->{type}};
  } else {
    return $self->{type};
  }
}

=over 4

=item * $p->time()

Applies to: DUID-LLT.

Returns time ticks in seconds since midnight 1st January 2000.

=back

=cut

sub time {
  my ($self) = @_;

  carp "time is irrelevant for DUID type $self->{type}"
  unless ($self->{type} == 1 || !($self->{warnings}));

  return $self->{time};
}

=over 4

=item * $p->iana_hw_type(..)

Applies to: DUID-LL and DUID-LLT.

Returns the IANA hardware type or undef if this parameter is irrelevant.

Specify "format => 'text'" for a textual representation of this value.
The default return value is numeric.

=back

=cut


sub iana_hw_type {
  my ($self, %opts) = @_;

  carp "iana_hw_type is irrelevant for DUID type $self->{type}"
  unless ($self->{type} == 1 || $self->{type} == 3 || !($self->{warnings}));

  if ($self->{iana_hw_type} && !($iana_hw_types{$self->{iana_hw_type}})) {
    carp "iana_hw_type $self->{iana_hw_type} is UNKNOWN for DUID type $self->{type}";
    return undef;
  } elsif ($self->{iana_hw_type} && $opts{format} && $opts{format} eq 'text') {
    return $iana_hw_types{$self->{iana_hw_type}};
  } else {
    return $self->{iana_hw_type};
  }
}

=over 4

=item * $p->enterprise_number()

Applies to: DUID-EN.

Returns the enterprise number.

=back

=cut


sub enterprise_number {
  my ($self) = @_;

  carp "enterprise_number is irrelevant for DUID type $self->{type}"
  unless ($self->{type} == 2 || !($self->{warnings}));

  return $self->{enterprise_number};
}

=over 4

=item * $p->identifier()

Applies to: DUID-EN.

Returns the identifier.

=back

=cut

sub identifier {
  my ($self) = @_;

  carp "enterprise_number is irrelevant for DUID type $self->{type}"
  unless ($self->{type} == 2 || !($self->{warnings}));

  return $self->{identifier};
}

=over 4

=item * $p->local_link_address(..)

Applies to: DUID-LL and DUID-LLT

Returns the local link address.

Specify "format => 'ethernet_mac'" for a pretty representation of this value.

The formatting will only apply if the IANA hardware type is '1' - i.e, if it's Ethernet.

=back

=cut

sub local_link_address { 
  my ($self, %opts) = @_;

  carp "local_link_address is irrelevant for DUID type $self->{type}"
   unless ($self->{type} == 1 || $self->{type} == 3 || !($self->{warnings}));

  my %formats = (
    ethernet_mac => 1,
  );

  if ($opts{format}) {
    croak "ERROR: ".__PACKAGE__."->local_link_address' valid options for 'format' are '"
      . (join "' OR '", keys %formats) . "'" 
    unless ($formats{$opts{format}});

    if ($self->{local_link_address} && $opts{format} eq 'ethernet_mac' && $self->iana_hw_type == 1) {
      my @ethernet_mac = unpack ('(A2)*', $self->{local_link_address});
      return join "-", @ethernet_mac;
    }
  } else { 
    return $self->{local_link_address};
  }

  return undef;

}

##
## PRIVATE METHODS
##

## DUID Based on Link-layer Address Plus Time [DUID-LLT]
sub _decode_type_1 {
  my ($self, $duid) = @_;

  my ($iana_hw_type, $time, $local_link_address) = 
    unpack ('xx (n) (N) (H*)',pack ($pack_templates{$self->{decode}},$duid));

  return ($iana_hw_type, $local_link_address, $time);
}

## DUID Assigned by Vendor Based on Enterprise Number [DUID-EN]
sub _decode_type_2 {
  my ($self, $duid) = @_;

  my ($enterprise_number, $identifier) =
   unpack ('xx (N) (H*)',pack($pack_templates{$self->{decode}},$duid));

  return ($enterprise_number, $identifier);

}

## DUID Based on Link-layer Address [DUID-LL]
sub _decode_type_3 {
  my ($self, $duid) = @_;

  my ($iana_hw_type, $local_link_address) =
    unpack('xx (n) (H*)',pack ($pack_templates{$self->{decode}},$duid));

  return ($iana_hw_type, $local_link_address);
}

## Determine only the DUID type
sub _decode_type {
  my ($self, $duid) = @_;
  return unpack ("n",pack("H*",$duid));
}

=head1 CREDITS

Mark Smith

=head1 SEE ALSO

http://tools.ietf.org/html/rfc3315#section-9

=head1 AUTHOR

Tom Wright, 2010

=cut


1;
