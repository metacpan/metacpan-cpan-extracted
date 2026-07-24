package TOML::XS::Document;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

TOML::XS::Document - Object representation of a L<TOML|https://toml.io> document

=head1 SYNOPSIS

See L<TOML::XS>.

=head1 DESCRIPTION

Instances of this class represent a parse of a TOML document.

This class is not directly instantiable.

=head1 METHODS

=head2 $what = I<OBJ>->get( @POINTER )

Returns some part of the parsed TOML document as a Perl scalar.

If @POINTER is empty, then the return will be the entire parsed TOML
document, represented as a hash reference.

@POINTER, if given, refers to some part of the document: $POINTER[0]
is a key in the document’s top-level table, $POINTER[1] references
some piece of the structure beneath it, etc. If @POINTER refers to a
nonexistent part of the document then a suitable exception is thrown.

All elements of @POINTER must be I<character> strings.

As of now thrown exceptions are simple character strings
that include, where relevant, a
L<JSON pointer|https://tools.ietf.org/html/rfc6901> to the problematic
data point.

For historical reasons this may also be called C<parse>.

=cut

1;
