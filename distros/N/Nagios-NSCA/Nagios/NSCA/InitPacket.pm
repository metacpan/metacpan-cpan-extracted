package Nagios::NSCA::InitPacket;
use strict;
use warnings;
use base 'Nagios::NSCA::Base';
use constant IV_SEGMENT => 'C128';
use constant TIMESTAMP_SEGMENT => 'N';
use constant INIT_PACKET_STRUCT => IV_SEGMENT . TIMESTAMP_SEGMENT;
use constant INIT_PACKET_SIZE => 132;

our $VERSION = sprintf("%d", q$Id: InitPacket.pm,v 1.2 2006/04/10 22:39:38 matthew Exp $ =~ /\s(\d+)\s/);

sub new {
    my ($class, %args) = @_;
    my $fields = {
        iv => $class->_makeDefaultIV(),
        timestamp => time(),
    };
    my $self = $class->SUPER::new(%args);
    $self->_initFields($fields);

    # Get inital values from the binary packet
    if (defined $args{binary}) {
        $self->_initFromBinary($args{binary});
    } 

    $self->iv($args{iv});
    $self->timestamp($args{timestamp});

    return $self;
}

sub size {
    return INIT_PACKET_SIZE;
}

sub toBinary {
    my $self = shift;
    pack("a128" .  TIMESTAMP_SEGMENT, $self->iv, $self->timestamp);
}

sub _initFromBinary {
    my ($self, $packet) = @_;
    my @data = unpack(INIT_PACKET_STRUCT, $packet);
    $self->timestamp(pop @data);
    $self->iv(pack(IV_SEGMENT, unpack(IV_SEGMENT, $packet)));
}

sub _makeDefaultIV {
    my $class = shift;
    my @chars = map {int rand 256} (1 .. 128);
    return pack(IV_SEGMENT, @chars);
}

1;
