package Quiq::Sdoc::Box;
use base qw/Quiq::Sdoc::Node/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = 1.138;

use Quiq::LineProcessor;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Sdoc::Box - Kasten

=head1 BASE CLASS

L<Quiq::Sdoc::Node>

=head1 ATTRIBUTES

=over 4

=item parent => $parent

Verweis auf den Elternknoten

=item childs => \@childs

Liste der Subknoten

=item title => $title

Überschrift

=back

=head1 METHODS

=head2 Konstruktor

=head3 new() - Konstruktor

=head4 Synopsis

    $node = $class->new($doc,$parent,\@att);

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$doc,$parent,$att) = @_;

    my @lines;
    while (@{$doc->lines}) {
        my $line = $doc->lines->[0];
        my $text = $line->text;
        last if $text !~ /^\|/;
        $text =~ s/\|\s?//; # Leerzeilen haben kein Whitespace
        $line->text($text);
        push @lines,$doc->shiftLine;
    }
    $doc = Quiq::LineProcessor->new(\@lines);

    # Objekt instantiieren

    my $self = $class->SUPER::new(
        parent=>undef,
        type=>'Box',
        childs=>[],
        title=>undef,
    );
    $self->parent($parent);
    # $self->lockKeys;
    $self->set(@$att);

    # Child-Objekte aus obigem Dokument verarbeiten

    while (@{$doc->lines}) {
        my ($type,$arr) = $self->nextType($doc);

        # Keine Abbruchbedingung, da das oben generierte Dokument
        # genau den Box-Abschnitt umfasst

        push @{$self->childs},"Quiq::Sdoc::$type"->new($doc,$self,$arr);
    }

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Methods

=head3 dump() - Erzeuge externe Repräsentation für Box-Element

=head4 Synopsis

    $str = $node->dump($format,@args);

=head4 Description

Erzeuge eine externe Repräsentation für das Box-Element,
einschließlich aller Subknoten, und liefere diese zurück.

=cut

# -----------------------------------------------------------------------------

sub dump {
    my $self = shift;
    my $format = shift;
    # @_: @args

    my $title = $self->title;
    my $childs = $self->dumpChilds($format,@_);

    if ($format eq 'debug') {
        return qq(BOX $title\n$childs);
    }
    elsif ($format =~ /^e?html$/) {
        my $h = shift;

        my $cssPrefix = $self->rootNode->get('cssPrefix');

        return $h->tag('div',
            class=>"$cssPrefix-box-div",
            $h->tag('p',
                -ignoreIf=>!$title,
                -nl=>1,
                class=>"$cssPrefix-box-title-p",
                $title
            ).
            $childs
        );
    }
    elsif ($format eq 'pod') {
        # FIXME: Metazeichen in $title ersetzen
        return "B<$title>\n\n$childs";
    }
    elsif ($format eq 'man') {
        $self->notImplemented;
    }

    # not reached
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.138

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
