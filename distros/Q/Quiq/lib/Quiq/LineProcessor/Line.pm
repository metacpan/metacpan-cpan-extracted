package Quiq::LineProcessor::Line;
use base qw/Quiq::Object/;

use strict;
use warnings;
use v5.10.0;
use utf8;

our $VERSION = '1.147';

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::LineProcessor::Line - Zeile einer Datei

=head1 BASE CLASS

L<Quiq::Object>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert eine Zeile, bestehend aus
dem Zeileninhalt (Text) und einer Zeilennummer.

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Zeilen-Objekt

=head4 Synopsis

    $ln = $class->new($text,$number,\$input);

=head4 Description

Instantiiere Zeilenobjekt und liefere eine Referenz auf dieses
Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$text,$number,$inputR) = @_;

    # Sicherheitstest für Übergangsphase nach Einführung des Parameters

    if (!$inputR || !ref $inputR) {
        $class->throw(
            'LINE-00002: Illegal path',
            Path => !defined($inputR)? 'undef': $inputR,
            Text => $text,
            Line => $number,
        );
    }

    my $self = bless [],$class;
    $self->text($text);     # entfernt Whitespace am Ende
    $self->number($number);
    $self->inputR($inputR);

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Akzessoren

=head3 text() - Liefere/Setze Zeilentext

=head4 Synopsis

    $text = $ln->text;
    $text = $ln->text($text);
    $text = $ln->text($text,$strip);

=head4 Description

Liefere den Zeilentext. Ist ein Argument angegeben, setze den
Zeilentext auf den Wert.  Ist $strip wahr, entferne Whitespace am
Zeilenende. Dadurch werden Zeilen, die nur aus Whitespace
bestehen, zu Leerzeilen.

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

=head3 textNl() - Liefere Zeilentext mit Newline

=head4 Synopsis

    $text = $ln->textNl;

=head4 Description

Liefere den Zeilentext mit einem angehängten Newline.

=cut

# -----------------------------------------------------------------------------

sub textNl {
    my $self = shift;
    return $self->[0]."\n";
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

=head3 inputR() - Liefere/Setze Referenz auf Input-Bezeichnung

=head4 Synopsis

    $inputR = $ln->inputR;
    $inputR = $ln->inputR(\$input);

=head4 Description

Liefere/Setze eine Referenz auf die Input-Bezeichung.

=cut

# -----------------------------------------------------------------------------

sub inputR {
    my $self = shift;
    # @_: $inputR

    if (@_) {
        $self->[2] = shift;
    }

    return $self->[2];
}

# -----------------------------------------------------------------------------

=head3 input() - Liefere die Input-Bezeichnung

=head4 Synopsis

    $input = $ln->input;

=cut

# -----------------------------------------------------------------------------

sub input {
    my $self = shift;
    return ${$self->[2]};
}

# -----------------------------------------------------------------------------

=head2 Eigenschaften

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

=head2 Operationen

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

=head3 trim() - Entferne Whitespace am Anfang und Ende

=head4 Synopsis

    $ln->trim;

=head4 Description

Entferne Whitespace am Anfang und am Ende der Zeile. Die Methode
liefert keinen Wert zurück.

=cut

# -----------------------------------------------------------------------------

sub trim {
    my $self = shift;
    $self->[0] =~ s/^\s+//;
    $self->[0] =~ s/\s+$//;
    return;
}

# -----------------------------------------------------------------------------

=head3 unindent() - Entferne Einrückung

=head4 Synopsis

    $ln->unindent($n);

=head4 Description

Entferne die ersten $n Zeichen von der Zeile. Die Methode liefert
keinen Wert zurück.

=cut

# -----------------------------------------------------------------------------

sub unindent {
    my ($self,$n) = @_;
    $self->[0] = substr $self->[0],$n;
    return;
}

# -----------------------------------------------------------------------------

=head2 Externe Repräsentation

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

Text der Zeile plus Newline (Default).

=item Z<>1

Text der Zeile plus Newline und vorangestellter
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

    $self->throw(
        'LINE-00001: Ungültiges Ausgabeformat',
        Format => $format,
    );
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.147

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2019 Frank Seitz

=head1 LICENSE

This code is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# -----------------------------------------------------------------------------

1;

# eof
