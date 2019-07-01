package Quiq::MediaWiki::Markup;
use base qw/Quiq::Hash/;

use strict;
use warnings;
use v5.10.0;
use utf8;

our $VERSION = '1.148';

use Quiq::Unindent;
use Quiq::Parameters;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::MediaWiki::Markup - MediaWiki Code Generator

=head1 BASE CLASS

L<Quiq::Hash>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert einen Generator für das
MediaWiki-Markup. Die Methoden der Klasse erzeugen den
Markup-Code, ohne dass man sich um die Details der Syntax kümmern
muss. Die Implementierung ist nicht vollständig, sondern wird
nach Bedarf erweitert.

=head2 Links

=over 2

=item *

Das lokale MediaWiki ist erreichbar unter:
L<http://localhost/mediawiki/> (anmelden als
Benutzer fs, ggf. apache2ctl start)

=item *

Homepage: L<https://www.mediawiki.org/>

=item *

Handbuch: L<https://www.mediawiki.org/wiki/Help:Contents>

=item *

Markup: L<https://www.mediawiki.org/wiki/Help:Formatting>

=item *

CSS-Regeln: L<https://www.mediawiki.org/wiki/Manual:CSS>

=item *

Globale Community Site für Wikimedia-Projekte:
L<https://meta.wikimedia.org/>

=back

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Markup-Generator

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

    $code = $gen->code($text,$withFormatting);

=head4 Arguments

=over 4

=item $text

Der Text des Code-Blocks

=item $withFormatting

Wenn wahr, erlaube Formatierung im Code-Abschnitt.

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

=over 2

=item *

Syntax: L<https://www.mediawiki.org/wiki/Help:Formatting>

=back

=head4 Examples

=over 2

=item *

Text:

    $gen->code("Dies ist\nein Test.");

erzeugt

    |  Dies ist
    |  ein Test.

=item *

Eine Einrückung der Quelle wird automatisch entfernt:

    $gen->code(q~
        Dies ist
        ein Test.
    ~);

erzeugt

    |  Dies ist
    |  ein Test.

=back

=cut

# -----------------------------------------------------------------------------

sub code {
    my ($self,$text,$withFormatting) = @_;

    $text = Quiq::Unindent->trim($text);
    if ($text ne '') {
        if ($withFormatting) {
            $text =~ s/^/  /mg;
        }
        else {
            $text = "<pre>$text</pre>";
        }
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

=over 2

=item *

Syntax: L<https://www.mediawiki.org/wiki/Help:Formatting>

=back

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

    my $code = Quiq::Unindent->trim($text);
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
        # $code .= "\n";
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

=over 2

=item *

Syntax: L<https://www.mediawiki.org/wiki/Help:Formatting>

=back

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

=head3 image() - Erzeuge Bild

=head4 Synopsis

    $code = $gen->image(@keyVal);

=head4 Options

=over 4

=item align => $align

Mögliche Werte: left, right, center, none.

=item alt => $str

Alternativer Text.

=item border => $bool

Umrandung.

=item caption => $str

Bildbeschriftung.

=item file => $file

(Pflichtangabe) Name der Datei. Hier wird nur der Dateiname, bestehend
aus NAME.EXT benötigt. Ein etwaiger Pfad, sofern vorhanden, wird entfernt.
Die Datei muss zuvor ins MediaWiki hochgeladen worden sein.

=item format => $format

Mögliche Werte: frameless, frame, thumb.

=item height => $height

Höhe des Bildes.

=item link => $url

Link, mit das Bild hinterlegt wird.

=item page => $n

Seitennumer im Falle eines PDF.

=item valign => $valign

Mögliche Werte: baseline, sub, super, top, text-top, middle, bottom,
text-bottom.

=item width => $width

Breite des Bildes.

=back

=head4 Returns

Markup-Code (String)

=head4 Description

Erzeuge den MediaWiki Markup-Code für ein Bild und liefere diesen zurück.

=head4 See Also

=over 2

=item *

Syntax: L<https://www.mediawiki.org/wiki/Help:Images>

=back

=head4 Example

    $gen->image(
        file => 'Ein_testbild.png',
        width => 1200,
        height => 900,
    );

erzeugt

    [[File:Ein_testbild.png|1200x900px]]

=cut

# -----------------------------------------------------------------------------

sub image {
    my $self = shift;

    my $opt = Quiq::Parameters->extractPropertiesToObject(\@_,
        align => undef,
        alt => undef,
        border => undef,
        caption => undef,
        file => undef,
        format => undef,
        height => undef,
        link => undef,
        page => undef,
        valign => undef,
        width => undef,
    );

    push my @arr,sprintf 'File:%s',$opt->file;

    my $width = $opt->width;
    my $height = $opt->height;

    if ($width && $height) {
        push @arr,"${width}x${height}px";
    }
    elsif ($width) {
        push @arr,"${width}px";
    }
    elsif ($height) {
        push @arr,"x${height}px";
    }

    # Attribute, deren Schlüssel und Wert eingetragen wird

    for my $key (qw/alt link page/) {
        if (my $val = $opt->$key) {
            push @arr,sprintf '%s=%s',$key,$val;
        }
    }

    # Boolsche Attribute, deren Name eingetragen wird

    for my $key (qw/border/) {
        if (my $val = $opt->$key) {
            push @arr,$key;
        }
    }

    # Attribute, deren Wert eingetragen wird (caption muss am Ende stehen)

    for my $key (qw/align format valign caption/) {
        if (my $val = $opt->$key) {
            push @arr,$val;
        }
    }

    return sprintf "[[%s]]\n\n",join('|',@arr);
}

# -----------------------------------------------------------------------------

=head3 item() - Erzeuge Listenelement

=head4 Synopsis

    $code = $gen->item($type,$val);
    $code = $gen->item($type,$key,$val);

=head4 Arguments

=over 4

=item $type

Typ der Liste. Mögliche Typen einer Liste:

=over 4

=item Zeichen: *

Punktliste.

=item Zeichen: #

Nummerierungsliste.

=item Zeichen: ;

Definitionsliste.

=back

Die Typangabe kann auch aus mehreren Typangaben zusammengesetzt
sein, wie es bei geschachtelten Listen benötigt wird, z.B. "*#*".

=item $key

Definitionsterm (nur Definitionsliste).

=item $val

Wert des Elements (alle Listen).

=back

=head4 Returns

Markup-Code (String)

=head4 Description

Erzeuge den MediaWiki Markup-Code für ein Listenelement des Typs
$type und mit Wert $val. Im Falle einer Definitonsliste verwende
den Definitionsterm $key.

=head4 See Also

=over 2

=item *

L<https://www.mediawiki.org/wiki/Help:Lists>

=back

=head4 Examples

=over 2

=item *

Punktliste

    $gen->item('*','Apfel');

produziert

    * Apfel

=item *

Nummerierungsliste

    $gen->item('#','Apfel');

produziert

    # Apfel

=item *

Definitionsliste

    $gen->item(';',A=>'Apfel);

produziert

    ; A : Apfel

=item *

Item einer untergeordneten Liste

    $gen->item('#*','Apfel');

produziert

    *#* Apfel

=item *

Item mit einer untergeordneten Liste als Wert

    $gen->item('#',"* Apfel\n* Birne\n*Pflaume");

produziert

    #* Apfel
    #* Birne
    #* Pflaume

=back

=cut

# -----------------------------------------------------------------------------

sub item {
    my $self = shift;
    my $type = shift;
    # @_: $val -or- $key,$val

    # Der übergebene Typ kann aus mehreren Typ-Zeichen bestehen.
    # Das letzte Zeichen ist das entscheidende. 

    # Term im Falle einer Definitonsliste

    my $key;
    if (substr($type,-1,1) eq ';') {
        $key = shift;
    }

    # Wert

    my $val = Quiq::Unindent->trim(shift);

    # Sonderbehandlung für Sublisten

    # Enthält der Wert eine Subliste, stellen wir dessen Elementen den
    # eigenen Typ voran. Im Falle einer Definitionsliste (;) fügen wir
    # außerdem einen Doppelpunkt (:) ein, damit die Definitionsliste
    # tief genug eingerückt ist.

    $val =~ s/^([*#])/$type$1/mg;
    $val =~ s/^(;)/$type:$1/mg;

    # Besteht der Wert allein aus der Subliste, liefern wir diese zurück.
    # Andernfalls erzeugen wir ein Listenelement (das in $val eine
    # Subliste enthalten kann).

    my $code;
    if ($val !~ /^[*#;]/) {
        # Listenelement generieren

        $code = "$type ";
        if ($key) {
            $code .= "$key : ";
        }
    }
    $code .= $val;

    return "$code\n";
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

=item Zeichen: *

Punktliste.

=item Zeichen: #

Numerierungsliste.

=item Zeichen: ;

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
mit den Elementen @items und liefere diesen zurück. Listen
können auch geschachtelt werden. Siehe Examples.

=head4 See Also

=over 2

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

    * Geschachtelte Liste:
    
         $code .= $gen->list('#',[
             'Obst',
             $gen->list('*',[
                 'Apfel',
                 'Birne',
                 'Pflaume',
             ]),
             'Gemüse',
             $gen->list('*',[
                 'Gurke',
                 'Spinat',
                 'Tomate',
             ]),
         ]);
    
       produziert
    
         # Obst
         #* Apfel
         #* Birne
         #* Pflaume
         # Gemüse
         #* Gurke
         #* Spinat
         #* Tomate

=cut

# -----------------------------------------------------------------------------

sub list {
    my ($self,$type,$itemA) = @_;

    my $code = '';
    for (my $i = 0; $i < @$itemA; $i++) {
        my @args;
        if ($type eq ';') {
            push @args,$itemA->[$i++];
        }
        push @args,$itemA->[$i];

        $code .= $self->item($type,@args);
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

=over 2

=item *

Syntax: L<https://www.mediawiki.org/wiki/Help:Formatting>

=back

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

    $text = Quiq::Unindent->trim($text);
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

=over 2

=item *

Syntax: L<https://www.mediawiki.org/wiki/Help:Formatting>

=back

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

=head3 table() - Erzeuge Tabelle

=head4 Synopsis

    $code = $gen->table(@keyVal);

=head4 Arguments

Die Argumentliste @keyVal wird gebildet über folgenden
Schlüssel/Wert-Paaren:

=over 4

=item alignments => \@alignments (Default: [])

Liste der Kolumnen-Ausrichtungen. Mögliche Werte je Kolumne: 'left',
'right', 'center'.

=item bodyBackground => $color (Default: '#ffffff')

Hintergrundfarbe der Rumpfzeilen.

=item caption => $str

Unterschrift der Tabelle.

=item rows => \@rows (Default: [])

Liste der Tabellenzeilen.

=item titleBackground => $color (Default: '#e8e8e8')

Hintergrundfarbe der Titelzeile.

=item titles => \@titles (Default: [])

Liste der Kolumnentitel.

=item valueCallback => sub {...} (Default: keiner)

Subroutine, die für I<jeden> Wert (caption, title, row value) aufgerufen
wird:

    valueCallback => sub {
        my $val = shift;
        ...
        return $val;
    }

Die Subroutine wird z.B. von Sdoc verwendet, um Segmente zu expandieren:

    valueCallback => sub {
        return $self->expandText($m,\shift);
    }

=back

=head4 Returns

Markup-Code (String)

=head4 Description

Erzeuge den MediaWiki Markup-Code für eine Tabelle und liefere diesen
zurück.

Das Aussehen der MediaWiki-Tabelle wird durch CSS-Angaben bestimmt,
die in den Wiki-Code eingestreut werden. Die Grundlage hierfür bietet
die Standard-CSS-Klasse "wikitable" (siehe Link unten).

=head4 See Also

=over 2

=item *

Syntax: L<https://www.mediawiki.org/wiki/Help:Tables>

=item *

CSS der Klasse "wikitable": L<https://www.mediawiki.org/wiki/Manual:CSS>

=back

=head4 Example

Der Code

    $gen->table(
        alignments => ['left','right','center'],
        caption => 'Eine Tabelle',
        titles => ['L','R','Z'],
        rows => [
            ['A',1,'ABCDEFG'],
            ['AB',12,'HIJKL'],
            ['ABC',123,'MNO'],
            ['ABCD',1234,'P'],
        ],
    );

produziert

    {| class="wikitable"
    |+ style="caption-side: bottom; font-weight: normal"|Eine Tabelle
    |-
    ! style="background-color: #e8e8e8; text-align: left" |L
    ! style="background-color: #e8e8e8; text-align: right" |R
    ! style="background-color: #e8e8e8" |Z
    |-
    | style="background-color: #ffffff" |A
    | style="background-color: #ffffff; text-align: right" |1
    | style="background-color: #ffffff; text-align: center" |ABCDEFG
    |-
    | style="background-color: #ffffff" |AB
    | style="background-color: #ffffff; text-align: right" |12
    | style="background-color: #ffffff; text-align: center" |HIJKL
    |-
    | style="background-color: #ffffff" |ABC
    | style="background-color: #ffffff; text-align: right" |123
    | style="background-color: #ffffff; text-align: center" |MNO
    |-
    | style="background-color: #ffffff" |ABCD
    | style="background-color: #ffffff; text-align: right" |1234
    | style="background-color: #ffffff; text-align: center" |P
    |}

was in der Darstellung so aussieht

    +-------+--------------------+
    | L     |      R |     Z     |
    +----------------------------+
    | A     |      1 |  ABCDEFG  |
    +----------------------------+
    | AB    |     12 |   HIJKL   |
    +----------------------------+
    | ABC   |    123 |    MNO    |
    +----------------------------+
    | ABCD  |   1234 |     P     |
    +----------------------------+
             Eine Tabelle

=cut

# -----------------------------------------------------------------------------

sub table {
    my $self = shift;
    # @_: @keyVal

    my $alignA = [];
    my $bodyBackground = '#ffffff';
    my $caption = undef;
    my $rowA = [];
    my $titleBackground = '#e8e8e8';
    my $titleA = [];
    my $valueCb = undef;

    Quiq::Parameters->extractPropertiesToVariables(\@_,
        alignments => \$alignA,
        bodyBackground => \$bodyBackground,
        caption => \$caption,
        rows => \$rowA,
        titleBackground => \$titleBackground,
        titles => \$titleA,
        valueCallback => \$valueCb,
    );

    if (!@$titleA && !@$rowA) {
        return '';
    }

    # Tabellenanfang
    my $code = qq~{| class="wikitable"\n~;

    # Tabellen-Unterschrift

    if ($caption) {
        if ($valueCb) {
            $caption = $valueCb->($caption);
        }
        $code .= qq{|+ style="caption-side: bottom; font-weight: normal"}.
            qq{|$caption\n};
    }

    # Titelzeile

    my $titleLine = '';
    if (@$titleA) {
        $code .= "|-\n";
        for (my $i = 0; $i < @$titleA; $i++) {
            # Style

            my $style = "background-color: $titleBackground";
            if (my $align = $alignA->[$i] || 'left') {
                if ($align ne 'center') {
                    $style .= "; text-align: $align";
                }
            }

            # Wert

            my $val = $titleA->[$i];
            if ($valueCb) {
                $val = $valueCb->($val);
            }

            # Code
            $code .= qq{! style="$style" |$val\n};
        }
    }

    # Datenzeilen

    for my $valA (@$rowA) {
        $code .= "|-\n";
        for (my $i = 0; $i < @$valA; $i++) {
            # Style

            my $style = "background-color: $bodyBackground";
            if (my $align = $alignA->[$i]) {
                if ($align ne 'left') {
                    $style .= "; text-align: $align";
                }
            }

            # Wert

            my $val = $valA->[$i];
            if ($valueCb) {
                $val = $valueCb->($val);
            }

            # Code
            $code .= qq{| style="$style" |$val\n};
        }
    }

    # Tabellenende
    $code .= '|}';

    return "$code\n\n";
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

=over 2

=item *

Syntax: L<https://www.mediawiki.org/wiki/Manual:Table_of_contents>

=back

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

=head2 Inline Code

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

=item nl

Erzeugt:

    <br />

=item quote

Erzeugt:

    <q>TEXT</q>

=back

=head4 See Also

=over 2

=item *

Syntax: L<https://www.mediawiki.org/wiki/Help:Formatting>

=back

=cut

# -----------------------------------------------------------------------------

sub fmt {
    my ($self,$type,$text) = @_;

    my $code = Quiq::Unindent->trim($text);
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
        elsif ($type eq 'quote') {
            $code = "<q>$code</q>";
        }
        elsif ($type eq 'nl') {
            $code = '<br />';
        }
        else {
            $self->throw(
                'MEDIAWIKI-00001: Unknown inline format',
                Format => $type,
            );
        }
    }

    return $code;
}

# -----------------------------------------------------------------------------

=head3 indent() - Erzeuge Einrückung

=head4 Synopsis

    $code = $gen->indent($n);

=head4 Returns

Markup-Code (String)

=head4 Description

Erzeuge den MediaWiki Markup-Code für eine Einrückung der Tiefe $n
und liefere diesen zurück.

=head4 See Also

=over 2

=item *

Syntax: L<https://www.mediawiki.org/wiki/Help:Formatting>

=back

=head4 Example

    $gen->indent(2);

erzeugt

    ::

=cut

# -----------------------------------------------------------------------------

sub indent {
    my ($self,$n) = @_;
    return ':' x $n;
}

# -----------------------------------------------------------------------------

=head3 link() - Erzeuge internen oder externen Link

=head4 Synopsis

    $code = $gen->link($type,$destination,$text);

=head4 Arguments

=over 4

=item $type

Art des Link. Mögliche Werte: 'internal', 'external'.

=item $destination

Link-Ziel.

=item $text

Link-Text.

=back

=head4 Returns

Markup-Code (String)

=head4 Description

Erzeuge den MediaWiki Markup-Code für einen internen oder externen
Link und liefere diesen zurück.

=head4 See Also

=over 2

=item *

Syntax: L<https://www.mediawiki.org/wiki/Help:Formatting>

=back

=head4 Examples

=over 2

=item *

Interner Link

    $gen->link('internal','Transaktionssicherheit',
        'Abschnitt Transaktiossicherheit');

erzeugt

    [[#Transaktionssicherheit|Abschnitt Transaktiossicherheit]]

=item *

Externer Link

    $gen->link('external','http::/fseitz.de','Homepage Frank Seitz');

erzeugt

    [http::/fseitz.de/ Homepage Frank Seitz]

=back

=cut

# -----------------------------------------------------------------------------

sub link {
    my ($self,$type,$destination,$text) = @_;

    if ($type eq 'internal') {
        return sprintf '[[#%s|%s]]',$destination,$text;
    }
    elsif ($type eq 'external') {
        return sprintf '[%s %s]',$destination,$text;
    }

    $self->throw;
}

# -----------------------------------------------------------------------------

=head2 Sonstiges

=head3 protect() - Schütze Metazeichen

=head4 Synopsis

    $code = $gen->protect($text);

=head4 Description

Schütze alle Metazeichen in Text $text, so dass das Resultat als Inhalt
in eine MediaWiki-Seite eingesetzt werden kann.

=cut

# -----------------------------------------------------------------------------

sub protect {
    my ($self,$text) = @_;

    if (defined $text) {
        #$text =~ s/&/&amp;/g;
        #$text =~ s/</&lt;/g;
        #$text =~ s/>/&gt;/g;
    }
    
    return $text;
}

# -----------------------------------------------------------------------------

=head2 Testseite

=head3 testPage() - Erzeuge Test-Seite

=head4 Synopsis

    $code = $this->testPage;

=head4 Description

Erzeuge eine Seite mit MediaWiki-Markup. Diese Seite kann in ein
MediaWiki übertragen und dort optisch begutachtet werden.

=head4 Example

    $ perl -MQuiq::MediaWiki::Markup -C -E 'print Quiq::MediaWiki::Markup->testPage'

=cut

# -----------------------------------------------------------------------------

sub testPage {
    my $class = shift;

    my $gen = $class->new;

    # Kommentar-Block

    my $code .= $gen->comment(q~
      Dies ist ein Test-Dokument, das alle von der Klasse
      Quiq::MediaWiki::Markup implementierten Syntaxelemente
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
    $code .= $gen->list('#',['Gurke','Spargel','Tomate']);

    $code .= $gen->section(2,'Definitionsliste');
    $code .= $gen->list(';',[A=>'Apfel',B=>'Birne',P=>'Pflaume']);

    $code .= $gen->section(2,'Geschachtelte Listen');

    $code .= $gen->section(3,'Verschachtelte Punktlisten');

    $code .= $gen->list('*',[
        'A',
        $gen->list('*',[
            'B',
            $gen->list('*',[
                'C',
                'D',
                'E',
            ]),
            'F',
            'G',
        ]),
        'H',
        $gen->list('*',[
            'I',
            'J',
            'K',
        ]),
        'L',
        'M',
    ]);

    $code .= $gen->section(3,'Punktliste in Nummerierungsliste');

    $code .= $gen->list('#',[
        'Obst',
        $gen->list('*',[
            'Apfel',
            'Birne',
            'Pflaume',
        ]),
        'Gemüse',
        $gen->list('*',[
            'Gurke',
            'Spinat',
            'Tomate',
        ]),
    ]);

    $code .= $gen->section(1,'Tabelle');

    $code .= $gen->table(
        alignments => ['left','right','center'],
        caption => 'Eine Tabelle',
        titles => ['L','R','Z'],
        rows => [
            ['A',1,'ABCDEFG'],
            ['AB',12,'HIJKL'],
            ['ABC',123,'MNO'],
            ['ABCD',1234,'P'],
        ],            
    );

    # Code

    $code .= $gen->section(1,'Code');

    $code .= $gen->section(2,'Ohne Inline-Formatierung');

    $code .= $gen->code(q~
        sub maxFilename {
            my ($class,$dir) = @_;
 
            my $max;
            my $dh = Quiq::DirHandle->new($dir);
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
            '''my''' $''dh'' = '''Quiq::DirHandle'''->'''new'''($''dir'');
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
        ).', '.
        $gen->fmt('bold','Fette und '.
            $gen->fmt('italic','kursive').' Schrift'
        )."\n\n";

    # Kommentar-Segment

    $code .= $gen->fmt('comment','eof');
    $code .= "\n";

    return $code;
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
