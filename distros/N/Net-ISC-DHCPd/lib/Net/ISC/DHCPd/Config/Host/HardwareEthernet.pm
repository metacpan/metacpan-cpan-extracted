package Net::ISC::DHCPd::Config::Host::HardwareEthernet;

=head1 NAME

Net::ISC::DHCPd::Config::Host::HardwareEthernet - Misc option config parameter

=head1 DESCRIPTION

See L<Net::ISC::DHCPd::Config::Role> for methods and attributes without
documentation.

An instance from this class, comes from / will produce one of the
lines below

    hardware ethernet $value_attribute_value;

=head1 SYNOPSIS

See L<Net::ISC::DHCPd::Config/SYNOPSIS>.

=cut

use Moose;
use Net::ISC::DHCPd::Types 'Mac';

with 'Net::ISC::DHCPd::Config::Role';

# not sure how I feel about the overload.  I would rather coerce the values
# into a Mac type, but I want case preserved from input to output.  I only
# want comparisions to be insensitive.

use overload '==' => \&myequals,
             'eq' => \&myequals,
            q("") => \&get_value;

=head1 ATTRIBUTES

=head2 myequals

equality check overload for case insensitive comparision

=cut

sub myequals {
    return (uc($_[0]->value) eq uc($_[1]));
}

=head2 get_value

for overload q("")

=cut

sub get_value { uc(shift->value) }

=head2 value

Value of the option - See L</DESCRIPTION> for details.

=cut

has value => (
    is => 'ro',
    isa => Mac,
    coerce => 1,
);

=head2 regex

See L<Net::ISC::DHCPd::Config::Role/regex>.

=cut

our $regex = qr{^\s* hardware \s+ ethernet \s+ (.*) ;}x;

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
    return sprintf qq(hardware ethernet %s;), $self->value;
}

=head1 COPYRIGHT & LICENSE

=head1 AUTHOR

See L<Net::ISC::DHCPd>.

=cut
__PACKAGE__->meta->make_immutable;
1;
