#!/usr/bin/perl -w
use strict;
use lib 'lib';
use Net::Pcap;
use Data::Dumper;
use NetPacket::Ethernet qw(:strip);
use NetPacket::IP;
use IO::Handle;
use File::Basename qw(basename);

=head1 NAME

dump-raw - Dumps a packet stream suitable for the test suite

=head1 SYNOPSIS

dump-raw [device] [filter]

=cut

$|++;

my $pattern = (basename $0) . "-dump-raw.$$.%05g.dump";

my ($usr_device, $pcap_filter) = @ARGV;
my $device_name = $ARGV[0] || 'any';

# Set up Net::Pcap
my ($err);
my %devinfo;

my @devs = Net::Pcap::findalldevs(\%devinfo, \$err);

my $device;
if ($^O =~ /mswin/i) {
  ($device) = grep {$devinfo{$_} =~ /$device_name/i} keys %devinfo;
} else {
  $device = $device_name;
};

if (! $device) {
  die Dumper \%devinfo;
};

warn "Using '$devinfo{$device}'\n";

$pcap_filter ||= '(dst localhost && (port 80))  || (src localhost && (port 80))';

$|++;
my $frame = 0;
sub process_packet {
  my($user_data, $header, $packet) = @_;
  my $outfile = sprintf $pattern, $frame++;

  open my $output, ">", $outfile
    or die "Couldn't create '$outfile': $!";
  binmode $output;

  my $ip_obj = NetPacket::IP->decode(eth_strip($packet));
  print $output $ip_obj->{data};
  print ".";
};

my ($address, $netmask);
if (Net::Pcap::lookupnet($device, \$address, \$netmask, \$err)) {
    die 'Unable to look up device information for ', $device, ' - ', $err;
}

#   Create packet capture object on device
my $pcap = Net::Pcap::open_live($device, 128000, -1, 10000, \$err);
unless (defined $pcap) {
    die 'Unable to create packet capture on device ', $device, ' - ', $err;
};

warn "Filtering '$device' on ($pcap_filter)";

my $filter;
Net::Pcap::compile(
    $pcap,
    \$filter,
    $pcap_filter,
    0,
    $netmask
) && die 'Unable to compile packet capture filter';
Net::Pcap::setfilter($pcap, $filter) &&
    die 'Unable to set packet capture filter';

#   Set callback function and initiate packet capture loop

Net::Pcap::loop($pcap, -1, \&process_packet, '') ||
    die 'Unable to perform packet capture';