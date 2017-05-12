package Net::ISC::DHCPd::Config::Host;

=head1 NAME

Net::ISC::DHCPd::Config::Host - Host config parameter

=head1 DESCRIPTION

See L<Net::ISC::DHCPd::Config::Role> for methods and attributes without
documentation.

An instance from this class, comes from / will produce:

    host $name_attribute_value {
        $keyvalues_attribute_value
        $filenames_attribute_value
        $options_attribute_value
    }

=head1 SYNOPSIS

See L<Net::ISC::DHCPd::Config/SYNOPSIS>.

=cut

use Moose;

with 'Net::ISC::DHCPd::Config::Role';

=head2 children

See L<Net::ISC::DHCPd::Config::Role/children>.

=cut

sub children {
    return qw/
        Net::ISC::DHCPd::Config::Host::FixedAddress
        Net::ISC::DHCPd::Config::Host::HardwareEthernet
        Net::ISC::DHCPd::Config::Option
        Net::ISC::DHCPd::Config::Filename
        Net::ISC::DHCPd::Config::KeyValue
    /;
}
__PACKAGE__->create_children(__PACKAGE__->children());

=head1 ATTRIBUTES

=head2 fixedaddress

Convienence method that wraps     shift->fixedaddresses->[0]

=head2 options

A list of parsed L<Net::ISC::DHCPd::Config::Option> objects.

=head2 filenames

A list of parsed L<Net::ISC::DHCPd::Config::Filename> objects. There can
be only one element in this list.

=cut

before add_filename => sub {
    if(0 < int @{ $_[0]->filenames }) {
        confess 'Host cannot have more than one filename';
    }
};

before add_fixedaddress => sub {
    if(0 < int @{ $_[0]->fixedaddresses }) {
        confess 'Host cannot have more than one ip address';
    }
};

before add_hardwareethernet => sub {
    if(0 < int @{ $_[0]->hardwareethernets }) {
        confess 'Host cannot have more than one mac address';
    }
};

sub fixedaddress {
    shift->fixedaddresses->[0];
}

=head2 hardwareethernet

Convienence method that wraps shift->hardwareethernets->[0]

=cut
sub hardwareethernet {
    shift->hardwareethernets->[0];
}

=head2 keyvalues

A list of parsed L<Net::ISC::DHCPd::Config::KeyValue> objects.

=head2 name

This attribute holds a string describing the host.

=cut

has name => (
    is => 'ro',
    isa => 'Str',
);

=head2 regex

See L<Net::ISC::DHCPd::Config::Role/regex>.

=cut

our $regex = qr{^ \s* host \s+ (\S+)}x;

=head1 METHODS

=head2 captured_to_args

See L<Net::ISC::DHCPd::Config::Role/captured_to_args>.

=cut

sub captured_to_args {
    return { name => $_[0] };
}

=head2 generate

See L<Net::ISC::DHCPd::Config::Role/generate>.

=cut

sub generate {
    my $self = shift;

    return(
        'host ' .$self->name .' {',
        $self->_generate_config_from_children,
        '}',
    );
}

=head1 COPYRIGHT & LICENSE

=head1 AUTHOR

See L<Net::ISC::DHCPd>.

=cut
__PACKAGE__->meta->make_immutable;
1;
