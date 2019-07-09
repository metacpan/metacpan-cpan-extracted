package Quiq::Html::Tag;
use base qw/Quiq::Hash/;

use strict;
use warnings;
use v5.10.0;
use utf8;

our $VERSION = '1.151';

use Quiq::Css;
use Quiq::Template;
use Quiq::String;
use Scalar::Util ();
use Quiq::Image;
use Quiq::Path;
use MIME::Base64 ();

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Html::Tag - Generierung von HTML-Tags

=head1 BASE CLASS

L<Quiq::Hash>

=head1 DESCRIPTION

=head2 Zweck der Klasse

Die Klasse generiert HTML-Code.  Sie implementiert zwei Methoden -
tag() und cat() - mit denen HTML-Code beliebiger Komplexität
erzeugt werden kann.

=head2 Methode new()

Ein Objekt der Klasse wird instantiiert durch

    my $h = Quiq::Html::Tag->new;

Die Methoden dieses Objekts generieren (X)HTML.

=head2 Methode tag()

Die Methode tag() generiert einen Tag. Sie kennt
alle Element-Typen des W3C HTML/XHTML Standard und liefert bei Aufruf
eine formatierte Tag-Repräsentation des betreffenden Element-Typs
und seiner Attribute. Beispiel:

    $str = $h->tag('img',src=>'URL');

ergibt

    <img src="URL" alt="" />

Das Beispiel verdeutlicht, dass der Methode tag() die
Element-Typen "kennt". In diesem Fall "weiß" die Methode, dass
Elemente des Typs 'img' leer sind und diese ein Pflicht-Attribut
'alt' besitzen (wird es nicht gesetzt, erhält es den Wert "").

Die Methode tag() hat die Signatur:

    $str = $h->tag($elem,@keyVal,$content);

Hierbei ist $elem der Element-Typ, @keyVal die Liste der
Attribut/Wert-Paare und Optionen (siehe unten) und $content
ist der Inhalt des Tag.

Da die Argumente der Methode die gleiche Abfolge haben wie die
Bestandteile eines Tag in HTML, können die Methodenaufrufe in Perl
analog geschachtelt werden wie die Tags in HTML. Beispiel:

    $h->tag('a',href=>'URL1',
        $h->tag('img',src=>'URL2'),
    );

ergibt

    <a href="URL1"><img src="URL2" alt="" /></a>

=head2 Methode cat()

Die Elemente eines HTML-Dokuments können syntaktisch ntürlich
nicht nur geschachtelt auftreten, sie können auch
aufeinanderfolgen. Die Methode cat() fügt aufeinanderfolgende
HTML-Elemente zusammen.

Die Methode cat() hat folgende Signatur:

    $str = $h->cat(@args);

Hierbei ist @args die Liste der HTML-Elemente, die zusammengefügt
werden sollen.

Beispiel:

    $h->cat(
        $h->tag('li','Orange'),
        $h->tag('li','Zitrone'),
        $h->tag('li','Ananas'),
    );

ergibt

    <li>Orange</li>
    <li>Zitrone</li>
    <li>Ananas</li>

Die Methode cat() wird von der Methode tag() intern gerufen, um
den Content des Tag zu konstruieren. Erstreckt sich der Content
über mehrere Argumente, statt nur einem Argument (dem letzten), muss der
Methode tag() das Ende der @keyVal Argumente angezeigt werden.
Dies geschieht durch Setzen des Arguments '-' vor die
Content-Argumente.

    $h->tag('ul','-',
        $h->tag('li','Orange'),
        $h->tag('li','Zitrone'),
        $h->tag('li','Ananas'),
    );

ergibt

    <ul>
      <li>Orange</li>
      <li>Zitrone</li>
      <li>Ananas</li>
    </ul>

Der Inhalt eines Tag kann nicht nur aus HTML-Elementen bestehen,
sondern auch einfachen Text enthalten oder aus einer Mischung
aus Text und Elementen bestehen. Beispiel:

    $h->tag('p','-',
       'Auf ',$h->tag('a',href=>'http://cpan.org','CPAN'),
       ' sind ',$h->tag('b','viele'),' Module!',
    );

ergibt

    <p>
      Auf <a href="http://cpan.org">CPAN</a> sind <b>viele</b> Module!
    </p>

=head2 Komplexere HTML-Strukturen

Mit der Methode tag() lassen sich beliebig komplexe HTML-Strukturen
generieren. Der folgende Code produziert ein einfaches, bis auf
die fehlende Dokumenttyp-Deklaration vollständiges HTML-Dokument.

    $h->tag('html','-',
        $h->tag('head',
            $h->tag('title','Test'),
        ),
        $h->tag('body',
            $h->tag('p',q|
                Hallo
                Welt!
            |),
        ),
    );

liefert

    <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
      <title>Test</title>
    </head>
    <body>
    <p>
      Hallo
      Welt!
    </p>
    </body>
    </html>

=head2 Formatierung

Wer die obigen Beispiele genau betrachtet, bemerkt, dass die Tags
nicht alle mit der gleichen Formatierung generiert werden.
Der a-Tag umschließt seinen Inhalt unmittelbar

    <a ...>INHALT</a>

wohingegen der p-Tag seinen Inhalt um zwei Leerzeichen einrückt
und der Begin- und End-Tag auf einer eignenen Zeile stehen

    <p>
      INHALT
    </p>

Dies sind zwei der Formatierungsvarianten, die die Methode
tag() kennt.

Für jeden HTML Element-Typ ist eine Default-Formatierung definiert,
welche bestimmt, wie die Tags des Element-Typs formatiert werden.
Jedes Format wird mit einem Buchstaben bezeichnet: e, E, i, m, M, p, v.

e=empty mit Zeilenumbruch

Der Tag hat keinen Inhalt und steht auf einer eigenen Zeile (d.h.
er wird mit \n abgeschlossen):

    <br />\n

E=empty ohne Zeilenumbruch

Wie e, nur dass der Tag nicht auf einer eigenen Zeile steht (also
nicht mit \n abgeschlossen wird):

    <img ... />

i=inline

Der Tag umschließt seinen Inhalt unmittelbar, es wird
kein \n angehängt:

    <a ...>IRGENDEIN\n
    INHALT</a>

m=multiline mit Einrückung

Der Inhalt wird um zwei Leerzeichen eingerückt, der Tag umschließt
diesen auf getrennten Zeilen. Das Konstrukt endet mit einem \n:

    <p ...>\n
      IRGENDEIN\n
      INHALT\n
    </p>\n

M=multiline ohne Einrückung

Wie m, nur dass der Inhalt nicht eingerückt wird:

    <html ...>\n
    HEAD\n
    BODY\n
    </html>\n

p=protected

Der Inhalt wird einzeilig gemacht, indem LF- und CR-Zeichen durch
die Entities &#10; und &#13; ersetzt werden und vom Tag
unmittelbar umschlossen werden.

    <pre ...>IRGENDEIN&#10;INHALT</pre>\n

Diese Formatierung schützt den Tag-Inhalt davor, dass er
durch eine Einrückung äußerer Tags verändert wird. Sie wird
bei Tags angewendet, bei deren Inhalt Whitespace signifikant ist.

v=variable

Enthält der Inhalt keine Zeilenumbrüche, wird er einzeilig ausgelegt:

    <title>INHALT</title>\n

Enthält der Inhalt Zeilenumbrüche, wird er mehrzeilig ausgelegt:

    <title>
      EIN
      TITEL
    </title>

=head2 Setzen von data-* Attributen

Die Methode tag() unterstützt data-* Attribute auf zwei Weisen:

=over 4

=item 1.

Einzelne Attribute:

    $h->tag('form',
        'data-x' => 'a',
        'data-y' => 'b',
        'data-z' => 'c',
         ...
    );

=item 2.

Liste von Attributen:

    $h->tag('form',
        data => [
            x => 'a',
            y => 'b',
            z => 'c',
        ],
        ...
    );

=back

Das Resultat in beiden Fällen:

    <form data-z="c" data-y="b" data-x="a" ...></form>

=head2 HTML Element-Typen

Die Methode tag() kennt alle Element-Typen des W3C-Standards. Die
folgende Liste gibt den Element-Typ, die Default-Formatierung und
die Default-Attribute an:

    Element   Format  Default-Attribute
    
    a           i
    abbr        i
    acronym     i
    address     v
    area        e
    b           i
    base        e
    bdo         i
    big         i
    blockquote  m
    body        M
    br          e
    button      v
    caption     v
    cite        i
    code        i
    col         e
    colgroup    m
    dd          v
    del         i
    dfn         i
    div         m
    dl          m
    dt          v
    em          i
    fieldset    m
    form        M
    frame       e
    frameset    m
    h1          v
    h2          v
    h3          v
    h4          v
    h5          v
    h6          v
    head        m
    hr          e
    html        M     xmlns=>'http://www.w3.org/1999/xhtml' (nur XHTML)
    i           i
    iframe      v
    img         E     alt=>''
    input       e
    ins         i
    kbd         i
    label       v
    legend      v
    li          v
    link        e
    map         m
    meta        e
    noframes    m
    noscript    m
    object      m
    ol          m
    optgroup    m
    option      v
    p           m
    param       e
    pre         p
    q           i
    samp        i
    script      m     type=>'text/javascript'
    select      v
    small       i
    span        i
    strong      i
    style       m     type=>'text/css'
    sub         i
    sup         i
    table       M
    tbody       m
    td          v
    textarea    p
    tfoot       m
    th          v
    thead       m
    title       v
    tr          m
    tt          i
    ul          m
    var         i

Das Default-Format kann mit der Option -fmt=>$val bei Aufruf
der Methode tag() überschrieben werden.

=head2 Zeilenumbruch

Bei allen Formaten außer i (inline) endet der generierte Tag Code per
Default mit einem Zeilenumbruch. Die Zahl der angehängten Zeilenumbrüche
kann unabhängig davon mit der Option -nl=>$n gesetzt werden.
Bei -nl=>0 wird kein Zeilenumbruch angehängt.

=head2 HTML statt XHTML

Per Default wird XHTML-Code generiert. Um klassischen HTML-Code
zu generieren, wird die HTML-Version gesetzt:

    Quiq::Html::Tag->setDefault(htmlVersion=>'html-4.01');

Ab diesem Aufruf instantiieren die nachfolgenden Konstruktor-Aufrufe
(sofern sie die htmlVersion nicht selbst setzen) Objekte zur Generierung
von klassischem HTML.

Der generierte Code sieht bei klassischem HTML folgendermaßen aus:

    <a href="URL1"><img src="URL2" alt=""></a>

Man beachte, dass der img-Tag nun mit '>', nicht mit ' />'
abgeschlossen ist.

=head2 HTML mit Großschreibung

HTML-Code mit großgeschriebenen Element- und Attributnamen wird
nach folgender Setzung erzeugt:

    Quiq::Html::Tag->setDefault(htmlVersion=>'html-4.01',uppercase=>1);

Der generierte Code sieht dann so aus:

    <A HREF="URL1"><IMG SRC="URL2" ALT=""></A>

Ist XHTML ('xhtml-1.0') eingestellt, hat die Option uppercase=>1
keinen Einfluss.

=head1 ATTRIBUTES

=over 4

=item checkLevel => 0|1|2 (Default: 1)

Umfang der Element/Attribut-Prüfung.

=over 4

=item Z<>0

keine Prüfung

=item Z<>1

prüfe Element-Typ

=item Z<>2

prüfe Element-Typ und Attributnamen

=back

Wird ein Fehler festgestellt, wird eine Exception geworfen.

=item compact => $bool (Default: 0)

Generiere den HTML-Code einzeilig mit so wenig Whitespace wie möglich.

=item embedImages => $bool (Default: 0)

Füge Bilddaten direkt in HTML ein.

=item htmlVersion => 'html-4.01'|'html-5'|'xhtml-1.0' (Default: 'xhtml-1.0')

HTML-Version. Beginnt die Versionsangabe mit 'xhtml' wird das
HTML gemäß den Regeln für XHTML generiert, andernfalls für
klassisches HTML. Die Versionsnummer wird bei der Generierung
des DOCTYPE herangezogen.

=item indentation => $n (Default: undef)

Forciere eine Content-Einrückung um $n Leerzeichen. Bei indentation=>0
wird nicht eingerückt. Ist indentation nicht gesetzt, gilt die
Einrückung, die als Argument bei der Tag-Methode angegeben ist bzw.
die in der Methode tag() als Default vorgegeben ist.

=item uppercase => $bool (Default: 0)

Erzeuge Tag- und Attribut-Namen in Großschreibung. Diese Setzung
wird nur bei klassischem HTML - nicht bei XHTML - beachtet.

=back

=cut

# -----------------------------------------------------------------------------

# Attribute und Defaultwerte bei der Instantiierung. Werden die
# Werte anders gesetzt, gelten sie für die gesamte Applikation.

my %Default = (
    checkLevel => 1,            # Umfang der Element- und Attribut-Prüfungen
    compact => 0,               # Einzeilig, Whitespace komprimiert
    embedImages => 0,           # Einbettung von Bildern
    # htmlVersion => 'xhtml-1.0', # XHTML vs. HTML, Versionsnr. für DOCTYPE
    htmlVersion => 'html-5',    # XHTML vs. HTML, Versionsnr. für DOCTYPE
    indentation => undef,       # forcierte Einrückung
    uppercase => 0,             # wandele Elem.- und Att.-Namen in Großschr.
);
Hash::Util::lock_keys(%Default);

# Liste der vom W3C definierten (X)HTML-DTD- und Frameset-DTD-Elemente
# und ihre Default-Formatierung

my %Element = (
    a => 'i',          # Link, Anker
    abbr => 'i',       # Text ist Abkürzung
    acronym => 'i',    # Text ist Akronym
    address => 'v',    # Text ist Adressangabe
    area => 'e',       # Bereich in einer clientseitigen Image-Map
    b => 'i',          # Fettschrift
    base => 'e',       # Basis-Pfadname für alle relativen URLs
    bdo => 'i',        # Text mit anderer Laufrichtung
    big => 'i',        # Großschrift
    blockquote => 'm', # Zitatabschnitt
    body => 'm',       # Rumpf HTML-Seite
    br => 'e',         # Zeilenumbruch
    button => 'v',     # Schaltfläche
    caption => 'v',    # Beschriftung zu einer Tabelle
    cite => 'i',       # Text ist Hinweis auf Literaturstelle
    code => 'i',       # Codebeispiel
    col => 'e',        # Eigenschaften einer Tabellenspalte
    colgroup => 'm',   # Definition einer Spaltengruppe
    dd => 'v',         # Text Definitionsliste
    del => 'i',        # gelöschter Text
    dfn => 'i',        # Text ist Definition
    div => 'm',        # allgemeines Block-Element
    dl => 'm',         # Definitionsliste
    dt => 'v',         # Terminus Definitionsliste
    em => 'i',         # hervorgehobener Text
    fieldset => 'm',   # Gruppe von Feldern eines Formulars
    form => 'm',       # Formular
    frame => 'e',      # (Frameset-DTD) Frame eines Frameset
    frameset => 'm',   # (Frameset-DTD) Frameset
    h1 => 'v',         # Überschrift
    h2 => 'v',         # Überschrift
    h3 => 'v',         # Überschrift
    h4 => 'v',         # Überschrift
    h5 => 'v',         # Überschrift
    h6 => 'v',         # Überschrift
    head => 'm',       # Kopf HTML-Seite
    hr => 'e',         # Trennbalken
    html => 'M',       # HTML-Seite
    i => 'i',          # kursiver Text
    iframe => 'v',     # (Frameset-DTD) Inline-Frame
    img => 'E',        # Bild
    input => 'e',      # Formular-Eingabeelement
    ins => 'i',        # eingefügter Text
    kbd => 'i',        # Text stellt Benutzereingabe dar
    label => 'v',      # Label zu Formular-Eingabeelement
    legend => 'v',     # Beschriftung zu Fieldset
    li => 'v',         # Listenelement
    link => 'e',       # Definiert Beziehung zu anderem Dokument
    map => 'm',        # Definition clientseitige Image-Map
    meta => 'e',       # Information zum Dokument
    noframes => 'm',   # (Frameset-DTD) Inhalt für nicht-framefähige Browser
    noscript => 'm',   # Inhalt für nicht-skriptfähige Browser
    object => 'm',     # einbettetes Objekt
    ol => 'm',         # nummerierte Liste
    optgroup => 'm',   # Gruppe von Optionen einer Selectliste
    option => 'v',     # Option einer Selectliste
    p => 'm',          # Absatz
    param => 'e',      # Parameter eines Object
    pre => 'p',        # Leerraum und Zeilenumbrüche erhalten
    q => 'i',          # Kurzzitat
    samp => 'i',       # Text stellt Ausgabe eines Programms dar
    script => 'c',     # Code, der vom Browser ausgeführt wird
    select => 'v',     # Auswahlmenü
    small => 'i',      # Kleinschrift
    span => 'i',       # allgemeines Inline-Element
    strong => 'i',     # stark hervorgehobener Text
    style => 'v',      # Stylesheet-Regeln
    sub => 'i',        # tiefgestellter Text
    sup => 'i',        # hochgestellter Text
    table => 'M',      # Tabelle
    tbody => 'm',      # Rumpf Tabelle
    td => 'v',         # Tabellenzelle
    textarea => 'p',   # Text-Eingabefeld
    tfoot => 'm',      # Fuß Tabelle (identisch zu tbody)
    th => 'v',         # Tabellenkopfzelle (identisch zu td)
    thead => 'm',      # Kopf Tabelle (identisch zu tbody)
    title => 'v',      # Titel HTML-Dokument
    tr => 'm',         # Tabellenzeile
    tt => 'i',         # Schreibmaschinenschrift
    ul => 'm',         # Ungeordnete Liste
    var => 'i',        # Text ist Variablenname
);

# Default-Optionen

my %DefaultOptions = (
    p => [-ignoreIfNull=>1],
    span => [-ignoreIfNull=>1],
);

# Default-Attribute von Elementen allgemein

my %DefaultAttributes = (
    # form => [method=>'post',enctype=>'multipart/form-data'],
    img => [alt=>''],
    script => [type=>'text/javascript'],
    style => [type=>'text/css'],
);

# Default-Attribute, nur XHTML

my %DefaultAttributesXhtml = (
    html => [xmlns=>'http://www.w3.org/1999/xhtml'],
);

# Liste aller Attribute und ihrer Domänen.
# FIXME: anhand DTD überprüfen

my %Attribute = (
    'accept-charset' => 'charsets', # form
    'http-equiv' => 'cdata',        # meta
    'xml:lang' => 'languageCode',   # I18N (XHTML)
    'xml:space' => 'space',         # ENUM pre,script,style(XHTML)
    abbr => 'text',                 # Cell
    accept => 'contentTypes',       # form,input
    accesskey => 'character',       # Focus,legend
    action => 'uri',                # form
    align => 'cellAlign',           # ENUM CellAlign
    alt => 'cdata',                 # input(cdata);area,img(text)
    archive => 'uriList',           # object
    axis => 'cdata',                # Cell
    border => 'pixels',             # table
    cellpadding => 'length',        # table
    cellspacing => 'length',        # table
    char => 'character',            # CellAlign
    charoff => 'length',            # CellAlign
    charset => 'charset',           # a,link,script
    checked => 'bool',              # input
    cite => 'uri',                  # blockquote,del,ins,q
    class => 'class',               # Core
    classid => 'uri',               # object
    codebase => 'uri',              # object
    codetype => 'contentType',      # object
    cols => 'multiLengths',         # frameset(multiLengths),textarea(number)
    colspan => 'number',            # Cell
    content => 'cdata',             # meta
    coords => 'coords',             # a, area
    data => 'uri',                  # object
    datetime => 'datetime',         # del, ins
    declare => 'bool',              # object
    defer => 'bool',                # script
    dir => 'dir',                   # ENUM I18N
    disabled => 'bool',             # button,input,optgroup,option,select,
                                  # textarea
    enctype => 'contentType',       # form
    frame => 'tframe',              # ENUM table
    frameborder => 'frameBorder',   # ENUM frame, iframe
    headers => 'idrefs',            # Cell
    height => 'length',             # iframe,img,object
    href => 'uri',                  # a,area,base,link
    hreflang => 'languageCode',     # a,link
    id => 'id',                     # Core
    ismap => 'bool',                # img,input
    label => 'text',                # optgroup,option
    lang => 'languageCode',         # I18N
    longdesc => 'uri',              # frame,iframe,img
    marginheight => 'pixels',       # frame,iframe
    marginwidth => 'pixels',        # frame,iframe
    maxlength => 'number',          # input
    media => 'mediaDesc',           # ENUM link,style
    method => 'method',             # ENUM form
    multiple => 'bool',             # select
    name => 'nmtoken',              # button,input,meta,param,select,textarea,
                                  # object;form,frame,map(HTML)
    nohref => 'bool',               # area
    noresize => 'bool',             # frame
    onblur => 'script',             # Focus,select
    onchange => 'script',           # input,select,textarea
    onclick => 'script',            # Event
    ondblclick => 'script',         # Event
    onfocus => 'script',            # Focus,select
    onkeydown => 'script',          # Event
    onkeypress => 'script',         # Event
    onkeyup => 'script',            # Event
    onload => 'script',             # body,frameset
    onmousedown => 'script',        # Event
    onmousemove => 'script',        # Event
    onmouseout => 'script',         # Event
    onmouseover => 'script',        # Event
    onmouseup => 'script',          # Event
    onreset => 'script',            # form
    onselect => 'script',           # input,textarea
    onsubmit => 'script',           # form
    onunload => 'script',           # body,frameset
    profile => 'uri',               # head
    readonly => 'bool',             # input,textarea
    rel => 'linkTypes',             # ENUM a,link
    rev => 'linkTypes',             # ENUM a,link
    rows => 'multiLengths',         # frameset(multiLengths);textarea(number)
    rowspan => 'number',            # Cell
    rules => 'trules',              # ENUM table
    scheme => 'cdata',              # meta
    scope => 'scope',               # ENUM Cell
    scoped => 'bool',               # style
    scrolling => 'scrolling',       # ENUM frame,iframe
    selected => 'bool',             # option
    shape => 'shape',               # ENUM a,area
    size => 'number',               # input,select
    span => 'number',               # col,colgroup
    src => 'uri',                   # frame,iframe,img,input,script
    standby => 'text',              # object
    style => 'styleSheet',          # Core
    summary => 'text',              # table
    tabindex => 'number',           # Focus,object,select
    target => 'frameTarget',        # a,area,base,form,link
    title => 'text',                # Core,style
    type => 'ContentType',          # button(ENUM);a,link,object,param,script,
                                  # style;input(ENUM)
    usemap => 'uri',                # img,input,object
    valign => 'cellValign',         # ENUM CellAlign
    value => 'cdata',               # button,input,option,param
    valuetype => 'valueType',       # ENUM param
    width => 'length',              # iframe,img,object,table(length);
                                  # col,colgroup(multiLength)
    xmlns => 'uri',                 # html (XHTML)
);

# Attribut-Domänen (werden aktuell nicht geprüft)

my %Domain = (
    bool => 1,
    buttonType => [qw/button reset submit/],
    cdata => 1,
    cellAlign => [qw/center char justify left right/],
    cellValign => [qw/baseline bottom middle top/],
    character => 1,
    charset => 1,
    charsets => 1,
    class => 1,
    contentType => 1,
    contentTypes => 1,
    coords => 1,
    datetime => 1,
    dir => [qw/ltr rtl/],
    frameBorder => [0,1],
    frameTarget => 1,
    id => 1,
    idrefs => 1,
    inputType => [qw/checkbox file hidden password radio reset submit text/],
    languageCode => 1,
    length => 1,
    linkTypes => [qw/stylesheet next prev copyright index glossary/], # unv.
    mediaDesc => [qw/all aural braille handheld print projection screen tty tv/],
    method => [qw/get post/],
    multiLength => 1,
    multiLengths => 1,
    nmtoken => 1,
    number => 1,
    pixels => 1,
    scope => [qw/col colgroup row rowgroup/],
    script => 1,
    scrolling => [qw/no yes auto/],
    shape => [qw/circle default poly rect/],
    space => ['preserve'],
    styleSheet => 1,
    text => 1,
    tframe => [qw/above below border box hsides lhs rhs void vsides/],
    trules => [qw/all cols groups none rows/],
    uri => 1,
    uriList => 1,
    valueType => [qw/data object ref/],
);

# # den Platzbdearf der Hashes ausgeben
# 
# use Devel::Size;
# my @arr = (
#     Default => \%Default,
#     Element => \%Element,
#     Attribute => \%Attribute,
#     DefaultAttributes => \%DefaultAttributes,
#     DefaultAttributesXhtml => \%DefaultAttributesXhtml,
# );
# my $bytes = 0;
# my $str = '';
# while (@arr) {
#     my $name = shift @arr;
#     my $ref = shift @arr;
#     my $n = Devel::Size::total_size($ref);
#     $bytes += $n;
#     $str .= ', ' if $str;
#     $str .= "%$name: $n";
# }
# warn "$str, Gesamt: $bytes Bytes\n";

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Konstruktor

=head3 new() - Konstruktor

=head4 Synopsis

    $h = $class->new(@keyVal);
    $h = $class->new($htmlVersion,@keyVal);

=head4 Description

Instantiiere ein Objekt zur Generierung von HTML-Code und liefere eine
Referenz auf dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;

    my $self = $class->SUPER::new(%Default);
    if (@_%2) {
        # Wenn ungerade Anzahl Argumente, interpretieren wir
        # das erste Argument als HTML-Version.
        unshift @_,'htmlVersion';
    }
    $self->set(@_);

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 tag() - Generiere HTML-Tag

=head4 Synopsis

    $html = $h->tag($elem,@keyVal); # [1]
    $html = $h->tag($elem,@keyVal,$content); # [2]
    $html = $h->tag($elem,@keyVal,'-',@content); # [3]

=head4 Options

=over 4

=item - (Dash)

Ende der Attribut/Wert-Liste. Die restlichen Argumente werden
zum Inhalt konkateniert.

    $h->tag('p',class=>'p1','-',
        'Ein ',$h->tag('b','kurzer'),' Text.'
    );

Man beachte die Kommata zwischen den Argumenten.

Ohne '-' wird allein das letzte Argument als Inhalt aufgefasst.
Besteht der Inhalt aus mehreren Teilen, müssen die Teile
dann konkateniert werden:

    $h->tag('p',class => 'p1',
        'Ein '.$h->tag('b','kurzer').' Text.'
    );

=item -checkLevel => 0|1|2 (Default: 1)

Umfang der Element-Typ und Attribut-Prüfung.

=item -compact => $bool (Default: Wert des Attributs compact)

Generiere den HTML-Code einzeilig mit so wenig Whitespace wie möglich.
Soll sämtlicher HTML-Code einzeilig erzeugt werden,
genügt es, beim Konstruktor das Attribut compact zu setzen:

    $h = Quiq::Html::Tag->new(...,compact=>1);

=item -contentInd => $n (Default: undef)

Reduziere die Content-Einrückung auf $n, wenn möglich. Im Falle
von undef wird an der Content-Einrückung nichts geändert. Diese
Option ist nützlich, wenn der Content eingerückter Code ist (Tags
<style> und <script>) und dieser auf bei der Seitengenerierung auf
eine geringere Einrücktiefe gebracht werden soll (z.B. von 4 auf 2).

=item -embedImage => $bool (Default: 0)

Bette im Falle eines <img>-Tag das Bild in den HTML-Code ein.

=item -endTagOnly => $bool (Default: 0)

Erzeuge nur den Content und den End-Tag. Diese Option ist nützlich,
wenn der HTML-Code inkrementell geschrieben wird und z.B. im Fehlerfall
nur der Rest mit schließenden Tags generiert werden soll.

    my $html = $h->tag('html',
        -endTagOnly => 1,
        $h->tag('body',
            -endTagOnly => 1,
            '-',
            $h->tag('h1','Fatal Error'),
            $h->tag('pre',$msg),
        )
    );
    $http->append($html);

=item -fmt => 'e'|'m'|'p'|'v'|'i' (Default: richtet sich nach $tag)

Art der Content-Formatierung.

=over 4

=item 'e' (empty)

Element hat keinen Content (br, hr, ...)

<TAG ... />\n

=item 'E' (empty, kein NEWLINE)

Wie 'e', nur ohne NEWLINE am Ende (img, input, ...)

<TAG ... />

=item 'm' (multiline)

Content wird auf eigene Zeile(n) zwischen Begin- und End-Tag
gesetzt und um -ind=>$n Leerzeichen eingerückt. Ist der Content
leer, wird der End-Tag direkt hinter den Begin-Tag gesetzt.
(html, head, body, form, p, div, script, style, ...)

    <TAG ...>
      CONTENT
    </TAG>\n

Ist der Content leer:

    <TAG ...></TAG>

=item 'M' (multiline, ohne Einrückung)

Wie 'm', nur ohne Einrückung (html, ...)

    <TAG ...>
    CONTENT
    </TAG>\n

=item 'c' (cdata)

Wie 'm', nur dass der Content in CDATA eingefasst wird:

    <TAG ...>
      // <![CDATA[
      CONTENT
      // ]]>
    </TAG>

Der W3 HTML Validator bemängelt die Zeichen & und > dann nicht
im Content. (script)

=item 'p' (protect)

Der Content wird geschützt, indem dieser einzeilig gemacht
(LF und CR werden durch &#10; und &#13; ersetzt) und unmittelbar
zwischen Begin- und End-Tag gesetzt wird (pre, textarea, ...).

    <TAG ...>CONTENT</TAG>\n

=item 'P' (protect, Einrückung entfernen)

Wie 'p', nur dass die Einrückung des Content entfernt wird.

=item 'v' (variable)

Ist der Content einzeilig, wird er unmittelbar zwischen Begin-
und End-Tag gesetzt:

    <TAG ...>CONTENT</TAG>\n

Ist der Content mehrzeilig, wird er eingerückt:

    <TAG ...>
      CONTENT
    </TAG>\n

(title, h1-h6, ...)

=item 'i' (inline)

Der Content wird belassen wie er ist. Dies ist der Default für Tags,
die in Fließtext eingesetzt werden. Ein NEWLINE wird nicht angehängt.

    Text Text <TAG ...>Text Text
    Text</TAG> Text Text

(a, b, span, ...)

=back

Bei Wert 0 generiere keinen End-Tag bei leerem Content, sondern

    <TAG .../>

=item -ignoreIf => $bool (Default: 0)

Liefere Leerstring, wenn Bedingung $bool erfüllt ist.

=item -ignoreIfNull => $bool (Default: 0)

Liefere Leerstring, wenn $content null (Leerstring oder undef)
ist. Für verschiedene Tags ist C<< -ignoreIfNull=>1 >> der
Default. Siehe Hash C<%DefaultOptions>. MEMO: Dieser Hash ist
nicht vollständig erstellt und kann (soll) nach Bedarf ergänzt
werden, insbesondere hinsichtlich der Option C<-ignoreIfNull>.
Für zahlreiche weitere Tags dürfte dies ein sinnvoller Default
sein (aber nicht für alle).

=item -ignoreTagIf => $bool (Default: 0)

Liefere $content (ohne Tag), wenn $bool erfüllt ist.

=item -ind => $n (Default: 2)

Rücke $content um $n Leerzeichen ein.

=item -indPos => $n (Default: 0)

Rücke bis auf die erste Zeile den Tag um $n Leerzeichen ein
und entferne Zeilenumbrüche am Ende. Diese Option ist nützlich, wenn
der Tag für einen Platzhalter mit der Einrücktiefe $n
in bestehenden HTML-Code eingesetzt wird.

=item -indTag => $n (Default: 0)

Rücke den Tag um $n Leerzeichen ein.

=item -nl => $n (Default: 1)

Anzahl NEWLINEs am Ende.

-nl => 0 (kein NEWLINE):

    <TAG>CONTENT</TAG>

-nl => 1 (ein NEWLINE):

    <TAG>CONTENT</TAG>\n

-nl => 2 (zwei NEWLINEs):

    <TAG>CONTENT</TAG>\n\n

    usw.

=item -placeholders => \@keyVal (Default: undef)

Ersetze im generierten HTML-Code die angegebenen Platzhalter durch
ihre Werte.

=item -remComments => $bool (Default: 0)

Entferne Kommentare aus dem Content. Die Option berücksichtigt,
ob es sich um HTML-, CSS- oder JavaScript-Content handelt.

=item -remNl => $bool (Default: 0)

Entferne Leerzeilen aus dem Content.

=item -tag => $tag (Default: erstes Argument des Methodenaufrufs)

Mit dieser Option kann der Tag verändert werden. Anwendungsfall:
statt eigentlich beim Aufruf angegebenen td soll ein th-Tag
gesetzt werden. Beispiel:

    $h->tag('td',
        -tag => 'th',
        ...
    );

Siehe: Quiq::Html::Table::Simple

=item -tagWrap => $n (Default: 0)

Brich eine Tag-Zeile um, wenn sie $n Zeichen überschreitet. Wenn 0,
findet kein Umbruch statt. Diese Option ist nützlich, wenn ein Tag lange
Attribute haben kann und dies stört (siehe <embed> in
R1::YouTube::Player).

=item -text => $bool (Default: 0)

Behandele den Content als Text, d.h. schütze &, < und >.

=back

=head4 Description

Generiere HTML-Tag $tag gemäß den Optionen und Attributen @keyVal
und dem Inhalt $content und liefere das Resultat zurück [2].
Der Inhalt kann auch fehlen [1] oder sich über mehrere Argumente
erstrecken [3].

B<Attribut C{style}>

Als Wert des Attributs C<style> kann eine Array-Referenz mit
CSS-Regeln angegeben werden. Diese werden von der
Methode Quiq::Css->rules() aufgelöst.

B<Boolsche Attribute>

Boolsche Attribute werden in HTML ohne Wert und in XHTML mit sich
selbst als Wert generiert.

HTML

    <TAG ... ATTRIBUTE ...>

XHTML

    <TAG ... ATTRIBUTE="ATTRIBUTE" ...>

Boolsche Attribute sind:

    checked
    declare
    defer
    disabled
    ismap
    multiple
    nohref
    noresize
    readonly
    selected

B<Default-Attribute>

Für einige Elemente sind Default-Attribute vereinbart, die nicht
explizit gesetzt werden müssen.

    Element Attribute
    
    form    method => 'post', enctype => 'multipart/form-data'
    script  type => 'text/javascript'
    style   type => 'text/css'

=cut

# -----------------------------------------------------------------------------

# Setze Formatiereigenschaften
# FIXME: Das Bündel *aller* Eigenschaften setzen, da eine Umschaltung
# zwischen beliebigen Status vorkommen kann.

my $setFmtDefaults = sub {
    my ($fmt,$fmtR,$indR,$endTagR,$nlR) = @_;

    $$fmtR = $fmt;
    if ($fmt eq 'i') {
        $$nlR = 0;
    }
    elsif ($fmt eq 'e') {
        $$endTagR = 0;
        $$nlR = 1;
    }
    elsif ($fmt eq 'E') {
        $$fmtR = 'e';
        $$endTagR = 0;
        $$nlR = 0;
    }
    elsif ($fmt eq 'M') {
        $$fmtR = 'm';
        $$indR = 0;
    }
    elsif ($fmt eq 'v') {
        $$nlR = 1;
    }

    return;
};

sub tag {
    my $self = shift;
    my $tag = shift;

    # Defaults

    my ($xhtml,$html5);
    my $htmlVersion = $self->{'htmlVersion'};
    if ($htmlVersion =~ /^html-5/) {
        $html5 = 1;
    }
    elsif ($htmlVersion =~ /^xhtml/) {
        $xhtml = 1;
    }

    my $uppercase = $self->{'uppercase'} && !($xhtml || $html5);
    my $embedImage = $self->{'embedImages'};
    my $checkLevel = $self->{'checkLevel'};
    my $compact = $self->{'compact'};
    my $contentInd = undef;
    my $fmt = 'm';
    my $nl = 1;
    my $ind = 2;
    my $indPos = 0;
    my $indTag = 0;
    my $endTag = 1;
    my $endTagOnly = 0;
    my $ignoreIfNull = 0;
    my $ignoreTagIf = 0;
    my $tagWrap = 0;
    my $remComments = 0;
    my $remNl = 0;
    my $text = 0;
    my $placeholders = undef;

    # Tag-spezifische Defaults

    if ($tag eq 'style' || $tag eq 'script') {
        $remComments = 1;
        $remNl = 1;
        $contentInd = 2;
    }
    
    # Element-Lookup -> elementspezifische Defaults
    # Bei -checkLevel=>0 muss $tag nicht existieren

    my $e = $Element{$tag};
    if ($e) {
        $setFmtDefaults->($e,\$fmt,\$ind,\$endTag,\$nl);
    }

    # Default-Attribute ermitteln (z.B. type="text/css" bei style)

    my (@defAttr,%seenAttr);
    if (my $arr = $DefaultAttributes{$tag}) {
        push @defAttr,@$arr;
    }
    if ($xhtml && (my $arr = $DefaultAttributesXhtml{$tag})) {
        push @defAttr,@$arr;
    }

    # BUG: funktioniert nicht, da spezifizierte Defaultattribute dann
    # mehrfach auftreten
    # if (my $arr = $DefaultAttributes{$tag}) {
    #     unshift @_,@$arr;
    # }
    # if ($xhtml && (my $arr = $DefaultAttributesXhtml{$tag})) {
    #     unshift @_,@$arr;
    # }

    # Tagbezeichner wandeln
    my $tagStr = $uppercase? uc $tag: $tag;

    # Tag generieren

    my $str = '';

    # Optionen und Attribute verarbeiten

    if (my $arr = $DefaultOptions{$tag}) {
        unshift @_,@$arr;
    }

    while (@_) {
        if (@_ == 1) {
            # Letztes Argument ist Content. Dieser Test muss als erstes
            # kommen, damit '-' als Content nicht unter den Tisch fällt.
            last;
        }
        elsif (defined $_[0] && $_[0] eq '-') {
            # explizites Ende der Options- und Attributliste
            shift; # '-' konsumieren
            last;
        }
        elsif (ref $_[0]) {
            # Argument ist (Array-)Referenz
            last;
        }

        my $key = shift;
        my $val = shift;

        if (substr($key,0,1) eq '-') {
            # FIXME: Fallunterscheidungen durch Hash-Lookup ersetzen
    
            if ($key eq '-nl') {
                $nl = $val;
            }
            elsif ($key eq '-fmt') {
                $setFmtDefaults->($val,\$fmt,\$ind,\$endTag,\$nl);
            }
            elsif ($key eq '-ind') {
                if (defined $val) {
                     $ind = $val;
                }
            }
            elsif ($key eq '-indTag') {
                $indTag = $val;
            }
            elsif ($key eq '-indPos') {
                $indPos = $val;
            }
            elsif ($key eq '-ignoreIf') {
                # sofortiger Abbruch
                return '' if $val;
            }
            elsif ($key eq '-ignoreIfNull') {
                $ignoreIfNull = $val;
            }
            elsif ($key eq '-ignoreTagIf') {
                $ignoreTagIf = $val;
            }
            elsif ($key eq '-checkLevel') {
                $checkLevel = $val;
            }
            elsif ($key eq '-tagWrap') {
                $tagWrap = $val;
            }
            elsif ($key eq '-text') {
                $text = $val;
            }
            elsif ($key eq '-endTagOnly') {
                $endTagOnly = $val;
            }
            elsif ($key eq '-embedImage') {
                $embedImage = $val;
            }
            elsif ($key eq '-contentInd') {
                $contentInd = $val;
            }
            elsif ($key eq '-remComments') {
                $remComments = $val;
            }
            elsif ($key eq '-remNl') {
                $remNl = $val;
            }
            elsif ($key eq '-compact') {
                $compact = $val;
            }
            elsif ($key eq '-placeholders') {
                $placeholders = $val;
            }
            elsif ($key eq '-tag') {
                if (defined($val) && $val ne '') {
                    $tag = $val;
                    $tagStr = $uppercase? uc $tag: $tag;
                }
            }
            else {
                $self->throw(
                    'HTML-00001: Unbekannte Option',
                    Option => $key,
                    Value => $val,
                );
            }
            next;
        }
        elsif ($key eq 'data' && Scalar::Util::reftype($val)) {
            # data-* Attribute als Liste data=>\@keyVal
    
            my @keyVal;
            for (my $i = @$val-2; $i >= 0; $i -= 2) {
                unshift @_,'data-'.$val->[$i],$val->[$i+1];
            }
            next;
        }
    
        if ($endTagOnly) {
            $self->throw(
                'HTML-00004: Attribute bei Option -endTagOnly nicht erlaubt',
                Tag => $tag,
                Attribute => $key,
                Value => $val,
            );
        }

        # Attribut-Lookup. Attribut data-* ist generell erlaubt.

        my $dom = $Attribute{$key} || '';
        if (!$dom && $checkLevel && $key !~ /^data-/) {
            $self->throw(
                'HTML-00003: Unbekanntes Attribut',
                Tag => $tag,
                Attribute => $key,
                Value => $val,
            );
        }

        # Attribut/Wert-Paar

        if ($key eq 'style' && ref($val)) {
            # liefert undef, wenn Array leer ist
            $val = Quiq::Css->rules(@$val);
        }
        if (defined $val) {
            if ($checkLevel >= 2) {
                $self->checkValue($dom,$val);
            }

            if ($tag eq 'img' && $key eq 'src') {
                $val = $self->imgSrcValue($val,$embedImage);
            }
            else {
                $val =~ s/"/&quot;/g; # FIXME: auf best. Domänen einschränken
            }

            $key = uc $key if $uppercase;

            if ($dom eq 'bool') {
                if ($val) {
                    $str .= $xhtml || $html5? qq| $key="$key"|: " $key";
                }
            }
            else {
                $str .= qq| $key="$val"|;
            }

            # Gesetzte Attribute merken, falls wir Defaultattribute haben

            if (@defAttr) {
                $seenAttr{$key}++;
            }
        }
    }

    # Defaultattribute hinzufügen, die nicht gesetzt wurden

    if (@defAttr && !$endTagOnly) {
        for (my $i = 0; $i < @defAttr; $i += 2) {
            if (!$seenAttr{$defAttr[$i]}) {
                $str .= sprintf ' %s="%s"',$defAttr[$i],$defAttr[$i+1];
            }
        }
    }

    # Attribute für kompakte Darstellung einstellen

    if ($compact) {
        if (lc($fmt) ne 'p') {
            $fmt = 'i';
        }
        $ind = 0;
        $nl = 0;
        $remComments = 1;
    }

    if (!$endTagOnly) {
        $str = "<$tagStr$str";
    }

    # Tag umbrechen

    if ($tagWrap && length($str) > $tagWrap) {
        $str = $self->wrapTag($tagWrap,$str);
    }

    # Element prüfen

    if (!$e && $checkLevel) {
        $self->throw('HTML-00002: Unbekanntes Element',Element=>$tag);
    }

    # Content bestimmen
    my $content = $self->cat(@_);

    # Klauseln auswerten, die auf den Content bezug nehmen

    if ($ignoreIfNull && (!defined $content || $content eq '')) {
        return '';
    }

    if ($placeholders) {
        # Platzhalter ersetzen

        my $tpl = Quiq::Template->new('text',\$content);
        $tpl->replace(@$placeholders);
        $content = $tpl->asStringNL;
    }
    if ($text) {
        # Content ist Text, wir schützen &, <, >

        $content =~ s/&/&amp;/g;
        $content =~ s/</&lt;/g;
        $content =~ s/>/&gt;/g;
    }
    if ($remNl) {
        $content =~ s/^(\s*)\n//mg;
    }
    if ($remComments) {
        if ($tag eq 'script') {
            $content = Quiq::String->removeComments($content,'//');
        }
        elsif ($tag eq 'style') {
            $content = Quiq::String->removeComments($content,'/*','*/');
        }
        else { # HTML
            $content = Quiq::String->removeComments($content,'<!--','-->');
        }
    }
    if ($compact) {
        $content =~ s/^\s+//g;
        $content =~ s/\s+$//g;

        if ($tag eq 'script') {
            $content =~ s/\n\s*/ /g; # Whitespace nur zwischen Zeilen kompr.
        }
        elsif ($tag eq 'style') {
            $content =~ s/\s+/ /g;
        }
        else { # HTML
            $content =~ s/\s+/ /g;
        }
    }

    if ($ignoreTagIf) {
        return $content;
    }

    # Content bearbeiten

    if ($fmt eq 'p' || $fmt eq 'P') {
        Quiq::String->removeIndentation(\$content) if $fmt eq 'P';
        $content =~ s/\x0a/&#10;/g;
        $content =~ s/\x0d/&#13;/g;
    }
    elsif ($fmt eq 's') {
        # Inhalt einzeilig machen durch Whitespace-Manipulation
        $self->throw('Not implemented');
    }
    elsif ($fmt eq 'e' || $fmt eq 'E') {
        if (length $content) {
            $self->throw('HTML-00003: Kein Content erwartet');
        }
    }
    elsif ($fmt eq 'v' && $content !~ /\n/ || $fmt eq 'i') {
        # nichts tun
    }
    elsif ($fmt eq 'v' || $fmt eq 'm' || $fmt eq 'c') {
        Quiq::String->removeIndentation(\$content);
        if ($contentInd) {
            # Bringe Einrückung des Content auf Tiefe $contendInd
            Quiq::String->reduceIndentation($contentInd,\$content);
        }
        if ($fmt eq 'c' && $content =~ tr/&<>//) {
            # Script-Code in CDATA einfassen, wenn &, < oder > enthalten
            $content = "// <![CDATA[\n$content\n// ]]>";
            # Folgendes geht nicht!
            # $content =~ s/&/&amp;/g;
            # $content =~ s/</&lt;/g;
        }
        if (defined(my $forceIndent = $self->{'indentation'})) {
            $ind = $forceIndent;
        }
        if ($ind) {
            my $space = ' ' x $ind;
            $content =~ s/^(?!$)/$space/gm; # Nicht-Leerzeilen einrücken
        }
        # MEMO: Test auf 'c', damit 'script' mit src nicht mehrzeilig wird
        $content = $content? "\n$content\n": ''; # $fmt eq 'c'? '': "\n";
    }
    else {
        $self->throw(
            'HTML-00002: Unerlaubter Wert für Option -fmt',
            Value => $fmt,
        );
    }

    # End-Tag

    if ($endTag || $content) {
        if ($endTagOnly) {
            $content =~ s/^\n+//;
        } else {
            $str .= '>';
        }
        $str .= "$content</$tagStr>";
    }
    else {
        $str .= $xhtml || $html5? ' />': '>';
    }

    if ($indPos) {
        # Einrückung erzeugen
        my $space = ' ' x $indPos;
        $str =~ s/^(?!$)/$space/gm; # Nicht-Leerzeilen einrücken
        # Einrückung erste Zeile entfernen
        $str =~ s/^$space//;
    }
    else {
        # NEWLINE
        $str .= "\n" x $nl;
    }

    if ($indTag) {
        # Einrückung erzeugen
        my $space = ' ' x $indTag;
        $str =~ s/^(?!$)/$space/gm; # Nicht-Leerzeilen einrücken
    }

    return $str;
}

# -----------------------------------------------------------------------------

=head3 wrapTag() - Umbreche langen Tag-String

=head4 Synopsis

    $str = $this->wrapTag($maxWidth,$str);

=cut

# -----------------------------------------------------------------------------

sub wrapTag {
    my ($this,$max,$tag) = @_;

    my $str = '';
    my $tmp = '';
    for my $val (split / (?=\w+=".*?")/,$tag) {
        my $l = length $val;
        if (length($tmp)+length($val) <= $max) {
            if ($tmp) {
                $tmp .= ' ';
            }
            $tmp .= $val;
        }
        else {
            if ($str) {
                $str .= "\n  ";
            }
            $str .= $tmp;
            $tmp = $val;
        }
    }
    if ($tmp) {
        $str .= "\n  $tmp";
    }

    return $str;
}

# -----------------------------------------------------------------------------

=head3 cat() - Füge HTML-Fragmente zusammen

=head4 Synopsis

    $html = $h->cat(@opt,@args);

=head4 Options

=over 4

=item -join => $str (Default: '')

Verwende $str als Trenner zwischen den Fragmenten.  Diese Option
ist praktisch, wenn die Fragmente optional sind und die
auftretenden Elemente durch eine Zeichenkette voneinander getrennt
werden sollen. Beispiel: Eine Icon-Leiste, deren Zusammensetzung
nicht festgelegt ist und die nicht direkt aneinander stoßen
sollen, sondern durch Leerzeichen getrennt werden.

=item -placeholders => \@keyVal (Default: undef)

Ersetze im generierten HTML-Code die angegebenen Platzhalter durch
ihre Werte.

=back

=head4 Description

Füge die HTML-Fragmente @args zusammen und liefere den
resultierenden HTML-Code zurück.

@args ist eine Abfolge von Array-Referenzen und/oder Zeichenketten.

Der Aufruf

    $h->cat(
        ['doctype'],
        ['comment',-nl=>2,'Copyright Lieschen Müller'],
        ['HTML',
            ['HEAD',
                ['TITLE','Meine Homepage'],
                ['STYLE',q|
                    .text { color: red; }
                |],
            ],
            ['BODY',
                ['H1','Hallo Welt!'],
                ['P',class=>'text',q|
                    Ich heiße Lieschen Müller und dies
                    ist meine Homepage.
                |],
            ],
        ]
    );

ist äquivalent zu

    $h->cat(
        $h->doctype,
        $h->comment(-nl=>2,'Copyright Lieschen Müller'),
        $h->tag('html','-',
            $h->tag('head','-',
                $h->tag('title','Meine Homepage'),
                $h->tag('style',q|
                    .text { color: red; }
                |),
            ),
            $h->tag('body','-',
                $h->tag('h1','Hallo Welt!'),
                $h->tag('p',class=>'text',q|
                    Ich heiße Lieschen Müller und dies
                    ist meine Homepage.
                |),
            ),
        ),
    );

Beide liefern

    <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
      "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
    
    <!-- Copyright Lieschen Müller -->
    
    <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
      <title>Meine Homepage</title>
      <style type="text/css">
        .text { color: red; }
      </style>
    </head>
    <body>
    <h1>Hallo Welt!</h1>
    <p class="text">
      Ich heiße Lieschen Müller und dies
      ist meine Homepage.
    </p>
    </body>
    </html>

=cut

# -----------------------------------------------------------------------------

sub cat {
    my $self = shift;

    # Optionen

    my $join = '';
    my $placeholders = undef;

    while (@_) {
        if (!defined($_[0]) || substr($_[0],0,1) ne '-') {
            # Ende der Optionen
            last;
        }
        elsif ($_[0] eq '-') {
            # explizites Ende der Options-Liste
            shift; # '-' konsumieren
            last;
        }
        elsif ($_[0] eq '-join') {
            $join = splice @_,0,2;
            next;
        }
        elsif ($_[0] eq '-placeholders') {
            $placeholders = splice @_,0,2;
            next;
        }
        #else {
        #    $self->throw(
        #        'HTML-00002: Unbekannte Option',
        #        Option=>$_[0],
        #    );
        #}
        last;
    }

    # Werte ermitteln und konkatenieren

    my @arr;
    for my $e (@_) {
        if (ref $e) { # Argument ist (Array-)Referenz
            if ($e->[0] =~ /^[[:upper:]]/) {
                # Namen beginnt mit Großbuchstaben -> Tag
                push @arr,$self->tag(lc $e->[0],@$e[1..$#$e]);
            }
            else {
                # Kleinbuchstabe -> Methode
                my $meth = $e->[0];
                push @arr,$self->$meth(@$e[1..$#$e]);
            }
        }
        else {
            push @arr,defined($e) && $e ne ''? $e: ();
        }
    }
    my $html = join $join,@arr;

    # Platzhalter ersetzen

    if ($placeholders) {
        my $tpl = Quiq::Template->new('text',\$html);
        $tpl->replace(@$placeholders);
        $html = $tpl->asStringNL;
    }

    return $html;
}

# -----------------------------------------------------------------------------

=head3 doctype() - <!DOCTYPE>-Tag

=head4 Synopsis

    $str = $h->doctype(@opt);

=head4 Options

=over 4

=item -frameset => $bool (Default: 0)

Liefere Frameset-Doctype.

=item -nl => $n (Default: 2)

Ergänze Doctype um $n Zeilenumbrüche.

=back

=head4 Description

Liefere <!DOCTYPE>-Tag:

    <!DOCTYPE ...>

Der Tag ergibt sich aus der eingestellten HTML-Variante.

=cut

# -----------------------------------------------------------------------------

sub doctype {
    my $self = shift;

    my $compact = $self->{'compact'};
    my $frameset = 0;
    my $nl = 2;

    while (@_) {
        my $key = shift;

        if ($key eq '-compact') {
            $compact = shift;
        }
        elsif ($key eq '-frameset') {
            $frameset = shift;
        }
        elsif ($key eq '-nl') {
            $nl = shift;
        }
        else {
            $self->throw(
                'HTML-00001: Unbekannte Option',
                Option => $key,
                Value => shift,
            );
        }
    }

    if ($compact) {
        $nl = 0;
    }

    my $version = $self->{'htmlVersion'};

    my $str;
    if ($version eq 'xhtml-1.0' && !$frameset) {
        $str = q|<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"|;
        if (!$compact) {
            $str .= "\n ";
        }
        $str .= q| "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">|;
    }
    elsif ($version eq 'xhtml-1.0' && $frameset) {
        $str = q|<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Frameset//EN"|;
        if (!$compact) {
            $str .= "\n ";
        }
        $str .= q| "http://www.w3.org/TR/xhtml1/DTD/xhtml1-frameset.dtd">|;
    }
    elsif ($version eq 'html-4.01' && !$frameset) {
        $str = q|<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01|;
        if (!$compact) {
            $str .= "\n ";
        }
        $str .= q| Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">|;
    }
    elsif ($version eq 'html-5') { # && !$frameset) {
        $str = q|<!DOCTYPE html>|;
    }
    else {
        $self->throw(
            'HTML-00002: Unbekannte HTML-Version',
            Version => "'$version'",
        );
    }

    $str .= "\n" x $nl;
    
    return $str;
}

# -----------------------------------------------------------------------------

=head3 comment() - Kommentar-Tag

=head4 Synopsis

    $html = $h->comment(@keyVal,$content);

=head4 Options

Wie Methode tag()

=head4 Description

Liefere HTML Kommentar-Tag:

    <!-- TEXT -->

bzw.

    <!--
      TEXT
    -->

wenn TEXT mehrzeilig ist.

=cut

# -----------------------------------------------------------------------------

sub comment {
    my $self = shift;
    return '' if !defined $_[-1] || $_[-1] eq ''; # kein Kommentar, wenn leer
    my $str = $self->tag('COMMENT',-checkLevel=>0,-fmt=>'v',@_);    
    $str =~ s|^<COMMENT[^>]*>(\s?)|'<!--'.($1? $1: ' ')|e;
    $str =~ s|(\s?)</COMMENT>|($1? $1: ' ').'-->'|e;
    return $str;
}

# -----------------------------------------------------------------------------

=head3 protect() - Schütze HTML Metazeichen

=head4 Synopsis

    $html = $h->protect($text);

=head4 Description

Schütze alle Metazeichen in Text $text, so dass das Resultat
gefahrlos in den Content eines HTML-Tag eingesetzt werden kann.

=cut

# -----------------------------------------------------------------------------

sub protect {
    my ($self,$text) = @_;

    if (defined $text) {
        $text =~ s/&/&amp;/g;
        $text =~ s/</&lt;/g;
        $text =~ s/>/&gt;/g;
    }
    
    return $text;
}

# -----------------------------------------------------------------------------

=head3 optional() - Optional-Klammer: <!--optional-->...<!--/optional-->

=head4 Synopsis

    $html = $h->optional(@keyVal,$content);

=head4 Description

Liefere optional-Klammer:

    <!--optional-->...<!--/optional-->

bzw.

    <!--optional-->
    ...
    <!--/optional-->

wenn $content mehrzeilig ist.

=cut

# -----------------------------------------------------------------------------

sub optional {
    my $self = shift;
    my $content = pop;
    # @_: @keyVal

    # Optionen

    my $nl = 0;
    while (@_) {
        my $key = shift;
        my $val = shift;
        
        if ($key eq '-nl') {
            $nl = $val;
        }
        else {
            $self->throw(
                'HTML--0001: Unbekannte Option',
                Option => $key,
                Value => $val,
            );
        }
    }

    # Generieren

    my $str;
    if (!defined($content) || $content eq '') {
        # kein Content
        $str = '';
    }
    elsif ($content !~ tr/\n//) {
        # Content ist einzeilig
        $str = "<!--optional-->$content<!--/optional-->";
    }
    else {
        # Content ist mehrzeilig
        $str = "<!--optional-->\n$content<!--/optional-->\n";
    }

    if ($str && $nl) {
        $str .= "\n" x $nl;
    }
    
    return $str;
}

# -----------------------------------------------------------------------------

=head3 checkValue() - Prüfe Attributwert

=head4 Synopsis

    $h->checkValue($dom,$val);

=head4 Description

Prüfe, ob der Attributwert $val für Domäne $dom korrekt ist.
Fällt die Prüfung negativ aus, löse eine Exception aus.
Die Methode liefert keinen Wert zurück.

=cut

# -----------------------------------------------------------------------------

sub checkValue {
    my ($self,$dom,$val) = @_;

    # FIXME: Wertprüfungen implementieren

    return;
}

# -----------------------------------------------------------------------------

=head3 imgSrcValue() - Liefere Wert für scr-Attribut eines Bildes

=head4 Synopsis

    $val = $this->imgSrcValue($val,$embedImage);

=cut

# -----------------------------------------------------------------------------

sub imgSrcValue {
    my ($this,$val,$embedImage) = @_;

    if (ref $val) {
        # Bilddaten in-memory
        my $type = Quiq::Image->type($val,-enum=>1);
        $val = sprintf 'data:image/%s;base64,%s',$type,
            MIME::Base64::encode_base64($$val,'');
    } elsif ($embedImage) {
        if (-f $val) {
            # lokale Bilddatei
            my $type = Quiq::Image->type($val,-enum=>1);
            $val = sprintf 'data:image/%s;base64,%s',$type,
                MIME::Base64::encode_base64(
                    Quiq::Path->read($val),'');
        }
        else {
            warn 'WARNING: <img> Embedding of URL-Image'.
                " currently not supported: $val\n";
        }
    }

    return $val;
}

# -----------------------------------------------------------------------------

=head3 import() - Setze Konstruktor-Defaults der Klasse

=head4 Synopsis

    $class->import(@keyVal);

=head4 Description

Setze die Konstruktor-Defaults @keyVal der Klasse. Die Setzung gilt
für alle folgenden Konstruktor-Aufrufe, bei denen die betreffenden Werte
beim Konstruktor-Aufruf nicht gesetzt werden.
Die Methode liefert keinen Wert zurück.

=head4 Example

=over 4

=item XHTML (Default):

    use Quiq::Html::Tag;

=item HTML (Großschreibung) statt XHTML generieren:

    use Quiq::Html::Tag(htmlVersion=>'html-4.01',uppercase=>1);

=back

=cut

# -----------------------------------------------------------------------------

sub import {
    my $class = shift;
    # @_: @keyVal

    while (@_) {
        my $key = shift;
        $Default{$key} = shift;
    }

    return;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.151

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
