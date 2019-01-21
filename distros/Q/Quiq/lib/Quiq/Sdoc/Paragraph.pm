package Quiq::Sdoc::Paragraph;
use base qw/Quiq::Sdoc::Node/;

use strict;
use warnings;
use v5.10.0;
use utf8;

our $VERSION = 1.131;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Sdoc::Paragraph - Paragraph

=head1 BASE CLASS

L<Quiq::Sdoc::Node>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert einen Paragraph im
Sdoc-Parsingbaum.

=head1 ATTRIBUTES

=over 4

=item type => 'Paragraph'

Typ des Knotens

=item parent => $parent

Verweis auf übergeordneten Knoten.

=item text => $text

Text des Paragraphs.

=back

=head1 METHODS

=head2 Konstruktor

=head3 new() - Konstruktor

=head4 Synopsis

    $node = $class->new($doc,$parent);

=head4 Description

Lies Paragraph aus Textdokument $doc und liefere
eine Referenz auf dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$doc,$parent) = @_;

    my $text = '';
    while (@{$doc->lines}) {
        my $line = $doc->lines->[0];

        # FIXME: Test verbessern

        # Ein Paragraph endet mit der nächsten Leerzeile,
        # einem List-Item oder einem tiefer eingerückten Block.

        last if $line->isEmpty || $line->indentation > 0 || $line->item;

        $text .= $line->text."\n";
        $doc->shiftLine;
    }
    $text =~ s/\s+$//;

    # Objekt instantiieren (Child-Objekte gibt es nicht)

    my $self = $class->SUPER::new(
        parent=>undef,
        type=>'Paragraph',
        text=>$text,
    );
    $self->parent($parent);
    # $self->lockKeys;

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Methods

=head3 lines() - Liefere die Anzahl der Textzeilen

=head4 Synopsis

    $n = $node->lines;

=cut

# -----------------------------------------------------------------------------

sub lines {
    my $self = shift;
    my $n = $self->{'text'} =~ tr/\n//;
    return $n+1;
}

# -----------------------------------------------------------------------------

=head3 dump() - Erzeuge externe Repräsentation für Paragraph-Knoten

=head4 Synopsis

    $str = $node->dump($format,@args);

=head4 Description

Erzeuge eine externe Repräsentation für den Paragraph-Knoten
und liefere diese zurück.

=cut

# -----------------------------------------------------------------------------

sub dump {
    my $self = shift;
    my $format = shift;
    # @_: @args

    my $text = $self->expand($format,$self->{'text'},1,@_);

    my $simple = 0;
    my $parent = $self->{'parent'};
    if ($parent->{'type'} eq 'Item') {
        $simple = $parent->{'parent'}->{'simple'};
    }

    if ($format eq 'debug') {
        if ($simple) {
            return "$text\n";
        }
        return "PARAGRAPH\n$text\n";
    }
    elsif ($format =~ /^e?html$/) {
        my $h = shift;

        my $cssPrefix = $self->rootNode->get('cssPrefix');

        if ($simple) {
            return $text;
        }
        return $h->tag('p',
            class=>"$cssPrefix-para-p",
            $text,
        );
    }
    elsif ($format eq 'pod') {
        return "$text\n\n";
    }
    elsif ($format eq 'man') {
        return "$text\n\n";
    }

    $self->throw(
        q~SDOC-00002: Nicht-unterstütztes Format~,
        Format=>$format,
    );
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.131

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
