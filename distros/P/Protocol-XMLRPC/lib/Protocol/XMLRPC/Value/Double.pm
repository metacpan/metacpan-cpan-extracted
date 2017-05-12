package Protocol::XMLRPC::Value::Double;

use strict;
use warnings;

use base 'Protocol::XMLRPC::Value';

sub type {'double'}

sub parse {
    my $class = shift;
    my $string = shift;

    die "Invalid 'Double' value"
      unless defined $string && $string =~ m/^(?:\+|-)?\d+(?:\.\d+)?$/;

    return $class->new($string, @_);
}

sub to_string {
    my $self = shift;

    my $value = $self->value;

    return "<double>$value</double>";
}

1;
__END__

=head1 NAME

Protocol::XMLRPC::Value::Double - XML-RPC array

=head1 SYNOPSIS

    my $double = Protocol::XMLRPC::Value::Double->new(1.12);

=head1 DESCRIPTION

XML-RPC double

=head1 METHODS

=head2 C<new>

Creates new L<Protocol::XMLRPC::Value::Double> instance.

=head2 C<type>

Returns 'double'.

=head2 C<value>

    my $double = Protocol::XMLRPC::Value::Double->new(1.2);
    # $double->value returns 1.2

Returns serialized Perl5 scalar.

=head2 C<to_string>

    my $double = Protocol::XMLRPC::Value::Double->new(1.2);
    # $double->to_string is now '<double>1.2</double>'

XML-RPC double string representation.
