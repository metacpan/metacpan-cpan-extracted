package RackMan::Template;

use Moose;
use HTML::Template ();
use HTML::Template::Filter::TT2 ();
use NetAddr::IP;
use RackMan;
use namespace::autoclean;


has _ht_obj => (
    is => "ro",
    isa => "HTML::Template",
    handles => {
        param   => "param",
        output  => "output",
    },
);


#
# BUILDARGS()
# ---------
sub BUILDARGS {
    my $class = shift;
    my %param;

    if (@_ % 2 == 0) {
        %param = @_;
    }
    elsif (ref $_[0] eq "HASH") {
        %param = %{$_[0]};
    }
    else {
        RackMan->error("invalid argument: ",
            lc ref $_[0], "ref instead of hashref");
    }

    my $tmpl = eval { HTML::Template->new(
        %param,
        filter   => \&HTML::Template::Filter::TT2::ht_tt2_filter,
        die_on_bad_params => 0,
    ) };
    if (not $tmpl) {
        (my $error = $@) =~ s/ at .*//sm;
        RackMan->error($error);
    }

    return { _ht_obj => $tmpl }
}


#
# populate_from()
# -------------
sub populate_from {
    my ($self, $rackdev, $rackman) = @_;

    # fetch the common name and FQDN of the host
    my $name    = $rackdev->object_name;
    my $fqdn    = $rackdev->attributes->{FQDN};
    RackMan->error("RackObject '$name' lacks a FQDN") unless $fqdn;

    # fetch the list of regular MAC addresses
    my @mac_addrs = $rackdev->regular_mac_addrs;
    RackMan->error("RackObject '$name' lacks a MAC address") unless @mac_addrs;

    # fetch the list of regular IPv4 addresses
    my @ip_addrs = $rackdev->regular_ipv4addrs;
    RackMan->error("RackObject '$name' lacks an IPv4 address") unless @ip_addrs;

    # Host IPv4 network parameters
    my $host_gateway = $rackdev->default_ipv4_gateway;

    # determine the network mask
    my $haddr = NetAddr::IP->new($ip_addrs[0]{addr}, $host_gateway->{masklen});
    my $host_netmask = $haddr->mask;

    # fetch template parameters specific to the current device
    my %devparam = $rackdev->tmpl_params if $rackdev->can("tmpl_params");

    # fetch the list of attributes, and convert their names to be
    # valid identifiers
    my %attr = %{ $rackdev->attributes };
    for my $name (keys %attr) {
        my $param = lc $name;
        s/,.*$//, s:[./]::g, s/\W+/_/g for $param;
        $attr{$param} = delete $attr{$name};
    }

    # fetch the list of DNS servers
    my @dns_servers
        = split / +/, $rackman->config->val(general => "dns_servers");

    # populate the template
    $self->param(
        type             => $rackdev->object_type,
        name             => $name,
        fqdn             => $fqdn,
        if0_mac          => $mac_addrs[0]{l2address_text},
        if0_ip           => $ip_addrs[0]{addr},
        if0_name         => $ip_addrs[0]{iface},
        gateway          => $host_gateway->{addr} || "0.0.0.0",
        network          => $host_gateway->{network},
        netmask          => $host_netmask,
        dns_server_1     => $dns_servers[0],
        dns_server_2     => $dns_servers[1],
        dns_server_3     => $dns_servers[2],
        %devparam,
        %attr,
    );
}


__PACKAGE__->meta->make_immutable

__END__

=pod

=head1 NAME

RackMan::Template - Simple templating module for RackMan

=head1 SYNOPSIS

    use RackMan::Template;

    my $tmpl = RackMan::Template->new(filename => "dhcp.tmpl");
    $tmpl->param(dhcp_server => "192.168.0.13");
    print $tmpl->output;


=head1 DESCRIPTION

This module is a simple Moose-based templating class, based on
HTML::Template and HTML::Template::Filter::TT2. Please read the
documentation of these modules for more details on the syntax.


=head1 METHODS

=head2 new

(delegated to C<HTML::Template>)

Create and return a new object.


=head2 param

(delegated to C<HTML::Template>)

Pass parameters to the template.


=head2 populate_from

Add to the template the parameters documented in L<"TEMPLATE PARAMETERS">
from the C<Rackman::Device> and C<RackMan> objects given in argument.

    my $tmpl = RackMan::Template->new(filename => $tmpl_path);
    $tmpl->populate_from($rackdev, $rackman);


=head2 output

(delegated to C<HTML::Template>)

Generate and return the output from the template and the given parameters.


=head1 TEMPLATE PARAMETERS

When the method C<populate_from()> is called with valid C<RackMan::Device>
and C<Rackman> objects given in arguments, it populates the template object
with the following parameters:

=over

=item *

C<dns_server_1>, C<dns_server_2>, C<dns_server_3> - DNS servers

=item *

C<gateway> - IPv4 address of the default gateway

=item *

C<fqdn> - FQDN of the host

=item *

C<name> - common name of the host

=item *

C<if0_ip> - IPv4 address of the first regular network interface

=item *

C<if0_mac> - MAC address of the first regular network interface

=item *

C<if0_name> - name of the first regular network interface

=item *

C<netmask> - IPv4 network mask

=item *

C<network> - IPv4 network address

=item *

C<type> - RackObject type

=back

The corresponding RackObject attributes are also available, with their
names mogrified to be valid identifiers: units are removed, some 
punctuation characters (dot (C<.>), comma (C<,>)) are removed, the
alphabetical characters are lowercased and the rest of non word
characters are collapsed and converted to underscores (C<_>).

Here is a non authoritative list of known attributes: C<alias>,
C<alive_check>, C<contact_person>, C<cpu>, C<dram> C<flash_memory>,
C<fqdn>, C<has_jumbo_frames>, C<hw_type>, C<hw_warranty_expiration>,
C<hypervisor>, C<max_power>, C<max_current>, C<oem_sn_1>, C<oem_sn_2>,
C<sw_type>, C<sw_version>, C<sw_warranty_expiration>, C<use>, C<uuid>.


=head1 SEE ALSO

L<HTML::Template>, L<HTML::Template::Filter::TT2>


=head1 AUTHOR

Sebastien Aperghis-Tramoni

=cut


