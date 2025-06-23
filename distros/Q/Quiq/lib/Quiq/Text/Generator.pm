# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Text::Generator - Generiere Textfragmente

=head1 BASE CLASS

L<Quiq::Hash>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert einen Generator für Text-Fragmente.

=cut

# -----------------------------------------------------------------------------

package Quiq::Text::Generator;
use base qw/Quiq::Hash/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Klassenmethoden

=head3 new() - Konstuktor

=head4 Synopsis

  $t = $class->new;

=head4 Description

Instantiiere ein Objekt der Klasse und liefere eine Referenz auf
dieses Objekt zurück. Da die Klasse ausschließlich Klassenmethoden
enthält, hat das Objekt ausschließlich die Funktion, eine abkürzende
Aufrufschreibweise zu ermöglichen.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    return bless \(my $dummy),$class;
}

# -----------------------------------------------------------------------------

=head3 title() - Generiere eine unterstrichene Titelzeile

=head4 Synopsis

  $text = $t->title($title);

=head4 Arguments

=over 4

=item $title

Titelzeile

=back

=head4 Options

=over 4

=item -lineChar => $char (Default: '-')

Zeichen für die Unterstreichung

=back

=head4 Returns

(String) Unterstrichene Titelzeile

=head4 Description

Erzeuge eine unterstrichene Titelzeile und liefere das Resultat zurück.

=head4 Example

      $t->title('Geschäftsregeln');
  
  produziert
  
      Geschäftsregeln
      ---------------

=cut

# -----------------------------------------------------------------------------

sub title {
    my ($this,$title) = splice @_,0,2;

    # Optionen und Argumente

    my $lineChar = '-';

    $this->parameters(\@_,
        -lineChar => \$lineChar,
    );

    return "$title\n".($lineChar x length($title))."\n";
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.228

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2025 Frank Seitz

=head1 LICENSE

This code is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# -----------------------------------------------------------------------------

1;

# eof
