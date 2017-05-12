# $Id: ScanDetails.pm 142 2009-10-16 19:13:45Z jabra $
package Nikto::Parser::ScanDetails;
{
    our $VERSION = '0.01';
    $VERSION = eval $VERSION;

    use Object::InsideOut;
    use XML::LibXML;
    use Nikto::Parser::Host;
    use Nikto::Parser::Host::Port;
    use Nikto::Parser::Host::Port::Item;
    my @hosts : Field : Arg(hosts) : Get(hosts) :
        Type(List(Nikto::Parser::Host));

    sub parse {
        my ( $self, $parser, $doc ) = @_;

        my $xpc = XML::LibXML::XPathContext->new($doc);
        my @hosts;

        foreach my $h ( $xpc->findnodes('//niktoscan/scandetails') ) {
            my $ip       = $h->getAttribute('targetip');
            my $hostname = $h->getAttribute('targethostname');
            my @ports;
            my $host = Nikto::Parser::Host->new(
                ip       => $ip,
                hostname => $hostname,
                ports    => \@ports,
            );

            foreach my $scandetail (
                $xpc->findnodes(
                    '//niktoscan/scandetails[@targetip="' . $ip . '"]'
                )
                )
            {
                my $port   = $scandetail->getAttribute('targetport');
                my $banner = $scandetail->getAttribute('targetbanner');

                my $start_scan_time = $scandetail->getAttribute('starttime');
                my $sitename        = $scandetail->getAttribute('sitename');
                my $siteip          = $scandetail->getAttribute('siteip');
                my @items;

                my ( @stats, $elasped_scan_time, $end_scan_time,
                    $items_tested, $items_found );
                if (scalar(
                        @{  $scandetail->getElementsByTagName('statistics')
                            }
                    ) > 0
                    )
                {
                    @stats = $scandetail->getElementsByTagName('statistics');

                    $elasped_scan_time = $stats[0]->getAttribute('elapsed');
                    $end_scan_time     = $stats[0]->getAttribute('endtime');
                    $items_tested = $stats[0]->getAttribute('itemstested');
                    $items_found  = $stats[0]->getAttribute('itemsfound');
                }

                foreach my $i ( $scandetail->getElementsByTagName('item') ) {
                    my $id        = $i->getAttribute('id');
                    my $osvdbid   = $i->getAttribute('osvdbid');
                    my $osvdblink = $i->getAttribute('osvdblink');
                    my $method    = $i->getAttribute('method');
                    my $description
                        = @{ $i->getElementsByTagName('description') }[0]
                        ->textContent();
                    my $uri
                        = scalar( @{ $i->getElementsByTagName('uri') } ) > 0
                        ? @{ $i->getElementsByTagName('uri') }[0]
                        ->textContent()
                        : undef;
                    my $namelink
                        = scalar( @{ $i->getElementsByTagName('namelink') } )
                        > 0
                        ? @{ $i->getElementsByTagName('namelink') }[0]
                        ->textContent()
                        : undef;
                    my $iplink
                        = scalar( @{ $i->getElementsByTagName('iplink') } )
                        > 0
                        ? @{ $i->getElementsByTagName('iplink') }[0]
                        ->textContent()
                        : undef;

                    my $item = Nikto::Parser::Host::Port::Item->new(
                        id          => $id,
                        osvdbid     => $osvdbid,
                        osvdblink   => $osvdblink,
                        method      => $method,
                        description => $description,
                        uri         => $uri,
                        namelink    => $namelink,
                        iplink      => $iplink,
                    );

                    push( @items, $item );
                }

                my $objport = Nikto::Parser::Host::Port->new(
                    port              => $port,
                    banner            => $banner,
                    start_scan_time   => $start_scan_time,
                    end_scan_time     => $end_scan_time,
                    elasped_scan_time => $elasped_scan_time,
                    sitename          => $sitename,
                    siteip            => $siteip,
                    items             => \@items,
                    items_tested      => $items_tested,
                    items_found       => $items_found
                );
                push( @ports, $objport );
            }

            $host->ports( \@ports );
            push( @hosts, $host );
        }

        return Nikto::Parser::ScanDetails->new( hosts => \@hosts );
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
