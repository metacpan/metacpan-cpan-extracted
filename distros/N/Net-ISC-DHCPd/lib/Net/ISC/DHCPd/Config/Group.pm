package Net::ISC::DHCPd::Config::Group;

=head1 NAME

Net::ISC::DHCPd::Config::Group - Group config parameter

=head1 DESCRIPTION

See L<Net::ISC::DHCPd::Config::Role> for methods and attributes without
documentation.

An instance from this class, comes from / will produce:

    group $name {
        $keyvalues_attribute_value
        $options_attribute_value
        $hosts_attribute_value
        $groups_attribute_value
        $sharednetworks_attribute_value
        $subnets_attribute_value
    }

Group names are optional.

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
        Net::ISC::DHCPd::Config::Subnet
        Net::ISC::DHCPd::Config::Subnet6
        Net::ISC::DHCPd::Config::SharedNetwork
        Net::ISC::DHCPd::Config::Group
        Net::ISC::DHCPd::Config::Host
        Net::ISC::DHCPd::Config::Option
        Net::ISC::DHCPd::Config::KeyValue
    /;
}
__PACKAGE__->create_children(__PACKAGE__->children());

=head1 ATTRIBUTES

=head2 subnets

A list of parsed L<Net::ISC::DHCPd::Config::Subnet> objects.

=head2 sharednetworks

A list of parsed L<Net::ISC::DHCPd::Config::SharedNetwork> objects.

=head2 groups

A list of parsed L<Net::ISC::DHCPd::Config::Group> objects.

=head2 hosts

A list of parsed L<Net::ISC::DHCPd::Config::Host> objects.

=head2 options

A list of parsed L<Net::ISC::DHCPd::Config::Option> objects.

=head2 keyvalues

A list of parsed L<Net::ISC::DHCPd::Config::KeyValue> objects.

=head2 name

Name of the group - See L</DESCRIPTION> for details.

=cut

has name => (
    is => 'ro',
    isa => 'Str',
);

=head2 quoted

This flag tells if the group name should be quoted or not.

=cut

has quoted => (
    is => 'ro',
    isa => 'Bool',
);

=head2 regex

See L<Net::ISC::DHCPd::Config::Role/regex>.

=cut


our $regex = qr{^ \s* group \s+ ([\w-]+|".*?")? }x;

=head1 METHODS

=head2 captured_to_args

See L<Net::ISC::DHCPd::Config::Role/captured_to_args>.

=cut

sub captured_to_args {
    my $name   = shift;
    my $quoted = 0;

    return if !defined($name);

    $quoted = 1 if ($name =~ s/^"(.*)"$/$1/g);

    return {
        name   => $name,
        quoted => $quoted,
    };
}

=head2 generate

See L<Net::ISC::DHCPd::Config::Role/generate>.

=cut

sub generate {
    my $self = shift;
    if (defined($self->name)) {
        my $name = $self->name;
        return 'group ' . ($self->quoted ? qq("$name") : $name) . ' {', $self->_generate_config_from_children, '}';
    }

    # default with no name
    return 'group {', $self->_generate_config_from_children, '}';
}

=head1 COPYRIGHT & LICENSE

=head1 AUTHOR

See L<Net::ISC::DHCPd>.

=cut
__PACKAGE__->meta->make_immutable;
1;
