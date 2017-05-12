# $Id: Port.pm 134 2009-10-16 18:21:38Z jabra $
package Sslscan::Parser::Host::Port;
{
    our $VERSION = '0.01';
    $VERSION = eval $VERSION;

    use Object::InsideOut;

    my @port : Field : Arg(port) : Get(port);
    my @ciphers : Field : Arg(ciphers) : Get(ciphers) : Type(List(Sslscan::Parser::Host::Port::Cipher));

    sub get_all_ciphers {
        my ($self) = @_;
        my @ciphers = @{ $self->ciphers };
        return @ciphers;
    }
 
}
1;
