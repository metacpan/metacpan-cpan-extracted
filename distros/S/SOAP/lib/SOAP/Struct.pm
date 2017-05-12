package SOAP::Struct;

use strict;
use vars qw($VERSION);

use SOAP::StructSerializer;

$VERSION = '0.28';

sub new {
    my $class = shift;
    my $self = {
	content => [@_],
    };
    bless $self, $class;
}

sub new_typed {
    my $self = &new;
    $self->{contains_types} = 1;
    $self;
}

sub get_soap_serializer {
    my $self = shift;
    SOAP::StructSerializer->new($self);
}

1;
__END__

=head1 NAME

SOAP::Struct - support for ordered hashes

=head1 SYNOPSIS

use SOAP::EnvelopeMaker;

# produce a body that will retain the order of params
# when serialized to a SOAP envelope
my $body = SOAP::Struct->new(
    a => 3,
    b => 4,
);

# same as above, but explicit xsi:type attrs will also
# be included for accessor 'b'
my $body = SOAP::Struct->new_typed(
    a => 3,     undef,
    b => 4,     'float',
);

=head1 DESCRIPTION

The SOAP spec explicitly mandates that it should be possible to
serialize structures and control both the names of the accessors
and the order that they appear in the serialized stream.
(SOAP 1.1, section 7.1, bullet 3) Prior to
SOAP/Perl 0.25, this was impossible, as the only way to serialize
a "struct" was to use a hash, which is unordered in Perl. This class
allows you to specify a structure where the order of the accessors
is preserved. This is important when making SOAP calls to many
traditional RPC-style servers that expect parameters to arrive
in a certain order (and could generally care less about the
names of those parameters).

=head2 new(accessor_1_name => accessor_1_value, ...)

This constructor feels the same as constructing a hash, but the order
of the accessors will be maintained when this "super-hash" is serialized.

=head2 new_typed(accessor_1_name => accessor_1_value, accessor_1_type, ...)

This constructor is for convenience - if you pass something other than
undef for accessor_n_type, then accessor_n_value will be wrapped with
a TypedPrimitive class with the specified type. This way you can force
explicit type names to be used for each element in the structure.
See SOAP::TypedPrimitive for a discussion of why this can be important.

=head1 DEPENDENCIES

SOAP::TypedPrimitive

=head1 AUTHOR

Keith Brown

=head1 SEE ALSO

SOAP::TypedPrimitive

=cut
