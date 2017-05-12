# $Id: Host.pm 142 2009-10-16 19:13:45Z jabra $
package Nikto::Parser::Host;
{
    our $VERSION = '0.01';
    $VERSION = eval $VERSION;

    use Object::InsideOut;

    my @ip : Field : Arg(ip) : Get(ip);
    my @hostname : Field : Arg(hostname) : Get(hostname);
    my @ports : Field : All(ports) : Type(List(Nikto::Parser::Host::Port));

    # returns the port obj based on port number
    sub get_port {
        my ( $self, $port ) = @_;
        my @ports = grep( $_->port eq $port, @{ $self->ports } );
        return $ports[0];
    }

    # returns a ArrayRef containing a list of port objs
    sub get_all_ports {
        my ($self) = @_;
        my @ports = @{ $self->ports };
        return @ports;
    }
}
1;
