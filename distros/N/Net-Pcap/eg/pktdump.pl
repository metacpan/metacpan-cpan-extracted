#!/usr/bin/perl
use strict;
use Getopt::Long qw(:config no_auto_abbrev);
use Net::Pcap qw(:functions);

$|=1;

my %options = (
    count   => 10, 
    promisc => 0, 
    snaplen => 68, 
);

GetOptions(\%options, qw{ count|c=i  interface|i=s  promisc|p!  snaplen|s=i  writeto|w=s }) 
    or die "usage: $0 [-c count] [-i interface] [-s snaplen] [-w file] [expression]\n";

my $err = '';
my $dev = $options{interface} || lookupdev(\$err);
my $pcap = open_live($dev, $options{snaplen}, !$options{promisc}, 5, \$err)
    or die "fatal: can't open network device $dev: $! (do you have the privileges?)\n";

my $dumper;
if ($options{writeto}) {
    $dumper = dump_open($pcap, $options{writeto}) 
        or die "fatal: can't write to file '$options{writeto}': $!\n";
}

loop($pcap, $options{count}, \&handle_packet, '');
pcap_close($pcap);


sub handle_packet {
    my ($user_data, $header, $packet) = @_;
    printf "packet: len=%s, caplen=%s, tv_sec=%s, tv_usec=%s\n", 
        map { $header->{$_} } qw(len caplen tv_sec tv_usec);
    pcap_dump($dumper, $header, $packet) if $options{writeto};
}

