package Prty::TextFile::Line;
use base qw/Prty::Object/;

use strict;
use warnings;
use utf8;

our $VERSION = 1.120;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Prty::TextFile::Line - Zeile einer Textdatei

=head1 BASE CLASS

L<Prty::Object>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert eine Textzeile, bestehend aus
dem eigentlichen Text und einer Zeilennummer.

=head1 METHODS

=head2 Konstruktor

=head3 new() - Konstruktor

=head4 Synopsis

    $ln = $class->new($text,$number);

=head4 Description

Instantiiere Zeilenobjekt und liefere eine Referenz auf dieses Objekt
zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$text,$number) = @_;

    my $self = bless [],$class;
    $self->text($text);     # entfernt Whitespace am Ende
    $self->number($number);

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Accessors

=head3 text() - Liefere/Setze Zeilentext

=head4 Synopsis

    $text = $ln->text;
    $text = $ln->text($text);
    $text = $ln->text($text,$strip);

=head4 Description

Liefere den Zeilentext. Ist ein Argument angegeben, setze den
Zeilentext auf den Wert.
Ist $strip wahr, entferne Whitespace am Zeilenende. Dadurch
werden Zeilen, die nur aus Whitespace bestehen, zu Leerzeilen.

=cut

# -----------------------------------------------------------------------------

sub text {
    my $self = shift;
    # @_: $text,$strip

    if (@_) {
        my $text = shift;
        $text =~ s/\s+$//;
        $self->[0] = $text;
    }
    return $self->[0];
}

# -----------------------------------------------------------------------------

=head3 number() - Liefere/Setze Zeilennummer

=head4 Synopsis

    $n = $ln->number;
    $n = $ln->number($n);

=cut

# -----------------------------------------------------------------------------

sub number {
    my $self = shift;
    # @_: $n

    $self->[1] = shift if @_;
    return $self->[1];
}

# -----------------------------------------------------------------------------

=head2 Methods

=head3 append() - Füge Text zu Zeile hinzu

=head4 Synopsis

    $ln->append($text);

=head4 Description

Füge $text zu Zeile $ln hinzu. Die Methode liefert keinen Wert zurück.

=cut

# -----------------------------------------------------------------------------

sub append {
    my ($self,$text) = @_;
    $self->[0] .= $text;
    return;
}

# -----------------------------------------------------------------------------

=head3 dump() - Liefere externe Repräsentation

=head4 Synopsis

    $str = $ln->dump($format);
    $str = $ln->dump;

=head4 Description

Erzeuge eine externe Zeilenrepräsentation in Format $format
und liefere diese zurück.

B<Formate>

=over 4

=item Z<>0

Text der Zeile (Default).

=item Z<>1

Text der Zeile mit angehängtem Newline und vorangestellter
Zeilennummer im Format:

    NNNN: TEXT

=back

=cut

# -----------------------------------------------------------------------------

sub dump {
    my $self = shift;
    my $format = shift || 0;

    unless ($format) {
        return $self->[0]."\n";
    }
    elsif ($format == 1) {
        return sprintf "%4d: %s\n",$self->[1],$self->[0];
    }

    $self->throw(q{LINE-00001: Ungültiges Ausgabeformat},
        Format=>$format,
    );
}

# -----------------------------------------------------------------------------

=head3 isEmpty() - Test auf Leerzeile

=head4 Synopsis

    $bool = $ln->isEmpty;

=head4 Description

Liefere "wahr", wenn Zeile eine Leerzeile ist, andernfalls "falsch".

=cut

# -----------------------------------------------------------------------------

sub isEmpty {
    return CORE::length shift->[0]? 0: 1;
}

# -----------------------------------------------------------------------------

=head3 indentation() - Liefere Einrücktiefe der Zeile

=head4 Synopsis

    $n = $ln->indentation;

=head4 Description

Liefere die Tiefe der Einrückung. Die Einrücktiefe ist die Anzahl
an Whitespacezeichen am Anfang der Zeile.

=cut

# -----------------------------------------------------------------------------

sub indentation {
    my $self = shift;
    $self->[0] =~ /^(\s*)/;
    return CORE::length $1;
}

# -----------------------------------------------------------------------------

=head3 length() - Liefere Zeilenlänge

=head4 Synopsis

    $n = $ln->length;

=head4 Description

Liefere die Länge der Zeile.

=cut

# -----------------------------------------------------------------------------

sub length {
    return CORE::length shift->[0];
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.120

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2017 Frank Seitz

=head1 LICENSE

This code is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# -----------------------------------------------------------------------------

1;

# eof
