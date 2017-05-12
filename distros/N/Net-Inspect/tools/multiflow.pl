#!/usr/bin/perl
use strict;
use warnings;

use Getopt::Long qw(:config posix_default bundling);
use Net::Pcap;

# use private include path based on script path
BEGIN { 
    my $bin = __FILE__;
    $bin = readlink($bin) while ( -l $bin );
    my ($dir) = $bin =~m{^(.*?)(?:\.\w+)?$};
    if ( -d $dir ) {
	unshift @INC,$dir
    } elsif ($dir =~s{/multiflow$}{/httpflow}) {
	unshift @INC,$dir
    }
}

use Net::Inspect::L2::Pcap;
use Net::Inspect::L3::IP;
use Net::Inspect::L4::TCP;
use Net::Inspect::L4::UDP;
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
my (@infile,$dev,$nopromisc,@trace);
my $outdir = '.';
my $http_uncompress = my $http_unchunk = 1;
my %flow = qw( udp 1 tcp 1 http 1 );

my $usage = sub {
    print STDERR "ERROR: @_\n" if @_;
    print STDERR <<USAGE;

Reads data from pcap file or device and analyzes it.
It will extract UDP and TCP streams and HTTP requests and will write each of
these into a separate pcap file. HTTP bodies will be unchunked and uncompressed
by default.

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
    --(no)tcp        extract TCP streams
    --(no)udp        extract UDP streams
    --(no)http       extract HTTP requests
    -D dir           extract data into dir, default .

    ## HTTP specific
    --http-(no)unchunk        unchunking if saving (default on)
    --http-(no)uncompress     uncompression if saving (default on)

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
    'D|dir=s'     => \$outdir,
    'udp!'        => \$flow{udp},
    'tcp!'        => \$flow{tcp},
    'http!'       => \$flow{http},
    'http-uncompress!' => \$http_uncompress,
    'http-unchunk!'    => \$http_unchunk,
    # debug
    'd|debug'     => \$DEBUG,
    'T|trace=s'   => sub { push @trace, split(m/,/, $_[1]) },
) or $usage->();
$usage->('only interface or file can be set') if @infile and $dev;
$infile[0] = '/dev/stdin' if ! $dev and ! @infile;
my $pcapfilter = join(' ',@ARGV);
$TRACE{$_} = 1 for(@trace);
die "cannot write to $outdir: $!" if $outdir and ! -w $outdir || ! -d _;


# ---------------------------------------------------------------------------- 
# process files
# ---------------------------------------------------------------------------- 

my $fcache = privFileCache->new(128);
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


    my (%l4,$tcp_guess);
    if ($flow{udp}) {
	$l4{udp} = Net::Inspect::L4::UDP->new(PcapWriter->new('udp'));
    }

    if ($flow{http}) {
	my $tcp_guess = Net::Inspect::L5::GuessProtocol->new;
	$l4{tcp} = Net::Inspect::L4::TCP->new($tcp_guess);

	my $http_request = privHTTPRequest->new( writer => PcapWriter->new('tcp','http'));

	my %opt = ( '-original-header-prefix' => 'X-Original-' );
	$http_request->add_hooks( %opt,'unchunk') 
	    if $http_unchunk || $http_uncompress;
	$http_request->add_hooks( %opt,'uncompress_te','uncompress_ce') 
	    if $http_uncompress;
	$tcp_guess->attach(privHTTPConn->new($http_request));

	# $tcp_guess->attach( Net::Inspect::L5::NoData->new());

	if ($flow{tcp}) {
	    my $rest_tcp = Net::Inspect::L5::Unknown->new(PcapWriter->new('tcp'));
	    $tcp_guess->attach($rest_tcp);
	}

    } elsif ($flow{tcp}) {
	$l4{tcp} = Net::Inspect::L4::TCP->new(PcapWriter->new('tcp'));
    }

    my $raw   = Net::Inspect::L3::IP->new([values %l4]);
    my $pc    = Net::Inspect::L2::Pcap->new($pcap,$raw);

    # ------------------------------------------------------------------------ 
    # pcap loop
    # ------------------------------------------------------------------------ 
    my $time;
    Net::Pcap::pcap_loop($pcap,-1,sub {
	my (undef,$hdr,$data) = @_;
	if ( ! $time || $hdr->{tv_sec}-$time>10 ) {
	    $_->expire($time = $hdr->{tv_sec}) for values %l4;
	}
	return $pc->pktin($data,$hdr);
    },undef);
}


############################################################################
# Connection Object
############################################################################
package PcapWriter;
use base 'Net::Inspect::Connection';
use Net::PcapWriter;
use fields qw(flowid saddr sport daddr dport time writer);
use Net::Inspect::Debug;

my $flowid = 0;
sub new {
    my $class = shift;
    my $self = $class->SUPER::new;
    $self->{flowid} = ++$flowid if ref($class);

    my $wsub;
    if (!@_) {
	$self->{writer} = $class->{writer};
    } elsif (ref($_[0])) {
	$self->{writer} = shift;
    } else {
	my ($proto,$prefix) = @_;
	$prefix ||= $proto;
	$self->{writer} = sub {
	    my $conn = shift;
	    my $fbase = sprintf("%s/%05d-%s.%d-%s.%s-%s.%s",
		$outdir,
		$conn->{flowid},
		$prefix,
		$conn->{time},
		$conn->{saddr}, $conn->{sport},
		$conn->{daddr}, $conn->{dport},
	    );

	    my $fh = $fcache->create("$fbase.pcap");
	    my $w = Net::PcapWriter->new($fh) or die $!;
	    if ( $proto eq 'tcp' ) {
		return $w->tcp_conn(
		    $conn->{saddr}, $conn->{sport},
		    $conn->{daddr}, $conn->{dport},
		);
	    } elsif ($proto eq 'udp') {
		return $w->udp_conn(
		    $conn->{saddr}, $conn->{sport},
		    $conn->{daddr}, $conn->{dport},
		);
	    } else {
		die "unsupported $proto";
	    }
	};
    }


    return $self;
}

sub syn { 1 }
sub new_connection {
    my ($self,$meta) = @_;
    my $obj = $self->new; # clones attached flows
    %$obj = ( %$obj,
	saddr => $meta->{saddr},
	sport => $meta->{sport},
	daddr => $meta->{daddr},
	dport => $meta->{dport},
	time  => $meta->{time},
    );
    $obj->{writer} = $self->{writer}($obj);
    return $obj;
}

sub in {
    my ($self,$dir,$data,$eof,$time) = @_;
    $self->{writer}->write($dir,$data,$time) if $data ne '';
    $self->{writer}->shutdown($dir,$time) if $eof;
    return length($data);
}

# UDP
sub pktin {
    my $self = shift;
    if ( ref($_[1])) {
	# packet w/o connection
	my ($data,$meta) = @_;
	# create connection
	my $conn = $self->new_connection($meta);
	$conn->in(0,$data,0,$meta->{time});
	return $conn;
    } else {
	# already connection
	my ($dir,$data,$time) = @_;
	return $self->in($dir,$data,0,$time);
    }
}

sub fatal {
    my ($self,$reason) = @_;
    warn "fatal: $reason\n";
}

