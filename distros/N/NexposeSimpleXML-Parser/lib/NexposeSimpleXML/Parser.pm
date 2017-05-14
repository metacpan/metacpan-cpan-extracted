# $Id: Parser.pm 71 2008-08-31 05:58:17Z jabra $
package NexposeSimpleXML::Parser;
{

    use Object::InsideOut;
    use NexposeSimpleXML::Parser::Session;
    my @session : Field : Arg(session) : Get(session) : Type(NexposeSimpleXML::Parser::Session);

    # parse_file
    #
    # Input:
    # argument  -   self obj    -
    # argument  -   xml         scalar
    #
    # Ouptut:
    #
    sub parse_file {
        my ( $self, $file ) = @_;
        my $parser = XML::LibXML->new();

        my $doc = $parser->parse_file($file);
        return NexposeSimpleXML::Parser->new(
            session => NexposeSimpleXML::Parser::Session->parse( $parser, $doc ) );
    }

    sub get_session {
        my ($self) = @_;
        return $self->session;
    }   

    sub get_host {
        my ($self, $ip) = @_;
        return $self->session->scandetails->get_host_ip($ip);
    }

    sub get_all_hosts {
        my ($self) = @_;
        my @all_hosts = $self->session->scandetails->all_hosts();
        return @all_hosts;
    }

    sub get_port {
        my ($self, $port) = @_;
        return $self->session->scandetails->get_port($port);
    }

    sub get_all_ports {
        my ($self) = @_;
        return $self->session->scandetails->all_ports();
    }
}
1;

