package Net::ISC::DHCPd::Config::Range;

=head1 NAME

Net::ISC::DHCPd::Config::Range - Range config parameter

=head1 DESCRIPTION

See L<Net::ISC::DHCPd::Config::Role> for methods and attributes without
documentation.

An instance from this class, comes from / will produce:

    range $lower_attribute_value $upper_attribute_value;

=head1 SYNOPSIS

See L<Net::ISC::DHCPd::Config/SYNOPSIS>.

=head1 NOTES

L</upper> and L</lower> attributes might change from L<NetAddr::IP> to
plain strings in the future.

=cut

use Moose;
use NetAddr::IP;

with 'Net::ISC::DHCPd::Config::Role';

=head1 ATTRIBUTES

=head2 upper

This attribute holds a L<NetAddr::IP> object, representing the
highest IP address in the range.

=cut

has upper => (
    is => 'ro',
    isa => 'Object',
);

=head2 lower

This attribute holds a L<NetAddr::IP> object, representing the
lowest IP address in the range.

=cut

has lower => (
    is => 'ro',
    isa => 'Object',
);

=head2 regex

See L<Net::ISC::DHCPd::Config::Role/regex>.

=cut

our $regex = qr{^\s* range \s+ (\S+) (?:\s+ (\S*))? ;}x;

=head1 METHODS

=head2 captured_to_args

See L<Net::ISC::DHCPd::Config::Role/captured_to_args>.

=cut

sub captured_to_args {

    if (!defined($_[1])) {
        return { lower => NetAddr::IP->new($_[0]) };
    } else {
        return {
            lower => NetAddr::IP->new($_[0]),
            upper => NetAddr::IP->new($_[1]),
        };
    }
}

=head2 generate

See L<Net::ISC::DHCPd::Config::Role/generate>.

=cut

sub generate {
    my $self = shift;
    if (defined($self->upper)) {
        return 'range ' .$self->lower->addr .' ' .$self->upper->addr .';';
    } else {
        return 'range ' .$self->lower->addr.';';
    }
}

=head1 COPYRIGHT & LICENSE

=head1 AUTHOR

See L<Net::ISC::DHCPd>.

=cut
__PACKAGE__->meta->make_immutable;
1;
