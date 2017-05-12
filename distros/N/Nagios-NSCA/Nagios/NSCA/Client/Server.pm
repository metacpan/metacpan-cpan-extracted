package Nagios::NSCA::Client::Server;
use strict;
use warnings;
use UNIVERSAL;
use IO::Socket::INET;
use Nagios::NSCA::InitPacket;
use Nagios::NSCA::Client::Encrypt;
use Nagios::NSCA::Client::Settings;
use base 'Nagios::NSCA::Client::Base';

our $VERSION = sprintf("%d", q$Id: Server.pm,v 1.2 2006/04/10 22:39:39 matthew Exp $ =~ /\s(\d+)\s/);

sub new {
    my ($class, %args) = @_;
    my $settings = Nagios::NSCA::Client::Settings->new();
    my $fields = {
        host => $settings->host,
        port => $settings->port,
        socket => undef,
        timestamp => undef,
        iv => undef,
        numPacketsSent => 0,
        encrypter => undef,
    };
    my $self = $class->SUPER::new(%args);
    $self->_initFields($fields);

    # Set the fields from the constructor values
    $self->host($args{host});
    $self->port($args{port});

    return $self;
}

sub connect {
    my $self = shift;
    my $socket = IO::Socket::INET->new(PeerAddr => $self->host,
                                       PeerPort => $self->port,
                                       Proto => 'tcp');
    if (not $socket) {
        die "$!\nError: Could not connect to host " . $self->host .
            " on port " . $self->port . "\n";
    }

    $self->socket($socket);
    $self->getInitializationPacket();
    $self->createEncrypter();
}

sub getInitializationPacket {
    my $self = shift;
    my $packet;

    my $size = Nagios::NSCA::InitPacket->size;
    $self->socket->recv($packet, $size, MSG_WAITALL);
    if (not $packet) {
        die "Error: Did not receive initialization packet.\n";
    }

    $packet = Nagios::NSCA::InitPacket->new(binary => $packet);
    $self->timestamp($packet->timestamp);
    $self->iv($packet->iv);
}

sub createEncrypter {
    my $self = shift;
    my $settings = Nagios::NSCA::Client::Settings->new();

    # Setup the encryption object.  We put the class name in a variable so as
    # to appease the 80-column gods.
    my $algo = $settings->encryption;
    my $enc = Nagios::NSCA::Client::Encrypt->new(iv => $self->iv,
                                                 key => $settings->password,
                                                 algorithm => $algo);
    $self->encrypter($enc);
}

sub sendPacket {
    my ($self, $packet) = @_;
    my $rv = 0;

    eval {
        if ($packet and UNIVERSAL::isa($packet, 'Nagios::NSCA::DataPacket')) {
            my $data = $self->encrypter->encrypt($packet->toBinary);
            if ($packet->size == $self->socket->send($data)) {
                $rv = 1;
                $self->numPacketsSent($self->numPacketsSent + 1);
            }
        }
    };
    $rv = 0 if $@;
    warn "$@\n" if $@;

    return $rv;
}

1;
