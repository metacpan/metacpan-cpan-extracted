package Prty::MediaWiki::Markup;
use base qw/Prty::Hash/;

use strict;
use warnings;
use v5.10.0;
use utf8;

our $VERSION = 1.125;

use Prty::Unindent;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Prty::MediaWiki::Markup - MediaWiki Code Generator

=head1 BASE CLASS

L<Prty::Hash>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert einen Generator für das
MediaWiki-Markup. Die Methoden der Klasse erzeugen den
Markup-Code, ohne dass man sich um die Details der Syntax kümmern
muss. Die Implementierung ist nicht vollständig, sondern wird
nach Bedarf erweitert.

=head2 Links

=over 2

=item *

MediaWiki-Homepage: L<https://m.mediawiki.org>

=item *

Als Grundlage für die Implementierung dieser Klasse diente die
Dokumentation der Wiki-Syntax:
L<https://m.mediawiki.org/wiki/Help:Formatting/en>

=item *

Globale Community Site für Wikimedia-Projekte:
L<https://meta.wikimedia.org/wiki/Help:Comment_tags>

=item *

Das lokale MediaWiki ist erreichbar unter:
L<http://localhost/mediawiki/> (anmelden als
Benutzer fs, ggf. apache2ctl start)

=back

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere MediaWiki Markup-Generator

=head4 Synopsis

    $gen = $class->new;

=head4 Description

Instantiiere einen MediaWiki Markup Generator und liefere
eine Referenz auf dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: @keyVal

    my $self = $class->SUPER::new(
        # z.Zt. keine Attribute
    );
    $self->set(@_);

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Blöcke

Der Code von Blöcken wird mit einer Leerzeile am Ende erzeugt, so
dass alle Blöcke einfach konkateniert werden können.

=head3 code() - Erzeuge Code-Abschnitt

=head4 Synopsis

    $code = $gen->code($text);
    $code = $gen->code($text,$withFormatting);

=head4 Arguments

=over 4

=item $text

Der Text des Code-Blocks

=item $withFormatting

Wenn wahr, sind Inline-Formatierungen bold und italic möglich.

=back

=head4 Returns

Markup-Code (String)

=head4 Description

Erzeuge den MediaWiki Markup-Code für einen Code-Block mit dem
Text $text und liefere diesen zurück. Ist $text undef oder ein
Leerstring, wird ein Leerstring geliefert. Andernfalls wird $text
per trim() von einer etwaigen Einrückung befreit, bevor er um
zwei Leerzeichen eingerückt wird.

=head4 See Also

Quelle: L<https://www.mediawiki.org/wiki/Help:Formatting>

=head4 Examples

=over 2

=item *

Text:

    $gen->code("Dies ist\nein Test.");

erzeugt

    |  <nowiki>Dies ist
    |  ein Test.</nowiki>

=item *

Eine Einrückung der Quelle wird automatisch entfernt:

    $gen->code(q~
        Dies ist
        ein Test.
    ~);

erzeugt

    |  <nowiki>Dies ist
    |  ein Test.

=back

=cut

# -----------------------------------------------------------------------------

sub code {
    my ($self,$text,$withFormatting) = @_;

    $text = Prty::Unindent->trim($text);
    if ($text ne '') {
        if (!$withFormatting) {
            $text = "<nowiki>$text</nowiki>";
        }
        $text =~ s/^/  /mg;
        $text .= "\n\n";
    }

    return $text;
}

# -----------------------------------------------------------------------------

=head3 comment() - Erzeuge Kommentar

=head4 Synopsis

    $code = $gen->comment($text);

=head4 Arguments

=over 4

=item $text

Der Text des Kommentars

=back

=head4 Returns

Markup-Code (String)

=head4 Description

Erzeuge den MediaWiki Markup-Code für einen Kommentar mit dem
Text $text und liefere diesen zurück. Ist $text undef oder ein
Leerstring, wird ein Leerstring geliefert. Andernfalls wird $text
per trim() von einer etwaigen Einrückung befreit.

Ist der Kommentar einzeilig, wird die Kommentar-Klammer auf die
gleiche Zeile gesetzt:

    <!-- TEXT -->

Ist der Kommentar mehrzeilig, wird die Kommentar-Klammer auf
separate Zeilen gesetzt und der Text um zwei Leerzeichen
eingerückt:

    <!--
      TEXT
    -->

=head4 See Also

Quelle: L<https://www.mediawiki.org/wiki/Help:Formatting>

=head4 Examples

=over 2

=item *

Einzeiliger Kommentar:

    $gen->comment('Dies ist ein Kommentar');

erzeugt

    <!-- Dies ist ein Kommentar -->

=item *

Mehrzeiliger Kommentar:

    $gen->comment(q~
        Dies ist
        ein Kommentar
    ~);

erzeugt

    <!--
      Dies ist
      ein Kommentar
    -->

=back

=cut

# -----------------------------------------------------------------------------

sub comment {
    my ($self,$text) = @_;

    my $code = Prty::Unindent->trim($text);
    if ($code ne '') {
        if ($code =~ tr/\n//) {
            # Mehrzeiliger Kommentar
            
            $code =~ s/^/  /mg;
            $code = "<!--\n$code\n-->\n";
        }
        else {
            # Einzeilige Kommentar
            $code = "<!-- $code -->\n";
        }
        $code .= "\n";
    }

    return $code;
}

# -----------------------------------------------------------------------------

=head3 horizontalRule() - Erzeuge horizontale Trennline

=head4 Synopsis

    $code = $gen->horizontalRule;

=head4 Returns

Markup-Code (String)

=head4 Description

Erzeuge den MediaWiki Markup-Code für eine horizontale Trennline
und liefere diesen zurück.

=head4 See Also

Quelle: L<https://www.mediawiki.org/wiki/Help:Formatting>

=head4 Example

    $gen->horizontalRule;

erzeugt

    ----

=cut

# -----------------------------------------------------------------------------

sub horizontalRule {
    my $self = shift;
    return "----\n\n";
}

# -----------------------------------------------------------------------------

=head3 list() - Erzeuge Liste

=head4 Synopsis

    $code = $gen->list($type,\@items);

=head4 Arguments

=over 4

=item $type

Typ der Liste. Mögliche Werte:

=over 4

=item *

Punktliste.

=item #

Numerierungsliste.

=item ;

Definitionsliste.

=back

=item @items

Liste der List-Items. Im Falle einer Definitionsliste ist dies
eine Liste von Schlüssel/Wert-Paaren. In allen anderen Fällen ist
es eine Liste von skalaren Werten.

=back

=head4 Returns

Markup-Code (String)

=head4 Description

Erzeuge den MediaWiki Markup-Code für eine Liste des Typs $type
mit den Elementen @items und liefere diesen zurück.

=head4 See Also

=over 2

=item *

L<https://www.mediawiki.org/wiki/Help:Formatting>

=item *

L<https://www.mediawiki.org/wiki/Help:Lists>

=back

=head4 Examples

=over 2

=item *

Punktliste

    $gen->list('*',['Apfel','Birne','Pflaume']);

produziert

    * Apfel
    * Birne
    * Pflaume

=item *

Nummerierungsliste

    $gen->list('#',['Apfel','Birne','Pflaume']);

produziert

    # Apfel
    # Birne
    # Pflaume

=item *

Definitionsliste

    $gen->list(';',[A=>'Apfel',B=>'Birne',C=>'Pflaume']);

produziert

    ; A : Apfel
    ; B : Birne
    ; C : Pflaume

=back

=cut

# -----------------------------------------------------------------------------

sub list {
    my ($self,$type,$itemA) = @_;

    my $code = '';
    for (my $i = 0; $i < @$itemA; $i++) {
        my $key;
        if ($type eq ';') {
            $key = $itemA->[$i++];
        }
        my $val = $itemA->[$i];

        $code .= $type.' ';
        if ($key) {
            $code .= $key.' : ';
        }
        
        # Etwaige Einrückung entfernen
        $val = Prty::Unindent->trim($val);
        
        $val =~ s/\n+/ /g;
        $code .= $val."\n";
    }

    return $code."\n";
}

# -----------------------------------------------------------------------------

=head3 paragraph() - Erzeuge Paragraph

=head4 Synopsis

    $code = $gen->paragraph($text);

=head4 Arguments

=over 4

=item $text

Der Text des Paragraphen

=back

=head4 Returns

Markup-Code (String)

=head4 Description

Erzeuge den MediaWiki Markup-Code für einen Paragraphen mit dem
Text $text und liefere diesen zurück. Ist $text undef oder ein
Leerstring, wird ein Leerstring geliefert. Andernfalls wird $text
per trim() von einer etwaigen Einrückung befreit.

=head4 See Also

Quelle: L<https://www.mediawiki.org/wiki/Help:Formatting>

=head4 Examples

=over 2

=item *

Text:

    $gen->paragraph("Dies ist\nein Test.");

erzeugt

    Dies ist
    ein Test.

=item *

Eine Einrückung wird automatisch entfernt:

    $gen->paragraph(q~
        Dies ist
        ein Test.
    ~);

erzeugt

    Dies ist
    ein Test.

=back

=cut

# -----------------------------------------------------------------------------

sub paragraph {
    my ($self,$text) = @_;

    $text = Prty::Unindent->trim($text);
    if ($text ne '') {
        $text .= "\n\n";
    }

    return $text;
}

# -----------------------------------------------------------------------------

=head3 section() - Erzeuge Abschnittsüberschrift

=head4 Synopsis

    $code = $gen->section($level,$title);

=head4 Arguments

=over 4

=item $level

Die Nummer der Abschnittsebene. Wertebereich: 1-6.

=item $title

Der Abschnitts-Titel.

=back

=head4 Returns

Markup-Code (String)

=head4 Description

Erzeuge den MediaWiki Markup-Code für einen Abschnitt der Tiefe
$level und der Abschnittsüberschrift $title und liefere diesen
zurück.

=head4 See Also

Quelle: L<https://www.mediawiki.org/wiki/Help:Formatting>

=head4 Example

    $gen->section(3,'Eine Überschrift');

produziert

    === Eine Überschrift ===

=cut

# -----------------------------------------------------------------------------

sub section {
    my ($self,$level,$title,$body) = @_;

    my $eqSigns = '=' x $level;
    return sprintf "%s %s %s\n\n",$eqSigns,$title,$eqSigns;
}

# -----------------------------------------------------------------------------

=head3 tableOfContents() - Setze oder unterdrücke Inhaltsverzeichnis

=head4 Synopsis

    $code = $gen->tableOfContents($bool);

=head4 Arguments

=over 4

=item $bool

Wenn wahr, wird an der aktuellen Position das Inhaltsverzeichnis
der Seite gesetzt. Wenn falsch, wird kein Inhaltsverzeichnis für
die Seite gesetzt, auch nicht automatisch.

=back

=head4 Returns

Markup-Code (String)

=head4 Description

Erzeuge den MediaWiki Markup-Code für das Setzen oder Unterdrücken
des Inhaltsverzeichnisses und liefere diesen zurück.

=head4 See Also

Quelle: L<https://www.mediawiki.org/wiki/Manual:Table_of_contents>

=head4 Examples

=over 2

=item *

Inhaltsverzeichnis setzen

    $gen->tableOfContents(1);

erzeugt

    __TOC__

=item *

Inhaltsverzeichnis unterdrücken

    $gen->tableOfContents(0);

erzeugt

    __NOTOC__

=back

=cut

# -----------------------------------------------------------------------------

sub tableOfContents {
    my ($self,$bool) = @_;
    return ($bool? '__TOC__': '__NOTOC__')."\n\n";
}

# -----------------------------------------------------------------------------

=head2 Segmente

=head3 fmt() - Inline-Formatierung

=head4 Synopsis

    $str = $gen->fmt($type,$text);

=head4 Description

Erzeuge Inline-Segment für Text $text und liefere den
resultierenden Wiki-Code zurück. Ist $text undef oder ein
Leerstring, wird ein Leerstring geliefert. Andernfalls wird $text
per trim() von einer etwaigen Einrückung befreit und einzeilig
gemacht, d.h. Zeilenumbrüche in $text werden entfernt.

Es existieren die Formatierungen:

=over 4

=item comment

Der Text wird als einzeiliger Kommentar gesetzt. Erzeugt:

    <!-- TEXT -->

=item italic

Erzeugt:

    ''TEXT''

=item bold

Erzeugt:

    '''TEXT'''

=item boldItalic

Erzeugt:

    '''''TEXT'''''

=item code

Der Text wird nicht interpretiert. Erzeugt:

    <code><nowiki>TEXT</nowiki></code>

=item codeWithFormatting

Inline-Formatierungen wie bold und italic sind möglich. Erzeugt:

    <code>TEXT</code>

=item nowiki

Erzeugt:

    <nowiki>TEXT</nowiki>

=back

=head4 See Also

Quelle: L<https://www.mediawiki.org/wiki/Help:Formatting>

=cut

# -----------------------------------------------------------------------------

sub fmt {
    my ($self,$type,$text) = @_;

    my $code = Prty::Unindent->trim($text);
    if ($code ne '') {
        # Text einzeilig machen
        $code =~ s/\n+/ /g;

        if ($type eq 'comment') {
            $code = "<!-- $code -->";
        }
        elsif ($type eq 'italic') {
            $code = "''$code''";
        }
        elsif ($type eq 'bold') {
            $code = "'''$code'''";
        }
        elsif ($type eq 'boldItalic') {
            $code = "'''''$code'''''";
        }
        elsif ($type eq 'code') {
            $code = "<code><nowiki>$code</nowiki></code>";
        }
        elsif ($type eq 'codeWithFormatting') {
            $code = "<code>$code</code>";
        }
        elsif ($type eq 'nowiki') {
            $code = "<nowiki>$code</nowiki>";
        }
        else {
            $self->throw(
                q~MEDIAWIKI-00001: Unknown inline format~,
                Format => $type,
            );
        }
    }

    return $code;
}

# -----------------------------------------------------------------------------

=head2 Testseite

=head3 testPage() - Erzeuge Test-Seite

=head4 Synopsis

    $code = $this->testPage;

=head4 Description

Erzeuge eine Seite mit MediaWiki-Markup. Diese Seite kann in ein
MediaWiki übertragen und dort visuell begutachtet werden.

=head4 Example

    $ perl -MPrty::MediaWiki::Markup -C -E 'print Prty::MediaWiki::Markup->testPage'

=cut

# -----------------------------------------------------------------------------

sub testPage {
    my $class = shift;

    my $gen = $class->new;

    # Kommentar-Block

    my $code .= $gen->comment(q~
      Dies ist ein Test-Dokument, das alle von der Klasse
      Prty::MediaWiki::Markup implementierten Syntaxelemente
      enthält und in ein MediaWiki-Wiki geladen werden kann.
    ~);

    # Table of contents

    $code .= $gen->tableOfContents(1);

    # Section

    $code .= $gen->section(1,'Überschrift 1');
    $code .= $gen->section(2,'Überschrift 2');
    $code .= $gen->section(3,'Überschrift 3');
    $code .= $gen->section(4,'Überschrift 4');
    $code .= $gen->section(5,'Überschrift 5');
    $code .= $gen->section(6,'Überschrift 6');

    # Paragraph

    $code .= $gen->section(1,'Paragraph, Horizontal Rule');

    $code .= $gen->paragraph(q~
        Dies ist
        ein Paragraph.
    ~);

    # Horizontal Rule

    $code .= $gen->horizontalRule;

    # Paragraph

    $code .= $gen->paragraph(q~
        Dies ist noch ein Paragraph
        unterhalb einer horizontalen
        Trennline.
    ~);

    # Listen

    $code .= $gen->section(1,'Listen');

    $code .= $gen->section(2,'Punktliste');
    $code .= $gen->list('*',['Apfel','Birne','Pflaume']);

    $code .= $gen->section(2,'Nummerierungsliste');
    $code .= $gen->list('#',['Apfel','Birne','Pflaume']);

    $code .= $gen->section(2,'Definitionsliste');
    $code .= $gen->list(';',[A=>'Apfel',B=>'Birne',C=>'Pflaume']);

    # Code

    $code .= $gen->section(1,'Code');

    $code .= $gen->section(2,'Ohne Inline-Formatierung');

    $code .= $gen->code(q~
        sub maxFilename {
            my ($class,$dir) = @_;
 
            my $max;
            my $dh = Prty::DirHandle->new($dir);
            while (my $file = $dh->next) {
               if ($file eq '.' || $file eq '..') {
                    next;
                }
                if (!defined($max) || $file gt $max) {
                    $max = $file;
                }
            }
            $dh->close;
         
            return $max;
        }
    ~);

    $code .= $gen->section(2,'Mit Inline-Formatierung');

    $code .= $gen->code(q~
        sub '''maxFilename''' {
            '''my''' ($''class'',$''dir'') = @_;
 
            '''my''' $''max'';
            '''my''' $''dh'' = '''Prty::DirHandle'''->'''new'''($''dir'');
            while ('''my''' $''file'' = $''dh''->'''next''') {
               if ($''file'' '''eq''' '.' || $''file'' '''eq''' '..') {
                    '''next''';
                }
                if (!'''defined'''($''max'') || $''file'' '''gt''' $''max'') {
                    $''max'' = $''file'';
                }
            }
            $''dh''->'''close''';
         
            '''return''' $''max'';
        }
    ~,1);

    # Segmente

    $code .= $gen->section(1,'Segmente');

    $code .= 'italic: '.$gen->fmt('italic','Kursive Schrift')."\n\n";
    $code .= 'bold: '.$gen->fmt('bold','Fette Schrift')."\n\n";
    $code .= 'boldItalic: '.
        $gen->fmt('boldItalic','Fette und kursive Schrift')."\n\n";

    $code .= 'code: '.
        $gen->fmt('code',q~Keine '''Interpretation''' <code>$x</code>~).
        "\n\n";
    $code .= 'codeWithFormatting: '.
        $gen->fmt('codeWithFormatting',q|$''x'' = $''img''->xPos();|).
        "\n\n";
    $code .= 'nowiki: '.
        $gen->fmt('nowiki',q~Keine '''Interpretation''' <code>$x</code>~).
        "\n\n";

    $code .= 'geschachtelt: '.
        $gen->fmt('italic','Kursive und '.
            $gen->fmt('bold','fette').' Schrift'
        )."\n\n";

    # Kommentar-Segment

    $code .= $gen->fmt('comment','eof');
    $code .= "\n";

    return $code;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.125

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2018 Frank Seitz

=head1 LICENSE

This code is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# -----------------------------------------------------------------------------

1;

# eof
