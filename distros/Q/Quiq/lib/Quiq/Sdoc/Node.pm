package Quiq::Sdoc::Node;
use base qw/Quiq::Hash/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = 1.132;

use Quiq::Array;
use Quiq::Converter;
use Quiq::Hash;
use Quiq::Pod::Generator;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Sdoc::Node - Basisklasse für die Knoten eines Sdoc-Dokuments (abstrakt)

=head1 BASE CLASS

L<Quiq::Hash>

=head1 DESCRIPTION

Die Klasse dient als Basisklasse für die Knotenklassen eines
Sdoc-Dokuments. Jede Knotenklasse repräsentiert einen speziellen
Elementtyp. Folgende Elementtypen existieren:

    Document
    Section
    List
    Item
    Paragraph
    Quote
    Code
    PageBreak

=head1 METHODS

=head2 Accessors

=head3 parent() - Liefere/Setze Elternknoten

=head4 Synopsis

    $node = $doc->parent;
    $node = $doc->parent($node);

=head4 Description

Liefere/Setze den Elternknoten. Die Referenz wird als schwache
Referenz gespreichert, so dass eine Destrukturierung des
Elternknotens durch die Referenz nicht verhindert wird.

=cut

# -----------------------------------------------------------------------------

sub parent {
    my $self = shift;

    if (@_) {
        $self->{'parent'} = shift;
        $self->weaken('parent');
    }

    return $self->{'parent'};
}

# -----------------------------------------------------------------------------

=head3 childs() - Liste der Kindknoten

=head4 Synopsis

    @arr|$arr = $doc->childs;

=head4 Description

Liefere die Liste der Kindknoten. Im Skalarkontext liefere eine
Referenz auf die Liste.

=cut

# -----------------------------------------------------------------------------

sub childs {
    my $self = shift;
    return wantarray? @{$self->{'childs'}}: $self->{'childs'};
}

# -----------------------------------------------------------------------------

=head3 title() - Liefere den Titel des Knotens

=head4 Synopsis

    $title = $node->title;

=head4 Description

Liefere den Titel des Knotens. Hat der Knoten keinen Titel - weil dieser
nicht definiert ist oder der Knoten dieses Attribut nicht besitzt -
liefere einen Leerstring.

Anmerkung: Bestimmte Knotenklassen (Dokument, Definitionslisten-Element)
überschreiben diese Methode.

=cut

# -----------------------------------------------------------------------------

sub title {
    return shift->try('title') || '';
}

# -----------------------------------------------------------------------------

=head2 Methods

=head3 nextType() - Liefere Typ des nächsten Elements

=head4 Synopsis

    ($type,$attibuteA) = $parent->nextType($doc);

=head4 Description

Analysiere die nächste nichtleere Zeile in LineProcessor $doc
(Leerzeilen am Anfang werden von der Methode entfernt)
hinsichtlich ihres Elementtyps und liefere die
Typbezeichnung und Attribute - sofern spezifiziert - zurück.

Folgende Elementtypen werden unterschieden:

=over 4

=item Section

Ein oder mehrere = am Zeilenanfang gefolgt von einem Leerzeichen.
Zusätzlich zur Typbezeichnung wird der Level der Section geliefert.

=item List

Wird mit dem ersten Item geliefert.

=item Item

Zeile, die von $ln->item() als Item identifiziert wird.

=item Table

Wird mit der ersten Row geliefert.

=item Row

Zeile mit | am Anfang und am Ende.

=item Code

Zeile mit Leerzeichen oder | am Anfang.

=item Quote

Zeile mit > am Anfang.

=item PageBreak

Zeile mit ~~~ (mindestens drei Tilden) am Anfang.

=item Paragraph

Zeile, auf die keine der obigen Eigenschaften zutrifft.

=back

=cut

# -----------------------------------------------------------------------------

sub nextType {
    my ($self,$doc) = @_;

    $doc->removeEmptyLines; # Leerzeilen überlesen

    my $line = $doc->lines->[0];
    my $type = $line->type;

    my $arr = [];
    if ($type eq 'Object') {
        ($type,$arr) = $self->parseObjectSpec($doc);
    }

    if ($type eq 'Item') {
        # Wenn das nächste Element ein Item ist, prüfen wir, ob
        # es das erste Item einer Liste ist (es gibt noch keine
        # Liste oder eine Liste eines anderen Typs). Wenn ja,
        # liefern wir anstelle des Typs Item den Typ Liste.
        # Die Prüfung auf den itemType sorgt dafür, dass wenn
        # mehrere verschiedenartige Listen aufeinander folgen,
        # diese nicht zu einer Liste verschmolzen werden.

        my ($itemType) = $line->item;
        if (!$self->isa('Quiq::Sdoc::List') ||
                $self->{'itemType'} ne $itemType) {
            $type = 'List';
        }
    }
    elsif ($type eq 'Row') {
        # Wenn das nächste Element eine Row ist, prüfen wir, ob
        # es die erste Row einer Tabelle ist. Wenn ja,
        # liefern wir anstelle des Typs Row den Typ Table.

        if (!$self->isa('Quiq::Sdoc::Table')) {
            $type = 'Table';
        }
    }
    elsif ($type eq 'KeyValRow') {
        # dasselbe Prinzip wie bei Row

        if (!$self->isa('Quiq::Sdoc::KeyValTable')) {
            $type = 'KeyValTable';
        }
    }

    return ($type,Quiq::Array->new($arr));
}

# -----------------------------------------------------------------------------

=head3 parseObjectSpec() - Liefere Information zu Objektspezifikation

=head4 Synopsis

    ($type,$arr) = $node->parseObjectSpec($doc);

=head4 Description

Parse Objektspezifikation auf $doc und liefere den Typ und
die Attribut/Wert-Paare des Objekts zurück.

=cut

# -----------------------------------------------------------------------------

sub parseObjectSpec {
    my ($self,$doc) = @_;

    my $line = $doc->shiftLine;
    my ($type,$str) = $line->text =~ /%(\w+):(.*)/;

    my $n = $line->indentation;
    if ($n || $type eq 'Code') {
        $str .= " indentation=$n";
    }

    while (@{$doc->lines}) {
        $line = $doc->lines->[0];
        # Wenn keine tiefere Einrückung oder Anfang ist nicht KEY=
        if ($line->indentation <= $n || $line->text !~ /^\s+\w+=/) {
            last;
        }
        $str .= $doc->shiftLine->text;
    }
    my $arr = Quiq::Converter->stringToKeyVal($str);

    return ($type,$arr);
}

# -----------------------------------------------------------------------------

=head3 anchors() - Liefere Zeichenkette aus allen Ankern

=head4 Synopsis

    $str = $node->anchors($format,@args);

=head4 Description

Liefere die Zeichenkette aus allen Ankern zur Einbettung in das
Dokument.

=cut

# -----------------------------------------------------------------------------

sub anchors {
    my $self = shift;
    my $format = shift;
    # @_: @args

    my $str = '';
    if ($format =~ /^e?html$/) {
        my $h = shift;
        if (my $aH = $self->{'anchors'}) {
            for my $key ($aH->keys) {
                $str .= $self->anchorSegment($format,$key,$h);
            }
        }
    }

    return $str;
}

# -----------------------------------------------------------------------------

=head3 dumpChilds() - Erzeuge Repräsentation für Subelemente

=head4 Synopsis

    $str = $node->dumpChilds($format,@args);

=head4 Description

Erzeuge eine externe Repräsentation im Format $format für die
Subelemente des Knotens und liefere diese zurück. Dies ist eine
Hilfsmethode, die von den Subkalssenmethoden $node->dump() gerufen
wird um die externe Repräsentation eines Knotens zu erzeugen.

Elementtypen mit Subelementen (in Klammern die erlaubten Subelemente):

    Document (alle Typen)
    Section (alle Typen)
    List (nur Items)
    Item (alle Typen)
    Table (nur Rows)

Elementtypen ohne Subelemente:

    Paragraph
    Code
    Quote
    PageBreak
    Row

=cut

# -----------------------------------------------------------------------------

sub dumpChilds {
    my $self = shift;
    my $format = shift;
    # @_: @args

    my $str = '';
    for my $node (@{$self->{'childs'}}) {
        $str .= $node->dump($format,@_);
    }

    if ($format eq 'debug') {
        $str =~ s/^/  /gm if $str;
    }

    return $str;
}

# -----------------------------------------------------------------------------

=head3 rootNode() - Liefere Wurzelknoten

=head4 Synopsis

    $root = $node->rootNode;

=cut

# -----------------------------------------------------------------------------

sub rootNode {
    my $self = shift;

    while ($self->parent) {
        $self = $self->parent;
    }

    return $self;
}

# -----------------------------------------------------------------------------

=head3 select() - Selektiere Knoten

=head4 Synopsis

    @nodes|$nodeA = $node->select(@keyVal);

=head4 Description

Selektiere alle Knoten ab und einschließlich Knoten $node, die die
Kriterien @keyVal erfüllen und liefere die Liste dieser Knoten zurück.
Im Skalarkontext liefere eine Referenz auf die Liste.

Ist kein Kriterium angegeben, liefere alle Knoten.

=cut

# -----------------------------------------------------------------------------

sub select {
    my $self = shift;
    my %att = @_;

    my $match = 1;
    while (my ($key,$val) = each %att) {
        # Wenn ein Kriterium nicht anwendbar ist oder nicht
        # übereinstimmt, trifft das Suchkriterium auf
        # den Knoten nicht zu.

        if (!$self->exists($key) || $self->get($key) ne $val) {
            $match = 0;
            last;
        }
    }

    my $nodes = [];
    push @$nodes,$self if $match;

    if ($self->exists('childs')) {
        for my $node ($self->childs) {
            push @$nodes,$node->select(@_);
        }
    }

    return wantarray? @$nodes: $nodes;
}

# -----------------------------------------------------------------------------

=head3 expand() - Schütze Metazeichen und ersetze Inline-Segmente

=head4 Synopsis

    $newVal = $sdoc->expand($format,$val,$inlineSegments,@args);

=head4 Description

Ersetze in $val die Metazeichen des Zielformats $format (<, >, &
im Falle von HTML) und liefere das Resultat zurück.
Ist $inlineSegments wahr, expandiere zusätzlich die
Sdoc Inline-Segmente.

B<Inline-Segmente>

Folgende Inline-Segmente sind definiert:

    B{...} bold
    C{...} constant width
    I{...} italic
    Q{...} quote
    U{...} URL (Link auf eine Webseite)
    G{...} Grafik/Bild

In Code-Abschnitten sollte keine Inline-Ersetzung stattfinden.

=cut

# -----------------------------------------------------------------------------

# FIXME: eigene Methodendefinition

sub graphicSegment {
    my $self = shift;
    my $format = shift;
    my $str = shift;
    # @_: @args

    my $attH = Quiq::Hash->new(
        width=>undef,
        height=>undef,
        title=>undef,
        anchor=>undef,
        border=>undef,
        style=>undef,
        class=>undef,
        url=>undef,
    );
    # $attH->lockKeys;

    my $src = $str;
    if ($str =~ s/^"(.*?)"//) {
        $src = $1;
        $attH->set($str =~ /(\w+)="(.*?)"/g);
    }

    my $anchor = $attH->{'anchor'} || '';
    if (!$anchor) {
        $anchor = $attH->{'title'};
        if (!$anchor) {
            $anchor = $src;
        }
    }
    $anchor =~ s/\W+/_/g;

    if ($format =~ /^e?html/) {
        my $h = shift;

        my $cssPrefix = $self->rootNode->get('cssPrefix');
        my $url = $attH->{'url'};

        return $h->cat(
            $h->tag('a',
                -ignoreIf=>!$anchor,
                id=>$anchor,
            ),
            $h->tag('a',
                -ignoreTagIf=>!$url,
                href=>$url,
                '-',
                $h->tag('img',
                    class=>"$cssPrefix-seg-g",
                    src=>$src,
                    width=>$attH->{'width'},
                    height=>$attH->{'height'},
                    style=>$attH->{'style'},
                    alt=>$attH->{'title'},
                    title=>$attH->{'title'},
                    border=>$attH->{'border'},
                )
            ),
        );
    }

    return "GRAPHIC: $src";
}

sub urlSegment {
    my $self = shift;
    my $format = shift;
    my $type = shift; # 'U'
    my $str = shift;
    # @_: @args

    # Innere Zeilenumbrüche entfernen

    my $attH = Quiq::Hash->new(
        text=>undef,
        target=>undef,
        noPodUrl=>0,
    );

    my $url = $str;
    if ($str =~ s/^"(.*?)"//) {
        $url = $1;
        $attH->set($str =~ /(\w+)="(.*?)"/g);
    }

    # Wenn U{TEXT} (d.h. kein Schema am Anfang, keine Extension am
    # Ende), schlagen wir die Link-Definition (%Link:) mit TEXT nach
    # und kopieren dessen Eigenschaften

    if ($url !~ /^[a-z]+:/ && $url !~ /\.[a-z]+$/) {
        $url =~ s/\n\s*/ /g; # innere Zeilenumbrüche durch ein Space ersetzen
        my $lnk = $self->rootNode->links->get($url);
        if (!$lnk) {
            $self->throw(
                q~SDOC-00005: Link ist nicht definiert~,
                Link=>$url,
            );
        }
        $attH->set(text=>$url);
        $url = $lnk->url;
    }

    my $text = $attH->{'text'};
    if ($format =~ /^e?html/) {
        my $h = shift;

        my $cssPrefix = $self->rootNode->get('cssPrefix');

        return $h->tag('a',
            class=>"$cssPrefix-seg-u",
            href=>$url,
            target=>$attH->{'target'},
            $text || $url,
        );
    }
    elsif ($format eq 'pod') {
        if ($text) {
            if ($attH->{'noPodUrl'}) {
                return "L<$text>";
            }
            return "L<$text|$url>";
        }
        return "L<$url>";
    }
    elsif ($text) { # sonstige Formate
        return $text;
    }

    return $url;
}

sub linkSegment {
    my $self = shift;
    my $format = shift;
    my $type = shift; # 'L' oder 'l'
    my $str = shift;
    # @_: @args

    my $attH = Quiq::Hash->new(
        text=>undef,
    );
    # $attH->lockKeys;

    my $anchor = $str;
    if ($str =~ s/^"(.*?)"//) {
        $anchor = $1;
        $attH->set($str =~ /(\w+)="(.*?)"/g);
    }
    $anchor =~ s/\s+/ /g; # wandele \n und Folgen von WS-Zeichen in Leerz.
    my $anchorCanonized = $self->canonizeAnchor($anchor);

    my $arr = $self->rootNode->get('anchorsGlob')->get($anchorCanonized);
    if (!$arr) {
        warn "WARNING: Anker nicht gefunden: $anchor\n";
        return '[ANCHOR NOT FOUND]'; # FIXME
    }
    elsif (@$arr > 1) {
        warn "WARNING: Anker ist nicht eindeutig: $anchor\n";
        # return '[ANCHOR NOT UNIQUE]'; # FIXME
    }

    my $text = $attH->{'text'} || do {
        my $str;
        if ($type eq 'L') {
            my $node = $arr->[0];

            # Linktext als Titel-Pfad

            $str = $node->title;

            for (my $p = $node->parent; $p; $p = $p->parent) {
                if (my $key = $p->try('key')) {
                    $str = $p->title.'/'.$str;
                }
            }
        }
        else {
            # Linktext als Anker-Pfad

            #$str = $node->try('key') || $node->try('anchor') ||
            #    $node->title;

            #for (my $p = $node->parent; $p; $p = $p->parent) {
            #    if (my $key = $p->try('key')) {
            #        $str = "$key/$str";
            #    }
            #}

            $str = $anchor;
        }

        $str;        
    };

    if ($format =~ /^e?html/) {
        my $h = shift;

        return $h->tag('a',
            href=>"#$anchorCanonized",
            $text,
        );
    }
    elsif ($format eq 'pod') {
        # Wenn Whitespace im Anker, in "..." einfassen
        return $anchor =~ /\s/? qq|L</"$anchor">|: "L</$anchor>";
    }

    return $anchor;
}

sub canonizeAnchor {
    my ($this,$str) = @_;
    $str =~ s/\W+/_/g;
    $str =~ s/^_+//g;
    $str =~ s/_+$//g;
    return lc $str;
}

sub anchorSegment {
    my $self = shift;
    my $format = shift;
    my $str = shift;
    # @_: @args

    if ($format =~ /^e?html/) {
        my $h = shift;

        return $h->tag('a',
            id=>$self->canonizeAnchor($str),
        );
    }

    return '';
}

sub expandMetaChars {
    my $self = shift;
    my $format = shift;
    my $val = shift;

    if ($format =~ /^e?html$/) {
        $val =~ s/&/&amp;/g;
        $val =~ s/</&lt;/g;
        $val =~ s/>/&gt;/g;
    }
    elsif ($format eq 'pod') {
        # $val =~ s/</L<lt>/g;
        # Großbuchstabe + < durch Großbuchstabe L<lt> ersetzen
        $val =~ s/([A-Z])</$1L<lt>/g;
    }

    return $val;
}

sub expand {
    my $self = shift;
    my $format = shift;
    my $val = shift;
    my $inlineSegments = shift;
    # @_: @args - formatspezifische Argumente

    if ($format =~ /^e?html/) {
        my $cssPrefix = $self->rootNode->get('cssPrefix');

        # Metazeichen ersetzen

        $val =~ s/&/&amp;/g;
        $val =~ s/</&lt;/g;
        $val =~ s/>/&gt;/g;

        if ($inlineSegments) {
            my $h = $_[0];

            # Inline-Segmente expandieren

            $val =~ s|B\{([^}]+)\}|$h->tag('b',class=>"$cssPrefix-seg-b",
                "$1")|ge;
            $val =~ s|C\{([^}]+)\}|$h->tag('tt',class=>"$cssPrefix-seg-c",
                "$1")|ge;
            $val =~ s|E\{([^}]+)\}|$h->tag('em',class=>"$cssPrefix-seg-e",
                "$1")|ge;
            $val =~ s|I\{([^}]+)\}|$h->tag('i',class=>"$cssPrefix-seg-i",
                "$1")|ge;
            $val =~ s|Q\{([^}]+)\}|&#132;$1&#148;|g; # wo in Unicode?
        }
    }
    elsif ($format eq 'pod') {
        # Metazeichen ersetzen

        # $val =~ s/</L<lt>/g;
        # Großbuchstabe + < durch Großbuchstabe L<lt> ersetzen
        $val =~ s/([A-Z])</$1L<lt>/g;

        if ($inlineSegments) {
            # Inline-Segmente expandieren

            $val =~ s|B\{([^}]+)\}|Quiq::Pod::Generator->fmt('B',$1)|gse;
            $val =~ s|C\{([^}]+)\}|Quiq::Pod::Generator->fmt('C',$1)|gse;
            $val =~ s|E\{([^}]+)\}|Quiq::Pod::Generator->fmt('I',$1)|gse;
            $val =~ s|I\{([^}]+)\}|Quiq::Pod::Generator->fmt('I',$1)|gse;
            $val =~ s|Q\{([^}]+)\}|"$1"|gs;
        }
    }
    elsif ($format eq 'man') {
        # Metazeichen ersetzen

        if ($inlineSegments) {
            # Inline-Segmente expandieren

            $val =~ s|B\{([^}]+)\}|$1|gs;
            $val =~ s|C\{([^}]+)\}|$1|gs;
            $val =~ s|E\{([^}]+)\}|$1|gs;
            $val =~ s|I\{([^}]+)\}|$1|gs;
            $val =~ s|Q\{([^}]+)\}|"$1"|gs;
        }
    }

    if ($inlineSegments) {
        # Formatübergreifende Behandlung von Grafik-Segmenten,
        # Link-Segmenten usw
        $val =~ s|G\{([^}]+?)\}|
            $self->graphicSegment($format,"$1",@_)|gse;
        $val =~ s|([Ll])\{([^}]+?)\}|
            $self->linkSegment($format,"$1","$2",@_)|gse;
        $val =~ s|(U)\{([^}]+?)\}|
            $self->urlSegment($format,"$1","$2",@_)|gse;
    }

    return $val;
}

# -----------------------------------------------------------------------------

=head3 tableOfContents() - Erzeuge Inhaltsverzeichnis

=head4 Synopsis

    $str = $node->tableOfContents($format,@args);

=cut

# -----------------------------------------------------------------------------

sub tableOfContents {
    my $self = shift;
    my $format = shift;
    my $maxDepth = shift;
    my $depth = shift;
    # @_: formatspezifische Parameter

    $depth++;
    return '' if $maxDepth && $depth > $maxDepth;

    my $toc = '';
    if ($format =~ /^e?html$/) {
        my $h = shift;

        my $cssPrefix = $self->rootNode->get('cssPrefix');

        for my $node ($self->childs) {
            my $type = $node->{'type'};
            if ($type eq 'Section') {
                my $subContents = '';
                if (!$node->{'stopToc'}) {
                    $subContents = $node->tableOfContents($format,
                        $maxDepth,$depth,$h);
                    if ($subContents) {
                        $subContents = "\n".$subContents;
                    }
                }

                $toc .= $h->tag('li',
                    class=>"$cssPrefix-toc-li",
                    $h->cat(
                        $h->tag('a',
                            class=>"$cssPrefix-toc-a",
                            href=>'#'.$node->numberAnchorText(1),
                            $node->visibleTitle($format)
                        ),
                        $subContents,
                    ),
                );
            }
        }
        if ($toc) {
            $toc = $h->tag('ul',
                class=>"$cssPrefix-toc-ul",
                $toc
            );
        }
    }
    # FIXME: POD Format unterstützen?

    return $toc;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.132

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
