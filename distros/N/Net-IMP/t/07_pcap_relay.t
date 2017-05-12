use strict;
use warnings;
use Test::More;
use File::Temp 'tempfile';
use Data::Dumper;

$Data::Dumper::Sortkeys = 1;

for (qw(
    Net::Pcap
    Net::PcapWriter!0.721
    Net::Inspect!0.24
    Net::Inspect::L4::TCP
    Net::Inspect::L3::IP
    Net::Inspect::L2::Pcap
    Net::IMP::ProtocolPinning
)) {
    my ($mod,$want_version) = split('!');
    if ( ! eval "require $mod" ) {
	plan skip_all => "cannot load $mod";
	exit;
    } elsif ( $want_version ) {
	no strict 'refs';
	my $v = ${"${mod}::VERSION"};
	if ( ! $v or $v < $want_version ) {
	    plan skip_all => "wrong version $mod - have $v want $want_version";
	    exit;
	}
    }
}

# find imp-pcap-file program
my $bin;
for(qw(. ..)) {
    my $f = "$_/bin/imp-pcap-filter.pl";
    -f $f or next;
    $bin = $f;
    last;
}
$bin or die "imp-pcap-filter.pl not found";

plan tests => 2;

# write test pcap file
my ($in,$out);
END { unlink($_) for (grep {$_} ($in,$out)) }
(undef,$in)  = tempfile();
(undef,$out) = tempfile();

my $pw = Net::PcapWriter->new($in)
    or die "cannot create pcapfile $in";
my $conn = $pw->tcp_conn('1.1.1.1',11,'2.2.2.2',22);
$conn->write(0,'foo');
$conn->write(1,'bar');
$conn->write(0,'pass');
$conn = $pw = undef;

# create ProtocolPinning config
my $config = Net::IMP::ProtocolPinning->cfg2str(
    rules => [
	{ dir => 0, rxlen => 3, rx => qr/foo/ },
	{ dir => 1, rxlen => 3, rx => qr/bar/ },
    ],
);

alarm(30);
$ENV{PERL5LIB} = join(':',@INC);
system( $^X, $bin,
    '--read',   $in,
    '--write',  $out,
    '--module', "Net::IMP::ProtocolPinning=$config",
    #'--debug',
) == 0 or fail("exec failed: $!");
pass("exec ok");
alarm(0);

my $err;
my $pcap = Net::Pcap::pcap_open_offline( $out,\$err )
    or die $err;

my @pkt;
my $ch  = ConnHandler->new(\@pkt);
my $tcp = Net::Inspect::L4::TCP->new($ch);
my $raw = Net::Inspect::L3::IP->new($tcp);
my $pc  = Net::Inspect::L2::Pcap->new($pcap,$raw);
Net::Pcap::pcap_loop($pcap,-1,sub {
    my (undef,$hdr,$data) = @_;
    return $pc->pktin($data,$hdr);
},undef);

my @expect = ([0,'foo'],[1,'bar'],[0,'pass']);
is( Dumper(\@pkt),Dumper(\@expect),"pcap out ok");


package ConnHandler;
sub new {
    my ($self,$pkts) = @_;
    if ( ref($self)) {
	return bless { pkts => $pkts || $self->{pkts} },ref($self);
    } else {
	return bless { pkts => $pkts},$self
    }
}

sub new_connection {
    my ($self,$meta) = @_;
    return $self->new;
}

sub syn { 1 }
sub fatal { die "@_\n" }
sub in {
    my ($self,$dir,$data) = @_;
    push @{ $self->{pkts}}, [ $dir,$data ] if $data ne '';
    return length($data);
}
