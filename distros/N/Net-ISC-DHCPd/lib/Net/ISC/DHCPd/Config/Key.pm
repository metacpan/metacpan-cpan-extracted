package Net::ISC::DHCPd::Config::Key;

=head1 NAME

Net::ISC::DHCPd::Config::Key - Server key

=head1 DESCRIPTION

See L<Net::ISC::DHCPd::Config::Role> for methods and attributes without
documentation.

An instance from this class, comes from / will produce the block below:

    $name_attribute_value $value_attribute_value;

    key "$name" {
        algorithm $algorithm;
        secret "$secret";
    };

=head1 SYNOPSIS

See L<Net::ISC::DHCPd::Config/SYNOPSIS>.

=cut

use Moose;

with 'Net::ISC::DHCPd::Config::Role';

=head1 ATTRIBUTES

=head2 quoted

This flag tells if the group name should be quoted or not.

=cut

has quoted => (
    is => 'ro',
    isa => 'Bool',
);

=head2 name

Name of the key - See L</DESCRIPTION> for details.

=head2 algorithm

=head2 secret

=cut

has [qw/ name algorithm secret /] => (
    is => 'rw', # TODO: WILL PROBABLY CHANGE!
    isa => 'Str',
);

=head2 regex

See L<Net::ISC::DHCPd::Config::Role/regex>.

=cut

our $regex = qr{^\s* key \s+ ([\w-]+|".*?") }x;

=head1 METHODS

=head2 slurp

This method is used by L<Net::ISC::DHCPd::Config::Role/parse>, and will
slurp the content of the function, instead of trying to parse the
statements.

=cut

sub slurp {
    my($self, $line) = @_;

    return 'last' if($line =~ /^\s*}/);
    $self->algorithm($1) if($line =~ /algorithm \s+ (\S+);/x);
    $self->secret($2) if($line =~ /secret \s+ ("?)(\S+)\1;/x);
    return 'next';
}

=head2 captured_to_args

See L<Net::ISC::DHCPd::Config::Role/captured_to_args>.

=cut

sub captured_to_args {
    my $value = shift;
    my $quoted = 0;
    $quoted = 1 if($value =~ s/^"(.*)"$/$1/g);
    return { quoted => $quoted, name => $value };
}

=head2 generate

See L<Net::ISC::DHCPd::Config::Role/generate>.

=cut

sub generate {
    my $self = shift;
    my $name = $self->name;

    return(
        sprintf('key '. ($self->quoted ? qq("$name") : $name). ' {'),
        $self->algorithm ? (sprintf '    algorithm %s;', $self->algorithm) : (),
        $self->secret ? (sprintf '    secret "%s";', $self->secret) : (),
        '};', # semicolon is for compatibility with bind key files
    );
}

=head1 COPYRIGHT & LICENSE

=head1 AUTHOR

See L<Net::ISC::DHCPd>.

=cut
__PACKAGE__->meta->make_immutable;
1;
