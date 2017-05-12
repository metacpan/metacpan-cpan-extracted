
use strict;

use Class::Generate qw(class);

class 'Nmap::Scanner::Host' => {qw(
        addresses   @Nmap::Scanner::Address
        ports       %
        hostnames   @Nmap::Scanner::Host
        smurf       $
        status      $
        extra_ports Nmap::Scanner::ExtraPorts
        distance    Nmap::Scanner::Distance
        os          Nmap::Scanner::OS
    ),
    '&add_address'  => q!push(@{$self->{'addresses'}}, $_[0]) if $_[0];!,
    '&hostname'     => q!
        # this returns the first hostname
        return $self->hostnames(0)->name() if $self->hostnames(0);
        return "";
    !,
    '&add_hostname' => q!push(@{ $self->{'hostnames'} }, $_[0]) if $_[0];!,
    '&add_port'     => q!

        my $port = shift;

        return unless defined $port;

        Nmap::Scanner::debug("Adding port with proto: " . $port->protocol());
        $self->{'ports'}->{lc $port->protocol()}->{$port->portid()} = $port;
    !,
    '&get_port'     => q!
        return $self->ports(lc $_[0])->{$_[1]}
            if $self->ports(lc $_[0])->{$_[1]};
    !,

    '&get_udp_port' => q!
        return $self->ports('udp')->{$_[0]}
            if $self->ports('udp')->{$_[0]};
    !,
    '&get_tcp_port' => q!
        return $self->ports('tcp')->{$_[0]}
            if $self->ports('tcp')->{$_[0]};
    !,
    '&get_port_list' => q!
        return Nmap::Scanner::PortList->new(
            $self->ports('tcp'), $self->ports('udp')
        );
    !,
    '&get_ip_port_list' => q!
        return Nmap::Scanner::PortList->new(undef, $self->ports('ip'));
    !,
    '&get_tcp_port_list' => q!
        return Nmap::Scanner::PortList->new($self->ports('tcp'));
    !,
    '&get_udp_port_list' => q!
        return Nmap::Scanner::PortList->new(undef, $self->ports('udp'));
    !,
    '&as_xml' => q!

    my $xml = qq(<host><status state="$self->{status}"/>\n);
  
    for my $a ($self->addresses()) {
        $xml .= $a->as_xml() . "\n";
    }

    $xml .= qq(<smurf responses="$self->{smurf}"/>\n) 
                if $self->{smurf} > 0;

    my $hxml = '';

    foreach my $h ($self->hostnames()) {
        $hxml .= $h->as_xml() if (keys %$h);
    } 

    $xml .= "<hostnames>$hxml</hostnames>\n" if $hxml;
  
    $xml .= $self->os()->as_xml() . "\n" if $self->os();
  
    my $pxml .= $self->extra_ports()->as_xml() ."\n"
                if $self->extra_ports();

    $pxml .= $self->get_tcp_port_list()->as_xml();
    $pxml .= $self->get_udp_port_list()->as_xml();
    $pxml .= $self->get_ip_port_list()->as_xml();

    $xml .= "<ports>$pxml</ports>\n" if $pxml;
    $xml .= $self->distance()->as_xml() . "\n" if $self->distance();
    $xml .= "</host>\n";
  
    return $xml;

    !  
};

=pod

=head1 DESCRIPTION

This class represents a host as repsented by the output
of an nmap scan.

=head1 PROPERTIES

=head2 status()

Whether the host is reachable or not: `up' or `down'

=head2 addresses()

Addresses of the host as determined by nmap (Nmap::Scanner::Address references).

=head2 add_address()

Add an address to the list of addresses for this host

=head2 hostname()

First hostname of the host as determined by nmap (single hostname string).

=head2 hostnames()

Hostnames of the host as determined by nmap (Array of Address references).

=head2 add_hostname()

Add a hostname to the list of hostnames for this host

=head2 smurf()

    True (1) if the host responded to a ping of a broadcast address and
    is therefore vulnerable to a Smurf-style attack.

=head2 extra_ports()

Nmap::Scanner::ExtraPorts instance associated with this host.

=head2 os()

holds a reference to an Nmap::Scanner::OS object that
describes the operating system and TCP fingerprint for this
host, as determined by nmap.  Only present if guess_os()
is called on the Nmap::Scanner::Scanner object AND nmap is
able to determine the OS type via TCP fingerprinting.  See the
nmap manual for more details.

=head2 add_port($port_object_reference)

=head2 get_port($proto, $number)

Returns reference to requested port object.

=head2 get_udp_port($number)

Returns reference to requested UDP port object.

=head2 get_tcp_port($number)

Returns reference to requested TCP port object.

=head2 ENUMERATION METHODS

All these methods return lists of objects that
can be enumration through using a while loop.

my $ports = $host->get_port_list();

while (my $p = $ports->get_next()) {
    #  Do something with port reference here.
}

=head2 get_port_list()

=head2 get_ip_port_list()

=head2 get_tcp_port_list()

=head2 get_udp_port_list()

=head2 distance()

The distance in hops this host is from the scanning host as
estimated by nmap.

=cut

1;
