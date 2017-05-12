use strict;
use warnings;
package Net::PcapWriter::ICMP_Echo;
use fields qw(id src dst seq ip6 l2prefix writer);
use Net::PcapWriter::IP;

sub new {
    my ($class,$writer,$src,$dst,$identifier) = @_;
    $identifier = 0 if ! defined $identifier;
    my $self = fields::new($class);
    $self->{writer} = $writer;
    $self->{id}     = $identifier;
    $self->{src}    = $src;
    $self->{dst}    = $dst;
    $self->{l2prefix} = $self->{writer}->layer2prefix($src);
    $self->{ip6}    = $src =~m{:};
    return $self;
}



sub _write {
    my ($self,$dir,$seq,$data,$timestamp) = @_;

    my ($src,$dst) = $dir ? @{$self}{qw(dst src)} : @{$self}{qw(src dst)};
    my $type = $dir ?
	$self->{ip6} ? 129 : 0 :  # echo reply
	$self->{ip6} ? 128 : 8;   # echo request
    my $echo = pack("CCnnna*",
	$type,
	0,             # code = 0
	0,             # checksum, computed below
	$self->{id},   # identifier
	$seq,          # sequence
	$data          # payload
    );

    $self->{writer}->packet(
	# checksum at offset 2
	# for ip4 no pseudo-header will be included in checksum
	$self->{l2prefix} . ( $self->{ip6}
	    ? ip6_packet($echo,$src,$dst, 58, 2  )
	    : ip4_packet($echo,$src,$dst,  1, 2,1)
	),
	$timestamp
    );
}


*echo_request = \&ping;
sub ping {
   my ($self,$seq,$data,$timestamp) = @_;
   $self->_write(0,$seq,$data,$timestamp);
}

*echo_response = \&pong;
sub pong {
   my ($self,$seq,$data,$timestamp) = @_;
   $self->_write(1,$seq,$data,$timestamp);
}

1;
