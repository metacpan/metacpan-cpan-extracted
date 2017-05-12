package NetworkInfo::Discovery::Nmap;
use strict;
use Carp;
use Nmap::Scanner;
use NetworkInfo::Discovery::Detect;

{ no strict;
  $VERSION = '0.02';
  @ISA = qw(NetworkInfo::Discovery::Detect);
}

=head1 NAME

NetworkInfo::Discovery::Nmap - NetworkInfo::Discovery extension using Nmap

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

    use NetworkInfo::Discovery::Nmap;

    my $scanner = NetworkInfo::Discovery::Nmap->new(
        hosts => [ qw( 192.168.0.0/24 192.168.1.0/24 ) ], 
    );
    $scanner->do_it;

See F<eg/nmapdisc.pl> for a more complete example. 

=head1 DESCRIPTION

This module is an extension to C<NetworkInfo::Discovery> which uses the 
Nmap utility to scan networks, find active hosts, their services and 
operating system. 

=head1 METHODS

=over 4

=item new()

Creates and returns a new C<NetworkInfo::Discovery::Nmap> object, which 
derives from C<NetworkInfo::Discovery::Detect>. 

B<Options>

=over 4

=item *

C<hosts> - expects a scalar or an arrayref of IP addresses in CIDR notation

=item *

C<ports> - expects a scalar or an arrayref with a port or a ports range

=item *

C<guess_system> - when enabled, tells nmap to use TCP/IP fingerprinting 
to guess remote operating system (note: root privileges required). 
Default is 0 (disabled). 

=back

B<Example>

    # specify one host
    my $scanner = new NetworkInfo::Discovery::Nmap hosts => '192.168.0.0/24';
    
    # specify several hosts
    my $scanner = new NetworkInfo::Discovery::Nmap hosts => [ qw(192.168.0.0/24) ];

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new();
    my %args = @_;
    
    $class = ref($class) || $class;
    bless $self, $class;
    
    # add private fields
    $self->{_hosts_to_scan} = [];
    $self->{_ports_to_scan} = [];
    
    # treat given arguments
    for my $attr (keys %args) {
        $self->$attr($args{$attr}) if $self->can($attr);
    }
    
    return $self
}

=item do_it()

Run the scan. 

=cut

sub do_it {
    my $self = shift;
    my @hosts = ();
    
    # initialize the scanner
    my $scanner = new Nmap::Scanner;
    map { $scanner->add_target($_) } $self->hosts;
    map { $scanner->add_scan_port($_) } $self->ports;
    $scanner->no_ping;
    $scanner->version_scan;
    $scanner->guess_os if $self->{_nmap_options}{guess_system};
    
    # run the scan
    my $results = $scanner->scan;
    
    # add found information
    my $list = $results->get_host_list;
    while(my $host = $list->get_next) {
        next unless $host->status eq 'up';
        my %host_info = ( services => [] );
        
        # get its address
        my %addrs = map { $_->addr => $_->addrtype } $host->addresses;
        for my $addr (keys %addrs) {
            $host_info{ip}  = $addr if $addrs{$addr} eq 'ipv4';
            $host_info{mac} = $addr if $addrs{$addr} eq 'mac';
        }
        $host_info{smurf} = $host->smurf;
        
        # get ports information
        my $portlist = $host->get_port_list;
        while(my $port = $portlist->get_next) {
            my %port_info = ();
            $port_info{port} = $port->portid;
            map { $port_info{$_} = $port->$_ || '' } qw(owner protocol state);
            $port_info{name} = $port->service->name || '';
            $port_info{rpcnum} = $port->service->rpcnum || '';
            $port_info{application} = {};
            map { $port_info{application}{$_} = $port->service->$_ || '' } qw(product version extrainfo);
            push @{$host_info{services}}, { %port_info };
        }
        
        # get operating system information
        if(my $guess_os = $host->os) {
            $host_info{system_info} = {
                os_classes => [], 
                os_matches => [], 
                uptime => $guess_os->uptime->seconds || 0, 
                last_boot => $guess_os->uptime->lastboot || '', 
            };
            
            for my $os_class ($guess_os->osclasses) {
                push @{$host_info{system_info}{os_classes}}, {
                    vendor => $os_class->vendor, type => $os_class->type, 
                    family => $os_class->osfamily, version => $os_class->osgen, 
                    accuracy => $os_class->accuracy
                }
            }
            
            for my $os_match ($guess_os->osmatches) {
                push @{$host_info{system_info}{os_matches}}, {
                    name => $os_match->name, accuracy => $os_match->accuracy
                }
            }
        }
                
        push @hosts, { %host_info };
    }
    
    # add found hosts
    $self->add_interface(@hosts);
    
    # return list of found hosts
    return $self->get_interfaces
}

=item hosts()

Add hosts or networks to the scan list. Expects addresses in CIDR notation. 
Return the current list of hosts when called with no argument. 

B<Examples>

    $scanner->hosts('192.168.4.53');     # add one host
    $scanner->hosts('192.168.5.48/29');  # add a subnet
    $scanner->hosts(qw(192.168.6.0/30 10.0.0.3/28));  # add two subnets

=cut

sub hosts {
    my $self = shift;
    if(@_ ==0) {
        return @{$self->{_hosts_to_scan}}
    } elsif(ref $_[0] eq 'ARRAY') {
        push @{$self->{_hosts_to_scan}}, @{$_[0]}
    } elsif(ref $_[0]) {
        croak "Don't know how to deal with a ", lc(ref($_[0])), "ref."
    } else {
        push @{$self->{_hosts_to_scan}}, @_
    }
}

=item ports()

Add ports to the scan list. 
Expects single ports (e.g. '8080') or ports ranges (e.g. '1-123'). 
Return the current list of ports when called with no argument. 

B<Examples>

    $scanner->ports('8080');     # add one port
    $scanner->ports('1-123');    # add a ports range
    $scanner->ports(qw(137-139 201-208));  # add two ports ranges

=cut

sub ports {
    my $self = shift;
    if(@_ ==0) {
        return @{$self->{_ports_to_scan}}
    } elsif(ref $_[0] eq 'ARRAY') {
        push @{$self->{_ports_to_scan}}, @{$_[0]}
    } elsif(ref $_[0]) {
        croak "Don't know how to deal with a ", lc(ref($_[0])), "ref."
    } else {
        push @{$self->{_ports_to_scan}}, @_
    }
}

=item guess_system()

When enabled, tells nmap to use TCP/IP fingerprinting to guess remote 
operating system (note: root privileges required). 
Default is 0 (disabled). 

=cut

# accessors
for my $attr (qw(guess_system)) {
    no strict 'refs';
    *{__PACKAGE__.'::'.$attr} = sub {
        my $self = shift;
        my $old = $self->{_nmap_options}{$attr};
        $self->{_nmap_options}{$attr} = $_[0] if $_[0];
        return $old;
    }
}

=back

=head1 SEE ALSO

L<NetworkInfo::Discovery>, L<Nmap::Scanner>

=head1 AUTHOR

SE<eacute>bastien Aperghis-Tramoni, E<lt>sebastien@aperghis.netE<gt>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-networkinfo-discovery-nmap@rt.cpan.org>, or through the web interface at
L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=NetworkInfo-Discovery-Nmap>. 
I will be notified, and then you'll automatically be notified of progress 
on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2004 SE<eacute>bastien Aperghis-Tramoni, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of NetworkInfo::Discovery::Nmap
