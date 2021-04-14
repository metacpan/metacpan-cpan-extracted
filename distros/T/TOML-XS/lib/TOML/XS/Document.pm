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

=head2 $hashref = I<OBJ>->to_struct()

Returns a hash reference that represents the parsed TOML document.

If the read of the TOML structure encounters a malformed data point
an exception is thrown. As of now that exception is a simple character string
that includes a L<JSON pointer|https://tools.ietf.org/html/rfc6901>
to the problematic data point.

=cut

1;
