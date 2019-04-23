package Quiq::Sdoc::Line;
use base qw/Quiq::LineProcessor::Line/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = 1.138;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Sdoc::Line - Zeile einer Sdoc-Quelldatei

=head1 BASE CLASS

L<Quiq::LineProcessor::Line>

=head1 METHODS

=head2 Methods

=head3 type() - Ermittele Zeilentyp

=head4 Synopsis

    ($type,$depth) = $line->type;

=head4 Description

Ermittele den Zeilentyp und liefefere diesen zurück.

=cut

# -----------------------------------------------------------------------------

sub type {
    my $self = shift;

    my $text = $self->text;

    # Generalisierte Spezifikation %OBJECT: ...
    # Der genaue Typ wird vom Aufrufer bestimmt

    return 'Object' if $text =~
        /^%(Document|TableOfContents|Box|Figure|Table|Include|Link):/;
    return 'Object' if $text =~ /^\s*%Code:/;

    # Seitenumbruch
    return 'PageBreak' if $text =~ /^~~~+/;

    # Item einer Liste, wie in $line->item() definiert.
    return 'Item' if $self->item;

    # Ein Sektionstitel beginnt mit einem oder mehreren =, optional
    # gefolgt von +, gefolgt einem Leerzeichen
    # + -> Appendix
    # ! -> Unterabschnitte nicht ins Inhaltsverzeichnis
    return 'Section' if $text =~ /^=+[!+v]* /;

    # Ein Sektionstitel beginnt mit einem oder mehreren =, optional
    # gefolgt von +, gefolgt einem Leerzeichen
    return 'BridgeHead' if $text =~ /^=+[?]? /;

    # Ein Zitatabschnitt beginnt mit einem >,
    # optional gefolgt von Leerzeichen
    return 'Quote' if $text =~ /^>\s+/;

    # Abschnitte mit |...=>...| sind KeyValue-Tabellen
    return 'KeyValRow' if $self->isKeyValRow;

    # Abschnitte mit |...| sind Tabellenzeilen
    return 'Row' if $self->isRow;

    # Abschnitte mit | am Anfang und solche, die eingerückt sind, ohne
    # dass eine andere Regel zutrifft, sind Code-Abschnitte.
    return 'Code' if $text =~ /(^\|\s+|^\s+|^\s*<<Code$)/;

    # Alle nicht-eingerückten Abschnitte, auf die keine andere
    # Regel zutrifft, sind Paragraphen.
    return 'Paragraph';
}

# -----------------------------------------------------------------------------

=head3 isRow() - Test auf Tabellenzeile

=head4 Synopsis

    $bool = $line->isRow;

=head4 Description

Prüfe, ob die Zeile eine Tabellenzeile ist. Wenn ja, liefere wahr,
ansonsten falsch.

=cut

# -----------------------------------------------------------------------------

sub isRow {
    return shift->text =~ /^\s*\|.*\|$/;
}

# -----------------------------------------------------------------------------

=head3 isKeyValRow() - Test auf Schlssel/Wert-Zeile

=head4 Synopsis

    $bool = $line->isKeyValRow;

=head4 Description

Prüfe, ob die Zeile eine Schlssel/Wert-Zeile ist. Wenn ja, liefere
wahr, ansonsten falsch.

=cut

# -----------------------------------------------------------------------------

sub isKeyValRow {
    return shift->text =~ /^\s*\|[^|]*=>[^|]*\|$/;
}

# -----------------------------------------------------------------------------

=head3 item() - Test auf List-Item

=head4 Synopsis

    ($itemType,$label,$indentation,$text) = $ln->item;
    ($itemType,$label,$indentation,$text) = $ln->item($nextLine);

=head4 Description

Anlysiere die Zeile darauf hin, ob diese ein List-Item
beschreibt, ihr Text also einem der folgenden Muster entspricht:

    o Text        (Punktliste)
    * Text        (Punktliste)
    + Text        (Punktliste)
    
    1. Text       (nummerierte Liste)
    1) Text       (nummerierte Liste)
    
    [Text]: Text  (Beschreibungsliste)
    [Text:] Text  (Beschreibungsliste)
    <Text>: Text  (Beschreibungsliste)
    <Text:> Text  (Beschreibungsliste)
    {Text}: Text  (Beschreibungsliste)
    {Text:} Text  (Beschreibungsliste)
    :Text: Text   (Beschreibungsliste)
    :Text:: Text  (Beschreibungsliste)

Ist dies nicht der Fall, liefert die Methode eine leere Liste
zurück. Ist dies der Fall liefert die Methode vier Werte zurück:

=over 4

=item $itemType

Typ des Labels. Fünf Itemtypen werden unterschieden:

    o, *, + (Punktliste)
    #       (numerierte Liste)
    []      (Beschreibungsliste)

=item $label

Im Falle einer Punktliste das Symbol, im Falle einer numerierten Liste
die Zahl (ohne Punkt oder Klammer), im Falle einer Beschreibungsliste
der Labeltext.

=item $indentation

Die Einrückung des Listenelements. Alle Folgezeilen mit
(mindestens) dieser Einrückung werden als zugehörig zum
Listenelement angesehen.  Diese Einrückung ist die Anzahl an
Zeichen bis zum ersten Buchstaben des Textes. Es wird davon
ausgegangen, dass die weiteren Zeilen genauso eingerückt
sind. Ausnahme: Beschreibungsliste. Da der Labeltext hier
schwankt, wird die Einrückung der nächsten Zeile genommen,
sofern es sich nicht um eine Leerzeile oder das nächste Item
handelt.  Wird diese Angabe benötigt, muss der Parameter
$nextLine angegeben sein.  Andernfalls wird der initale
Whitespace plus vier Zeichen angenommen.

    |  o Text Text Text Text Text
    |    Text Text Text Text Text
    |    Text Text Text Text Text
     ----
         ^ Textbeginn der ersten Zeile
    
    |  1) Text Text Text Text Text
    |     Text Text Text Text Text
    |     Text Text Text Text Text
    | ...
    | 10) Text Text Text Text Text
    |     Text Text Text Text Text
     -----
          ^ Textbeginn der ersten Zeile
    
    |  [Text]: Text Text Text Text Text
    |      Text Text Text Text Text
    |      Text Text Text Text Text
    
    |  [Text:] Text Text Text Text Text
    |      Text Text Text Text Text
    |      Text Text Text Text Text
    
    |  :Text: Text Text Text Text Text
    |      Text Text Text Text Text
    |      Text Text Text Text Text
    
    |  :Text:: Text Text Text Text Text
    |      Text Text Text Text Text
    |      Text Text Text Text Text
    
     ------
           ^ initialer Whitespce der Folgezeile -oder-
             initialer Whitespace plus vier Zeichen

=item $text

Die erste Zeile des Listenelements, bei dem das Label durch Whitespace
ersetzt ist.

    |    Text Text Text Text Text
     ----
       ^ Textbeginn der ersten Zeile
    
    |     Text Text Text Text Text
     -----
       ^ Textbeginn der ersten Zeile
    
    |      Text Text Text Text Text
     ------
        ^ initialer Whitespace der Folgezeile -oder-
          der ersten Zeile plus vier Zeichen

=back

=cut

# -----------------------------------------------------------------------------

sub item {
    my $self = shift;
    my $nextLine = shift;

    my $text = $self->text;

    my ($type,$label,$indent);
    if ($text =~ /^(([o*+])\s+)/) {
        $type = $label = $2;
        $indent = length $1;
        $text = (' ' x $indent).substr $text,$indent;
    }
    elsif ($text =~ /^((\d+)([.)])\s+)/) {
        $type = '#';
        $label = "$2$3";
        $indent = length $1;        
        $text = (' ' x $indent).substr $text,$indent;
    }
    elsif ($text =~ /^([\[<{](.*?)[\]>}]:\s*)/ || # [...]: {...}: <...>:
        $text =~ /^([\[<{](.*?:)[\]>}]\s*)/ ||    # [...:] {...:} <...:>
        $text =~ /^(:(.*?:?):\s*)/)               # :...: :...::
    {
        $type = '[]';
        $label = $2;
        my $width = length($1);
        $indent = 2;
        # FIXME: Test verbessern
        if ($nextLine && !$nextLine->isEmpty &&
            $nextLine->text !~ /^([\[<{](.*?)[\]>}]:\s*)/ &&
            $nextLine->text !~ /^([\[<{](.*?:)[\]>}]\s*)/ &&
            $nextLine->text !~ /^(:(.*?:?):\s*)/)
        {
            $nextLine->text =~ /^(\s+)/;
            $indent = length($1);
        }
        $text = (' 'x$indent).substr $text,$width;
    }

    return $type? ($type,$label,$indent,$text): ();    
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.138

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
