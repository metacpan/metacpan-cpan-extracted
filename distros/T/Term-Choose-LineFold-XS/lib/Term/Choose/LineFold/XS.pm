package Term::Choose::LineFold::XS;

use strict;
use warnings;
use 5.16.0;

our $VERSION = '0.004';

use Exporter 'import';
our @EXPORT_OK = qw( print_columns );

require XSLoader;
XSLoader::load( 'Term::Choose::LineFold::XS', $VERSION );



1;

__END__



=pod

=encoding UTF-8

=head1 NAME

Term::Choose::LineFold::XS - XS acceleration for Term-Choose-LineFold

=head1 VERSION

Version 0.004

=cut

=head1 DESCRIPTION

I<Width> in this context refers to the number of occupied columns of a character string on a terminal with a monospaced
font.

By default ambiguous width characters are treated as half width. If the environment variable
C<TC_AMBIGUOUS_WIDTH_IS_WIDE> is set to a true value, ambiguous width characters are treated as full width.

=head2 Perl version

Requires Perl version 5.16.0 or greater.

=head1 EXPORT

Nothing by default.

    use Term::Choose::LineFold::XS qw( print_columns );

=head1 FUNCTIONS

=head2 print_columns

Get the number of occupied columns of a character string on a terminal.

The string passed to this function is a decoded string, free of control characters, non-characters, and surrogates.

    $print_width = print_columns( $string );

=head1 AUTHOR

Matthäus Kiem <cuer2s@gmail.com>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2025 Matthäus Kiem.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl 5.10.0. For
details, see the full text of the licenses in the file LICENSE.

=cut
