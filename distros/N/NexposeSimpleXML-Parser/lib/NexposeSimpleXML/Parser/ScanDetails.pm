# $Id: ScanDetails.pm 18 2008-05-05 23:55:18Z jabra $
package NexposeSimpleXML::Parser::ScanDetails;
{
    use Object::InsideOut;
    use XML::LibXML;
    use NexposeSimpleXML::Parser::Host;
    use NexposeSimpleXML::Parser::Host::Service;
    use NexposeSimpleXML::Parser::Fingerprint;
    use NexposeSimpleXML::Parser::Vulnerability;
    use NexposeSimpleXML::Parser::Reference;
    my @hosts : Field : Arg(hosts) : Get(hosts) :
        Type(List(NexposeSimpleXML::Parser::Host));

    sub parse {
        my ( $self, $parser, $doc ) = @_;

        my $xpc = XML::LibXML::XPathContext->new($doc);
        my @hosts;

        foreach my $h ( $xpc->findnodes('//NeXposeSimpleXML/devices/device') )
        {
            my $ip = $h->getAttribute('address');
            my @services;

            my (@vulns,          $fp,         $fp_certainty,
                $fp_description, $fp_vendor,  $fp_family,
                $fp_product,     $fp_version, $fp_class
            );
            foreach my $f ( $h->findnodes('fingerprint') ) {
                $fp_certainty = $f->getAttribute('certainty');
                $fp_description
                    = scalar( @{ $f->getElementsByTagName('description') } )
                    > 0
                    ? @{ $f->getElementsByTagName('description') }[0]
                    ->textContent()
                    : undef;
                $fp_device_class
                    = scalar( @{ $f->getElementsByTagName('device-class') } )
                    > 0
                    ? @{ $f->getElementsByTagName('device-class') }[0]
                    ->textContent()
                    : undef;
                $fp_vendor
                    = scalar( @{ $f->getElementsByTagName('vendor') } ) > 0
                    ? @{ $f->getElementsByTagName('vendor') }[0]
                    ->textContent()
                    : undef;
                $fp_family
                    = scalar( @{ $f->getElementsByTagName('family') } ) > 0
                    ? @{ $f->getElementsByTagName('family') }[0]
                    ->textContent()
                    : undef;
                $fp_product
                    = scalar( @{ $f->getElementsByTagName('product') } ) > 0
                    ? @{ $f->getElementsByTagName('product') }[0]
                    ->textContent()
                    : undef;
                $fp_version
                    = scalar( @{ $f->getElementsByTagName('version') } ) > 0
                    ? @{ $f->getElementsByTagName('version') }[0]
                    ->textContent()
                    : undef;
                $fp_arch
                    = scalar( @{ $f->getElementsByTagName('architecture') } )
                    > 0
                    ? @{ $f->getElementsByTagName('architecture') }[0]
                    ->textContent()
                    : undef;

            }
            $host_fp = NexposeSimpleXML::Parser::Fingerprint->new(
                certainty    => $fp_certainty,
                description  => $fp_description,
                family       => $fp_family,
                version      => $fp_version,
                product      => $fp_product,
                vendor       => $fp_vendor,
                arch         => $fp_arch,
                device_class => $fp_device_class,
            );

            my @host_vulns;
            foreach my $v ( $h->findnodes('vulnerabilities/vulnerability') ) {
                my @refs;
                foreach my $r ( $v->findnodes('id') ) {
                    my $ref = NexposeSimpleXML::Parser::Reference->new(
                        id   => $r->textContent(),
                        type => $r->getAttribute('type'),
                    );
                    push( @refs, $ref );
                }
                my $vuln = NexposeSimpleXML::Parser::Vulnerability->new(
                    id          => $v->getAttribute('id'),
                    result_code => $v->getAttribute('resultCode'),
                    references  => \@refs,
                );
                push( @host_vulns, $vuln );
            }

            foreach my $s ( $h->findnodes('services/service') ) {

                my ( @vulns, $fp, $fp_certainty, $fp_description, $fp_vendor,
                    $fp_family, $fp_product, $fp_version );
                foreach my $f ( $s->findnodes('fingerprint') ) {
                    $fp_certainty = $f->getAttribute('certainty');
                    $fp_description
                        = scalar(
                        @{ $f->getElementsByTagName('description') } ) > 0
                        ? @{ $f->getElementsByTagName('description') }[0]
                        ->textContent()
                        : undef;
                    $fp_vendor
                        = scalar( @{ $f->getElementsByTagName('vendor') } )
                        > 0
                        ? @{ $f->getElementsByTagName('vendor') }[0]
                        ->textContent()
                        : undef;
                    $fp_family
                        = scalar( @{ $f->getElementsByTagName('family') } )
                        > 0
                        ? @{ $f->getElementsByTagName('family') }[0]
                        ->textContent()
                        : undef;
                    $fp_product
                        = scalar( @{ $f->getElementsByTagName('product') } )
                        > 0
                        ? @{ $f->getElementsByTagName('product') }[0]
                        ->textContent()
                        : undef;
                    $fp_version
                        = scalar( @{ $f->getElementsByTagName('version') } )
                        > 0
                        ? @{ $f->getElementsByTagName('version') }[0]
                        ->textContent()
                        : undef;

                }
                $fp = NexposeSimpleXML::Parser::Fingerprint->new(
                    certainty   => $fp_certainty,
                    family      => $fp_family,
                    version     => $fp_version,
                    product     => $fp_product,
                    vendor      => $fp_vendor,
                    description => $fp_description,
                );

                foreach
                    my $v ( $s->findnodes('vulnerabilities/vulnerability') )
                {
                    my @refs;
                    foreach my $r ( $v->findnodes('id') ) {
                        my $ref = NexposeSimpleXML::Parser::Reference->new(
                            id   => $r->textContent(),
                            type => $r->getAttribute('type'),
                        );
                        push( @refs, $ref );
                    }
                    my $vuln = NexposeSimpleXML::Parser::Vulnerability->new(
                        id          => $v->getAttribute('id'),
                        result_code => $v->getAttribute('resultCode'),
                        references  => \@refs,
                    );
                    push( @vulns, $vuln );

                }

                my $service = NexposeSimpleXML::Parser::Host::Service->new(
                    name            => $s->getAttribute('name'),
                    protocol        => $s->getAttribute('protocol'),
                    port            => $s->getAttribute('port'),
                    fingerprint     => $fp,
                    vulnerabilities => \@vulns,
                );
                push( @services, $service );
            }
            my $host = NexposeSimpleXML::Parser::Host->new(
                address         => $ip,
                fingerprint     => $host_fp,
                services        => \@services,
                vulnerabilities => \@host_vulns,
            );
            push( @hosts, $host );
        }

        return NexposeSimpleXML::Parser::ScanDetails->new( hosts => \@hosts );
    }

    sub get_host_ip {
        my ( $self, $ip ) = @_;
        my @hosts = grep( $_->address eq $address, @{ $self->hosts } );
        return $hosts[0];
    }

    sub all_hosts {
        my ($self) = @_;
        my @hosts = @{ $self->hosts };
        return @hosts;
    }
}
1;
