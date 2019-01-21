package Quiq::Sdoc::KeyValTable;
use base qw/Quiq::Sdoc::Node/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = 1.131;

use Quiq::Sdoc::KeyValRow;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Sdoc::KeyValTable - Schlüssel/Wert-Tabelle

=head1 BASE CLASS

L<Quiq::Sdoc::Node>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert eine Tabelle aus
Schlüsel/wert-Paaren.

=head1 ATTRIBUTES

=over 4

=item parent => $parent

Verweis auf Superknoten.

=item childs => \@childs

Liste der Subknoten. Die Subknoten sind ausschließlich
KeyValRow-Knoten.

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

    # Objekt instantiieren

    my $self = $class->SUPER::new(
        parent=>undef,
        type=>'KeyValTable',
        childs=>[],
    );
    $self->parent($parent);
    # $self->lockKeys;

    # Child-Objekte verarbeiten

    my $i = 1;
    while (@{$doc->lines}) {
        # Eine KeyValue-Tabelle endet, wenn das nächste Element keine
        # KeyValRow ist
        last if !$doc->lines->[0]->isKeyValRow;

        my ($type,$arr) = $self->nextType($doc);

        # last if $type ne 'KeyValRow';

        push @{$self->childs},Quiq::Sdoc::KeyValRow->new($doc,$self,$arr,
            $i++);
    }

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Methods

=head3 dump() - Erzeuge externe Repräsentation für eine KeyValue-Tabelle

=head4 Synopsis

    $str = $node->dump($format);

=head4 Description

Erzeuge eine externe Repräsentation für die KeyValue-Tabelle,
einschließlich aller Subknoten, und liefere diese zurück.

=cut

# -----------------------------------------------------------------------------

sub dump {
    my $self = shift;
    my $format = shift;
    # @_: @args

    my $childs = $self->dumpChilds($format,@_);

    if ($format eq 'debug') {
        return "KEYVALTABLE\n$childs";
    }
    elsif ($format =~ /^e?html$/) {
        my $h = shift;

        my $cssPrefix = $self->rootNode->get('cssPrefix');

        return $h->tag('table',
            class=>"$cssPrefix-keyval-table",
            $childs
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
