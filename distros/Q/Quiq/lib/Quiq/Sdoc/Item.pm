package Quiq::Sdoc::Item;
use base qw/Quiq::Sdoc::Node/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = 1.132;

use Quiq::LineProcessor;
use Quiq::OrderedHash;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Sdoc::Item - Listenelement

=head1 BASE CLASS

L<Quiq::Sdoc::Node>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert ein Listenelement
im Sdoc-Parsingbaum.

=head1 ATTRIBUTES

=over 4

=item parent => $parent

Verweis auf den Elternknoten

=item childs => \@childs

Liste der Subknoten.

=item label => $label

Bullet-Zeichen (*, o, +), Zahl oder Text.

=back

=head1 METHODS

=head2 Konstruktor

=head3 new() - Konstruktor

=head4 Synopsis

    $node = $class->new($doc,$parent);

=head4 Description

Lies ein Listenelement aus Textdokument $doc und liefere
eine Referenz auf dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$doc,$parent) = @_;

    my $line = $doc->lines->[0];
    my $nextLine = $doc->lines->[1];
    my (undef,$label,$indent,$text) = $line->item($nextLine);
    $line->text($text);

    my ($key,$anchor);
    #if ($label =~ s/K\{(.+)\}/$1/ || $label =~ s/\s*\bk\{([^{]+)\}//) {
    #    $key = $1;
    #}
    if ($label =~ s/A\{(.+)\}/$1/ || $label =~ s/\s*\ba\{([^}]+)\}//) {
        $anchor = $1;
    }

    my @lines;
    while (@{$doc->lines}) {
        my $line = $doc->lines->[0];
        last if !$line->isEmpty && $line->indentation < $indent;
        if (!$line->isEmpty) {
            my $text = $line->text;
            $text = substr $text,$indent;
            $line->text($text);
        }
        push @lines,$doc->shiftLine;
    }
    $doc = Quiq::LineProcessor->new(\@lines);

    # Objekt instantiieren

    my $self = $class->SUPER::new(
        parent=>undef,
        type=>'Item',
        childs=>[],
        anchors=>Quiq::OrderedHash->new,
        label=>$label, # Punktsymbol, Nummer oder Text
        key=>$key,
        anchor=>$anchor,
    );
    $self->parent($parent);
    # $self->lockKeys;

    # Child-Objekte aus obigem Dokument verarbeiten

    while (@{$doc->lines}) {
        my ($type,$arr) = $self->nextType($doc);

        # Keine Abbruchbedingung, da das oben generierte Dokument
        # genau den Itemabschnitt umfasst

        push @{$self->childs},"Quiq::Sdoc::$type"->new($doc,$self,$arr);
    }

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Methods

=head3 title() - Liefere den Labeltext

=head4 Synopsis

    $title = $node->title;

=head4 Description

Liefere das Label des Listenelements, sofern es zu einer
Definitionsliste gehört. Andernfalls liefere einen Leerstring.

=cut

# -----------------------------------------------------------------------------

sub title {
    my $self = shift;

    my $title = '';
    if ($self->parent->itemType eq '[]') {
        $title = $self->{'label'};
    }

    return $title;
}

# -----------------------------------------------------------------------------

=head3 dump() - Erzeuge externe Repräsentation für Listenelement

=head4 Synopsis

    $str = $node->dump($format);

=head4 Description

Erzeuge eine externe Repräsentation für das Listenelement,
einschließlich aller Subknoten, und liefere diese zurück.

=cut

# -----------------------------------------------------------------------------

sub dump {
    my $self = shift;
    my $format = shift;
    # @_: @args

    my $itemType = $self->parent->itemType;
    my $childs = $self->dumpChilds($format,@_);
    my $label = $self->expand($format,$self->{'label'},1,@_);

    if ($format eq 'debug') {
        $label = qq("$label") if $self->parent->itemType eq '[]';
        return qq(ITEM $label\n$childs);
    }
    elsif ($format =~ /^e?html$/) {
        my $h = shift;

        my $cssPrefix = $self->rootNode->get('cssPrefix');

        chomp $childs;
        if ($itemType eq '[]') {
            return $h->cat(
                $self->anchors($format,$h)."\n".
                $h->tag('dt',
                    class=>"$cssPrefix-list-dt",
                    $label
                ),
                $h->tag('dd',
                    class=>"$cssPrefix-list-dd",
                    $childs
                )
            );
        }
        elsif ($itemType eq '#') {
            return $h->tag('li',
                class=>"$cssPrefix-list-li-num",
                $childs,
            );
        }
        else {
            my $type = $itemType eq '*'? 'disc':
                $itemType eq 'o'? 'circle': 'square';
            return $h->tag('li',
                class=>"$cssPrefix-list-li-point",
                style=>"list-style-type:$type",
                # type=>$type, bei XHTML nicht erlaubt
                $childs,
            );
        }
    }
    elsif ($format eq 'pod') {
        if ($itemType eq '[]') {
            if ($label =~ /^\d+$/) {
                # Vermeidung des Test::Pod-Fehlers:
                # Expected text after =item, not a number
                $label = "Z<>$label";
            }
            return "=item $label\n\n$childs";
        }
        elsif ($itemType eq '#') {
            return "=item $label\n\n$childs";
        }
        else {
            return "=item $itemType\n\n$childs";
        }
    }
    elsif ($format eq 'man') {
        if ($itemType eq '[]') {
            $childs =~ s/^/    /mg;
            return "$label\n$childs";
        }
        elsif ($itemType eq '#') {
            $childs =~ s/^/   /mg; # um drei Zeichen einrücken
            $childs =~ s/^\s+//; # Einrückung auf erster Zeile zurücknehmen
            return "$label $childs";
        }
        else {
            $childs =~ s/^/  /mg; # um zwei Zeichen einrücken
            $childs =~ s/^\s+//; # Einrückung auf erster Zeile zurücknehmen
            return "$itemType $childs";
        }
    }

    $self->throw(
        q~SDOC-00001: Unbekanntes Format~,
        Format=>$format,
    );
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
