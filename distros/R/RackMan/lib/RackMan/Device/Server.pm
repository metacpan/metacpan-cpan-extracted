package RackMan::Device::Server;

use Module::Runtime;
use Moose::Role;
use RackMan;
use namespace::autoclean;


use constant HW_ROLES => (
    HP_ProLiant     => qr/^HP\s+ProLiant/,
);

use constant {
    CONFIG_SECTION  => "device:server",
    DEFAULT_FORMATS => "DHCP PXE Kickstart Cacti Nagios Bacula",
};


has class => (
    is => "rw",
    isa => "Str",
);


#
# formats()
# -------
sub formats {
    my ($self) = @_;

    # fetch the list of formats for this type
    my $rackman = $self->rackman;
    my @formats = split / *,? +/, $rackman->options->{formats}
        || $rackman->config->val(CONFIG_SECTION, "formats", DEFAULT_FORMATS);

    return @formats
}


#
# specialise()
# ----------
sub specialise {
    my $self = shift;

    # fetch the sub-roles patterns
    my %hw_roles = eval { $self->HW_ROLES };

    # determine the role corresponding to the hardware
    my $hw_type = $self->attributes->{"HW type"};
    return unless $hw_type;
    my ($hw_role) = grep { $hw_type =~ $hw_roles{$_} } keys %hw_roles;

    if ($hw_role) {
        # load and apply the role to the object
        $hw_role = __PACKAGE__."::$hw_role";
        $self->class($hw_role);
        eval { Module::Runtime::require_module($hw_role) }
            or RackMan->error("can't load $hw_role: $@");
        $hw_role->meta->apply($self);
    }
}


#
# has_ilo()
# -------
sub has_ilo { 0 }


#
# tmpl_params()
# -----------
sub tmpl_params {
    my ($self) = @_;
    my %params = ( has_ilo => $self->has_ilo );
    return %params;
}


__PACKAGE__

__END__

=head1 NAME

RackMan::Device::Server - Base role for servers

=head1 SYNOPSIS

    RackMan::Device::Server->meta->apply($rackdev);
    $rackdev->specialise;


=head1 DESCRIPTION

This module is the base role for servers.


=head1 METHODS

=head2 formats

Return the list of configuration file formats to generate for this
type of object.


=head2 specialise

Apply a specialised role, if available, to the object so it can know
how to speak with the actual hardware, if needed.


=head2 has_ilo

Indicates whether the server has an iLO subsystem.


=head2 tmpl_params

Return a hash of additional template parameters.
See L<"TEMPLATE PARAMETERS">


=head1 TEMPLATE PARAMETERS

This role provides the following additional template parameters:

=over

=item *

C<has_ilo> - indicates whether the server has an iLO subsystem

=back


=head1 CONFIGURATION

This module gets its configuration from the C<[device:server]> section
of the main F<rack.conf>, with the following parameters:

=over

=item *

C<formats> - specify the formats associated with a Server object as a
comma or space seperated list. Can be overridden with the C<--formats>
option. Default is C<"DHCP PXE Kickstart Cacti Nagios Bacula">

=back


=head1 AUTHOR

Sebastien Aperghis-Tramoni

=cut

