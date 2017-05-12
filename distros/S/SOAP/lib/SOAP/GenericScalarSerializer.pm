package SOAP::GenericScalarSerializer;

use strict;
use vars qw($VERSION);

$VERSION = '0.28';

sub new {
    my ($class, $scalar) = @_;
    
    my $self = \$scalar;
    bless $self, $class;
}

sub get_typeinfo {
    (undef, undef);
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
    $$self;
}

1;
__END__


=head1 NAME

SOAP::GenericScalarSerializer - Generic serializer for Perl scalar references

=head1 SYNOPSIS

Forthcoming

=head1 DESCRIPTION

Forthcoming

=head1 AUTHOR

Keith Brown

=cut
