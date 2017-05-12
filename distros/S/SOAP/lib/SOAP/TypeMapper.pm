package SOAP::TypeMapper;

use SOAP::GenericScalarSerializer;
use SOAP::GenericHashSerializer;

use strict;
use vars qw($VERSION);

$VERSION = '0.28';

sub new {
    my ($class) = @_;
    
    my $self = {
        serializer_map   => {},
        deserializer_map => {},
    };
    bless $self, $class;
}

my $g_defaultMapper;

sub defaultMapper {
    $g_defaultMapper ||= SOAP::TypeMapper->new();
}

my $g_unhandled_types_for_serialization = {
    REF     => "SOAP/Perl does not attempt to serialize references to references. Please simplify.",
    CODE    => "SOAP/Perl does not attempt to serialize code references.",
    GLOB    => "SOAP/Perl does not attempt to serialize typeglobs.",
};

sub get_serializer {
    my ($self, $object) = @_;

# for now, assume caller handles undef according to context
    unless (defined $object) {
	die "unexpected call to get_serializer with <undef>";
    }
#    unless (defined $object) {
#	return SOAP::GenericScalarSerializer->new('');
#    }
    my $reftype = ref $object;
    unless ($reftype) {
	return SOAP::GenericScalarSerializer->new($object)
    }
    if (exists $g_unhandled_types_for_serialization->{$reftype}) {
        die $g_unhandled_types_for_serialization->{$reftype};
    }
    if ('SCALAR' eq $reftype) {
        return SOAP::GenericScalarSerializer->new($$object);
    }
    if ('HASH' eq $reftype) {
        return SOAP::GenericHashSerializer->new($object);
    }
    elsif ('ARRAY' eq $reftype) {
        die "This implementation of SOAP/Perl doesn't attempt to marshal/unmarshal arrays.";
    }

    # by process of elimination, it must be a blessed object reference
    # see if the object itself wants to provide its own serializer,
    # otherwise do lookup in dictionary
    if ($object->can('get_soap_serializer')) {
        return $object->get_soap_serializer();
    }
    elsif (exists $self->{serializer_map}{$reftype}) {
        return $self->{serializer_map}{$reftype}->($object);
    }
    # if all else fails, do something generic (eventually)
    die "This implementation of SOAP/Perl doesn't attempt to marshal/unmarshal blessed object references.";
}

sub get_deserializer {
    my ($self, $typeuri, $typename, $resolver) = @_;

    $typeuri  ||= '';
    $typename ||= '';

    my $map = $self->{deserializer_map};

    my $key = $typeuri . '#' . $typename;
    if (exists $map->{$key}) {
        return $map->{$key}->($typeuri, $typename, $resolver);
    }
    return SOAP::GenericInputStream->new($typeuri,
                                         $typename,
                                         $resolver,
                                         $self);
}

sub register_deserializer_factory {
    my ($self, $typename, $typeuri, $factory_fcn) = @_;

    $self->{deserializer_map}{$typeuri . '#' . $typename} = $factory_fcn;
}

sub register_serializer_factory {
    my ($self, $reftype, $factory_fcn) = @_;

    $self->{serializer_map}{$reftype} = $factory_fcn;
}

1;
__END__


=head1 NAME

SOAP::TypeMapper - Maps Perl types to their serializer/deserializer classes

=head1 SYNOPSIS

This is an extensibility point built in to SOAP/Perl to allow for future expansion,
especially with regards to the eventual development of an XML Schema-based metadata
format. In the short term, you can use this extensibility point to add support
for marshaling blessed object references.

This is currently an experimental feature and will be documented in more detail
once we have a bit more implementation experience. Feel free to peruse the sources
and use this class if you like, and send feedback.

=head1 DESCRIPTION

Forthcoming...

=head1 AUTHOR

Keith Brown

=cut
