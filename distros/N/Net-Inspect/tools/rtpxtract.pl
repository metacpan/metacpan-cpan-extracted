#!/usr/bin/perl
use strict;
use warnings;
use Socket;
use Getopt::Long qw(:config posix_default bundling);
use Net::Pcap qw(:functions);

use Net::Inspect::Debug qw(:DEFAULT %TRACE $DEBUG);
use Net::Inspect::L2::Pcap;
use Net::Inspect::L3::IP;
use Net::Inspect::L4::UDP;

############################################################################
# Options
############################################################################
my ($infile,$dev,$nopromisc,@trace,$outdir);
GetOptions(
    'r=s' => \$infile,
    'i=s' => \$dev,
    'p'   => \$nopromisc,
    'h|help' => sub { usage() },
    'd|debug' => \$DEBUG,
    'T|trace=s' => sub { push @trace,split(m/,/,$_[1]) },
    'D|dir=s' => \$outdir,
) or usage();
usage('only interface or file can be set') if $infile and $dev;
$infile ||= '/dev/stdin' if ! $dev;
my $pcapfilter = join(' ',@ARGV);
$TRACE{$_} = 1 for(@trace);
die "cannot write to $outdir: $!" if $outdir and ! -w $outdir || ! -d _;

sub usage {
    print STDERR "ERROR: @_\n" if @_;
    print STDERR <<USAGE;

reads data from pcap file or device and extracts rtp streams.
Depending on the used codec you might use to convert data afterwards.
For G711a:
  sox -c1 -r8000 -t al in.rtp out.wav

Usage: $0 [options] [pcap-filter]
Options:
    -h|--help        this help
    -r file.pcap     read pcap from file
    -i dev           read pcap from dev
    -p               do net set dev into promisc mode
    -D dir           extract data into dir, right now only for http requests
                     and responses
    -T trace         trace messages are enabled in the modules, option can
                     be given multiple times, trace is last part of module name,
                     e.g. tcp, rawip
                     To enable all specify '*'
    -d|--debug       various debug messages are shown
USAGE
    exit(2);
}


# open pcap
############################################################################
my $err;
my $pcap = $infile
    ? pcap_open_offline($infile,\$err)
    : pcap_open_live($dev,2**16,!$nopromisc,0,\$err);
$pcap or die $err;
if ( $pcapfilter ) {
    pcap_compile($pcap, \(my $compiled), $pcapfilter,0,0xffffffff) == 0
	or die "bad filter '$pcapfilter'";
    pcap_setfilter($pcap,$compiled) == 0 or die;
}

# parse hierarchy
############################################################################

my $udp = Net::Inspect::L4::UDP->new( SIPXTract->new);
my $raw = Net::Inspect::L3::IP->new($udp);
my $pc  = Net::Inspect::L2::Pcap->new($pcap,$raw);


# Mainloop
############################################################################
my $time;
pcap_loop($pcap,-1,sub {
    my (undef,$hdr,$data) = @_;
    if ( ! $time || $hdr->{tv_sec}-$time>10 ) {
	$udp->expire($time = $hdr->{tv_sec});
    }
    return $pc->pktin($data,$hdr);
},undef);


package SIPXTract;
use base 'Net::Inspect::Connection';
use Net::Inspect::Debug;
use Net::SIP;


my %rtp;
sub pktin {
    my ($self,$data,$meta) = @_;
    
    # are these expected RTP data?
    if ( my $m = delete $rtp{ $meta->{daddr},$meta->{dport} } ) {
	# make connection
	my $s = SIPXTract::RTPStream->new($meta,$m);
	$s->pktin(0,$data,$meta->{time});
	return $s;
    }

    # extract SDP data and store in %rtp
    my $pkt = eval { Net::SIP::Packet->new($data) } or return;
    my $sdp = eval { $pkt->sdp_body } or return;
    my @media = $sdp->get_media or return;
    for(@media) {
	$rtp{ $_->{addr},$_->{port} } = $_;
	debug( "rtp $_->{addr}:$_->{port}");
    }

    # no connection for SIP packets
    return;
}

package SIPXTract::RTPStream;
use base 'Net::Inspect::Connection';
use Net::Inspect::Debug;
use fields qw(meta fh0 fh1);

sub new {
    my ($class,$meta,$media) = @_;
    return bless { meta => $meta }, $class;
}
sub pktin {
    my ($self,$dir,$data,$time) = @_;
    $self->{expire} = $time + 30; # short expiration
    my $fh = "fh$dir";
    if ( ! $self->{$fh} ) {
	my $fname = sprintf "$outdir/%x-%s.%d-%s.%d-%d.rtp",
	    @{$self->{meta}}{qw(time saddr sport daddr dport)},$dir;
	open( $self->{$fh},'>',$fname) or die $!;
    }

    # extract payload from RTP data
    my ($vpxcc,$mpt,$seq,$tstamp,$ssrc) = unpack( 'CCnNN',substr( $data,0,12,'' ));
    my $version = ($vpxcc & 0xc0) >> 6;
    if ( $version != 2 ) {
	    debug("RTP version $version");
	    return
    }
    # skip csrc headers
    my $cc = $vpxcc & 0x0f;
    substr( $data,0,4*$cc,'' ) if $cc;

    # skip extension header
    my $xh = $vpxcc & 0x10 ? (unpack( 'nn', substr( $data,0,4,'' )))[1] : 0;
    substr( $data,0,4*$xh,'' ) if $xh;

    # ignore padding
    my $padding = $vpxcc & 0x20 ? unpack( 'C', substr($data,-1,1)) : 0;
    my $payload = $padding ? substr( $data,0,length($data)-$padding ): $data;

    # XXX if data are lost filling might be useful
    # XXX no duplicate detection
    syswrite($self->{$fh},$payload);
    return;
}

