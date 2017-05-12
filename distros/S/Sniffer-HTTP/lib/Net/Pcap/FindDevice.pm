package Net::Pcap::FindDevice;
use strict;
use Net::Pcap; # just for the convenience function below
use Carp qw(croak);
use Exporter 'import';

use vars qw($VERSION @EXPORT);
$VERSION = '0.24';
@EXPORT = qw(find_device);

# TODO: Add diagnosis function to tell the user what the "best" function is

=head1 NAME

Net::Pcap::FindDevice - find the "best" network device for sniffing

=head1 SYNOPSIS

  use Net::Pcap;
  use Net::Pcap::FindDevice;

  my $device = find_device($ARGV[0]);

  my $pcap = Net::Pcap::open_live($device, 128000, -1, 500, \$err);

This module exports only one subroutine, C<find_device>,
which employs a dwimish method to find a network
device suitable for sniffing with L<Net::Pcap>.

=head2 C<< find_device DEVICE >>

Finds a good L<Net::Pcap> device based on some criteria:

If the parameter given is a regular expression,
is used to scan the names I<and> descriptions of the Net::Pcap
device list. The name of the first matching element
is returned.

If a L<Net::Pcap> device matching the
stringified parameter exists, it is returned.
If there exists no matching device for the scalar,
C<undef> is returned.

If there is only one network device, the name of
that device is returned.

If there is only one device left after removing all
network devices with IP address 127.0.0.1, the name
of that device is returned.

The name of the device with the default gateway
(if any) is returned.

Otherwise it gives up and returns C<undef>.

=cut

sub find_device {
  my ($device_name) = @_;
  # Set up Net::Pcap
  my @devs = Net::Pcap::findalldevs(\my %devinfo,\my $err);
  $err ||= '';
  if (! @devs) {
    croak <<NO_DEVICE
Net::Pcap didn't find any device: ($err).
This may be because your version of libpcap is too
low or you might not have the sufficient
privileges. You might also not have any networking
installed on this system.
NO_DEVICE
  };

  my $device = $device_name;
  if ($device_name) {
    if (ref $device_name eq 'Regexp') {
      ($device) = grep {$_ =~ /$device_name/ || $_ =~ $devinfo{$_}} keys %devinfo;
    } elsif (exists $devinfo{$device_name}) {
      $device = $device_name;
    } elsif  ( $device_name =~ m!^\d+\.\d+\.\d+\.\d+$! ) {
      ($device) = interfaces_from_ip( $device_name );
    } else {
      croak "Don't know how to handle $device_name as a Net::Pcap device";
    };
  } else {
    # TODO: Remove Data::Dumper dependency
    #use Data::Dumper;
    #warn Dumper \%devinfo;
    # 'any' is disabled as it returns information in a format
    # I don't understand
    #if (exists $devinfo{any}) {
    #  $device = 'any';
    #} elsif
    if (@devs == 1) {
      $device = $devs[0];
    } else {
      # Now we need to actually look at the devices and select the
      # one with the default gateway:

      # First, get the default gateway by using
      # `netstat -rn` and looking for the interface tied to the gateway
      my $device_ip;
      my $re_if = $^O eq 'MSWin32'
                  #         route        mask    gateway interface
                  ? qr/^\s*(?:0.0.0.0)\s+(?:\S+)\s+(\S+)\s+(\S+)/
                  : qr/^(?:0.0.0.0|default)\s+(\S+)\s+.*?(\S+)\s*$/;
      for (qx{netstat -rn}) {
        if ( /$re_if/ ) {
          $device_ip = $2;
          #warn "Found $2 in $_";
          last;
        };
      };

      #if (! $device_ip) {
      #  croak "Couldn't find IP address/interface of the default gateway interface. Maybe 'netstat' is unavailable?";
      #};

      #for (keys %devinfo) {
      #  warn $_;
      #};
      if (exists $devinfo{$device_ip}) {
        return $device_ip
      };

      # Looks like we got an IP and not an interface name.

      # This should all go into
      # sub interface_from_ip {}

      # So scan all interfaces if they have that IP address.

      my @good_devices = interfaces_from_ip($device_ip);

      if (@good_devices == 1) {
        $device = $good_devices[0];
      } elsif (@good_devices > 1) {
        croak "Too many device candidates found (@good_devices)";
      }
    };
  };

  return $device
};

=head2 C<< interfaces_from_ip IP >>

Returns all interfaces that have the ip C<IP>.
The value of C<IP> must be given as a string of
four numbers.

This method is not exported by default so you
need to call it fully specified as

  Net::Pcap::FindDevice::interfaces_from_ip('127.0.0.1')

=cut

sub interfaces_from_ip {
  my ($ip) = @_;
  my $good_address = unpack "N", pack "C4", (split /\./, $ip);

  my @devs = Net::Pcap::findalldevs(\my %devinfo,\my $err);
  my @result;
  for my $device (@devs) {
    #warn "$device/$ip";
    (Net::Pcap::lookupnet($device, \(my $address), \(my $netmask), \$err) == 0) or next;

    #print "$device / $address / $netmask\n";
    #for ($address,$netmask) {
    #  print ((join ".", unpack "C4", pack "N", $_),"\n");
    #};

    $address != 0 or next;

    for ($address,$netmask) {
      $_ = unpack "N", pack "N", $_;
    };
    #print "$device / $address / $netmask\n";

    if ($address == ($good_address & $netmask)) {
      push @result, $device;
    };
  };
  @result
};

1;

__END__

=head1 AUTHOR

Max Maischein (corion@cpan.org)

=head1 COPYRIGHT

Copyright (C) 2005-2011 Max Maischein.  All Rights Reserved.

This code is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<Net::Pcap>, Wireshark, the Alsace in autumn

=cut
