package SOAP::TypedPrimitive;

use strict;
use vars qw($VERSION);
use SOAP::Defs;
use SOAP::TypedPrimitiveSerializer;

$VERSION = '0.28';

sub new {
    my ($class, $value, $type) = @_;
    
    my $self = [$value, $type];
    bless $self, $class;
}

sub get_soap_serializer {
    my $self = shift;
    SOAP::TypedPrimitiveSerializer->new($self);
}

1;
__END__

=head1 NAME

SOAP::TypedPrimitive - Wrapper for xsd primitives that need explicit SOAP type attributes

=head1 SYNOPSIS

use SOAP::TypedPrimitive;

my $body = {
    a => SOAP::TypedPrimitive->new(3, 'float'),
    b => SOAP::TypedPrimitive->new(4, 'float'),
};

=head1 DESCRIPTION

In some cases it is desirable to provide explicit types for parameters
being passed to SOAP methods. One legitimate case is when you need to
disambiguate a call to a method that is one of many with the same
name that only differ by the parameter types (i.e., an 'overloaded'
method).

=head2 new(value, typeString)

Returns a blessed object reference that has a custom serializer that
will emit explicit xsi:type attributes. For instance, the above
example produces the following SOAP representation for 'a':

<a xsi:type='xsd:float'>3</a>

Note that this class only supports primitive types defined in the xsd
namespace (see XML Schema Part 2: Datatypes)

=head1 DEPENDENCIES

SOAP::Defs
SOAP::TypedPrimitiveSerializer

=head1 AUTHOR

Keith Brown

=head1 SEE ALSO

SOAP::EnvelopeMaker

=cut




