package Net::ISC::DHCPd::Config::Pool;

=head1 NAME

Net::ISC::DHCPd::Config::Pool - Pool config parameter

=head1 DESCRIPTION

See L<Net::ISC::DHCPd::Config::Role> for methods and attributes without
documentation.

An instance from this class, comes from / will produce:

    pool {
        $keyvalue_attribute_value
        $range_attribute_value
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
        Net::ISC::DHCPd::Config::Host
        Net::ISC::DHCPd::Config::Option
        Net::ISC::DHCPd::Config::Range
        Net::ISC::DHCPd::Config::Range6
        Net::ISC::DHCPd::Config::KeyValue
    /;
}
__PACKAGE__->create_children(__PACKAGE__->children());

=head1 ATTRIBUTES

=head2 options

A list of parsed L<Net::ISC::DHCPd::Config::Option> objects.

=head2 ranges

A list of parsed L<Net::ISC::DHCPd::Config::Range> objects.

=cut

=head2 regex

See L<Net::ISC::DHCPd::Config::Role/regex>.

=cut
our $regex = qr{^ \s* pool}x;

=head1 METHODS

=head2 generate

See L<Net::ISC::DHCPd::Config::Role/generate>.

=cut

sub generate {
    my $self = shift;
    return 'pool {', $self->_generate_config_from_children, '}';
}

=head1 COPYRIGHT & LICENSE

=head1 AUTHOR

See L<Net::ISC::DHCPd>.

=cut
__PACKAGE__->meta->make_immutable;
1;
