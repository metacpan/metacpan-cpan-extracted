package Net::ISC::DHCPd::Config::OptionCode;

=head1 NAME

Net::ISC::DHCPd::Config::OptionCode - Optionspace config param data

=head1 DESCRIPTION

See L<Net::ISC::DHCPd::Config::Role> for methods and attributes without
documentation.

An instance from this class, comes from / will produce one of the
lines below, dependent on L</quoted>.

    option $prefix_attribute_value.$name_attribute_value \
        code $code_attribute_value = $value_attribute_value;

    option $prefix_attribute_value.$name_attribute_value \
        code $code_attribute_value = "$value_attribute_value";

This used to be under OptionSpace, but they can actually be seperated in
dhcpd.conf files, which means they need to be parsed seperately.  This
actually makes the parsing easier because they're treated as individual lines.

There is no real difference between these and normal options, but I'm leaving
them seperate in the parser to keep things easy.


=head1 SYNOPSIS

See L<Net::ISC::DHCPd::Config> for synopsis.

=cut

use Moose;

with 'Net::ISC::DHCPd::Config::Role';

=head1 ATTRIBUTES

=head2 prefix

Human readable prefix of this option.  This is the parent of the option.

=cut

has prefix => (
    is => 'ro',
    isa => 'Str',
);

=head2 name

Human readable name of this option, without parent name prefix

=cut

has name => (
    is => 'ro',
    isa => 'Str',
);

=head2 code

Computer readable code for this option.

=cut

has code => (
    is => 'ro',
    isa => 'Int',
);

=head2 value

Value of the option, as a string.

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
our $regex = qr{^\s* option \s+ (\S+) \s+ code \s+ (\d+) \s+ = \s+ (.*) ;}x;

=head1 METHODS

=head2 captured_to_args

See L<Net::ISC::DHCPd::Config::Role/captured_to_args>.

=cut

sub captured_to_args {
    my $name   = shift;
    my $code   = shift;
    my $value  = shift;
    my %values;
    my $quoted = 0;
    if ($name =~ /(\S+)\.(\S+)/) {
        $name = $2;
        $values{prefix} = $1;
    }

    $quoted = 1 if($value =~ s/^"(.*)"$/$1/g);

    return {
        %values,
        name   => $name,
        code   => $code,
        value  => $value,
        quoted => $quoted,
    };
}

=head2 generate

See L<Net::ISC::DHCPd::Config::Role/generate>.

=cut

sub generate {
    my $self = shift;

    if (defined($self->prefix)) {
        return sprintf('option %s.%s code %i = %s;',
            $self->prefix,
            $self->name,
            $self->code,
            $self->value,
        );
    } else {
        return sprintf('option %s code %i = %s;',
            $self->name,
            $self->code,
            $self->value,
        );
    }
}

=head1 COPYRIGHT & LICENSE

=head1 AUTHOR

See L<Net::ISC::DHCPd>.

=cut

1;
