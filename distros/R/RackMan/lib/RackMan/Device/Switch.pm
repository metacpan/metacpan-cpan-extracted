package RackMan::Device::Switch;

use Module::Runtime;
use Moose::Role;
use RackMan;
use namespace::autoclean;


use constant HW_ROLES => (
    Cisco_Catalyst  => qr/^Cisco\s+Catalyst/,
);

use constant {
    CONFIG_SECTION  => "device:server",
    DEFAULT_FORMATS => "Cacti Nagios",
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


__PACKAGE__

__END__

=head1 NAME

RackMan::Device::Switch - Base role for network switches

=head1 SYNOPSIS

    RackMan::Device::Switch->meta->apply($rackdev);
    $rackdev->specialise;


=head1 DESCRIPTION

This module is the base role for network switches.


=head1 METHODS

=head2 formats

Return the list of configuration file formats to generate for this
type of object.


=head2 specialise

Apply a specialised role, if available, to the object so it can know
how to speak with the actual hardware, if needed.


=head1 CONFIGURATION

This module gets its configuration from the C<[device:switch]> section
of the main F<rack.conf>, with the following parameters:

=over

=item *

C<formats> - specify the formats associated with a Switch object as a
comma or space seperated list. Can be overridden with the C<--formats>
option. Default is C<"Cacti Nagios">

=back


=head1 AUTHOR

Sebastien Aperghis-Tramoni

=cut

