package Net::IP::Util;

use strict;
use warnings;
use Carp qw/croak/;

require Exporter;
our @ISA       = qw/Exporter/;
our $VERSION   = '1.03';

our @EXPORT    = qw/isClassAddrA
                    isClassAddrB
                    isClassAddrC
                    isClassAddrD
                    isClassAddrE
                    dec2binIpAddr
                    bin2decIpAddr/;

our @EXPORT_OK = qw/getAddrMaskDefault
                    getAddrClass
                    isValidMask
                    extendMaskByBits
                    calcSubnet
                    calcSubnetCIDR
                    calcSubnetExt
                    getNetworkAddr/;

our %EXPORT_TAGS = ('class'   => [qw/isClassAddrA isClassAddrB isClassAddrC
                                  isClassAddrD isClassAddrE getAddrClass/],
                    'convert' => [qw/dec2binIpAddr bin2decIpAddr/]);

use constant { 'A' => qr'^0',
               'B' => qr'^10',
               'C' => qr'^110',
               'D' => qr'^1110',
               'E' => qr'^11110',
               'MASKA' => '255.0.0.0',
               'MASKB' => '255.255.0.0',
               'MASKC' => '255.255.255.0',
               'IPREGEXP' => qr'^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$',
             };

sub isClassAddrA {
  my ($addr) = @_;

  (isBinIpAddr($addr)) && _validateIp(&bin2decIpAddr($addr))
                       || ($addr = &dec2binIpAddr($addr));
  return 1 if($addr =~ A);
}

sub isClassAddrB {
  my ($addr) = @_;

  (isBinIpAddr($addr)) && _validateIp(&bin2decIpAddr($addr))
                       || ($addr = &dec2binIpAddr($addr));
  return 1 if($addr =~ B);
}

sub isClassAddrC {
  my ($addr) = @_;

  (isBinIpAddr($addr)) && _validateIp(&bin2decIpAddr($addr))
                       || ($addr = &dec2binIpAddr($addr));
  return 1 if($addr =~ C);
}

sub isClassAddrD {
  my ($addr) = @_;

  (isBinIpAddr($addr)) && _validateIp(&bin2decIpAddr($addr))
                       || ($addr = &dec2binIpAddr($addr));
  return 1 if($addr =~ D);
}

sub isClassAddrE {
  my ($addr) = @_;

  (isBinIpAddr($addr)) && _validateIp(&bin2decIpAddr($addr))
                       || ($addr = &dec2binIpAddr($addr));
  return 1 if($addr =~ E);
}

sub getAddrMaskDefault {
  my ($addr) = @_;

  (! isBinIpAddr($addr)) && ($addr = &dec2binIpAddr($addr));

  my ($class) = getAddrClass($addr);

  my $mask = eval 'MASK'.$class;

  return $mask;
}

sub getAddrClass {
  my ($addr) = @_;

  (isBinIpAddr($addr)) && _validateIp(&bin2decIpAddr($addr))
                       || ($addr = &dec2binIpAddr($addr));

  my $class = (($addr =~ A)?'A'
                :($addr =~ B)?'B'
                   :($addr =~ C)?'C'
                      :($addr =~ D)?'D'
                         :($addr =~ E)?'E'
                            :undef);

  return $class;
}

sub dec2binIpAddr {
  my ($addr) = @_;

  _validateIp($addr);

  my @octets = split /\./,$addr;

  map {$_ = sprintf '%08b', $_} @octets;

  return join '.',@octets;
}

sub bin2decIpAddr {
  my ($addr) = @_;
  my @octets = split /\./, $addr;

  map {$_ = oct "0b$_"} @octets;

  my $decAddr = join '.',@octets;

  _validateIp($decAddr);

  return $decAddr;
}

sub isBinIpAddr {
  my ($addr) = @_;

  return 1 if ($addr =~ /^(([0|1]){8}\.){3}([0|1]){8}$/);
}

sub _validateIp {
  my ($addr) = @_;

  ($addr =~ /^[01.]*$/) && ($addr = &bin2decIpAddr($addr));
  my $validate = sub { map { return 0 if ( $_ > 255);}@_; return 1;};

  if(($addr =~ IPREGEXP) && $validate->($1,$2,$3,$4)) {
      return 1;
  }
  else {
      croak "$addr is not a valid IP address";
  }
}

sub isValidMask {
  my ($addr) = @_;

  (!isBinIpAddr($addr)) && ($addr = &dec2binIpAddr($addr));

  my ($prefix) = ($addr =~ /(.*1)/);

  ($prefix =~ /0/)?return 0:return 1;
}

sub extendMaskByBits {
  my ($mask,$noBits) = @_;

  (! isBinIpAddr($mask)) && ($mask = &dec2binIpAddr($mask));

  return $mask if(!$noBits);

  croak "Bits $noBits is invalid!!" if ($noBits !~ /^\d+$/ || $noBits > 24);
  croak "Mask $mask invalid!!" if (! isValidMask($mask));

  for (1..$noBits) {
      $mask =~ s/0/1/;
  }

  return $mask;
}

sub calcSubnet {
  my ($addr) = @_;

  (isBinIpAddr($addr)) && _validateIp($addr)
                       || ($addr = &dec2binIpAddr($addr));
  my $mask = getAddrMaskDefault($addr);

  ($mask && ! isBinIpAddr($mask)) && ($mask = dec2binIpAddr($mask));

  my $numZeros = ($mask =~ s/0//g) || 0;
  my $numHosts = 2 ** $numZeros - 2;

  return (0, $numHosts);
}

sub calcSubnetCIDR {
  my ($addr, $mask) = @_;

  my ($ip, $maskBits) = split (/\//, $addr);

  (isBinIpAddr($ip)) && _validateIp(&bin2decIpAddr($ip))
                       || ($ip = &dec2binIpAddr($ip)); 

  ($maskBits !~ /^\d+$/ || $maskBits < 0 || $maskBits > 32) && croak "Given mask bits $maskBits is invalid!";

  my $numOnes;
  if(!$mask) {
    $mask            = &dec2binIpAddr(getAddrMaskDefault($ip));
    my $temp         = $mask;
    $numOnes         = ($temp =~ s/1//g) ||0;
  }
  else {
    (! isValidMask($mask)) && croak "Given mask $mask is not valid!!";
    (! isBinIpAddr($mask)) && ($mask = &dec2binIpAddr($mask));
    my $temp         = $mask;
    $numOnes         = ($temp =~ s/1//g) ||0;
  }
 
  my $diffBits     = $maskBits - $numOnes;

  ($diffBits < 0) && croak "Given masking bits $maskBits should be >= $numOnes (no. of default mask 1 bits";
  my $extendedMask = extendMaskByBits($mask,$diffBits);

  $diffBits = 0 if(!defined $diffBits);

  my $numSubnets = 2 ** $diffBits;

  my $numZeros = ($extendedMask =~ s/0//g) || 0;
  my $numHosts = 2 ** $numZeros - 2;

  return ($numSubnets, $numHosts);
}

sub calcSubnetExt {
  my ($addr,$borrow) = @_;

  (isBinIpAddr($addr)) && _validateIp($addr)
                       || ($addr = &dec2binIpAddr($addr));

  my $defaultMask = getAddrMaskDefault($addr);

  my $extendedMask = extendMaskByBits($defaultMask,$borrow);

  $borrow = 0 if(!defined $borrow);

  my $numSubnets = 2 ** $borrow;

  my $numZeros = ($extendedMask =~ s/0//g) || 0;
  my $numHosts = 2 ** $numZeros - 2;

  return ($numSubnets, $numHosts);
}

sub getNetworkAddr {
  my ($addr, $defaultMask, $subnetMask, $bc) = @_;

  $defaultMask && isValidMask($defaultMask);
  !$defaultMask && ($defaultMask = getAddrMaskDefault($addr));

  $subnetMask && isValidMask($subnetMask);
  (! isBinIpAddr($addr)) && ($addr = &dec2binIpAddr($addr));
  (! isBinIpAddr($defaultMask)) && ($defaultMask = &dec2binIpAddr($defaultMask));
  (! isBinIpAddr($subnetMask)) && ($subnetMask = &dec2binIpAddr($subnetMask));

  my $subnetMaskOnBits = ($subnetMask =~ s/1/1/g);
  my $defaultMaskOnBits = ($defaultMask =~ s/1/1/g);
  my $numSubnetBits = ($subnetMaskOnBits - $defaultMaskOnBits);

  croak "Default mask : $defaultMask and/or Subnet mask : $subnetMask incorrect!!" if($numSubnetBits !~/^\d+$/);

  my $numHostBits = 32 - $subnetMaskOnBits;
  my $numHostAddrs = 2 ** $numHostBits;

  my $numSubnets = 2 ** $numSubnetBits;

  my @nwAddrs;
  
  if ($bc) {
      for (0..($numSubnets-1)) {
          push @nwAddrs, bin2decIpAddr(_incrIpAddr($addr, $numHostAddrs-1));
          $addr = _incrIpAddr($addr, $numHostAddrs);
      }
  }
  else {
      for (0..($numSubnets-1)) {
          push @nwAddrs, bin2decIpAddr ($addr);
          $addr = _incrIpAddr($addr, $numHostAddrs);
      }
  } 
  return (@nwAddrs);
}

sub _incrIpAddr {
  my ($addr, $incr) = @_;
  $addr = bin2decIpAddr($addr);

  my ($o4,$o3,$o2,$o1) = split /\./,$addr;

  $o1 += $incr;
  if($o1 <= 255) {
      return dec2binIpAddr("$o4.$o3.$o2.$o1");
  }
  else {
      $incr = $o1 - 255;
      $o1 = 255;

      $o2 += $incr;
      if ($o2 <= 255) {
          return dec2binIpAddr("$o4.$o3.$o2.$o1");
      }
      else {
          $incr = $o2 - 255;
          $o2 = 255;

          $o3 += $incr;
          if($o3 <= 255) {
              return dec2binIpAddr("$o4.$o3.$o2.$o1");
          }
          else {
              $incr = $o3 - 255;
              $o3 = 255;

              $o4 += $incr;
              return dec2binIpAddr("$o4.$o3.$o2.$o1");
          }
      }
   }
}

1;

=head1 NAME

Net::IP::Util - Common useful routines like converting decimal address to binary and vice versa, determining address class,
                determining default mask, subnets and hosts and broadcast addresses for hosts in subnet.

=head1 SYNOPSIS

  use Net::IP::Util;                       ## subroutines isClassAddrA-E, bin2decIpAddr, dec2binIpAddr
  use Net::IP::Util qw/:class/;            ## subroutines isClassAddrA-E, getAddrClass
  use Net::IP::Util qw/:convert/;          ## subroutines bin2decIpAddr, dec2binIpAddr 
  use Net::IP::Util qw/getAddrMaskDefault
                       getAddrClass
                       isValidMask
                       extendMaskByBits
                       calcSubnet
                       calcSubnetCIDR
                       calcSubnetExt
                       getNetworkAddr    ## Explicit inclusions

  isClassAddrA('127.0.32.45');
  isClassAddrA('00001111.11110010.00100100.10000001');

  dec2binIpAddr('128.0.0.56');
  bin2decIpAddr('10001000.10100001.00010101.00000001');

  getAddrMaskDefault('124.45.0.0');
  getAddrMaskDefault('10000000.00000001.01010101.10000001');

  getAddrClass('124.45.0.0');
  getAddrClass('00001111.11110010.00100100.10000001');

  isValidMask('255.255.252.0');
  isValidMask('11111111.00000000.00000000.00000000');

  extendMaskByBits('255.255.0.0',2);
  extendMaskByBits('11111111.00000000.00000000.00000000',2);

  calcSubnet('128.8.9.0');
  calcSubnet('10001000.10100001.00010101.00000001');

  calcSubnetCIDR('128.9.0.218/24');
  calcSubnetCIDR('128.9.0.218/28', '255.255.255.0');

  calcSubnetExt('128.0.0.1',4);
  calcSubnetExt('10001000.10100001.00010101.00000001',4);
                           
  getNetworkAddr('198.23.16.0','255.255.255.240','255.255.255.252');
  getNetworkAddr('198.23.16.0','255.255.255.240','255.255.255.252', 1);
  getNetworkAddr('10000000.00000001.01010101.10000001',
                   '11111111.11111111.11111111.11110000',
                   '11111111.11111111.11111111.11111100',);
  getNetworkAddr('10000000.00000001.01010101.10000001',
                   '11111111.11111111.11111111.11110000',
                   '11111111.11111111.11111111.11111100', 1);

=head1 ABSTRACT

  This module tries provide the basic functionalities related to IPv4 addresses.
  Address class, subnet masks, subnet addresses, broadcast addresses can be deduced
  using the given methods. Ip addresses passed are also validated implicitly.

  Provision has been given to specify IP addresses in either dotted decimal notation
  or dotted binary notation, methods have been provided for conversion to-from these
  to notations which are internally used by other methods too.

=head1 METHODS

=head2 isClassAddrA,isClassAddrB,isClassAddrC,isClassAddrD,isClassAddrE

  isClassAddrA(<addr in decimal/binary>) : returns 1 if true
  eg.
  isClassAddrA('127.0.32.45');
  isClassAddrA('00001111.11110010.00100100.10000001');

=head2 dec2binIpAddr

  dec2binIpAddr(<ip addr in dotted decimal notation>) : returns ip in binary dotted notation
  eg.
  dec2binIpAddr('128.0.0.56');

=head2 bin2decIpAddr

  bin2decIpAddr(<ip addr in dotted binary notation>) : returns ip in decimal dotted notation
  eg.
  bin2decIpAddr('10001000.10100001.00010101.00000001');

=head2 getAddrMaskDefault

  getAddrMaskDefault(<ip addr in decimal/binary notation>) : returns default subnet mask in dotted decimal notation
  eg.
  getAddrMaskDefault('124.45.0.0'); >> 255.0.0.0
  getAddrMaskDefault('10000000.00000001.01010101.10000001'); >> 255.0.0.0

=head2 getAddrClass

  getAddrClass(<ip addr in decimal/binary notation>) : returns class (A/B/C/D/E) of ip address
  eg.  
  getAddrClass('124.45.0.0');
  getAddrClass('00001111.11110010.00100100.10000001');

=head2 isValidMask

  isValidMask(<ip addr in decimal/binary notation>) : returns 1 if valid mask
  eg.
  isValidMask('255.255.252.0');
  isValidMask('11111111.00000000.00000000.00000000');

=head2 extendMaskByBits

  extendMaskByBits(<ip addr in decimal/binary notation>,<no.of bits to extend>)
    : returns mask after extending/turning on given no. of bits after the already on bits of the mask
  eg.
  extendMaskByBits('255.255.0.0',2); >> 255.255.192.0
  extendMaskByBits('11111111.00000000.00000000.00000000',2); >> 11111111.11000000.00000000.00000000

=head2 calcSubnet

  calcSubnet(<ip addr in decimal/binary notation>) : returns (no. of subnets, no. of hosts)
  calcSubnet('128.90.80.12');
  calcSubnet('11000000.00000000.11000000.01011100');
  - These always assumes Default Mask in calculation - hence no of subnets returned is always 0

=head2 calcSubnetCIDR

  calcSubnetCIDR(<ip addr in decimal/binary CIDR notation>, [<mask in decimal/binary notation>])
      : returns (no. of subnets, no. of hosts)
  calcSubnetCIDR('128.87.56.26/28');
  calcSubnetCIDR('128.87.56.26/28','255.255.252.0');

=head2 calcSubnetExt

  calcSubnetExt(ip addr in decimal/binary notation>, no. of bits to extend in default mask OR no. of borrowed bits)
    : returns (no. of subnets, no. of hosts)
  eg.
  calcSubnetExt('128.0.0.1',4);
  calcSubnetExt('10001000.10100001.00010101.00000001',4);

  Expln : no. of borrowed bits is added to the default subnet mask of ip addr to subnet mask
          and subnetting is done so :
          ***************************************************
          127.0.40.1           = ip addr
          255.0.0.0            = default subnet mask
          no. of borrowed bits = 4
                               => 255.240.0.0 = extended mask 
          ***************************************************

=head2 getNetworkAddr

  getNetworkAddr(<ip addr in decimal/binary notation>,
                   <default mask in decimal/binary notation>,
                   <subnet mask in decimal/binary notation>,
                   <true flag - if you want broadcast addresses instead of n/w addresses
                   ) : returns network/broadcast addresses of the subnets after subnetting as a list
  eg.
  getNetworkAddr('198.23.16.0','255.255.255.240','255.255.255.252'); >> ('198.23.16.0','198.23.16.4','198.23.16.8','198.23.16.12')
  getNetworkAddr('198.23.16.0','255.255.255.240','255.255.255.252',1); >> ('198.23.16.3','198.23.16.7','198.23.16.11','198.23.16.15')
  getNetworkAddr('10000000.00000001.01010101.10000001',
                   '11111111.11111111.11111111.11110000',
                   '11111111.11111111.11111111.11111100',); >> Always returns n/w addresses in dotted decimal irrespective of binary/decimal
                                                               address parameter passed

=head1 CAVEAT

  IPv4 only
  Validation of IP addresses are done, but because of conversions here and there it may not show the IP address properly in the error message
  as passed earlier by the user.

=head1 Similar Modules

  Net::IP, Net::IpAddr etc.

=head1 SUPPORT

  debashish@cpan.org

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2013 Debashish Parasar, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
