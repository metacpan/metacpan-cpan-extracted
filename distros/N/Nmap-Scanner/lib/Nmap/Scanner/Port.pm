
use strict;
use Class::Generate qw(class);

class 'Nmap::Scanner::Port' => {
    qw(owner    $
       portid   $
       protocol $
       state    $
       service  Nmap::Scanner::Service
    ),
    '&as_xml' => q!

    my $service_xml = ($self->{'service'} ? $service->as_xml() : '');
    my $owner_xml = ($self->{'owner'} ? qq(owner="$self->{'owner'}" ) : '');

    my $xml = qq(<port protocol="$self->{protocol}" ) .
              qq(portid="$self->{portid}" $owner_xml>
    <state state="$self->{state}"/>
    $service_xml
</port>);

    return $xml;

    !
};

=pod

=head1 Name

Port - Holds information about a remote port as detected by nmap.

=head2 portid()

Port number

=head2 owner()

If ident scan was performed and succeeded, this will contain
the username the service on the port runs as.

=head2 protocol()

Protocol of the port, 'TCP' or 'UDP' for application level ports,
'BGP,' 'ICMP,' etc for protocol level ports.

=head2 state()

Textual representation of the state of the port: `open', `closed', 
`filtered', etc.

=head2 service()

Service this port represents if known (Nmap::Scanner::Service reference)

=cut

1;
