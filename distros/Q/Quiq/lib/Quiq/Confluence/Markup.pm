package Quiq::Confluence::Markup;
use base qw/Quiq::Hash/;

use strict;
use warnings;
use v5.10.0;
use utf8;

our $VERSION = '1.148';

use Quiq::Unindent;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Confluence::Markup - Confluence-Wiki Markup

=head1 BASE CLASS

L<Quiq::Hash>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert einen Generator für das
Wiki-Markup von Confluence. Die Methoden der Klasse erzeugen
dieses Markup, ohne dass man sich um die Details der Syntax
kümmern muss.

Als Grundlage für die Implementierung dient die
Confluence-Dokumentation:

=over 2

=item *

L<Allgemeine Syntax|https://confluence.atlassian.com/doc/confluence-wiki-markup-251003035.html>

=item *

L<Macros|https://confluence.atlassian.com/doc/macros-139387.html>

=back

Die Implementierung ist nicht vollständig, sondern wird nach Bedarf
erweitert.

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Markup-Generator

=head4 Synopsis

    $gen = $class->new;

=head4 Description

Instantiiere einen Confluence Wiki-Markup Generator und liefere
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

=head2 Allgemeine Syntax

=head3 section() - Abschnitt

=head4 Synopsis

    $markup = $gen->section($level,$title);
    $markup = $gen->section($level,$title,$body);

=head4 Alias

heading()

=head4 Description

Confluence-Doku: L<Heading|https://confluence.atlassian.com/doc/confluence-wiki-markup-251003035.html#ConfluenceWikiMarkup-Headings>

Erzeuge einen Abschnitt der Ebene $level mit dem Titel $title und
dem (optionalen) Abschnitts-Körper $body und liefere den
resultierenden Code zurück. Ist $body nicht angegeben oder ein
Leerstring, wird nur der Titel erzeugt. Andernfalls wird $body per
trim() von einer etwaigen Einrückung befreit.

=head4 Examples

=over 2

=item *

Ohne Body:

    $gen->section(1,'Test');

erzeugt

    h1. Test

=item *

Mit Body:

    $gen->section(1,'Test',"Dies ist ein Test.");

erzeugt

    h1. Test
    
    Dies ist ein Test.

=item *

Eine Einrückung wird automatisch entfernt:

    $gen->section(1,'Test',q~
        Dies ist ein Test.
    ~);

erzeugt

    h1. Test
    
    Dies ist ein Test.

=back

=cut

# -----------------------------------------------------------------------------

sub section {
    my ($self,$level,$title,$body) = @_;

    my $markup = "h$level. $title\n\n";
    if (defined $body) {
        $body = Quiq::Unindent->trim($body);
        if ($body ne '') {
            $markup .= "$body\n\n";
        }
    }

    return $markup;
}

{
    no warnings 'once';
    *heading = \&section;
}

# -----------------------------------------------------------------------------

=head3 paragraph() - Paragraph

=head4 Synopsis

    $markup = $gen->paragraph($text);

=head4 Description

Erzeuge einen Paragraph und liefere den resultierenden Wiki-Code
zurück. Ist $text nicht angegeben oder ein Leerstring, wird ein
Leerstring geliefert. Andernfalls wird $text per trim() von einer
etwaigen Einrückung befreit und Zeilenumbrüche durch Leerzeichen
ersetzt, da ein Paragraph in Confluence-Wiki Syntax einzeilig ist.

=head4 Examples

=over 2

=item *

Text:

    $gen->paragraph("Dies ist\nein Test.");

erzeugt

    Dies ist ein Test.

=item *

Eine Einrückung wird automatisch entfernt:

    $gen->paragraph(q~
        Dies ist
        ein Test.
    ~);

erzeugt

    Dies ist ein Test.

=back

=cut

# -----------------------------------------------------------------------------

sub paragraph {
    my $self = shift;
    my $text = shift // '';

    $text = Quiq::Unindent->trim($text);
    $text =~ s/\n+/ /g; # Zeilenumbrüche zu Leerzeichen
    if ($text ne '') {
        $text .= "\n\n";
    }

    return $text;
}

# -----------------------------------------------------------------------------

=head2 Macros

=head3 code() - Code-Block (code)

=head4 Synopsis

    $markup = $gen->code($type,$code,@opts);

=head4 Options

=over 4

=item -collapse => $bool (Confluence-Default: 0)

Zeige den Code-Block zusammengeklappt an. Durch Betätigung eines
Link kann er aufgeklappt werden.

=item -firstLine => $n (Confluence-Default: 1)

Wenn Option C<-lineNumbers> gesetzt ist, die Nummer der ersten Zeile,
ggf. mit führenden Nullen. Z.B. C<0001>.

=item -lineNumbers => $bool (Confluence-Default: 0)

Nummeriere die Zeilen durch.

=item -theme => $theme (Confluence-Default: 'Confluence')

Das Farbschema für die Darstellungs des Code-Blocks. Mögliche
Werte siehe o.g. Confluence-Doku.

=item -title => $title (Confluence-Default: kein Titel)

Füge einen Titel zum Code-Block hinzu.

=back

=head4 Description

Confluence Doku: L<Code Block Macro|https://confluence.atlassian.com/doc/code-block-macro-139390.html>

Erzeuge ein Code-Macro für Code $code mit Syntax-Typ $type und
liefere den resultierenden Wiki-Code zurück. Die Liste der verfügbaren
Syntax-Typen findet sich in o.g. Confluence-Doku.

=head4 Examples

=over 2

=item *

Ein eingeklappter Code-Block:

    $gen->code('perl',"print 'Hello, world!';",
        -collapse => 1,
    );

erzeugt

    {code:language=perl|collapse=true}
    print 'Hello, world!';
    {code}

=back

=cut

# -----------------------------------------------------------------------------

sub code {
    my ($self,$type,$code) = splice @_,0,3;
    # @_: @opts

    my @opts = ("language=$type");
    while (@_) {
        my $key = shift;
        if ($key eq '-collapse') {
             if (shift) {
                 push @opts,'collapse=true';
             }
        }
        elsif ($key eq '-firstLine') {
             push @opts,'firstline='.shift;
        }
        elsif ($key eq '-lineNumbers') {
             push @opts,'linenumbers='.shift;
        }
        elsif ($key eq '-theme') {
             push @opts,'theme='.shift;
        }
        elsif ($key eq '-title') {
             push @opts,'title='.shift;
        }
        else {
             $self->throw(
                 'CONFLUENCE-00001: Unknown code macro option',
                 Option => $key,
             );
        }
    }

    $code =~ s/^\n+//;
    $code =~ s/\n+$//;
    if ($code) {
        $code .= "\n";
    }

    return sprintf "\{code:%s\}\n$code\{code\}\n\n",join('|',@opts);
}

# -----------------------------------------------------------------------------

=head3 noFormat() - Text-Block ohne Formatierung (noformat)

=head4 Synopsis

    $markup = $gen->noFormat($text,@opts);

=head4 Options

=over 4

=item -noPanel => $bool (Confluence-Default: 0)

Kein Panel um den Inhalt herum.

=back

=head4 Description

Confluence Doku: L<Noformat Macro|https://confluence.atlassian.com/doc/noformat-macro-139545.html>

Zeige einen Text-Block monospaced ohne weitere Formatierung an.

Anmerkung: Dieses Makro ist nicht geeignet, um eine Formatierung
innerhalb eines Paragraphen zu verhindern, da der Text als
eigenständiger Block (mit oder ohne Umrandung) dargestellt wird.
Es entspricht einem Code-Block-Makro ohne Syntax-Highlighting,
bei dem zusätzlich die Umrandung unterdrückt werden kann.

=head4 Examples

=over 2

=item *

Anzeige eines regulären Ausdrucks:

    $gen->noFormat('m|/([^/]+)xxx{5}$|',
        -noPanel => 1,
    );

erzeugt

    {noformat:nopanel=true}m|/([^/]+)xxx{5}$|{noformat}

=back

=cut

# -----------------------------------------------------------------------------

sub noFormat {
    my ($self,$text) = splice @_,0,2;
    # @_: @opts

    my @opts;
    while (@_) {
        my $key = shift;
        if ($key eq '-noPanel') {
             if (shift) {
                 push @opts,'nopanel=true';
             }
        }
        else {
             $self->throw(
                 'CONFLUENCE-00001: Unknown noformat macro option',
                 Option => $key,
             );
        }
    }

    $text =~ s/^\n+//;
    $text =~ s/\n+$//;
    if ($text =~ /\n/) {
        $text = "\n$text\n";
    }

    return sprintf "{noformat:%s}${text}{noformat}\n\n",join('|',@opts);
}

# -----------------------------------------------------------------------------

=head3 panel() - Umrandung mit optionalem Titel (panel)

=head4 Synopsis

    $markup = $gen->panel($body,@opts);

=head4 Options

=over 4

=item -title => $title (Confluence-Default: none)

Titel des Panel.

=item -borderStyle => $style (Confluence-Default: 'solid')

Stil der Umrandung. Wert: solid, dashed und andere CSS
Umrandungs-Stile.

=item -borderColor => $color

Farbe der Umrandung. Wert: wie HTML.

=item -borderWidth => $n

Breite der Umrandung in Pixeln.

=item -backgroundColor => $color.

Hintergrundfarbe. Wert: wie HTML.

=item -titleBackgroundColor => $color

Farbe Titel-Hintergrund. Wert: wie HTML.

=item -titleTextColor => $color

Farbe des Titel-Textes. Wert: wie HTML.

=back

=head4 Description

Confluence-Doku: L<Panel Macro|https://confluence.atlassian.com/doc/panel-macro-51872380.html>

Erzeuge ein Panel-Macro mit Inhalt $body und liefere den
resultierenden Wiki-Code zurück.

=cut

# -----------------------------------------------------------------------------

sub panel {
    my $self = shift;
    my $body = shift // '';
    # @_: @opts

    my @opts;
    while (@_) {
        my $key = shift;
        if ($key eq '-title') {
             push @opts,'title='.shift;
        }
        elsif ($key eq '-borderStyle') {
             push @opts,'borderStyle='.shift;
        }
        elsif ($key eq '-borderColor') {
             push @opts,'borderColor='.shift;
        }
        elsif ($key eq '-borderWidth') {
             push @opts,'borderWidth='.shift;
        }
        elsif ($key eq '-backgroundColor') {
             push @opts,'bgColor='.shift;
        }
        elsif ($key eq '-titleBGColor') {
             push @opts,'titleBGColor='.shift;
        }
        elsif ($key eq '-titleColor') {
             push @opts,'titleColor='.shift;
        }
        else {
             $self->throw(
                 'CONFLUENCE-00001: Unknown panel option',
                 Option => $key,
             );
        }
    }

    $body =~ s/^\n+//;
    $body =~ s/\n+$//;
    if ($body) {
        $body .= "\n";
    }

    return sprintf "\{panel:%s\}\n$body\{panel\}\n\n",join('|',@opts);
}

# -----------------------------------------------------------------------------

=head3 tableOfContents() - Inhaltsverzeichnis (toc)

=head4 Synopsis

    $markup = $gen->tableOfContents(@opts);

=head4 Options

=over 4

=item -type => 'list'|'flat' (Confluence-Default: 'list')

Listenartiges oder horizontales Menü.

=item -outline => $bool (Confluence-Default: 0)

Outline-Numbering ((1.1, 1.2, usw.) aus oder ein.

=item -style => $style (Confluence-Default: 'disc')

Style der Bullet-Points. Wert: Wie CSS (none, circle, disc,
square, decimal, lower-alpha, lower-roman, upper-roman).

=item -indent => $indent

Einrücktiefe zwischen den Ebenen (nur Liste). Wert: CSS-Einheit
(z.B. 10px).

=item -separator => $separator (Confluence-Default: 'brackets')

Separator bei horizontalem Inhaltsverzeichnis: Wert: brackets,
braces, parens, pipe, I<anything>.

=item -minLevel => $n (Confluence-Default: 1)

Die niedrigste Ebene, die in das Inhaltsverzeichnis aufgenommen wird.

=item -maxLevel => $n (Confluence-Default: 7)

Die höchste Ebene, die in das Inhaltsverzeichnis aufgenommen wird.

=item -include => $regex

Regulärer Ausdruck, der die Abschnittstitel matcht, die in das
Inhaltsverzweichnis aufgenommen werden.

=item -exclude => $regex

Regulärer Ausdruck, der die Abschnittstitel matcht, die I<nicht>
in das Inhaltsverzweichnis aufgenommen werden.

=item -printable => $bool (Confluence-Default: 1)

Das Inhaltsverzeichnis wird mit ausgegeben, wenn die Seite
gedruckt wird.

=item -class => $class

Inhaltsverzeichnis wird in <div class="$class">...</div> eingefasst.

=item -absoluteUrl => $bool

Verwende absolute URLs.

=back

=head4 Description

Confluence-Doku: L<Table of Contents Macro|https://confluence.atlassian.com/doc/table-of-contents-macro-182682099.html>

Erzeuge ein Inhaltsverzeichnis-Macro und liefere den
resultierenden Wiki-Code zurück.

=cut

# -----------------------------------------------------------------------------

sub tableOfContents {
    my $self = shift;
    # @_: @opts

    my @opts;
    while (@_) {
        my $key = shift;
        if ($key eq '-') {
             push @opts,'='.shift;
        }
        elsif ($key eq '-type') {
             push @opts,'type='.shift;
        }
        elsif ($key eq '-outline') {
             push @opts,'outline='.shift;
        }
        elsif ($key eq '-style') {
             push @opts,'style='.shift;
        }
        elsif ($key eq '-indent') {
             push @opts,'indent='.shift;
        }
        elsif ($key eq '-separator') {
             push @opts,'separator='.shift;
        }
        elsif ($key eq '-minLevel') {
             push @opts,'minLevel='.shift;
        }
        elsif ($key eq '-maxLevel') {
             push @opts,'maxLevel='.shift;
        }
        elsif ($key eq '-include') {
             push @opts,'include='.shift;
        }
        elsif ($key eq '-exclude') {
             push @opts,'exclude='.shift;
        }
        elsif ($key eq '-printable') {
             push @opts,'printable='.shift;
        }
        elsif ($key eq '-class') {
             push @opts,'class='.shift;
        }
        elsif ($key eq '-absoluteUrl') {
             push @opts,'absoluteUrl='.shift;
        }
        else {
             $self->throw(
                 'CONFLUENCE-00001: Unknown panel option',
                 Option => $key,
             );
        }
    }

    # FIXME: Weitere Optionen

    return sprintf "\{toc:%s\}\n\n",join '|',@opts;
}

# -----------------------------------------------------------------------------

=head2 Text-Formatierung

=head3 fmt() - Text-Formatierung

=head4 Synopsis

    $str = $this->fmt($format,$text);
    $str = $this->fmt($color,$text);

=head4 Description

Confluence-Doku: L<Text Effects|https://confluence.atlassian.com/doc/confluence-wiki-markup-251003035.html#ConfluenceWikiMarkup-TextEffects>

Erzeuge Formatierung $format für Text $text und liefere den
resultierenden Wiki-Code zurück.

Es existieren die Formatierungen:

=over 2

=item *

bold

=item *

italic

=item *

citation

=item *

deleted

=item *

inserted

=item *

superscript

=item *

subscript

=item *

monospace

=item *

blockquote

=item *

$color

=item *

protect

=back

Das Format 'protect' ist eine Erweiterung der
Confluence-Formatierungen. Es schützt die Zeichen in $text, so
dass diese formatierungsfrei dargestellt werden. Geschützt werden
die Zeichen:

    - * _ + ^ ~ [ ] { }

Die Interpretation als Metazeichen wird durch das Voranstellen
eines Backslash (\) verhindert.

=cut

# -----------------------------------------------------------------------------

sub fmt {
    my $this = shift;
    my $format = shift;
    my $text = shift // '';

    $text = Quiq::Unindent->trim($text);
    $text =~ s/\n+/ /g;

    if ($format eq 'bold') {
        $text = "*$text*";
    }
    elsif ($format eq 'italic') {
        $text = "_$text\_";
    }
    elsif ($format eq 'citation') {
        $text = "??$text??";
    }
    elsif ($format eq 'deleted') {
        $text = "-$text-";
    }
    elsif ($format eq 'inserted') {
        $text = "+$text+";
    }
    elsif ($format eq 'superscript') {
        $text = "^$text^";
    }
    elsif ($format eq 'subscript') {
        $text = "~$text~";
    }
    elsif ($format eq 'monospace') {
        $text = "{{$text}}";
    }
    elsif ($format eq 'blockquaote') {
        $text = "bq. $text";
    }
    elsif ($format eq 'protect') {
        # $text =~ s/((?<!\\)[-[\]{}*_+^~])/\\$1/g;
        # $text =~ s/([-[\]{}*_+^~])/\\$1/g;
        $text =~ s/([^ A-Za-z0-9.,])/'&#'.ord($1).';'/eg;
    }
    else {
        $text = "{color:$format}$text\{color}";
    }

    return $text;
}

# -----------------------------------------------------------------------------

=head3 lineBreak() - Zeilenumbruch

=head4 Synopsis

    $str = $gen->lineBreak;

=cut

# -----------------------------------------------------------------------------

sub lineBreak {
    my $self = shift;
    return ' \\\\ ';
}

# -----------------------------------------------------------------------------

=head2 Test

=head3 testPage() - Generiere Test-Seite

=head4 Synopsis

    $str = $this->testPage;

=head4 Description

Generiere eine Seite mit Wiki-Markup. Das Markup kann nach Confluence
übertragen und dort optisch begutachtet werden.

=head4 Examples

=over 2

=item *

Test-Seite von der Kommandozeile ins Wiki übertragen:

    $ quiq-confluence test-page | quiq-confluence update-page PAGE_ID

=item *

Manuelle Übertragung:

=over 4

=item 1.

Markup generieren:

    $ quiq-confluence test-page

=item 2.

In Confluence die Zielseite zum Editieren öffnen und Option
"Markup {}" wählen. Ausgabe aus 1. per copy-and-paste in den
Dialog übertragen und diesen speichern.

=back

=back

=cut

# -----------------------------------------------------------------------------

sub testPage {
    my $class = shift;

    my $gen = $class->new;

    my $str = $gen->heading(1,'Inhaltsverzeichnis');
    $str =~ s/\n+$/\n/;

    $str .= $gen->panel(
        $gen->tableOfContents,
    );

    for my $i (1 .. 6) {
        $str .= $gen->heading($i,"Überschrift $i");
    }

    $str .= $gen->heading(1,'Paragraph');

    $str .= $gen->paragraph(q~
        Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam
        nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam
        erat, sed diam voluptua. At vero eos et accusam et justo duo
        dolores et ea rebum. Stet clita kasd gubergren, no sea takimata
        sanctus est Lorem ipsum dolor sit amet.
    ~);

    $str .= $gen->heading(1,'Code Block');

    $str .= $gen->code('perl',"print 'Hello, world';");

    $str .= $gen->code('perl',"print 'Hello, world';",
        -title => 'Code Block',
    );

    $str .= $gen->code('perl',"print 'Hello, world';",
        -title => 'Code Block, collapse=true',
        -collapse => 1,
    );

    $str .= $gen->heading(1,'Text-Formatierung');

    for my $format (qw/bold italic citation deleted inserted superscript
            subscript monospace blockquote red green navy/) {
        $str .= sprintf "%s: %s\n\n",
            $gen->fmt('bold',$format),
            $gen->fmt($format,q~
                Lorem ipsum dolor sit amet, consetetur sadipscing elitr,
                sed diam
            ~);
    }

    $str .= $gen->paragraph(
        $gen->fmt('bold','Dies').' '.
        $gen->fmt('italic','ist').' '.
        $gen->fmt('red','ein').' '.
        $gen->fmt('green','Test').'.'
    );

    $str .= $gen->heading(1,'No Format');

    $str .= $gen->noFormat('m|/([^/]+)xxx{5}$|');

    $str .= $gen->noFormat('m|/([^/]+)xxx{5}$|',
        -noPanel => 1,
    );

    $str .= $gen->heading(1,'Protect');

    $str .= $gen->paragraph(
        'Die Zeichenkette "'.
        $gen->fmt('green',
            $gen->fmt('monospace',
                $gen->fmt('bold',
                    $gen->fmt('protect','m|/([^/]+)xxx{5}$|'),
                ),
            ),
        ).
        '" ist ein Regex.'
    );

    $str .= $gen->paragraph(
        $gen->fmt('protect','_Hallo Welt_'),
    );

    return $str;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.148

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
