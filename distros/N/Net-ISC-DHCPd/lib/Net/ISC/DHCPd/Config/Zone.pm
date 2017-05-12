package Net::ISC::DHCPd::Config::Zone;

=head1 NAME

Net::ISC::DHCPd::Config::Zone - Server Zone

=head1 DESCRIPTION

See L<Net::ISC::DHCPd::Config::Role> for methods and attributes without
documentation.

An instance from this class, comes from / will produce the block below:

    $name_attribute_value $value_attribute_value;

    zone $name {
        primary $primary;
        key $key;
    };

=head1 SYNOPSIS

See L<Net::ISC::DHCPd::Config/SYNOPSIS>.

=cut

use Moose;

with 'Net::ISC::DHCPd::Config::Role';

=head1 ATTRIBUTES

=head2 name

Name of the Zone - See L</DESCRIPTION> for details.

=head2 primary

=head2 key

=cut

has [qw/ name key primary /] => (
    is => 'rw', # TODO: WILL PROBABLY CHANGE!
    isa => 'Str',
);

=head2 regex

See L<Net::ISC::DHCPd::Config::Role/regex>.

=cut

# not sure if this can be quoted or not
our $regex = qr{^\s* zone \s+ (")?(\S+)(\1|$) }x;

=head1 METHODS

=head2 slurp

This method is used by L<Net::ISC::DHCPd::Config::Role/parse>, and will
slurp the content of the function, instead of trying to parse the
statements.

=cut

sub slurp {
    my($self, $line) = @_;

    return 'last' if($line =~ /^\s*}/);
    # not sure if these can really be quoted
    $self->primary($1) if($line =~ /primary \s+ (\S+);/x);
    $self->key($2) if($line =~ /key \s+ ("?)(\S+)\1;/x);
    return 'next';
}

=head2 captured_to_args

See L<Net::ISC::DHCPd::Config::Role/captured_to_args>.

=cut

sub captured_to_args {
    return { name => $_[1] }; # $_[0] == quote or empty string
}

=head2 generate

See L<Net::ISC::DHCPd::Config::Role/generate>.

=cut

sub generate {
    my $self = shift;

    return(
        sprintf('zone %s {', $self->name),
        $self->primary ? (sprintf '    primary %s;', $self->primary) : (),
        $self->key ? (sprintf '    key %s;', $self->key) : (),
        '}',
    );
}

=head1 COPYRIGHT & LICENSE

=head1 AUTHOR

See L<Net::ISC::DHCPd>.

=cut

__PACKAGE__->meta->make_immutable;
1;
