package Protocol::XMLRPC::Value::Integer;

use strict;
use warnings;

use base 'Protocol::XMLRPC::Value';

sub new {
    my $self = shift->SUPER::new(@_);

    $self->{alias} ||= 'i4';

    return $self;
}

sub parse {
    my $class = shift;
    my $string = shift;

    die "Invalid 'Integer' value"
      unless defined $string && $string =~ m/^(?:\+|-)?\d+$/;

    return $class->new($string, @_);
}

sub alias { defined $_[1] ? $_[0]->{alias} = $_[1] : $_[0]->{alias} }

sub type {'int'}

sub to_string {
    my $self = shift;

    my $value = $self->value;

    $value = int($value);

    my $alias = $self->alias;
    return "<$alias>$value</$alias>";
}

1;
__END__

=head1 NAME

Protocol::XMLRPC::Value::Integer - XML-RPC array

=head1 SYNOPSIS

    my $integer = Protocol::XMLRPC::Value::Integer->new(123);

=head1 DESCRIPTION

XML-RPC integer

=head1 ATTRIBUTES

=head2 C<alias>

XML-RPC integer can be represented as 'int' and 'i4'. This parameter is 'i4' by
default, but you can change it to 'int'.

=head1 METHODS

=head2 C<new>

Creates new L<Protocol::XMLRPC::Value::Integer> instance.

=head2 C<type>

Returns 'integer'.

=head2 C<value>

    my $integer = Protocol::XMLRPC::Value::Integer->new(1);
    # $integer->value returns 1

Returns serialized Perl5 scalar.

=head2 C<to_string>

    my $integer = Protocol::XMLRPC::Value::Integer->new(1);
    # $integer->to_string is now '<i4>1</i4>'

    my $integer = Protocol::XMLRPC::Value::Integer->new(1, alias => 'int');
    # $integer->to_string is now '<int>1</int>'

XML-RPC integer string representation.
