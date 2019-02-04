package Quiq::Sdoc::List;
use base qw/Quiq::Sdoc::Node/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = 1.132;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Sdoc::List - Liste

=head1 BASE CLASS

L<Quiq::Sdoc::Node>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert eine Liste im Sdoc-Parsingbaum.

=head1 ATTRIBUTES

=over 4

=item parent => $parent

Verweis auf Superknoten.

=item childs => \@childs

Liste der Subknoten. Die Subknoten sind ausschließlich Item-Knoten.

=item itemType => $itemType

"*", "o", "+", "-", "#" oder "[]".

=item simple => $bool

Alle Items einer Punktliste bestehen aus jeweils einem Paragraphen
mit einer Textzeile. In dem Fall setzen wir in HTML den Text nicht
in einen Paragraphen.

=back

=head1 METHODS

=head2 Konstruktor

=head3 new() - Konstruktor

=head4 Synopsis

    $node = $class->new($doc,$parent);

=head4 Description

Lies eine Liste aus Textdokument $doc und liefere
eine Referenz auf dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$doc,$parent) = @_;

    my $line = $doc->lines->[0];
    my ($itemType) = $line->item;

    # Objekt instantiieren

    my $self = $class->SUPER::new(
        parent=>undef,
        type=>'List',
        childs=>[],
        itemType=>$itemType,
        simple=>0,
    );
    $self->parent($parent);
    # $self->lockKeys;

    # Child-Objekte verarbeiten

    while (@{$doc->lines}) {
        # Eine Liste endet, wenn das nächste Element kein Item ist
        last if !$doc->lines->[0]->item;

        my ($type,$arr) = $self->nextType($doc);

        # last if $type ne 'Item';

        push @{$self->childs},"Quiq::Sdoc::$type"->new($doc,$self,$arr);
    }

    # Handelt es sich um eine einfache Punktliste? (siehe Attribut "simple")

    if ($itemType ne '#' && $itemType ne '[]') {
        my $simple = 1;
        for my $itm (@{$self->childs}) {
            my $childA = $itm->childs;
            if (@$childA == 1) {
                my $cld = $childA->[0];
                if ($cld->{'type'} eq 'Paragraph' && $cld->lines == 1) {
                    next;
                }
            }
            $simple = 0;
            last;
        }
        $self->{'simple'} = $simple;
    }

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Accessors

=head3 itemType() - Liefere Itemtyp der Liste

=head4 Synopsis

    $itemType = $node->itemType;

=cut

# -----------------------------------------------------------------------------

sub itemType {
    return shift->{'itemType'};
}

# -----------------------------------------------------------------------------

=head2 Methods

=head3 dump() - Erzeuge externe Repräsentation für Liste

=head4 Synopsis

    $str = $node->dump($format);

=head4 Description

Erzeuge eine externe Repräsentation für die Liste,
einschließlich aller Subknoten, und liefere diese zurück.

=cut

# -----------------------------------------------------------------------------

sub dump {
    my $self = shift;
    my $format = shift;
    # @_: @args

    my $itemType = $self->{'itemType'};
    my $childs = $self->dumpChilds($format,@_);

    if ($format eq 'debug') {
        return "LIST $itemType\n$childs";
    }
    elsif ($format =~ /^e?html$/) {
        my $h = shift;

        my $cssPrefix = $self->rootNode->get('cssPrefix');

        my $tag = $itemType eq '[]'? 'dl': $itemType eq '#'? 'ol': 'ul';
        return $h->tag($tag,
            class=>"$cssPrefix-list-$tag",
            $childs,
        );
    }
    elsif ($format eq 'pod') {
        if ($itemType eq '[]') {
            return "=over 4\n\n$childs=back\n\n";
        }
        elsif ($itemType eq '#') {
            return "=over 4\n\n$childs=back\n\n";
        }
        return "=over 2\n\n$childs=back\n\n";
    }
    elsif ($format eq 'man') {
        return $childs;
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
