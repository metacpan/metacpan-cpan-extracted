# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Xml - Einfache XML-Operationen

=cut

# -----------------------------------------------------------------------------

package Quiq::Xml;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.222';

use XML::Twig ();

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 print() - Formatiere XML

=head3 Synopsis

  $xmlFormatted = $this->print($xml);

=head3 Returns

XML als formatierte Zeichenkette

=head3 Description

Liefere XML-Code $xml als formtierte Zeichenkette mit Einrückung.

=head3 Example

  say Quiq::Xml->print($xml);

=cut

# -----------------------------------------------------------------------------

sub print {
    my ($this,$xml) = @_;

    my $twg = XML::Twig->new(pretty_print=>'indented');
    $twg->parsestring($xml);

    return $twg->sprint;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.222

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2024 Frank Seitz

=head1 LICENSE

This code is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# -----------------------------------------------------------------------------

1;

# eof
