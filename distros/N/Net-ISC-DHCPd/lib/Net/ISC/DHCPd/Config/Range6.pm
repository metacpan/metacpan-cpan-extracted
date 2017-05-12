package Net::ISC::DHCPd::Config::Range6;

=head1 NAME

Net::ISC::DHCPd::Config::Range6 - Range6 config parameter

=head1 DESCRIPTION

See L<Net::ISC::DHCPd::Config::Role> for methods and attributes without
documentation.

An instance from this class, comes from / will produce:

    range6 $lower_attribute_value $upper_attribute_value;

or

    range6 $lower_attribute_value temporary;

=head1 SYNOPSIS

See L<Net::ISC::DHCPd::Config/SYNOPSIS>.

=head1 NOTES

L</upper> and L</lower> attributes might change from L<NetAddr::IP> to
plain strings in the future.

=cut

use Moose;
use NetAddr::IP qw(:lower);

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

=head2 temporary

In place of an upper address range, you can specify that the range is for
temporary addresses and it will be used like RFC4941

=cut

has temporary => (
    is => 'ro',
    isa => 'Bool',
);

=head2 regex

See L<Net::ISC::DHCPd::Config::Role/regex>.

=cut

our $regex = qr{^\s* range6 \s+ (\S+) \s+ (\S*) \s* ;}x;

=head1 METHODS

=head2 captured_to_args

See L<Net::ISC::DHCPd::Config::Role/captured_to_args>.

=cut

sub captured_to_args {
    my $args;
    $args->{'temporary'}=0;
    if ($_[1] eq 'temporary') {
        $args->{'temporary'}=1;
    } else {
        $args->{'upper'}=NetAddr::IP->new($_[1]);
    }
    $args->{'lower'}=NetAddr::IP->new($_[0]);

    return $args;
}

=head2 generate

See L<Net::ISC::DHCPd::Config::Role/generate>.

=cut

sub generate {
    my $self = shift;
    return 'range6 ' .$self->lower->short .' '. ($self->temporary ?  'temporary' : $self->upper->short) .';';
}

=head1 COPYRIGHT & LICENSE

=head1 AUTHOR

See L<Net::ISC::DHCPd>.

=cut

__PACKAGE__->meta->make_immutable;

1;
