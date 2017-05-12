# $Id: ScanDetails.pm 134 2009-10-16 18:21:38Z jabra $
package Sslscan::Parser::ScanDetails;
{
    our $VERSION = '0.01';
    $VERSION = eval $VERSION;

    use Object::InsideOut;
    use XML::LibXML;
    use Sslscan::Parser::Host;
    use Sslscan::Parser::Host::Port;
    use Sslscan::Parser::Host::Port::Cipher;
    my @hosts : Field : Arg(hosts) : Get(hosts) : Type(List(Sslscan::Parser::Host));

    sub parse {
        my ( $self, $parser, $doc ) = @_;

        my $xpc = XML::LibXML::XPathContext->new($doc);
        my @hosts;

        foreach my $h ( $xpc->findnodes('//document/ssltest') ) {
            my $ip          = $h->getAttribute('host');
            my @ports;
            my $host = Sslscan::Parser::Host->new(
                ip          => $ip,
                ports       => \@ports,
            );

            foreach my $scandetail (
                $xpc->findnodes(
                    '//document/ssltest[@host="' . $ip . '"]'
                )
                )
            {
                my $port   = $scandetail->getAttribute('port');
                
                my @ciphers;
                #my @default_ciphers;

                foreach my $i ( $doc->getElementsByTagName('cipher') ) {
                    my $status        = $i->getAttribute('status');
                    my $sslversion        = $i->getAttribute('sslversion');
                    my $bits        = $i->getAttribute('bits');
                    my $cipher        = $i->getAttribute('cipher');
                
                    my $cipher_obj = Sslscan::Parser::Host::Port::Cipher->new(
                        status      => $status,
                        sslversion  => $sslversion,
                        bits        => $bits,
                        cipher      => $cipher,
                    );

                    push( @ciphers, $cipher_obj );
                }

                my $objport = Sslscan::Parser::Host::Port->new(
                    port              => $port,
                    ciphers           => \@ciphers,
                );
                push( @ports, $objport );
            }

            $host->ports( \@ports );
            push( @hosts, $host );
        }

        return Sslscan::Parser::ScanDetails->new( hosts => \@hosts );
    }

    sub get_host_ip {
        my ( $self, $ip ) = @_;
        my @hosts = grep( $_->ip eq $ip, @{ $self->hosts } );
        return $hosts[0];
    }

    sub get_host_hostname {
        my ( $self, $hostname ) = @_;
        my @hosts = grep( $_->hostname eq $hostname, @{ $self->hosts } );
        return $hosts[0];
    }

    sub all_hosts {
        my ($self) = @_;
        my @hosts = @{ $self->hosts };
        return @hosts;
    }

    sub print_hosts {
        my ($self) = @_;
        foreach my $host ( @{ $self->hosts } ) {
            print "IP: " . $host->ip . "\n";
            print "Hostname: " . $host->hostname . "\n";
        }
    }
}
1;
