package Quiq::Sdoc::Document;
use base qw/Quiq::Sdoc::Node/;

use strict;
use warnings;
use v5.10.0;
use utf8;

our $VERSION = 1.135;

use Quiq::Sdoc::Line;
use Quiq::Sdoc::Link;
use Quiq::Sdoc::Node;
use Quiq::Sdoc::TableOfContents;
use Quiq::Sdoc::Figure;
use Quiq::Sdoc::Section;
use Quiq::Sdoc::BridgeHead;
use Quiq::Sdoc::Paragraph;
use Quiq::Sdoc::Code;
use Quiq::Sdoc::Include;
use Quiq::Sdoc::Table;
use Quiq::Sdoc::Row;
use Quiq::Sdoc::KeyValTable;
use Quiq::Sdoc::KeyValRow;
use Quiq::Sdoc::List;
use Quiq::Sdoc::Box;
use Quiq::Sdoc::Item;
use Quiq::Sdoc::Quote;
use Quiq::Sdoc::PageBreak;
use Quiq::Option;
use Quiq::LineProcessor;
use Quiq::Hash;
use Quiq::OrderedHash;
use Quiq::Object;
use Quiq::Html::Tag;
use Quiq::Path;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Sdoc::Document - Sdoc-Dokument

=head1 BASE CLASS

L<Quiq::Sdoc::Node>

=head1 SYNOPSIS

Aufrufe zur Generierung eines Sdoc-Parsing-Baums:

    $tree = Quiq::Sdoc::Document->new($file);
    $tree = Quiq::Sdoc::Document->new(\$str);
    $tree = Quiq::Sdoc::Document->new(\@lines);

Aufrufe zur Generierung einer Repräsentation:

    $str = $tree->dump('ehtml');
    $str = $tree->dump('pod');
    $str = $tree->dump('debug');

In einem Aufruf:

    $str = Quiq::Sdoc::Document->dump($format,$source);

=head1 DESCRIPTION

Die Klasse repräsentiert einen Sdoc-Parsingbaum.

=head1 METHODS

=head2 Konstruktor

=head3 new() - Konstruktor

=head4 Synopsis

    $tree = $class->new($file,@opt);
    $tree = $class->new(\$str,@opt);
    $tree = $class->new(\@lines,@opt);

=head4 Options

=over 4

=item -baseUrl => $url

Setze in den Kopf der HTML-Seite einen <base>-Tag mit dem angegebenen URL.

=item -centerTablesAndFigures => $bool (Default: 0)

Zentriere Abbildungen und Tabellen.

=item -comments => $bool (Default: 1)

Übergehe Zeilen, die mit '#' am Zeilenanfang beginnen.

=item -cssPrefix => $str (Default: 'sdoc')

Präfix für alle CSS-Bezeichner (Klassen- und Id-Bezeichner).

=item -deeperSections => $n (Default: 0)

Die Abschnitte werden um $n Schritte tiefer eingestuft.

=item -embedImages => $bool (Default: 0)

Bette Bilddaten in HTML ein.

=item -html4 => $bool (Default: 0)

Generiere HTML4 Code. Per Default wird XHTML Code generiert.

=item -minLnWidth => $n (Default: 1)

Minimale Breite der Listing Zeilennummern-Spalte in Zeichen.

=item -sectionNumbers => $bool (Default: 0)

Setze den Abschnittstiteln automatisch generierte Abschnittsnummern voran.

=item -styleSheet => $stylesheet (Default: sdoc.css)

Verwende Stylesheet $stylesheet, was ein URL sein oder
Inline-Style "inline:FILE" sein kann. In letzterem Fall wird die
angegebene Datei geöffnet und als Inline-Style zum Dokument hinzugefügt.

=item -tableAndFigureNumbers => $bool (Default: 0)

Stelle dem Titel "Tabelle N:" bzw. "Abbildung N:" voran.

=item -utf8 => $bool (Default: 0)

Der Text ist UTF-8 kodiert.

=back

=head4 Description

Erzeuge einen Sdoc-Parsingbaum und liefere eine Referenz auf
diesen zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    my $inp = shift;
    # @_: @opt

    # Optionen

    my $baseUrl = undef;
    my $centerTablesAndFigures = 0;
    my $comments = 1;
    my $cssPrefix = 'sdoc';
    my $deeperSections = 0;
    my $embedImages = 0;
    my $html4 = 0;
    my $minLnWidth = 1;
    my $sectionNumbers = 0;
    my $styleSheet = undef;
    my $tableAndFigureNumbers = 0;
    my $utf8 = 0;

    if (@_) {
        Quiq::Option->extract(\@_,
            -baseUrl=>\$baseUrl,
            -centerTablesAndFigures=>\$centerTablesAndFigures,
            -comments=>\$comments,
            -cssPrefix=>\$cssPrefix,
            -deeperSections=>\$deeperSections,
            -embedImages=>\$embedImages,
            -html4=>\$html4,
            -minLnWidth=>\$minLnWidth,
            -sectionNumbers=>\$sectionNumbers,
            -styleSheet=>\$styleSheet,
            -tableAndFigureNumbers=>\$tableAndFigureNumbers,
            -utf8=>\$utf8,
        );
    }

    # Zunächst LineProcessor-Dokument instantiieren

    my $doc = Quiq::LineProcessor->new($inp,
        -lineClass=>'Quiq::Sdoc::Line',
        -lineContinuation=>'backslash',
        -skip=>$comments? qr/^#/: undef,
    );

    # Ein Dokument hat keine eigene Information im Text

    my $self = $class->SUPER::new(
        type=>'Document',
        parent=>undef,
        childs=>[],
        links=>Quiq::Hash->new->unlockKeys, # für Link-Definitionen
        anchorsGlob=>Quiq::OrderedHash->new,
        generateAnchors=>1,
        html4=>$html4,
        tableAndFigureNumbers=>$tableAndFigureNumbers,
        centerTablesAndFigures=>$centerTablesAndFigures,
        language=>'german', # Defaultwert
        sectionNumbers=>$sectionNumbers,
        deeperSections=>$deeperSections,
        embedImages=>$embedImages,
        styleSheet=>$styleSheet,
        title=>undef,
        utf8=>$utf8,
        minLnWidth=>$minLnWidth,
        baseUrl=>$baseUrl,
        cssPrefix=>$cssPrefix,
        
    );

    while (@{$doc->lines}) {
        my ($type,$arr) = $self->nextType($doc);
        if ($type eq 'Document') {
            $self->set(@$arr);
            next;        
        }

        # alle Knoten sind dem Dokument untergeordet, daher
        # gibt es hier keine Abbruchbedingung

        push @{$self->{'childs'}},
            "Quiq::Sdoc::$type"->new($doc,$self,$arr);
    }

    # alle Knoten
    my @nodes = $self->select;

    # Prüfe, ob Inhaltsverzeichnis (wenn nicht, erzeugen wir
    # keine Abschnitts-Links)

    my $hasToc = 0;
    for my $node (@nodes) {
        if ($node->isa('Quiq::Sdoc::TableOfContents')) {
            $hasToc = 1;
            last;
        }
    }

    # Generiere Abschnittsnummer für alle Abschnitte

    my @secNum = (0); # Abschnittszähler für jede Ebene
    my $figNum = 0; # Abbildungszähler
    my $tabNum = 0; # Tabellenzähler
    my $isAppendix = 0;
    for my $node (@nodes) {
        if ($node->isa('Quiq::Sdoc::Section')) {
            # Nummer der aktuellen Ebene hochzählen
            my $level = $node->{'level'};
            my $n = ++$secNum[$level-1];
            if ($level == 1 && $node->{'isAppendix'} && $n =~ /^\d+$/) {
                $secNum[0] = 'A';
                $isAppendix = 1;
            }

            # Appendix-Eigenschaft setzen

            if ($isAppendix) {
                $node->{'isAppendix'} = 1;
            }

            # Nummern der Subebenen auf 0 setzen

            for (my $i = $level; $i < @secNum; $i++) {
                $secNum[$i] = 0;
            }

            # Nummer generieren und setzen

            my $secNum;
            for (my $i = 0; $i < $level; $i++) {
                if (!defined $secNum[$i]) {
                    $self->throw(
                        q~SDOC-00004: Abschnittsebene zu tief~,
                        Depth=>$level,
                        DocumentTitle=>$self->{'title'},
                        SectionTitle=>$node->{'title'},
                    );
                }
                $secNum .= "$secNum[$i].";
            }
            $node->{'number'} = $secNum;
        }
        elsif ($node->isa('Quiq::Sdoc::Figure')) {
            $node->{'number'} = ++$figNum;
        }
        elsif ($node->isa('Quiq::Sdoc::Table')) {
            $node->{'number'} = ++$tabNum;
        }
    }

    # Generiere Anker über allen Knoten

    # Der Dokument-Hash sammelt Informationen über allen Ankern.
    # Hierüber wird die Existenz und Eindeutigkeit der
    # Anker sichergestellt. FIXME: Eigene API zum Setzen und
    # Abfragen von Ankern.
    #
    # Konzept: Alle Knoten, für die Anker vergeben werden können,
    # besitzen ein Attribut "anchors" (Hash aller Anker).
    # Diese Hashs werden unten mit Ankern "befüllt".
    # Zum Schluss wird Existenz und Eindeutigkeit geprüft.

    my $aGlobH = $self->{'anchorsGlob'};

    for my $node (@nodes) {
        my $aH = $node->try('anchors') or next; # Knoten ohne Anker

        if ($node->isa('Quiq::Sdoc::TableOfContents')) {
            # Anker "toc" für Inhaltsverzeichnis
            $aH->set(toc=>1);
        }
        elsif ($node->isa('Quiq::Sdoc::Section')) {
            # Bei Abschnitten: Nummern-Anker für Inhaltsverzeichnis

            if ($hasToc) {
                $aH->set($node->numberAnchorText=>1);
            }
        }

        # Titel-Anker. Nur wenn generateAnchors=1.

        my $title = $node->title;
        if ($title && $self->{'generateAnchors'}) {
            $aH->set($self->canonizeAnchor($title)=>1);
        }

        # Explizit definierter Anker per K{} oder A{}

        my $anchor = $node->try('key') || $node->try('anchor');
        if ($anchor) {
            $aH->set($self->canonizeAnchor($anchor)=>1);
        }

        # Pfad-Anker generieren, wenn ein Objekt mit Schlüssel
        # übergeordnet ist. 1) Die Titel bilden einen Pfad 2) Die
        # explizit definierten Anker/Keys bilden einen Pfad. Hat $node
        # keinen Key/Anker, wird der Titel genommen.

        $anchor ||= $node->title;
        for (my $p = $node->parent; $p; $p = $p->parent) {
            if (my $key = $p->try('key')) {
                if ($title) {
                    $title = $p->title."/$title";
                    $aH->set($self->canonizeAnchor($title)=>1);
                }
                if ($anchor) {
                    $anchor = "$key/$anchor";
                    $aH->set($self->canonizeAnchor($anchor)=>1);
                }
            }
        }

        for my $key ($aH->keys) {
            my $arr = $aGlobH->get($key);
            push @$arr,$node;
            $aGlobH->set($key=>$arr);
        }
    }

    # Der globale Anker-Hash speichert für eindeutige Anker
    # einen Verweis auf den Knoten, für nicht-eindeutige Anker
    # die Anzahl der Objekte, die denselben Anker haben.

    for my $node (@nodes) {
        my $aH = $node->try('anchors') or next;
        for my $key ($aH->keys) {
            if (@{$aGlobH->get($key)} > 1) {
                # Anker entfernen, die nicht global eindeutig sind
                # $aH->delete($key);
                next;
            }
        }
    }    

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 title() - Liefere den Titel des Dokuments

=head4 Synopsis

    $title = $node->title;

=head4 Description

Der Titel kann bei Aufruf des Konstuktors mittels der Option -title
angegeben werden. Andernfalls wird der Titel des ersten Abschnitts
genommen. Hat das Dokument keinen Abschnitt, ist der Titel leer ('').

=cut

# -----------------------------------------------------------------------------

sub title {
    my $self = shift;

    my $title = $self->{'title'} || '';
    if (!$title) {
        # FIXME: lookup implementieren
        #my ($sec) = $self->select(type=>'Section');
        #if ($sec) {
        #    $title = $sec->get('title');
        #}
    }

    return $title;
}

# -----------------------------------------------------------------------------

=head3 dump() - Erzeuge Repräsentation für Sdoc-Dokument

=head4 Synopsis

    $str = Quiq::Sdoc::Document->dump($format,$source);
    $str = $node->dump($format,@opt);

=head4 Description

Erzeuge eine externe Repräsentation des Dokument-Knotens
einschließlich aller Subknoten im Format $format und liefere diese
an den Aufrufer zurück.

=cut

# -----------------------------------------------------------------------------

sub dump {
    my ($class,$self,$isClassMethod) = Quiq::Object->this(shift);
    my $format = shift;

    # Dokument instantiieren, wenn als Klassenmethode gerufen

    my $noTitle = 0;
    if ($isClassMethod) {
        $self = $class->new(@_);
    }
    elsif (@_) {
        Quiq::Option->extract(\@_,
            -noTitle=>\$noTitle,
        );
    }

    my $baseUrl = $self->get('baseUrl');
    my $cssPrefix = $self->get('cssPrefix');
    my $html4 = $self->get('html4');
    my $embedImages = $self->get('embedImages');
    my $styleSheet = $self->get('styleSheet');
    my $title;
    if (!$noTitle) {
        $title = $self->title;
    }
    if ($title) {
        $title = $self->expandMetaChars('html',$title);
    }
    my $utf8 = $self->get('utf8');

    my (@args,$h);
    if ($format =~ /^e?html$/) {
        push @args,$h = Quiq::Html::Tag->new(
            $html4? (htmlVersion=>'html-4.01',uppercase=>1): (), 
            embedImages=>$embedImages,
        );
    }
    my $childs = $self->dumpChilds($format,@args);

    if ($format eq 'debug') {
        return "DOCUMENT\n$childs";
    }
    elsif ($format =~ /^e?html$/) {
        my $charset = $utf8? 'UTF-8': 'ISO-8859-1';
        my $styleSheet = $self->get('styleSheet');

        my $style;
        if ($styleSheet) {
            for my $s (split /[,\s]+/,$styleSheet) {
                $style .= "\n" if $style;
                if ($s =~ s/^inline://) {
                    $style .= Quiq::Path->read($s);
                    # FIXME: Optional Kommentare entfernen
                    # Leerzeilen entfernen
                    $style =~ s|\n\s*\n+|\n|g;
                    # /* eof */ entfernen
                    $style =~ s|\s+$||;
                    $style =~ s|\s*/\* eof \*/$||;
                }
                else {
                    $style .= "\@import url($s);";
                }
            }
        }

        # Generiere Vorspann

        my $frontPage = '';

        if ($title) {
            $frontPage = $h->tag('h1',
                class=>"$cssPrefix-doc-h1",
                $title
            );
            # FIXME: weitere Informationen wie Autor usw.
        }

        if ($format eq 'ehtml') {
            return $frontPage.$childs;
        }

        # my $highlightUrl = 'http://alexgorbatchev.com/pub/sh/current';
        #my $highlightUrl = '/tmp/highlight';
        my $highlightUrl = 'http://s31tz.de/js/syntaxhighlighter';
        my $xregexpUrl = 'http://s31tz.de/js/xregexp';

        return $h->cat(
            $h->doctype,
            # $h->comment(-nl=>2,'automatically created by sdoc'),
            $h->tag('html','-',
                $h->tag('head','-',
                    $h->tag('meta',
                        'http-equiv'=>'content-type',
                        content=>"text/html; charset=$charset",
                    ),
                    $h->tag('base',
                        -ignoreIf=>!$baseUrl,
                        href=>$baseUrl,
                    ),
                    $h->tag('title',
                        -ignoreIf=>!$title,
                        $title,
                    ),
                    $h->tag('link',
                        rel=>'stylesheet',
                        type=>'text/css',
                        # Anpassung: font-size: 11px
                        href=>"$highlightUrl/styles/shCore.css",
                    ),
                    $h->tag('link',
                        rel=>'stylesheet',
                        type=>'text/css',
                        # Anpassung: .toolbox { display: none }
                        href=>"$highlightUrl/styles/shThemeDefault.css",
                    ),
                    $h->tag('style',
                        -ignoreIf=>!$style,
                        $style,
                    ),
                ),
                $h->tag('body',
                    id=>"$cssPrefix-body",
                    $frontPage.$childs.
                    $h->tag('script',
                        src=>"$xregexpUrl/src/xregexp.js",
                    ).
                    $h->tag('script',
                        # src=>"$highlightUrl/scripts/shCore.js",
                        src=>"$highlightUrl/src/shCore.js",
                    ).
                    $h->tag('script',
                        src=>"$highlightUrl/scripts/shBrushBash.js",
                    ).
                    $h->tag('script',
                        src=>"$highlightUrl/scripts/shBrushJScript.js",
                    ).
                    $h->tag('script',
                        src=>"$highlightUrl/scripts/shBrushPerl.js",
                    ).
                    $h->tag('script',
                        src=>"$highlightUrl/scripts/shBrushXml.js",
                    ).
                    $h->tag('script',q~
                        SyntaxHighlighter.all();
                    ~)
                ),
            ),
        );
    }
    elsif ($format eq 'ehtml') {
        return $childs;
    }
    elsif ($format eq 'pod') {
        my $str;
        if ($utf8) {
            $str .= "=encoding utf8\n\n";
        }
        #else {
        #    $str .= "=encoding iso-8859-1\n\n";
        #}
        # Problem: Bei CoTeDo erscheint der Zusatztitel in der POD-Doku
        if ($title) {
            $str .= "=head1 $title\n\n";
        }
        $str .= $childs;
        $str =~ s/\s+$/\n/;
        return $str;
    }
    elsif ($format eq 'man') {
        my $str = $childs;
        $str =~ s/\s+$/\n/;
        return $str;
    }

    $self->throw(
        q~SDOC-00002: Nicht-unterstütztes Format~,
        Format=>$format,
    );
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.135

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
