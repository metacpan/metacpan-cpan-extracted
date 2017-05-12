package Net::ISC::DHCPd::Config::Option;

=head1 NAME

Net::ISC::DHCPd::Config::Option - Option config parameter

=head1 DESCRIPTION

See L<Net::ISC::DHCPd::Config::Role> for methods and attributes without
documentation.

An instance from this class, comes from / will produce one of the
lines below, dependent on L</quoted>.

    option $name_attribute_value "$value_attribute_value";
    option $name_attribute_value $value_attribute_value;

=head1 SYNOPSIS

See L<Net::ISC::DHCPd::Config/SYNOPSIS>.

=cut

use Moose;

with 'Net::ISC::DHCPd::Config::Role';

=head1 ATTRIBUTES

=head2 name

A plain string representing the name of the option.

=cut

has name => (
    is => 'ro',
    isa => 'Str',
);

=head2 value

A plain string representing the value of the option.

=cut

has value => (
    is => 'ro',
    isa => 'Str',
);

=head2 quoted

This flag tells if the option value should be quoted or not.

=cut

has quoted => (
    is => 'ro',
    isa => 'Bool',
);

=head2 regex

See L<Net::ISC::DHCPd::Config::Role/regex>.

=cut

our $regex = qr{^\s* option \s+ (\S+) \s+ (.*) ;}x;

=head1 METHODS

=head2 captured_to_args

See L<Net::ISC::DHCPd::Config::Role/captured_to_args>.

=cut

sub captured_to_args {
    my $name   = shift;
    my $value  = shift;
    my $quoted = 0;

    $quoted = 1 if($value =~ s/^"(.*)"$/$1/g);

    return {
        name   => $name,
        value  => $value,
        quoted => $quoted,
    };
}

=head2 generate

See L<Net::ISC::DHCPd::Config::Role/generate>.

=cut

sub generate {
    my $self = shift;
    my $format = $self->quoted ? qq(option %s "%s";) : qq(option %s %s;);

    return sprintf $format, $self->name, $self->value;
}

=head1 COPYRIGHT & LICENSE

=head1 AUTHOR

See L<Net::ISC::DHCPd>.

=cut
__PACKAGE__->meta->make_immutable;
1;
