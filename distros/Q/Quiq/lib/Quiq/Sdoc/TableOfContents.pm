package Quiq::Sdoc::TableOfContents;
use base qw/Quiq::Sdoc::Node/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = 1.134;

use Quiq::OrderedHash;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Sdoc::TableOfContents - Inhaltsverzeichnis

=head1 BASE CLASS

L<Quiq::Sdoc::Node>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert das Inhaltsverzeichnis des
Dokuments.

=head1 ATTRIBUTES

=over 4

=item parent => $parent

Verweis auf Superknoten.

=item maxDepth => $n

Tiefe des Inhaltsverzeichnisses

=item title => $str

Überschrift.

=back

=head1 METHODS

=head2 Konstruktor

=head3 new() - Konstruktor

=head4 Synopsis

    $node = $class->new($doc,$parent,$att);

=head4 Description

Erzeuge einen TableOfContents-Knoten und liefere eine Referenz auf
diesen zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$doc,$parent,$att) = @_;

    # Objekt instantiieren

    my $self = $class->SUPER::new(
        parent=>undef,
        type=>'TableOfContents',
        anchors=>Quiq::OrderedHash->new,
        maxDepth=>undef,
        title=>'', # kein Title
    );
    $self->parent($parent); # schwache Referenz
    # $self->lockKeys;
    $self->set(@$att);

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Methods

=head3 dump() - Erzeuge externe Repräsentation für Inhaltsverzeichnis-Knoten

=head4 Synopsis

    $str = $node->dump($format,@args);

=head4 Description

Erzeuge eine externe Repräsentation des Inhaltsverzeichnis-Knotens
liefere diese zurück.

=cut

# -----------------------------------------------------------------------------

sub dump {
    my $self = shift;
    my $format = shift;
    # @_: @args

    my $title = $self->{'title'};
    if (!defined $title) {
        my $language = $self->rootNode->{'language'};
        if ($language eq 'german') {
            $title = 'Inhalt';
        }
        else {
            $title = 'Contents';
        }
    }

    if ($format eq 'debug') {
        return qq(TOC "$title"\n);
    }
    elsif ($format =~ /^e?html$/) {
        my $h = shift;

        my $cssPrefix = $self->rootNode->get('cssPrefix');

        # FIXME: Ruler an/abschaltbar machen
        # $h->tag('hr',
        #     -ignoreIf=>$level == 1 && $self->parent->childs->[0] == $self
        #       || $level > 3,
        #     class=>"$cssPrefix-hr",
        # ),

        my $html = '';
        if ($title) {
            $html = $h->tag("h1",
                class=>"$cssPrefix-toc-h1",
                $title.$self->anchors($format,$h)
            );
        }
        else {
            $html = $self->anchors($format,$h)."\n";
        }
        my $root = $self->rootNode;
        $html .= $root->tableOfContents($format,$self->{'maxDepth'},0,$h);

        $html = $h->tag('div',
            id=>"$cssPrefix-toc",
            # class=>"$cssPrefix-toc",
            $html
        );

        return $html;
    }
    elsif ($format eq 'pod') {
        # POD hat kein Inhaltsverzeichnis
        return '';
    }
    elsif ($format eq 'man') {
        # man hat kein Inhaltsverzeichnis
        return '';
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
