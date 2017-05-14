# $Id: Port.pm 18 2008-05-05 23:55:18Z jabra $
package NexposeSimpleXML::Parser::Host::Service;
{
    use Object::InsideOut;

    my @name : Field : Arg(name) : Get(name);
    my @protocol : Field : Arg(protocol) : Get(protocol);
    my @port : Field : Arg(port) : Get(port);
    my @fingerprint : Field : Arg(fingerprint) : Get(get_fingerprint) : Type(NexposeSimpleXML::Parser::Fingerprint);
    my @vulnerabilities : Field : Arg(vulnerabilities) : Get(vulnerabilities) : Type(List(NexposeSimpleXML::Parser::Vulnerability));
   sub get_all_vulnerabilities {
        my ($self) = @_;
        my @all_vulnerabilities = @{ $self->vulnerabilities };
        return @all_vulnerabilities;
    }

}
1;
