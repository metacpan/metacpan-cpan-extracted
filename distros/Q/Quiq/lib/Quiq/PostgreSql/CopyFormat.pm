# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::PostgreSql::CopyFormat - Erzeuge Daten für PostgreSQL COPY-Kommando

=head1 BASE CLASS

L<Quiq::Hash>

=head1 SYNOPSIS

  use Quiq::PostgreSql::CopyFormat;
  
  # Instantiiere Objekt
  my $cpy = Quiq::PostgreSql::CopyFormat->new($width);
  
  # Übersetze Array in COPY-Zeile
  my $line = $cpy->arrayToLine(\@arr);

=head1 DESCRIPTION

Die Klasse dient zur Umwandlung von Daten, so dass sie vom
PostgreSQL COPY-Kommando verarbeitet werden können.

=head1 ATTRIBUTES

=over 4

=item width => $n

Anzahl der Kolumnen pro Zeile.

=back

=cut

# -----------------------------------------------------------------------------

package Quiq::PostgreSql::CopyFormat;
use base qw/Quiq::Hash/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Klassenmethoden

=head3 new() - Konstruktor

=head4 Synopsis

  $cpy = $class->new($width);

=head4 Arguments

=over 4

=item $width

Anahl der Kolumnen pro Zeile.

=back

=head4 Returns

Objekt

=head4 Description

Instantiiere ein Objekt der Klasse für die Behandlung von Daten mit
$width Kolumnen und liefere eine Referenz auf dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$width) = @_;

    return $class->SUPER::new(
        width => $width,
    );
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 arrayToLine() - Übersetze Array in eine COPY-Zeile

=head4 Synopsis

  $line = $cpy->arrayToLine(\@arr);

=head4 Arguments

=over 4

=item \@arr

Array mit $width Komponenten.

=back

=head4 Returns

Zeile für eine COPY-Datei (String)

=head4 Description

Erzeuge aus den Komponenten des Arrays @arr eine Datenzeile für
das PostgreSQL COPY Kommando.

=cut

# -----------------------------------------------------------------------------

sub arrayToLine {
    my ($self,$arr) = @_;

    if (@$arr != $self->{'width'}) {
        $self->throw(
            'PG-00001: Wrong array length',
            ArrayLength => scalar @$arr,
            ExpectedLength => $self->{'width'},
        );
    }

    my $str = '';
    for (@$arr) {
        my $val = $_; # Wert kopieren
        $val =~ s/\t/\\t/g;
        $val =~ s/\n/\\n/g;
        if ($str) {
            $str .= "\t";
        }
        $str .= $val;
    }

    return $str;
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
