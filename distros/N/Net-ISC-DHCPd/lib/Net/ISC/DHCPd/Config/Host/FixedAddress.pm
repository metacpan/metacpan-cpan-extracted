package Net::ISC::DHCPd::Config::Host::FixedAddress;

=head1 NAME

Net::ISC::DHCPd::Config::Host::FixedAddress - IP address for Hosts

=head1 DESCRIPTION

See L<Net::ISC::DHCPd::Config::Role> for methods and attributes without
documentation.

An instance from this class, comes from / will produce one of the
lines below

    fixed-address $value_attribute_value;

=head1 SYNOPSIS

See L<Net::ISC::DHCPd::Config/SYNOPSIS>.

=cut

use Moose;

with 'Net::ISC::DHCPd::Config::Role';

=head1 ATTRIBUTES

=head2 value

Value of the option - See L</DESCRIPTION> for details.

=cut

has value => (
    is => 'ro',
    isa => 'Str',
);

=head2 regex

See L<Net::ISC::DHCPd::Config::Role/regex>.

=cut

our $regex = qr{^\s* fixed-address \s+ (.*) ;}x;

=head1 METHODS

=head2 captured_to_args

See L<Net::ISC::DHCPd::Config::Role/captured_to_args>.

=cut

sub captured_to_args {
    my $value  = shift;

    return {
        value  => $value,
    };
}

=head2 generate

See L<Net::ISC::DHCPd::Config::Role/generate>.

=cut

sub generate {
    my $self  = shift;
    return sprintf qq(fixed-address %s;), $self->value;
}

=head1 COPYRIGHT & LICENSE

=head1 AUTHOR

See L<Net::ISC::DHCPd>.

=cut
__PACKAGE__->meta->make_immutable;
1;
