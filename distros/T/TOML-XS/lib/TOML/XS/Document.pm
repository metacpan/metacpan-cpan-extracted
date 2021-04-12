package TOML::XS::Document;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

TOML::XS::Document - Object representation of a L<TOML|https://toml.io> document

=head1 SYNOPSIS

See L<TOML::XS>.

=head1 DESCRIPTION

This object represents a parse of a TOML document. It is not
directly instantiable.

=head1 METHODS

=head2 $hashref = I<OBJ>->to_struct()

Returns a hash reference that represents the parsed TOML document.

=cut

1;
