#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long qw(:config posix_default bundling);
use Net::Inspect::Debug '%TRACE';
use Net::Inspect::L2::Pcap;
use Net::Inspect::L3::IP;
use Net::Inspect::L4::TCP;
use Net::Inspect::L4::UDP;
use Net::PcapWriter 0.721;
use Net::Pcap qw(pcap_open_offline pcap_loop);
use Net::IMP;
use Net::IMP::Cascade;
use Net::IMP::Debug;

# interface we support in this program
my @rtypes = (
    IMP_PASS,
    IMP_PREPASS,
    IMP_DENY,
    IMP_REPLACE,
    IMP_LOG,
    IMP_ACCTFIELD,
    IMP_PAUSE,
    IMP_CONTINUE,
    IMP_FATAL,
);
my @interface = (
    [ IMP_DATA_STREAM, \@rtypes ],
    [ IMP_DATA_PACKET, \@rtypes ],
);


sub usage {
    print STDERR <<USAGE;

filter tcp connections from pcap file using Net::IMP analyzers
$0 Options*  -r in.pcap -w out.pcap

Options:
  -h|--help               show usage
  -M|--module mod[=arg]   use Net::IMP module for connections
			  can be given multiple times for cascading modules
  -r|--read  in.pcap      input pcap file
  -w|--write out.pcap     output pcap file
  -d|--debug              debug mode
  -T|--trace T            Net::Inspect traces

USAGE
    exit(2);
}

my (@module,$infile,$outfile);
GetOptions(
    'M|module=s' => \@module,
    'r|read=s'   => \$infile,
    'w|write=s'  => \$outfile,
    'h|help'     => sub { usage() },
    'd|debug'    => \$DEBUG,
    'T|trace=s'  => sub { $TRACE{$_}=1 for split(m/,/,$_[1]) }
);

$Net::Inspect::Debug::DEBUG=$DEBUG;

$infile ||= '/dev/stdin';
my $err;
my $pcap_in = pcap_open_offline($infile,\$err) or die $err;
my $pcap_out = Net::PcapWriter->new( $outfile || \*STDOUT ) or die $!;


my @factory;
for my $module (@module) {
    $module eq '=' and next;
    my ($mod,$args) = $module =~m{^([a-z][\w:]*)(?:=(.*))?$}i
	or die "invalid module $module";
    eval "require $mod" or die "cannot load $module";
    my %args = $mod->str2cfg($args//'');
    my $factory = $mod->new_factory(%args) or
	croak("cannot create Net::IMP factory for $mod");
    push @factory, $factory;
}

my $imp_factory;
if (@factory == 1) {
    $imp_factory = $factory[0];
} elsif (@factory) {
    $imp_factory = Net::IMP::Cascade->new_factory(
	parts => \@factory
    ) or croak("cannot create factory from Net::IMP::Cascade");
}
@interface = $imp_factory->get_interface(@interface) or
    croak("cannot use modules - wrong interface");

my @l4;
for my $if (@interface) {
    if ( $if->[0] == IMP_DATA_STREAM ) {
	# factory support stream interface
	my $cw  = ConnWriter->new($pcap_out,$imp_factory);
	push @l4,Net::Inspect::L4::TCP->new($cw);
    } elsif ( $if->[0] == IMP_DATA_PACKET ) {
	# factory support packet interface
	my $pw  = PacketWriter->new($pcap_out,$imp_factory);
	push @l4,Net::Inspect::L4::UDP->new($pw);
    }
}
my $raw = Net::Inspect::L3::IP->new(@l4>1 ? \@l4:@l4);
my $pc  = Net::Inspect::L2::Pcap->new($pcap_in,$raw);

my $time;
my @tcpconn;
pcap_loop($pcap_in,-1,sub {
    my (undef,$hdr,$data) = @_;
    if ( ! $time || $hdr->{tv_sec}-$time>10 ) {
	$_->expire($time = $hdr->{tv_sec}) for(@l4);
    }
    return $pc->pktin($data,$hdr);
},undef);

for(@tcpconn) {
    $_ or next;
    $_->shutdown(0);
    $_->shutdown(1);
}


package ConnWriter;
use base 'Net::IMP::Filter';
use Net::IMP;

sub new {
    my ($class,$pcap,$imp) = @_;
    my $self = $class->SUPER::new($imp, pcap => $pcap, expire => 0);
    return $self;
}

sub new_connection {
    my ($self,$meta) = @_;
    my $imp = $self->{imp}
	&& $self->{imp}->new_analyzer(meta => $meta);
    my $pcap = $self->{pcap}->tcp_conn(
	$meta->{saddr}, $meta->{sport},
	$meta->{daddr}, $meta->{dport},
    );

    # collect open connections to destroy them before pcap writer
    # gets destroyed
    @tcpconn = grep { $_ } @tcpconn;
    push @tcpconn,$pcap;
    Scalar::Util::weaken( $tcpconn[-1] );

    return $self->new($pcap,$imp);
}

sub syn { return 1 }
sub fatal { warn "fatal: $_[1]\n" }
sub in {
    my ($self,$dir,$data,$eof) = @_;
    $self->SUPER::in($dir,$data,IMP_DATA_STREAM) if $data ne '';
    $self->SUPER::in($dir,'',IMP_DATA_STREAM) if $eof;
    return length($data);
}

sub out {
    my ($self,$dir,$data) = @_;
    $self->{pcap}->write($dir,$data);
}

sub expire {
    my ($self,$expire) = @_;
    return $self->{expire} && $time>$self->{expire};
}

sub log {
    my ($self,$level,$msg,$dir,$offset,$len) = @_;
    print STDERR "[$level] $msg\n";
}


package PacketWriter;
sub new {
    my ($class,$pcap,$imp) = @_;
    my $self = bless [ $imp,$pcap ],$class;
    return $self;
}

sub pktin {
    my ($self,$data,$meta) = @_;
    my $imp = $self->[0] && $self->[0]->new_analyzer(meta => $meta);
    my $pcap = $self->[1]->udp_conn(
	$meta->{saddr}, $meta->{sport},
	$meta->{daddr}, $meta->{dport},
    );
    my $conn = PacketWriter::Conn->new($pcap,$imp);
    $conn->pktin(0,$data);
    return $conn;
}

package PacketWriter::Conn;
use base 'Net::IMP::Filter';
use Net::IMP;

sub new {
    my ($class,$pcap,$imp) = @_;
    return $class->SUPER::new($imp, pcap => $pcap, expire => 0 );
}

sub fatal { warn "fatal: $_[1]\n" }
sub pktin {
    my ($self,$dir,$data) = @_;
    $self->SUPER::in($dir,$data,IMP_DATA_PACKET);
    return length($data);
}

sub out {
    my ($self,$dir,$data) = @_;
    $self->{pcap}->write($dir,$data) if $data ne '';
}

sub expire {
    my ($self,$expire) = @_;
    return $self->{expire} && $time>$self->{expire};
}

sub log {
    my ($self,$level,$msg,$dir,$offset,$len) = @_;
    print STDERR "[$level] $msg\n";
}

