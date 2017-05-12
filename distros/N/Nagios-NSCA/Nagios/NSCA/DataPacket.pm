package Nagios::NSCA::DataPacket;
use strict;
use warnings;
use Digest::CRC;
use base 'Nagios::NSCA::Base';
use constant NSCA_PACKET_VERSION => 3;
use constant DEFAULT_NSCA_CODE => 3;
use constant DATA_PACKET_STRUCT => 'n x2 N N n Z64 Z128 Z512 x2';
use constant DATA_PACKET_SIZE => 720;

our $VERSION = sprintf("%d", q$Id: DataPacket.pm,v 1.2 2006/04/10 22:39:38 matthew Exp $ =~ /\s(\d+)\s/);

sub new {
    my ($class, %args) = @_;
    my $fields = {
        version => NSCA_PACKET_VERSION,
        crc => undef,
        timestamp => time(),
        code => DEFAULT_NSCA_CODE,
        host => "",
        service => "",
        output => "",
    };
    my $self = $class->SUPER::new(%args);
    $self->_initFields($fields);

    # Get inital values from the binary packet
    if (defined $args{binary}) {
        $self->_initFromBinary($args{binary});
    } 

    # Set fields passed into constructor, overriding any previous values.
    $self->version($args{version});
    $self->crc($args{crc});
    $self->timestamp($args{timestamp});
    $self->code($args{code});
    $self->host($args{host});
    $self->service($args{service});
    $self->output($args{output});

    # If a CRC arg was not supplied and the packet wasn't initialized from 
    # binary data then calculated the CRC field.  Otherwise we just defer to
    # the passed in value and/or value from the binary data.
    if (not $args{crc} and not $args{binary}) {
        $self->calculateCRC32();
    }

    return $self;
}

sub size {
    return DATA_PACKET_SIZE;
}

sub toText {
    my $self = shift;

    # Add time stamp and Nagios command name
    my $text = "[" . $self->timestamp . "] ";
    if ($self->service) {
        $text .= "PROCESS_SERVICE_CHECK_RESULT;"; 
    } else {
        $text .= "PROCESS_HOST_CHECK_RESULT;";
    }

    # Add the rest of the data
    $text .= $self->host . ";"; 
    $text .= $self->service . ";" if $self->service;
    $text .= $self->code . ";";
    $text .= $self->output . "\n";

    return $text;
}

sub toBinary {
    my ($self, $noCRC) = @_;
    return pack(DATA_PACKET_STRUCT, $self->version,
                                    ($noCRC ? 0 : $self->crc),
                                    $self->timestamp,
                                    $self->code,
                                    $self->host,
                                    $self->service,
                                    $self->output);
}

sub calculateCRC32 {
    my $self = shift;
    my $packet = $self->toBinary("no crc");
    my $crcGen = Digest::CRC->new(type => 'crc32');
    $crcGen->add($packet);
    $self->crc($crcGen->digest());
}

sub _initFromBinary {
    my ($self, $packet) = @_;
    my @fields = unpack(DATA_PACKET_STRUCT, $packet);
    for my $field (qw(version crc timestamp code host service output)) {
        $self->$field(shift @fields);
    }
}

1;
