# $Id: Host.pm 18 2008-05-05 23:55:18Z jabra $
package NexposeSimpleXML::Parser::Host;
{
    use Object::InsideOut;

    my @address : Field : Arg(address) : Get(address);
    my @fingerprint : Field : All(fingerprint) :
        Type(NexposeSimpleXML::Parser::Fingerprint);
    my @services : Field : All(services) :
        Type(List(NexposeSimpleXML::Parser::Host::Service));
    my @vulnerabilities : Field : All(vulnerabilities) :
        Type(List(NexposeSimpleXML::Parser::Vulnerability));

    sub get_all_services {
        my ($self) = @_;
        my @all_services = @{ $self->services };
        return @all_services;
    }

    sub get_fingerprint {
        my ($self) = @_;
        return $self->fingerprint;
    }

    sub get_all_vulnerabilities {
        my ($self) = @_;
        my @all_vulnerabilities = @{ $self->vulnerabilities };
        return @all_vulnerabilities;
    }
}
1;
