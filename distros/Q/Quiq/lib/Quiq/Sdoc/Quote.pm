package Quiq::Sdoc::Quote;
use base qw/Quiq::Sdoc::Node/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = 1.131;

use Quiq::Pod::Generator;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Sdoc::Quote - Zitat-Abschnitt

=head1 BASE CLASS

L<Quiq::Sdoc::Node>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert einen Zitat-Abschnitt
im Sdoc-Parsingbaum.

=head1 ATTRIBUTES

=over 4

=item parent => $parent

Verweis auf den Elternknoten.

=item text => $text

Zitat-Text.

=back

=head1 METHODS

=head2 Konstruktor

=head3 new() - Konstruktor

=head4 Synopsis

    $node = $class->new($doc,$parent);

=head4 Description

Lies Zitatabschnitt aus Textdokument $doc und liefere
eine Referenz auf dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$doc,$parent) = @_;

    # Ein Quote-Abschnitt beginnt mit > gefolgt von Whitespace.
    # Der Abschnitt reicht so weit, bis der Anfang der ersten Zeile
    # nicht mehr gefunden wird.

    $doc->lines->[0]->text =~ /^(>\s+)/;
    my $re = qr/^\Q$1/;

    my $text = '';
    while (@{$doc->lines}) {
        my $line = $doc->lines->[0];
        my $str = $line->text;

        # Ein Quote-Abschnitt endet mit der ersten Zeile,
        # die nicht dem Anfang der ersten Zeile entspricht.

        $str =~ s/$re// || last; # Zeilenanfang entfernen
        $text .= "$str\n";
        $doc->shiftLine;
    }
    $text =~ s/\s+$//;

    # Objekt instantiieren (Child-Objekte gibt es nicht)

    my $self = $class->SUPER::new(
        parent=>undef,
        type=>'Quote',
        text=>$text,
    );
    $self->parent($parent);
    # $self->lockKeys;

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Methods

=head3 dump() - Erzeuge externe Repräsentation für Zitatabschnitt

=head4 Synopsis

    $str = $node->dump($format);

=head4 Description

Erzeuge eine externe Repräsentation für den Zitatabschnitt,
einschließlich aller Subknoten, und liefere diese zurück.

=cut

# -----------------------------------------------------------------------------

sub dump {
    my $self = shift;
    my $format = shift;
    # @_: @args

    my $text = $self->expand($format,$self->{'text'},1,@_);

    if ($format eq 'debug') {
        return "QUOTE\n$text\n";
    }
    elsif ($format =~ /^e?html$/) {
        my $h = shift;

        my $cssPrefix = $self->rootNode->get('cssPrefix');

        # FIXME: Auf Child-Objekte umstellen, denn Blockquote erwartet
        # Sub-Paragraphen

        return $h->tag('blockquote',
            class=>"$cssPrefix-quot-blockquote",
            $h->tag('p',
                $text
            )
        );
    }
    elsif ($format eq 'pod') {
        return Quiq::Pod::Generator->fmt('I',$text)."\n\n";
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
