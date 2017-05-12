use strict;
use Net::Inspect::L2::Pcap;
use Net::Inspect::L3::IP;
use Net::Inspect::L4::TCP;
use Net::Inspect::L5::GuessProtocol;
use Net::Inspect::L5::Unknown;
use Net::Inspect::L7::SMTP;
use Net::Inspect::Debug qw(:DEFAULT %TRACE $DEBUG);
use Net::Pcap ':functions';
use Getopt::Long qw(:config posix_default bundling);

my $usage = sub {
    print STDERR "ERROR: @_\n" if @_;
    print STDERR <<USAGE;

Reads SMTP traffic from pcap file or device and extracts mails into mbox format,
which then will be written to stdout.

Usage: $0 [options] [pcap-filter]
Options:
    -h|--help        this help

    ## input
    -i dev           read pcap from dev
    -p               do net set dev into promisc mode
    -r file.pcap     read pcap from file, use stdin if not given and no dev
		     more then one file can be given by using option multiple
		     times

    ## debugging
    -d|--debug       various debug messages are shown
    -T trace         trace messages are enabled in the modules, option can
		     be given multiple times, trace is last part of module name,
		     e.g. tcp, rawip, http,...
		     To enable all specify '*'
USAGE
    exit(2);
};

my ($dev,$nopromisc,@infile);
GetOptions(
    'h|help'      => sub { $usage->() },
    # input
    'i=s'         => \$dev,
    'p'           => \$nopromisc,
    'r=s'         => \@infile,
    # debug
    'd|debug'     => \$DEBUG,
    'T|trace=s'   => sub { $TRACE{$_}=1 for split(m/,/, $_[1]) },
) or $usage->();
$usage->('only interface or file can be set') if @infile and $dev;
$infile[0] = '/dev/stdin' if ! $dev and ! @infile;
my $pcapfilter = join(' ',@ARGV);

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

    my $guess = Net::Inspect::L5::GuessProtocol->new;
    my $tcp   = Net::Inspect::L4::TCP->new($guess);
    my $raw   = Net::Inspect::L3::IP->new($tcp);
    my $pc    = Net::Inspect::L2::Pcap->new($pcap, $raw);

    my $sc = mySMTPConn->new;
    my $smtp  = Net::Inspect::L7::SMTP->new($sc);
    $guess->attach($smtp);

    Net::Pcap::loop( $pcap, -1, sub {
	my (undef, $hdr, $data) = @_;
	$pc->pktin($data, $hdr);
    }, undef );
}



package mySMTPConn;
use base 'Net::Inspect::Flow';
use fields qw(prefix mail cmd);

sub new {
    my ($class,$flow) = @_;
    my $self = $class->SUPER::new($flow);
    $self->{cmd} = [];
    _rset($self);
    return $self;
}

sub _rset {
    my $self = shift;
    $self->{mail} = '';
    $self->{prefix} = "X-SMTP-Trace:\n";
}

sub _save {
    my $self = shift;
    s{\r\n}{\n}g for($self->{mail},$self->{prefix});
    print "From somebody Thu Jun 16 15:46:20 2016\n".
	$self->{prefix}.
	$self->{mail}.
	"\n";
}

sub _smtp_trace {
    my ($self,$dir,$data) = @_;
    $self->{prefix} or return;
    $data .= "\n" if $data !~ m{\n\z};
    $dir = $dir ? '<<':'>>';
    $data =~s{^(.)}{ $dir $1}mg;
    $self->{prefix} .= $data;
}

sub greeting {
    my ($self,$msg,$time) = @_;
    _smtp_trace($self,0,$msg);
}

sub response {
    my ($self,$msg,$time) = @_;
    my ($code) = $msg =~m{^(\d\d\d)} or die $msg;
    my $cmd = pop @{$self->{cmd}};
    die "cmd stack underflow" if ! defined $cmd;

    if ($cmd eq 'AUTH' && $code =~m{^3}) {
	# don't log sensitive data
    } else {
	_smtp_trace($self,0,$msg);
    }

    if ($code =~m{^3}) {
	push @{$self->{cmd}},$cmd
    } elsif ($cmd eq 'RSET') {
	_rset($self);
    } elsif ($cmd eq 'DATA') {
	_save($self) if $code =~m{^2};
	_rset($self);
    }
}

sub command {
    my ($self,$msg,$time) = @_;
    my ($cmd) = $msg =~m{^(\w+)} or die $msg;
    push @{$self->{cmd}},uc($cmd);

    $msg =~s{^(\w+\s+\w+).*}{$1} if $cmd eq 'AUTH';
    _smtp_trace($self,1,$msg);
}

sub mail_data {
    my ($self,$chunk,$time) = @_;
    $self->{mail} .= $chunk;
}

sub auth_data {
    my ($self,$dir,$chunk,$time) = @_;
    return; # do nothing
}

sub fatal {
    my ($self,$dir,$reason,$time) = @_;
    warn "[$dir] $reason\n";
}
