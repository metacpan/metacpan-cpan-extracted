package Penguin::Channel::TCP::Server;

use Penguin::Channel::TCP;

use Penguin::Frame::Code;
use Penguin::Frame::Data;

use IO::Socket;

@ISA = qw( Penguin::Channel::TCP );

$VERSION = "4.0";

sub new {
    my ($class, %args) = @_;
    my $bindport = ($args{'Bind'} or 8118); # standard Penguin port
    my $listeners = ($args{'Listen'} or 5); # what one might imagine
    $self = {};

    $self->{'Master Socket'} = new IO::Socket::INET LocalPort => $bindport,
                                                    Listen => $listeners,
                                                    Proto => 'tcp';
    
    if (! $self->{'Master Socket'}) {
        die("Unable to create a socket on port $bindport.  Try another?");
    }

    $self->{'Master Socket'}->autoflush();
    bless $self, $class;
}

sub open { # gets a new connection, or waits until one comes along
    my ($self, %args) = @_;

    $self->{'Socket'} = $self->{'Master Socket'}->accept();
    $self->{'Status'} = 'connected';
}
1;
