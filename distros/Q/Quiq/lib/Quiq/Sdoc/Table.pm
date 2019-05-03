package Quiq::Sdoc::Table;
use base qw/Quiq::Sdoc::Node/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = 1.139;

use Quiq::Sdoc::Row;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Sdoc::Table - Tabelle

=head1 BASE CLASS

L<Quiq::Sdoc::Node>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert eine Tabelle im Sdoc-Parsingbaum.

=head1 ATTRIBUTES

=over 4

=item parent => $parent

Verweis auf Superknoten.

=item childs => \@childs

Liste der Subknoten. Die Subknoten sind ausschließlich Row-Knoten.

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
    my ($class,$doc,$parent,$att) = @_;

    my $line = $doc->lines->[0];

    # Objekt instantiieren

    my $self = $class->SUPER::new(
        parent=>undef,
        type=>'Table',
        childs=>[],
        alignment=>[], # Default-Ausrichtung, wird sukzessive gesetzt
        number=>undef,
        title=>'',
        center=>$parent->rootNode->{'centerTablesAndFigures'},
    );
    $self->parent($parent);
    # $self->lockKeys;
    $self->set(@$att);

    # Child-Objekte verarbeiten

    my $i = 1;
    while (@{$doc->lines}) {
        # Eine Tabelle endet, wenn das nächste Element keine Row ist
        last if !$doc->lines->[0]->isRow;

        my ($type,$arr) = $self->nextType($doc);

        # last if $type ne 'Row';

        push @{$self->childs},Quiq::Sdoc::Row->new($doc,$self,$arr,$i++);
    }

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Methods

=head3 visibleTitle() - Liefere den Titel, wie er ins Dokument geschrieben wird

=head4 Synopsis

    $text = $node->visibleTitle($format);

=cut

# -----------------------------------------------------------------------------

sub visibleTitle {
    my ($self,$format) = @_;

    my $root = $self->rootNode;

    # Tabelle|Table N

    my $title;
    if ($root->{'tableAndFigureNumbers'}) {
        my $language = $root->{'language'};
        if ($language eq 'german') {
            $title = 'Tabelle';
        }
        else {
            $title = 'Table';
        }
        $title .= " $self->{'number'}: ";
    }

    # Titel, wie er in der Quelle steht

    if (my $text = $self->{'title'}) {
        $title .= $text;
    }
    else {
        # FIXME: von Link auf Tabelle abhängig machen
        $title = '';
    }

    return $title;
}

# -----------------------------------------------------------------------------

=head3 dump() - Erzeuge externe Repräsentation für eine Tabelle

=head4 Synopsis

    $str = $node->dump($format);

=head4 Description

Erzeuge eine externe Repräsentation für die Tabelle,
einschließlich aller Subknoten, und liefere diese zurück.

=cut

# -----------------------------------------------------------------------------

sub dump {
    my $self = shift;
    my $format = shift;
    # @_: @args

    my $childs = $self->dumpChilds($format,@_);

    if ($format eq 'debug') {
        return "TABLE\n$childs";
    }
    elsif ($format =~ /^e?html$/) {
        my $h = shift;

        my $center = $self->{'center'};
        my $cssPrefix = $self->rootNode->get('cssPrefix');

        my $style;
        if ($center) {
            $style .= "margin-left: auto; margin-right: auto";
        }

        return $h->tag('div',
            class=>"$cssPrefix-tab-div",
            style=>$center? 'text-align: center': undef,
            '-',
            $h->tag('table',
                border=>1,
                class=>"$cssPrefix-tab-table",
                style=>$style,
                $childs
            ),
            $self->visibleTitle($format,$h)
        );

    }
    elsif ($format eq 'pod') {
        # FIXME: Texttabelle erzeugen
        $childs =~ s/^/    /mg;
        return "$childs\n";
    }
    elsif ($format eq 'man') {
        $self->notImplemented;
    }

    $self->throw(
        q~SDOC-00001: Unbekanntes Format~,
        Format=>$format,
    );
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.139

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
