package SOAP::TypedPrimitiveSerializer;

use strict;
use vars qw($VERSION);
use SOAP::Defs;

$VERSION = '0.28';

sub new {
    my ($class, $prim) = @_;
    
    my $self = \$prim;
    bless $self, $class;
}

sub get_typeinfo {
    my $self = shift;
    ($xsd_namespace, $$self->[1]);
}

sub is_compound {
    0;
}

sub is_multiref {
    0;
}

sub is_package {
    0;
}

sub serialize_as_string {
    my $self = shift;
    $$self->[0];
}

1;
__END__

=head1 NAME

SOAP::TypedPrimitiveSerializer - serializer for xsd scalars

=head1 DEPENDENCIES

SOAP::TypedPrimitive

=head1 AUTHOR

Keith Brown

=head1 SEE ALSO

SOAP::TypedPrimitive

=cut




