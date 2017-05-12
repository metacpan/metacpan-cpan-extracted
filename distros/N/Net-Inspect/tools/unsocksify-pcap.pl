#!/usr/bin/perl

use strict;
use warnings;
use Socket;
use Getopt::Long qw(:config posix_default bundling);
use Net::Pcap qw(:functions);

use Net::Inspect::Debug qw(:DEFAULT %TRACE $DEBUG);
use Net::Inspect::L2::Pcap;
use Net::Inspect::L3::IP;
use Net::Inspect::L4::TCP;
use Net::Inspect::L5::GuessProtocol;
use Net::Inspect::L5::Unknown;
use Net::Inspect::L5::Socks;
use Net::PcapWriter;

############################################################################
# Options
############################################################################
my ($infile,$outfile);
GetOptions(
    'r|read=s'  => \$infile,
    'w|write=s' => \$outfile,
    'h|help'    => sub { usage() },
    'd|debug'   => \$DEBUG,
    'T|trace=s' => sub { $TRACE{$_} = 1 for(split(m/,/,$_[1])) },
) or usage();
$infile ||= '/dev/stdin';

sub usage {
    print STDERR "ERROR: @_\n" if @_;
    print STDERR <<USAGE;

reads pcap, finds socksified (socks4 only) tcp connections and extracts
them unsocksified into new pcap. 

Usage: $0 [options] -r in.pcap -w out.pcap
Options:
    -h|--help            this help
    -r|--read in.pcap    read pcap from file
    -w|--write out.pcap  write pcap to file
    -T|--trace trace     enable Net::Inspect tracing
    -d|--debug           various debug messages are shown
USAGE
    exit(2);
}


# open pcap
my $err;
my $pcap_in  = pcap_open_offline($infile,\$err) or die $err;
my $pcap_out = Net::PcapWriter->new( $outfile || \*STDOUT ) or die $!;

# parse hierarchy
my $sck = Net::Inspect::L5::Socks->new(ConnWriter->new($pcap_out));
my $unk = Net::Inspect::L5::Unknown->new;
my $gs  = Net::Inspect::L5::GuessProtocol->new($sck,$unk);
my $tcp = Net::Inspect::L4::TCP->new($gs);
my $raw = Net::Inspect::L3::IP->new($tcp);
my $pc  = Net::Inspect::L2::Pcap->new($pcap_in,$raw);


# Mainloop
my $time;
pcap_loop($pcap_in,-1,sub {
    my (undef,$hdr,$data) = @_;
    if ( ! $time || $hdr->{tv_sec}-$time>10 ) {
	$tcp->expire($time = $hdr->{tv_sec});
    }
    return $pc->pktin($data,$hdr);
},undef);


package ConnWriter;
use base 'Net::Inspect::Connection';
use fields qw(pcap);

sub new {
    my ($class,$pcap) = @_;
    my $self;
    if ( ref($class)) {
	$self = fields::new(ref($class));
	$self->{pcap} = $pcap || $class->{pcap};
    } else {
	$self = fields::new($class);
	$self->{pcap} = $pcap;
    }
    return $self;
}

sub new_connection {
    my ($self,$meta) = @_;
    my $pcap = $self->{pcap}->tcp_conn(
	$meta->{saddr}, $meta->{sport},
	$meta->{daddr}, $meta->{dport},
    );
    return $self->new($pcap);
}

sub fatal { warn "fatal: $_[1]\n" }
sub syn { return 1 }
sub in {
    my ($self,$dir,$data,$eof,$time) = @_;
    $self->{pcap}->write($dir,$data,$time) if $data ne '';
    $self->{pcap}->shutdown($dir,$time) if $eof;
    return length($data);
}

