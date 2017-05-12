package Protocol::XMLRPC::ValueFactory;

use strict;
use warnings;

use B;
use Scalar::Util qw(blessed);

use Protocol::XMLRPC::Value::Double;
use Protocol::XMLRPC::Value::String;
use Protocol::XMLRPC::Value::Integer;
use Protocol::XMLRPC::Value::Array;
use Protocol::XMLRPC::Value::Boolean;
use Protocol::XMLRPC::Value::DateTime;
use Protocol::XMLRPC::Value::Struct;

sub build {
    my $class = shift;

    return unless @_;

    my ($type, $value) = @_;
    ($value, $type) = ($type, '') unless defined $value;

    return $value if blessed($value);

    # From JSON::PP
    my $flags = B::svref_2object(\$value)->FLAGS;
    my $is_number = $flags & (B::SVp_IOK | B::SVp_NOK)
      and !($flags & B::SVp_POK) ? 1 : 0;

    if (($type && $type eq 'array') || ref($value) eq 'ARRAY') {
        return Protocol::XMLRPC::Value::Array->new($value);
    }
    elsif (($type && $type eq 'struct') || ref($value) eq 'HASH') {
        return Protocol::XMLRPC::Value::Struct->new($value);
    }
    elsif (($type && $type eq 'int') || ($is_number && $value =~ m/^(?:\+|-)?\d+$/)) {
        return Protocol::XMLRPC::Value::Integer->new($value);
    }
    elsif (($type && $type eq 'double') || ($is_number && $value =~ m/^(?:\+|-)?\d+\.\d+$/)) {
        return Protocol::XMLRPC::Value::Double->new($value);
    }
    elsif (($type && $type eq 'boolean') || ref($value) eq 'SCALAR') {
        return Protocol::XMLRPC::Value::Boolean->new($value);
    }
    elsif (($type && $type eq 'datetime')
        || $value =~ m/^(\d\d\d\d)(\d\d)(\d\d)T(\d\d):(\d\d):(\d\d)$/)
    {
        return Protocol::XMLRPC::Value::DateTime->parse($value);
    }

    return Protocol::XMLRPC::Value::String->new($value);
}

1;
__END__

=head1 NAME

Protocol::XMLRPC::ValueFactory - value objects factory

=head1 SYNOPSIS

    my $array    = Protocol::XMLRPC::ValueFactory->build([...]);
    my $struct   = Protocol::XMLRPC::ValueFactory->build({...});
    my $integer  = Protocol::XMLRPC::ValueFactory->build(1);
    my $double   = Protocol::XMLRPC::ValueFactory->build(1.2);
    my $datetime = Protocol::XMLRPC::ValueFactory->build('19980717T14:08:55');
    my $boolean  = Protocol::XMLRPC::ValueFactory->build(\1);
    my $string   = Protocol::XMLRPC::ValueFactory->build('foo');

=head1 DESCRIPTION

This is a value object factory. Used internally. In synopsis you can see what
types can be guessed.

=head1 ATTRIBUTES

=head1 METHODS

=head2 C<build>

Builds new value object. If no instance was provided tries to guess type.
