package Net::ISC::DHCPd::Config::OptionSpace;

=head1 NAME

Net::ISC::DHCPd::Config::OptionSpace - Optionspace config parameter

=head1 DESCRIPTION

See L<Net::ISC::DHCPd::Config::Role> for methods and attributes without
documentation.

An instance from this class, comes from / will produce:

    option space $name_attribute_value;

=head1 SYNOPSIS

See L<Net::ISC::DHCPd::Config/SYNOPSIS>.

=cut

use Moose;

with 'Net::ISC::DHCPd::Config::Role';

=head1 ATTRIBUTES

=head2 name

Name of the option namespace as a string.

=cut

has name => (
    is => 'rw',
    isa => 'Str',
);

=head2 regex

See L<Net::ISC::DHCPd::Config::Role/regex>.

=cut
our $regex = qr{^\s* option \s+ space \s+ (.*) ;}x;

=head1 METHODS

=head2 captured_to_args

See L<Net::ISC::DHCPd::Config::Role/captured_to_args>.

=cut

sub captured_to_args {
    return { name => $_[0] }
}

=head2 generate

See L<Net::ISC::DHCPd::Config::Role/generate>.

=cut

sub generate {
    return 'option space ' . shift->name. ';';
}

=head1 COPYRIGHT & LICENSE

=head1 AUTHOR

See L<Net::ISC::DHCPd>.

=cut
__PACKAGE__->meta->make_immutable;
1;
