use strict;
use warnings;

package Net::Inspect::L2::Pcap;
use Net::Pcap qw(pcap_datalink :datalink);
use base 'Net::Inspect::Flow';
use fields qw(offset);

sub new {
    my ($class,$pcap,$flow) = @_;
    my $linktype = ref($pcap) ? pcap_datalink($pcap) : $pcap;
    my $offset =
	($linktype == DLT_EN10MB)    ? 14 :
	($linktype == DLT_LOOP)      ?  4 :
	($linktype == DLT_NULL)      ?  4 :
	($linktype == DLT_LINUX_SLL) ? 16 :
	($linktype == DLT_RAW)       ?  0 :
	die "cannot handle linktype $linktype";

    my $self = $class->SUPER::new($flow);
    $self->{offset} = $offset;
    return $self;
}

sub pktin {
    my Net::Inspect::L2::Pcap $self = shift;
    my ($data,$hdr) = @_;
    if ( $hdr->{caplen} > $hdr->{len} ) {
	$data = substr($data,0,$hdr->{len});
    } elsif ( $hdr->{caplen} < $hdr->{len} ) {
	warn "packet truncated\n";
	return 1;
    }

    my $time = $hdr->{tv_sec} + $hdr->{tv_usec}/1000_000;
    $data = substr($data,$self->{offset}) if $self->{offset};

    $self->{upper_flow}->pktin($data,$time);
    return 1;
}
1;

__END__

=head1 NAME

Net::Inspect::L2::Pcap - get packets from PCAP

=head1 SYNOPSIS

 # $pcap is Net::Pcap|linktype
 my $pc = Net::Inspect::L2::Pcap->new($pcap);
 $pc->attach( $rawip );
 pcap_loop($pcap,-1,sub {
   my (undef,$hdr,$data) = @_;
   return $pc->pktin($data,$hdr);
 },undef);

=head1 DESCRIPTION

Gets data from pcap via C<pktin> method, extracts data and calls C<pktin> hook
once for each packet.

Usually C<pktin> is called directly and C<Net::Inspect::L3::IP> is used as
upper flow.

Hooks provided:

=over 4

=item pktin($pcapdata,\%pcaphdr)

=back

Hooks called:

=over 4

=item pktin($data,$time)

=back
