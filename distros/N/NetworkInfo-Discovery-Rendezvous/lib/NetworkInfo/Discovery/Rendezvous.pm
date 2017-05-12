package NetworkInfo::Discovery::Rendezvous;
use strict;
use Carp;
use Encode;
use Net::Rendezvous;
use NetworkInfo::Discovery::Detect;
#use Data::Dumper; $Data::Dumper::Indent = 0; $Data::Dumper::Terse = 1;

{ no strict;
  $VERSION = '0.06';
  @ISA = qw(NetworkInfo::Discovery::Detect);
}

=head1 NAME

NetworkInfo::Discovery::Rendezvous - NetworkInfo::Discovery extension to find Rendezvous services

=head1 VERSION

Version 0.06

=head1 SYNOPSIS

    use NetworkInfo::Discovery::Rendezvous;

    my $scanner = new NetworkInfo::Discovery::Rendezvous domain => 'example.net';
    $scanner->do_it;

    # print the list of services sorted by host
    for my $host ($scanner->get_interfaces) {
        printf "%s (%s)\n", $host->{nodename}, $host->{ip};

        for my $service (@{$host->{services}}) {
            printf "  %s (%s:%d)\n", $service->{name}, $service->{protocol}, $service->{port}
        }
    }

    # print the list of services by service name
    for my $service (sort {$a->{name} cmp $b->{name}} $scanner->get_services) {
        printf "--- %s ---\n", $service->{name};

        for my $host (sort @{$service->{hosts}}) {
            printf "  %s (%s:%s:%d)\n    %s\n", $host->{nodename}, $host->{ip}, 
                $host->{services}[0]{protocol}, $host->{services}[0]{port}
        }
    }


See also F<eg/rvdisc.pl> for a more complete example.

=head1 DESCRIPTION

This module is an extension to C<NetworkInfo::Discovery> which can find 
services that register themselves using DNS-SD (DNS Service Discovery), 
the services discovery protocol behind Apple Rendezvous. 

It will first try to enumerate all the registered services by querying 
the C<dns-sd> pseudo-service, which is available since the latest versions 
of mDNSResponder. If nothing is returned, it will then query some well-known 
services like C<afpovertcp>. 

=head1 METHODS

=over 4

=item B<new()>

Creates and returns a new C<NetworkInfo::Discovery::Rendezvous> object, 
which derives from C<NetworkInfo::Discovery::Detect>. 

B<Options>

=over 4

=item *

C<domain> - expects a scalar or an arrayref of domains

=back

B<Example>

    # specify one domain
    my $scanner = new NetworkInfo::Discovery::Rendezvous domain => 'example.net';

    # specify several domains
    my $scanner = new NetworkInfo::Discovery::Rendezvous domain => [ qw(local example.net) ];

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new();
    my %args = @_;
    #printf STDERR ">>> new(): args=(%s)\n", join ', ', map{Dumper($_)}@_;
    
    $class = ref($class) || $class;
    bless $self, $class;
    
    # add private fiels
    $self->{_domains_to_scan} ||= [];
    
    # treat given arguments
    for my $attr (keys %args) {
        $self->$attr($args{$attr}) if $self->can($attr);
    }
    
    return $self
}

=item B<do_it()>

Run the services discovery. 

=cut

sub do_it {
    my $self = shift;
    
    for my $domain (@{$self->{_domains_to_scan}}) {
        # first, try to find all registered services in the domain
        my @services = Net::Rendezvous->all_services;
        
        # if services enumeration worked, try to find all instances of each service
        if(@services) {
            for my $service (@services) {
                $self->discover_service($service->service, $service->protocol, $domain)
            }
        
        # if it failed, try to find common services
        } else {
            $self->discover_service('afpovertcp', 'tcp', $domain);  # AFP over TCP shares
            $self->discover_service('ipp',        'tcp', $domain);  # CUPS servers
            $self->discover_service('presence',   'tcp', $domain);  # iChat nodes
            $self->discover_service('printer',    'tcp', $domain);  # printing servers
            $self->discover_service('workstation','tcp', $domain);  # workgroup manager
        }
    }
    
    # group services
    for my $host ($self->get_interfaces) {
        for my $service (@{$host->{services}}) {
            my $name = $service->{name};
            $self->{servicelist}{$name}{name} ||= $name;
            push @{$self->{servicelist}{$name}{hosts}}, $host
        }
    }
    
    # return list of found hosts
    return $self->get_interfaces
}

=item B<get_services()>

Returns the list of discovered services. 

=cut

sub get_services { return values %{$_[0]->{servicelist}} }

=item B<discover_service()>

Discover instances of a given service. 

=cut

sub discover_service {
    my $self = shift;
    my($service,$protocol,$domain) = @_;
    #printf STDERR ">>> discover_service(): args=(%s)\n", join ', ', map{Dumper($_)}@_;
    
    my $rsrc = new Net::Rendezvous;
    $rsrc->application($service, $protocol);
    $rsrc->domain($domain);
    $rsrc->discover;
    
    for my $entry ($rsrc->entries) {
        # host name: $entry->name
        # host addr: $entry->address
        # host services: 
        #   > this service: 
        #       service name: $service
        #       service fqdn: $entry->fqdn
        #       service port: $entry->port
        #       service attr: $entry->all_attrs
        $self->add_interface({
            ip => $entry->address, nodename => $entry->name, services => [{
                name => $service, port => $entry->port, protocol => $protocol, 
                fqdn => $entry->fqdn, attrs => { map {decode('utf-8',$_)} $entry->all_attrs }
            }]
        })
    }
}

=item B<domain()>

Add domains to the search list.

B<Examples>

    $scanner->domain('zeroconf.org');
    $scanner->domain(qw(local zeroconf.org example.com));

=cut

sub domain {
    my $self = shift;
    if(ref $_[0] eq 'ARRAY') {
        push @{$self->{_domains_to_scan}}, @{$_[0]}
    } elsif(ref $_[0]) {
        croak "Don't know how to deal with a ", lc(ref($_[0])), "ref."
    } else {
        push @{$self->{_domains_to_scan}}, @_
    }
}

=back

=head1 SEE ALSO

L<NetworkInfo::Discovery>, L<Net::Rendezvous>

=head1 AUTHOR

SE<eacute>bastien Aperghis-Tramoni, E<lt>sebastien@aperghis.netE<gt>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-networkinfo-discovery-rendezvous@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=NetworkInfo-Discovery-Rendezvous>. 
I will be notified, and then you'll automatically be notified of progress on 
your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2004-2006 SE<eacute>bastien Aperghis-Tramoni, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of NetworkInfo::Discovery::Rendezvous
