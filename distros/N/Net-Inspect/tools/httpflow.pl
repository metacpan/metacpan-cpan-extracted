#!/usr/bin/perl
use strict;
use warnings;

use Getopt::Long qw(:config posix_default bundling);
use Net::Pcap;

# use private include path based on script path
BEGIN { 
    my $bin = __FILE__;
    $bin = readlink($bin) while ( -l $bin );
    unshift @INC, $bin =~m{^(.*?)(?:\.\w+)?$}; 
}

use Net::Inspect::L2::Pcap;
use Net::Inspect::L3::IP;
use Net::Inspect::L4::TCP;
use Net::Inspect::L5::GuessProtocol;
use Net::Inspect::L7::HTTP;
use Net::Inspect::L5::NoData;
use Net::Inspect::L5::Unknown;
use Net::Inspect::L5::Socks;
use Net::Inspect::Debug qw(:DEFAULT %TRACE $DEBUG);

use privHTTPConn;
use privHTTPRequest;
use privFileCache;

# ---------------------------------------------------------------------------- 
# usage and options parsing
# ---------------------------------------------------------------------------- 
my (@infile,$dev,$nopromisc,@trace,$outdir,$verbose,$anon_stats);
my $uncompress = my $unchunk = 1;

my $usage = sub {
    print STDERR "ERROR: @_\n" if @_;
    print STDERR <<USAGE;

reads data from pcap file or device and analyzes it.
Right now it will collect tcp streams which look like http and extract
requests and responses. Transfer encoding of chunked and content encoding
of gzip/deflate will be transparently removed.

Usage: $0 [options] [pcap-filter]
Options:
    -h|--help        this help

    ## input
    -i dev           read pcap from dev
    -p               do net set dev into promisc mode
    -r file.pcap     read pcap from file, use stdin if not given and no dev
                     more then one file can be given by using option multiple
		     times

    ## output
    -v|--verbose     print information about each request (implied if no outdir
                     and no anon-stats)
    --anon-stats     output anonymous stats for generating benchmarks
    -D dir           extract data into dir, right now only for http requests
		     and responses. If not given prints info to stdout
    --unchunk        do unchunking if saving (default)
    --nounchunk      no unchunking if saving
    --uncompress     do uncompression if saving (default), implies unchunking
    --nouncompress   no uncompression if saving

    ## debugging
    -d|--debug       various debug messages are shown
    -T trace         trace messages are enabled in the modules, option can
		     be given multiple times, trace is last part of module name,
		     e.g. tcp, rawip, http,...
		     To enable all specify '*'
USAGE
    exit(2);
};


GetOptions(
    'h|help'      => sub { $usage->() },
    # input
    'i=s'         => \$dev,
    'p'           => \$nopromisc,
    'r=s'         => \@infile,
    # output
    'v|verbose'   => \$verbose,
    'D|dir=s'     => \$outdir,
    'uncompress!' => \$uncompress,
    'unchunk!'    => \$unchunk,
    'anon-stats'  => \$anon_stats,
    # debug
    'd|debug'     => \$DEBUG,
    'T|trace=s'   => sub { push @trace, split(m/,/, $_[1]) },
) or $usage->();
$usage->('only interface or file can be set') if @infile and $dev;
$infile[0] = '/dev/stdin' if ! $dev and ! @infile;
$verbose = 1 if ! $outdir && ! $anon_stats;
my $pcapfilter = join(' ',@ARGV);
$TRACE{$_} = 1 for(@trace);
die "cannot write to $outdir: $!" if $outdir and ! -w $outdir || ! -d _;


# ---------------------------------------------------------------------------- 
# process files
# ---------------------------------------------------------------------------- 

for my $infile (@infile ? @infile : undef ) {
    # ------------------------------------------------------------------------ 
    # open pcap
    # ------------------------------------------------------------------------ 
    my $err;
    my $pcap = $infile
	? Net::Pcap::pcap_open_offline($infile,\$err)
	: Net::Pcap::pcap_open_live($dev,2**16,!$nopromisc,0,\$err);
    $pcap or die $err;
    if ( $pcapfilter ) {
	Net::Pcap::pcap_compile($pcap, \(my $compiled), $pcapfilter,0,0xffffffff) == 0
	    or die "bad filter '$pcapfilter'";
	Net::Pcap::pcap_setfilter($pcap,$compiled) == 0 or die "pcap_setfilter failed";
    }

    # ------------------------------------------------------------------------ 
    # setup parse hierarchy
    # ------------------------------------------------------------------------ 

    my $guess = Net::Inspect::L5::GuessProtocol->new;
    my $tcp   = Net::Inspect::L4::TCP->new($guess);
    my $raw   = Net::Inspect::L3::IP->new($tcp);
    my $pc    = Net::Inspect::L2::Pcap->new($pcap,$raw);

    my $http_request = privHTTPRequest->new(
	! $outdir ? (): ( 
	    dir => $outdir, 
	    fcache => privFileCache->new(128) 
	),
	! ( $verbose || $anon_stats ) ? () : (
	    info => \&info,
	),
    );
    if ( $outdir ) {
	my %opt = ( '-original-header-prefix' => 'X-Original-' );
	$http_request->add_hooks( %opt,'unchunk') if $unchunk || $uncompress;
	$http_request->add_hooks( %opt,'uncompress_te','uncompress_ce') if $uncompress;
    }

    my $http_conn = privHTTPConn->new($http_request);
    my $null = Net::Inspect::L5::NoData->new();
    my $fallback = Net::Inspect::L5::Unknown->new();

    $guess->attach($http_conn);
    $guess->attach($null);
    $guess->attach($fallback);

    # detect socks encapsulation
    my $guess2 = Net::Inspect::L5::GuessProtocol->new;
    my $socks = Net::Inspect::L5::Socks->new($guess2);
    $guess2->attach($http_conn);
    $guess2->attach($null);
    $guess2->attach($fallback);
    $guess->attach($socks);


    # ------------------------------------------------------------------------ 
    # pcap loop
    # ------------------------------------------------------------------------ 
    my $time;
    Net::Pcap::pcap_loop($pcap,-1,sub {
	my (undef,$hdr,$data) = @_;
	if ( ! $time || $hdr->{tv_sec}-$time>10 ) {
	    $tcp->expire($time = $hdr->{tv_sec});
	}
	return $pc->pktin($data,$hdr);
    },undef);
}


# ---------------------------------------------------------------------------- 
# verbose/anon-stats
# ---------------------------------------------------------------------------- 
my $basetime;
sub info {
    my ($line,$d) = @_;
    print "$line\n" if $verbose;
    if ( $anon_stats ) {
	$basetime ||= $d->{meta}{time};
	my $ct = $d->{resp}->header('content-type') || '?';
	$ct =~s/;.*//;
	my $ce = $d->{resp}->header('content-encoding');
	printf("%7.2f %6.2f %05d.%04d %s/%s%s stat:%d,%d,%d,%d%s%s\n",
	    $d->{meta}{time} - $basetime,
	    $d->{stat}{duration},
	    $d->{flowid}, $d->{reqid},
	    $d->{method},
	    $d->{resp}->code,
	    $d->{stat}{rpbody} ? " ct:$ct" : '',
	    $d->{stat}{rqhdr}, $d->{stat}{rqbody},
	    $d->{stat}{rphdr}, $d->{stat}{rpbody},
	    $d->{stat}{chunks} ? " chunks:$d->{stat}{chunks}" :'',
	    $ce ? " ce:$ce":''
	);
    }
}
