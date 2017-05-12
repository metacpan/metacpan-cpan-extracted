package RackMan::Device::Server::HP_ProLiant;

use Moose::Role;
use Net::ILO;
use RackMan;
use Socket;
use Term::ANSIColor qw< GREEN RED >;
use namespace::autoclean;


use constant {
    CONFIG_SECTION  => "device:server:hp_proliant",
};

use constant SERIAL_SPEED => qw< 0 9600 19200 38400 57600 115200 >;


#
# additional object attributes
#
has ilo_mac_addr => (
    is => "ro",
    isa => "HashRef",
    lazy => 1,
    builder => "_get_ilo_mac_addr",
);

has ilo_ipv4addr => (
    is => "ro",
    isa => "HashRef",
    lazy => 1,
    builder => "_get_ilo_ipv4addr",
);

has default_ilo_ipv4_gateway => (
    is => "ro",
    isa => "HashRef",
    lazy => 1,
    builder => "_get_default_ilo_ipv4_gateway",
);

has ilo_fqdn => (
    is => "ro",
    isa => "Str",
    lazy => 1,
    builder => "_get_ilo_fqdn",
);

has has_ilo => (
    is => "ro",
    isa => "Int",
    default => 1,
);


#
# _get_ilo_mac_addr()
# -----------------
sub _get_ilo_mac_addr {
    for my $port (@{ $_[0]->ports }) {
        return $port if $port->{name} eq "ilo"
    } 

    return
}


#
# _get_ilo_ipv4addr()
# -----------------
sub _get_ilo_ipv4addr {
    for my $addr (@{ $_[0]->ipv4addrs}) {
        if ($addr->{type} eq "regular" and $addr->{iface} eq "ilo") {
            return $addr
        }
    }

    return
}


#
# _get_ilo_fqdn()
# -------------
sub _get_ilo_fqdn {
    my ($self) = @_;

    my $ilo_addr = $self->ilo_ipv4addr->{addr};
    my $ilo_fqdn = gethostbyaddr(inet_aton($ilo_addr), AF_INET);

    RackMan->error("the iLO subsystem of ", $self->object_name,
        " has an IP address ($ilo_addr) but no associated FQDN; please",
        " check the reverse record") unless $ilo_fqdn;

    return $ilo_fqdn
}


#
# _get_default_ilo_ipv4_gateway()
# -------------------------
sub _get_default_ilo_ipv4_gateway {
    my ($self) = @_;
    my @addrs = $self->ilo_ipv4addr;
    return $self->_get_default_ipv4_gateway($addrs[0]{addr})
}


#
# write_config()
# ------------
sub write_config {
    my ($self, $args) = @_;

    print "  ! This action is not implemented. ",
        "Please use the 'push' action instead.\n"
        if $args->{verbose};
}


#
# diff_config()
# -----------
sub diff_config {
    my ($self, $args) = @_;

    my $rackman = $args->{rackman};
    my $config  = $rackman->config;

    # fetch the credentials
    my $ilo_password = $rackman->options->{device_password}
        || $config->val(CONFIG_SECTION, "ilo_password")
        or RackMan->error("missing password for iLO account 'Administrator'");

    # fetch the IP address and FQDN of the iLO subsystem
    my $ilo_addr = $self->ilo_ipv4addr->{addr};
    my $ilo_fqdn = $self->ilo_fqdn;
    my ($ilo_name, $ilo_domain) = split /\./, $ilo_fqdn;

    # connect to the iLO API
    my $ilo = Net::ILO->new({
        address  => $ilo_addr,
        username => "Administrator",
        password => $ilo_password,
    });

    my $ilo_type = $ilo->fw_type or RackMan->error($ilo->error);

    print "  $ilo_type v", $ilo->fw_version, " / ", $ilo->model, "\n"
        if $args->{verbose};

    # construct the expected values
    my $serial_speed = $config->val(CONFIG_SECTION, "serial_cli_speed", 5);
    my %expected = (
        hostname            => $ilo_name,
        domain_name         => $ilo_domain,
        server_name         => $self->object_name,
        serial_cli_speed    => (SERIAL_SPEED)[$serial_speed],
    );

    my @dns_servers = split / +/, $config->val(general => "dns_servers");
    my @dns_fields = qw< prim_dns_server sec_dns_server ter_dns_server >;
    $expected{$dns_fields[$_]} = $dns_servers[$_] for 0 .. $#dns_servers;

    if ($ilo->_version >= 3) {
        my @ntp_servers = split / +/, $config->val(general => "ntp_servers");
        my @ntp_fields = qw< sntp_server1 sntp_server2 >;
        $expected{$ntp_fields[$_]} = $ntp_servers[$_] for 0 .. $#ntp_servers;
    }

    # fetch the corresponding current values
    my %current = map { $_ => $ilo->$_ || "(undef)" } keys %expected;

    my $diff = 0;

    # compare the two hashes and print the differences
    for my $field (sort keys %expected) {
        next if $current{$field} eq $expected{$field};
        my $sp = " " x length $field;
        print "  - $field: ", RED("current value: $current{$field}"), "\n",
              "    $sp ", GREEN("expected value: $expected{$field}"), "\n\n";
        $diff = 1;
    }

    # check if the user "admin" is present
    my $user_info = $ilo->get_user("admin");

    if ($user_info) {
        if (not $user_info->{admin} =~ /^y(?:es)?/i) {
            print "  - account 'admin' exists but lack admin privilege\n";
            $diff = 1;
        }
    }
    else {
        print "  - account 'admin' does not exist\n";
        $diff = 1;
    }

    print "  - no differences\n" if !$diff and $args->{verbose};

    RackMan->set_status($diff);
}


#
# push_config()
# -----------
sub push_config {
    my ($self, $args) = @_;

    my $rackman = $args->{rackman};
    my $config  = $rackman->config;

    # fetch the credentials
    my $ilo_password = $rackman->options->{device_password}
        || $config->val(CONFIG_SECTION, "ilo_password")
        or RackMan->error("missing password for iLO account 'Administrator'");
    my $admin_password = $config->val(CONFIG_SECTION, "admin_password")
        or RackMan->error("missing password for iLO account 'admin'");

    # fetch the IP address and FQDN of the iLO subsystem
    my $ilo_addr = $self->ilo_ipv4addr->{addr};
    my $ilo_fqdn = $self->ilo_fqdn;
    my ($ilo_name, $ilo_domain) = split /\./, $ilo_fqdn;

    # connect to the iLO API
    print "  > configuring iLO subsystem" if $args->{verbose};
    my $ilo = Net::ILO->new({
        address  => $ilo_addr,
        username => "Administrator",
        password => $ilo_password,
    });

    my $ilo_type = $ilo->fw_type or RackMan->error_n($ilo->error);
    print " (" if $args->{verbose};

    # configure serial port
    print "serial CLI, " if $args->{verbose};
    my $serial_speed = $config->val(CONFIG_SECTION, "serial_cli_speed", 5);
    $ilo->serial_cli_speed($serial_speed)
        or RackMan->error_n($ilo->error);

    # configure the server name
    print "server name, " if $args->{verbose};
    $ilo->server_name($self->object_name)
        or RackMan->error_n($ilo->error);

    # check if the user "admin" is present
    print "user 'admin', " if $args->{verbose};
    my $user_info = $ilo->get_user("admin");

    if (not $user_info) {
        # if not, create it
        $ilo->add_user({
            name        => "admin",
            username    => "admin",
            password    => $admin_password,
            admin       => "Yes",
            remote_console_privilege    => "Yes",
            reset_privilege             => "Yes",
            virtual_media_privilege     => "Yes",
            config_ilo_privilege        => "Yes",
        }) or RackMan->error_n($ilo->error);
    }
    else {
        # if yes, change its password
        $ilo->mod_user({
            username    => "admin",
            password    => $admin_password,
        }) or RackMan->error_n($ilo->error);
    }

    # activate the license
    print "license, " if $args->{verbose};
    my $license_key = $config->val(CONFIG_SECTION, "license_key");

    if ($license_key and not $ilo->license($license_key)) {
        RackMan->error_n($ilo->error)
            unless $ilo->error =~ /already active/;
    }

    # complete network settings
    print "network" if $args->{verbose};
    my @ntp_servers = split / +/, $config->val(general => "ntp_servers");
    my @dns_servers = split / +/, $config->val(general => "dns_servers");

    $ilo->network({
        hostname        => $ilo_name,
        dhcp_enabled    => 'no',
        domain_name     => $ilo_domain,
        prim_dns_server => $dns_servers[0],
        sec_dns_server  => $dns_servers[1],
        ter_dns_server  => $dns_servers[2],
        sntp_server1    => $ntp_servers[0],
        sntp_server2    => $ntp_servers[1],
        sntp_server3    => $ntp_servers[2],
    }) or RackMan->error_n($ilo->error);

    print ") done\n" if $args->{verbose};
}


#
# tmpl_params()
# -----------
around tmpl_params => sub {
    my ($orig, $self) = @_;

    my $name = $self->object_name;

    # fetch the IP address and FQDN of the iLO subsystem
    my $ilo_addr = $self->ilo_ipv4addr->{addr};
    my $ilo_fqdn = $self->ilo_fqdn;
    my ($ilo_name, $ilo_domain) = split /\./, $ilo_fqdn;

    # find iLO MAC address
    my @ilo_mac_addr = $self->ilo_mac_addr;
    RackMan->error("RackObject '$name' lacks an iLO interface")
        unless defined $ilo_mac_addr[0];
    RackMan->error("RackObject '$name' lacks an iLO MAC address")
        unless defined $ilo_mac_addr[0]{l2address};

    # fetch iLO IPv4 address
    my @ilo_ipv4addr = $self->ilo_ipv4addr;
    RackMan->error("RackObject '$name' lacks an iLO IPv4 address")
        unless defined $ilo_ipv4addr[0]{addr};

    # iLO IPv4 network parameters
    my $ilo_gateway = $self->default_ilo_ipv4_gateway;
    my $iaddr = NetAddr::IP->new($ilo_ipv4addr[0]{addr}, $ilo_gateway->{masklen});
    my $ilo_netmask = $iaddr->mask;

    my %params = (
        $self->$orig,
        ilo_fqdn    => $ilo_fqdn,
        ilo_name    => $ilo_name,
        ilo_ip      => $ilo_ipv4addr[0]{addr},
        ilo_mac     => $ilo_mac_addr[0]{l2address_text},
        ilo_netmask => $ilo_netmask,
        ilo_network => $ilo_gateway->{network},
        ilo_gateway => $ilo_gateway->{addr} || "0.0.0.0",
    );

    return %params
};



__PACKAGE__

__END__

=head1 NAME

RackMan::Device::Server::HP_ProLiant - Role for HP ProLiant servers

=head1 DESCRIPTION

This module is the role for HP ProLiant servers, to configure their
iLO management subsystem.

Because iLO is a protocol, no configuration file can be written on
disk, therefore the C<write> action is not implemented.


=head1 PUBLIC METHODS

=head2 write_config

I<Not implemented>


=head2 diff_config

Because there is no configuration file I<per se>, this action can't
perform a traditional diff. However, it can and does compare some of
the values fetched from the iLO subsystem with the expected values,
as computed from the RackTables database.

B<Arguments:>

=over

=item 1. options (hashref)

=back


=head2 push_config

Talk with the iLO subsystem of the target server to configure it
accordingly to the information from the RackTables database.

B<Arguments:>

=over

=item 1. options (hashref)

=back


=head2 tmpl_params

Return a hash of additional template parameters.
See L<"TEMPLATE PARAMETERS">


=head2 ilo_mac_addr

Return the MAC address of the iLO subsystem


=head2 ilo_ipv4addr

Return the IPv4 address of the iLO subsystem


=head1 TEMPLATE PARAMETERS

This role provides the following additional template parameters:

=over

=item *

C<ilo_fqdn> - FQDN of the iLO subsystem

=item *

C<ilo_name> - domain name of the iLO subsystem

=item *

C<ilo_ip> - IPv4 address of the iLO subsystem

=item *

C<ilo_mac> - MAC address of the iLO subsystem

=item *

C<ilo_gateway> - gateway of the iLO subsystem

=item *

C<ilo_netmask> - netmask of the iLO subsystem

=item *

C<ilo_network> - IPv4 network of the iLO subsystem

=back


=head1 CONFIGURATION

See L<rack/"Section [device:server:hp_proliant]">


=head1 AUTHOR

Sebastien Aperghis-Tramoni

=cut

