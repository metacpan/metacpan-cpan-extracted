package Quiq::Sdoc::Section;
use base qw/Quiq::Sdoc::Node/;

use strict;
use warnings;
use v5.10.0;
use utf8;

our $VERSION = 1.134;

use Quiq::OrderedHash;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Sdoc::Section - Abschnittsüberschrift

=head1 BASE CLASS

L<Quiq::Sdoc::Node>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert einen Abschnitt im
Sdoc-Parsingbaum.

=head1 ATTRIBUTES

=over 4

=item parent => $parent

Verweis auf Superknoten.

=item childs => \@childs

Liste der Subknoten.

=item level => $n

Tiefe des Abschnitts in der Abschnittshierarchie, beginnend mit 1.

=item number => $str

Nummer des Abschitts in der Form N.N.N (abhängig von der Ebene).
Der Attributwert wird automatisch generiert.

=item title => $str

Titel des Abschnitts.

=item key => $str

Verlinkungsschlüssel.

=back

=head1 METHODS

=head2 Konstruktor

=head3 new() - Konstruktor

=head4 Synopsis

    $node = $class->new($doc,$parent);

=head4 Description

Erzeuge einen Section-Parsingbaum und liefere eine Referenz auf
den Section-Knoten zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$doc,$parent) = @_;

    my $root = $parent->rootNode;

    # Ein Sektionstitel ist grundsätzlich einzeilig und endet
    # daher mit der nächsten Zeile.

    my $line = $doc->shiftLine;
    $line->text =~ /^(=+)([!+v]*) (.*)/;
    my $level = length $1;
    my $secOpts = $2;
    my $title = $3;

    my ($key,$anchor,$menu);
    if ($title =~ s/K\{([^}]+)\}/$1/ || $title =~ s/\s*\bk\{([^}]+)\}//) {
        $key = $1;
    }
    if ($title =~ s/A\{([^}]+)\}/$1/ || $title =~ s/\s*\ba\{([^}]+)\}//) {
        $anchor = $1;
    }
    if ($title =~ s/M\{([^}]+)\}//) {
        $menu = $1;
        $menu =~ s/"//g;
    }

    # my $pageBreak = index($secOpts,'!') >= 0? 1: 0;
    my $isAppendix = index($secOpts,'+') >= 0? 1: 0;
    my $stopToc = index($secOpts,'!') >= 0? 1: 0;
    my $smaller = index($secOpts,'v') >= 0? 1: 0;

    $title =~ s/^\s+//g;
    $title =~ s/\s+$//g;

    # Objekt instantiieren

    my $self = $class->SUPER::new(
        parent=>undef,
        type=>'Section',
        childs=>[],
        anchors=>Quiq::OrderedHash->new,
        level=>$level+$root->{'deeperSections'}, # $level nur hier ändern!
        number=>undef,
        title=>$title,
        # pageBreak=>$pageBreak,
        isAppendix=>$isAppendix,
        stopToc=>$stopToc,
        smaller=>$smaller,
        key=>$key,
        anchor=>$anchor,
        menu=>$menu,
    );
    $self->parent($parent); # schwache Referenz
    # $self->lockKeys;

    # Child-Objekte verarbeiten

    while (@{$doc->lines}) {
        my ($type,$arr) = $self->nextType($doc);

        # Abbruch, bei Section mit gleichem oder kleinerem Level

        if ($type eq 'Section') {
            $doc->lines->[0]->text =~ /^(=+)/;
            last if length $1 <= $level;
        }

        push @{$self->{'childs'}},"Quiq::Sdoc::$type"->new($doc,$self,$arr);
    }

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Methods

=head3 numberAnchorText() - Liefere den Text des Nummern-Ankers des Abschnitts

=head4 Synopsis

    $text = $node->numberAnchorText;
    $text = $node->numberAnchorText($bool);

=head4 Description

Wenn $bool wahr ist, kanonisiere den Text, so dass er als
Wert eines Ankers eingesetzt werden kann.

=cut

# -----------------------------------------------------------------------------

sub numberAnchorText {
    my $self = shift;
    my $canonize = shift;

    my $text = "Section $self->{'number'}";
    if ($canonize) {
        $text = $self->canonizeAnchor($text);
    }

    return $text;
}

# -----------------------------------------------------------------------------

=head3 visibleTitle() - Liefere den Abschnitts-Titel, wie er ins Dokument geschrieben wird

=head4 Synopsis

    $text = $node->visibleTitle($format);

=cut

# -----------------------------------------------------------------------------

sub visibleTitle {
    my ($self,$format) = @_;

    my $root = $self->rootNode;

    # Titel, wie er in der Quelle steht
    my $title = $self->{'title'};

    # Titel, wie er ins generierte Dokument geschrieben wird

    $title = $self->expandMetaChars($format,$title);
    if ($root->{'sectionNumbers'}) {
        $title = "$self->{'number'} $title";
    }

    return $title;
}

# -----------------------------------------------------------------------------

=head3 dump() - Erzeuge externe Repräsentation für Section-Knoten

=head4 Synopsis

    $str = $node->dump($format,@args);

=head4 Description

Erzeuge eine externe Repräsentation des Section-Knotens
einschließlich aller Subknoten im Format $format und liefere diese zurück.

=cut

# -----------------------------------------------------------------------------

sub dump {
    my $self = shift;
    my $format = shift;
    # @_: @args

    my $level = $self->{'level'};
    my $smaller = $self->{'smaller'};
    # my $pageBreak = $self->{'pageBreak'};
    my $childs = $self->dumpChilds($format,@_);
    my $visibleTitle = $self->visibleTitle($format);

    if ($format eq 'debug') {
        return qq(SECTION $level "$self->{'title'}"\n$childs);
    }
    elsif ($format =~ /^e?html$/) {
        my $h = shift;

        my $cssPrefix = $self->rootNode->get('cssPrefix');

        if (my $menu = $self->{'menu'}) {
            my ($menuTitle,$menuLink) = split /,/,$menu;
            $visibleTitle .= ' '.$h->tag('span',
                class=>"$cssPrefix-sec-menu",
                '-',
                '['.$h->tag('a',
                    href=>$menuLink,
                    $menuTitle
                ).']'
            );
        }

        return $h->cat(
            # FIXME: Ruler an/abschaltbar machen
            #$h->tag('hr',
            #    -ignoreIf=>$level == 1 && $self->parent->childs->[0] == $self
            #        || $level > 3,
            #    class=>"$cssPrefix-hr",
            #),
            $self->anchors($format,$h)."\n".
            $h->tag("h$level",
                class=>sprintf("$cssPrefix-sec-h%d%s",$level,$smaller?
                    '-small': ''),
                # $pageBreak? (style=>'page-break-before:always'): (),
                $visibleTitle
            ),
            $childs,
        );
    }
    elsif ($format eq 'pod') {
        if ($level > 5) {
            $self->throw(
                q~SDOC-00003: Abschnitt zu tief für POD (max. Ebene 4)~,
                Section=>"=head$level",
                Title=>$visibleTitle,
            );
        }
        if ($level <= 4) {
            return "=head$level $visibleTitle\n\n$childs";
        }
        else {
            # Wir simulieren in POD Glederungsebene größer 4 durch B<...>
            return "B<$visibleTitle>\n\n$childs";
        }
    }
    elsif ($format eq 'man') {
        if ($level == 1) {
            # nur Childs einrücken
            $childs =~ s/^/    /mg;
            return "$visibleTitle\n$childs";
        }
        else {
            # alles einrücken
            my $str = "$visibleTitle\n\n$childs";
            # $str =~ s/^/    /mg;
            return $str;
        }
    }

    $self->throw(
        q~SDOC-00001: Unbekanntes Format~,
        Format=>$format,
    );
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.134

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
