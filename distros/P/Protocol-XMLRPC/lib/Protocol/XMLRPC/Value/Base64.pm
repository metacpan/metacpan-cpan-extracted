package Protocol::XMLRPC::Value::Base64;

use strict;
use warnings;

use base 'Protocol::XMLRPC::Value';

require MIME::Base64;

sub type {'base64'}

sub parse {
    my $class = shift;
    my ($value) = @_;

    die "Invalid 'Base64' value" unless $value =~ m/^[A-Za-z0-9\+\/=]+$/;

    return $class->new(MIME::Base64::decode_base64($value));
}

sub to_string {
    my $self = shift;

    my $value = $self->value;

    $value = MIME::Base64::encode_base64($value);

    return "<base64>$value</base64>";
}

1;
__END__

=head1 NAME

Protocol::XMLRPC::Value::Base64 - XML-RPC array

=head1 SYNOPSIS

    my $base64 = Protocol::XMLRPC::Value::Base64->new('foo');
    my $base64 = Protocol::XMLRPC::Value::Base64->parse("Zm9v\n");

=head1 DESCRIPTION

XML-RPC base64

=head1 METHODS

=head2 C<new>

Creates new L<Protocol::XMLRPC::Value::Base64> instance.

=head2 C<parse>

Parses base64 string and creates a new L<Protocol::XMLRPC:::Value::Base64>
instance.

=head2 C<type>

Returns 'base64'.

=head2 C<value>

    my $base64 = Protocol::XMLRPC::Value::Base64->new('foo');
    # $base64->value returns 'Zm9v\n'

Returns serialized Perl5 scalar.

=head2 C<to_string>

    my $base64 = Protocol::XMLRPC::Value::Base64->new('foo');
    # $base64->to_string is now
    # '<base64>Zm9v
    # </base64>'

XML-RPC base64 string representation.
