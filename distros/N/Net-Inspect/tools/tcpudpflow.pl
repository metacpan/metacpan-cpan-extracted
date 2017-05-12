#!/usr/bin/perl
use strict;
use warnings;
use Socket;
use Getopt::Long qw(:config posix_default bundling);
use Net::Pcap qw(pcap_open_offline pcap_loop);

use Net::Inspect::Debug qw(:DEFAULT %TRACE $DEBUG);
use Net::Inspect::L2::Pcap;
use Net::Inspect::L3::IP;
use Net::Inspect::L4::TCP;
use Net::Inspect::L4::UDP;

############################################################################
# Options
############################################################################
my ($infile,$dev,$nopromisc,@trace,$outdir,$format_pcap);
my %proto = qw( tcp 1 udp 1 );
GetOptions(
    'r=s' => \$infile,
    'i=s' => \$dev,
    'p'   => \$nopromisc,
    'h|help' => sub { usage() },
    'd|debug' => \$DEBUG,
    'T|trace=s' => sub { push @trace,split(m/,/,$_[1]) },
    'D|dir=s' => \$outdir,
    'pcap' => \$format_pcap,
    'tcp!' => \$proto{tcp},
    'udp!' => \$proto{udp},
) or usage();
usage('only interface or file can be set') if $infile and $dev;
$infile ||= '/dev/stdin' if ! $dev;
my $pcapfilter = join(' ',@ARGV);
$TRACE{$_} = 1 for(@trace);
die "cannot write to $outdir: $!" if $outdir and ! -w $outdir || ! -d _;

if ($format_pcap) {
    eval { require Net::PcapWriter }
	or die "need Net::PcapWriter for writing pcap files"
}

sub usage {
    print STDERR "ERROR: @_\n" if @_;
    print STDERR <<USAGE;

reads data from pcap file or device and extracts tcp and udp streams.

Usage: $0 [options] [pcap-filter]
Options:
    -h|--help        this help
    -r file.pcap     read pcap from file
    -i dev           read pcap from dev
    -p               do net set dev into promisc mode
    -D dir           extract data into dir, each flow as a sperate tcp-*
		     or udp-* files, either with seperate files for both
		     direction or with --pcap as pcap files
    --(no)tcp        output TCP or not (default on)
    --(no)udp        output UDP or not (default on)
    --pcap           write each flow as file in pcap format
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

my $writer = sub {
    my $proto = shift;
    return sub {
	my $conn = shift;
	my $fbase = sprintf("%s/%s%05d.%d-%s.%s-%s.%s",
	    $outdir,
	    $proto,
	    $conn->{flowid},
	    $conn->{time},
	    $conn->{saddr}, $conn->{sport},
	    $conn->{daddr}, $conn->{dport},
	);
	if ( $format_pcap ) {
	    my $w = Net::PcapWriter->new("$fbase.pcap") or die $!;
	    if ( $proto eq 'tcp' ) {
		return $w->tcp_conn(
		    $conn->{saddr}, $conn->{sport},
		    $conn->{daddr}, $conn->{dport},
		);
	    } else {
		return $w->udp_conn(
		    $conn->{saddr}, $conn->{sport},
		    $conn->{daddr}, $conn->{dport},
		);
	    }
	}
	return myFileWriter->new($fbase);
    }
};

my %l4;
$l4{tcp} = Net::Inspect::L4::TCP->new( ConnWriter->new( $writer->('tcp'))) if $proto{tcp};
$l4{udp} = Net::Inspect::L4::UDP->new( ConnWriter->new( $writer->('udp'))) if $proto{udp};
my $raw = Net::Inspect::L3::IP->new([values %l4]);
my $pc  = Net::Inspect::L2::Pcap->new($pcap,$raw);


# Mainloop
############################################################################
my $time;
pcap_loop($pcap,-1,sub {
    my (undef,$hdr,$data) = @_;
    if ( ! $time || $hdr->{tv_sec}-$time>10 ) {
	$_->expire($time = $hdr->{tv_sec}) for (values %l4);
    }
    return $pc->pktin($data,$hdr);
},undef);


############################################################################
# Connection Object
############################################################################
package ConnWriter;
use base 'Net::Inspect::Connection';
use fields qw(flowid saddr sport daddr dport time writer);
use Net::Inspect::Debug;

my $flowid = 0;
sub new {
    my ($class,$wsub) = @_;
    my $self = $class->SUPER::new;
    if ( ref $class ) {
	$self->{writer} = $wsub || $class->{writer};
	$self->{flowid} = ++$flowid;
    } else {
	$self->{writer} = $wsub;
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

############################################################################
# myFileWriter
############################################################################
package myFileWriter;
sub new {
    my ($class,$fbase) = @_;
    return bless \$fbase,$class;
}
sub write {
    my ($self,$dir,$data,$time) = @_;
    open( my $fh,'>>',"$$self-$dir" ) or die "open $$self-$dir: $!";
    print $fh $data;
}
sub shutdown {}
