package NetworkInfo::Discovery::NetBIOS;
use strict;
use Carp;
use Net::NBName;
use Net::Netmask;
use NetworkInfo::Discovery::Detect;

{ no strict;
  $VERSION = '0.05';
  @ISA = qw(NetworkInfo::Discovery::Detect);
}

=head1 NAME

NetworkInfo::Discovery::NetBIOS - NetworkInfo::Discovery extension to find NetBIOS services

=head1 VERSION

Version 0.05

=head1 SYNOPSIS

    use NetworkInfo::Discovery::NetBIOS;

    my $scanner = new NetworkInfo::Discovery::NetBIOS hosts => [ qw(192.168.0.0/24) ];
    $scanner->do_it;
    
    for my $host ($scanner->get_interfaces) {
        printf "<%s> NetBios(node:%s zone:%s)\n", $host->{ip}, 
            $host->{netbios}{node}, $host->{netbios}{zone};
    }


=head1 DESCRIPTION

This module is an extension to C<NetworkInfo::Discovery> which can find 
hosts and services using the NetBIOS protocol. 

=head1 METHODS

=over 4

=item new()

Create and return a new object. 

B<Options>

=over 4

=item *

C<hosts> - expects a scalar or an arrayref of IP addresses in CIDR notation

=back

B<Example>

    # with a scalar argument
    my $scanner = new NetworkInfo::Discovery::NetBIOS hosts => '192.168.0.0/24;

    # with an arrayref
    my $scanner = new NetworkInfo::Discovery::NetBIOS hosts => [ qw(192.168.0.0/24) ];

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new();
    my %args = @_;
    
    $class = ref($class) || $class;
    bless $self, $class;
    
    # add private fields
    $self->{_hosts_to_scan} = [];
    
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
    my $netbios = new Net::NBName;
    
    for my $host (@{$self->{_hosts_to_scan}}) {
        for my $ip (Net::Netmask->new($host)->enumerate) {
            # trying to find status information on each IP address
            my %host = ();
            my $status = $netbios->node_status($ip);
            
            if($status) {
                $host{ip} = $ip;
                $host{mac} = $status->mac_address;
                $host{netbios} = {};
                
                for my $rr ($status->names) {
                    $host{netbios}{node} = $rr->name if $rr->suffix == 0x00 and $rr->G eq 'UNIQUE';
                    $host{netbios}{zone} = $rr->name if $rr->suffix == 0x00 and $rr->G eq 'GROUP';
                }
                
                push @hosts, { %host };
            }
        }
    }
    
    # add found hosts
    $self->add_interface(@hosts);
    
    # return list of found hosts
    return $self->get_interfaces
}

=item hosts()

Add hosts or networks to the scan list. Expects addresses in CIDR notation. 

B<Examples>

    $scanner->hosts('192.168.4.53');     # add one host
    $scanner->hosts('192.168.5.48/29');  # add a subnet
    $scanner->hosts(qw(192.168.6.0/30 10.0.0.3/28));  # add two subnets

=cut

sub hosts {
    my $self = shift;
    if(ref $_[0] eq 'ARRAY') {
        push @{$self->{_hosts_to_scan}}, @{$_[0]}
    } elsif(ref $_[0]) {
        croak "fatal: Don't know how to deal with a ", lc(ref($_[0])), "ref."
    } else {
        push @{$self->{_hosts_to_scan}}, @_
    }
}

=back

=head1 DIAGNOSTICS

=over 4

=item Don't know how to deal with a %sref.

B<(F)> C<hosts()> was called with something it can't handle. 

=back

=head1 SEE ALSO

L<NetworkInfo::Discovery>, L<Net::NBName>

=head1 AUTHOR

Sébastien Aperghis-Tramoni, E<lt>sebastien@aperghis.netE<gt>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-networkinfo-discovery-netbios@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically
be notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2004 Sébastien Aperghis-Tramoni, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of NetworkInfo::Discovery::NetBIOS
