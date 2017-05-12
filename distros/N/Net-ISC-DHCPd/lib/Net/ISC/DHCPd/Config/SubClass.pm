package Net::ISC::DHCPd::Config::SubClass;

=head1 NAME

Net::ISC::DHCPd::Config::Subclass - Subclass config parameter

=head1 DESCRIPTION

See L<Net::ISC::DHCPd::Config::Role> for methods and attributes without
documentation.

An instance from this class, comes from / will produce one of the
lines below, dependent on L</quoted>.

    subclass "$name" "$value";

=head1 SYNOPSIS

See L<Net::ISC::DHCPd::Config/SYNOPSIS>.

=cut

use Moose;

with 'Net::ISC::DHCPd::Config::Role';

=head1 ATTRIBUTES

=head2 name

Name of the subclass - See L</DESCRIPTION> for details.

=cut

has name => (
    is => 'ro',
    isa => 'Str',
);

=head2 value

Value of the subclass - See L</DESCRIPTION> for details.

=cut

has value => (
    is => 'ro',
    isa => 'Str',
);

=head2 quoted

This flag tells if the subclass value should be quoted or not.

=cut

has quoted => (
    is => 'ro',
    isa => 'Bool',
);

=head2 namequoted

This flag tells if the subclass name should be quoted or not.

=cut

has namequoted => (
    is => 'ro',
    isa => 'Bool',
);

=head2 regex

See L<Net::ISC::DHCPd::Config::Role/regex>.

=cut

our $regex = qr{^\s*subclass \s+ ([\w-]+|".*?") \s+ (.*) ;}x;

=head1 METHODS

=head2 captured_to_args

See L<Net::ISC::DHCPd::Config::Role/captured_to_args>.

=cut

sub captured_to_args {
    my $name   = shift;
    my $value  = shift;
    my $quoted = 0;
    my $namequoted = 0;

    $namequoted = 1 if ($name =~ s/^"(.*)"$/$1/g);
    $quoted = 1 if($value =~ s/^"(.*)"$/$1/g);

    return {
        name   => $name,
        value  => $value,
        quoted => $quoted,
        namequoted => $namequoted,
    };
}

=head2 generate

See L<Net::ISC::DHCPd::Config::Role/generate>.

=cut

sub generate {
    my $self  = shift;
    my $format = "subclass ";
    $format .= $self->namequoted ? qq("%s" ) : qq(%s );
    $format .= $self->quoted ? qq("%s";) : qq(%s;);

    return sprintf $format, $self->name, $self->value;
}

=head1 COPYRIGHT & LICENSE

=head1 AUTHOR

See L<Net::ISC::DHCPd>.

=cut
__PACKAGE__->meta->make_immutable;
1;
