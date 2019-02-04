package Quiq::Sdoc::Row;
use base qw/Quiq::Sdoc::Node/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = 1.132;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Sdoc::Row - Zeile einer Tabelle

=head1 BASE CLASS

L<Quiq::Sdoc::Node>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert eine Tabellenzeile
im Sdoc-Parsingbaum.

=head1 ATTRIBUTES

=over 4

=item parent => $parent

Verweis auf den Elternknoten

=item columns => \@columns

Liste der Kolumnen.

=back

=head1 METHODS

=head2 Konstruktor

=head3 new() - Konstruktor

=head4 Synopsis

    $node = $class->new($doc,$parent);

=head4 Description

Lies eine Tabellenzeile aus Textdokument $doc und liefere
eine Referenz auf dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$doc,$parent,$attH,$rowNum) = @_;

    my $text = $doc->shiftLine->text;
    # my $firstRow = $parent->childs->size? 0: 1;
    my $firstRow = @{$parent->childs}? 0: 1;

    # 1. Schritt: | am Anfang und am Ende entfernen

    $text =~ s/^\s*\|//;
    $text =~ s/\|$//;
    my @vals = split /\|/,$text;

    # 2. Schritt: Eigenschaften bestimmen und Whitespace um Wert entfernen

    my (@align,@header);
    for (my $i = 0; $i < @vals; $i++) {
        my $val = $vals[$i];

        $val =~ s/^([+<>~]+)?//;
        my $colAtt = $1 || '';

        push @header,index($colAtt,'+') >= 0? 1: 0;

        if ($firstRow || $colAtt =~ /[<>~]/) {
            my $align;
            if (index($colAtt, '>') >= 0) {
                $align = 'right';
            }
            elsif (index($colAtt,'~') >= 0) {
                $align = 'center';
            }
            else {
                $align = 'left';
            }
            $parent->{'alignment'}->[$i] = $align;
        }
        push @align,$parent->{'alignment'}->[$i];

        $val =~ s/^\s+//;
        $val =~ s/\s+$//;

        $vals[$i] = $val;
    }

    # Objekt instantiieren

    my $self = $class->SUPER::new(
        parent=>undef,
        type=>'Row',
        alignment=>\@align,
        header=>\@header,
        number=>$rowNum,
        values=>\@vals,
    );
    $self->parent($parent);
    # $self->lockKeys;

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Methods

=head3 dump() - Erzeuge externe Repräsentation für eine Tabellenzeile

=head4 Synopsis

    $str = $node->dump($format);

=head4 Description

Erzeuge eine externe Repräsentation für die Tabellenzeile und liefere
diese zurück.

=cut

# -----------------------------------------------------------------------------

sub dump {
    my $self = shift;
    my $format = shift;
    # @_: @args

    my $parentAlignA = $self->parent->{'alignment'};

    my $headerA = $self->{'header'};
    my $alignA = $self->{'alignment'};
    my $valA = $self->{'values'};

    if ($format eq 'debug') {
        return 'ROW ('.join('|',@$valA).")\n";
    }
    elsif ($format =~ /^e?html$/) {
        my $h = shift;

        my $cssPrefix = $self->rootNode->get('cssPrefix');

        my $cols = '';
        for (my $i = 0; $i < @$valA; $i++) {
            my $tag = $headerA->[$i]? 'th': 'td';
            $cols .= $h->tag($tag,
                class=>"$cssPrefix-tab-$tag",
                align=>$alignA->[$i],
                $self->expand($format,$valA->[$i],1,$h),
            );
        }

        return $h->tag('tr',
            class=>"$cssPrefix-tab-tr-".($self->{'number'}%2? 'odd': 'even'),
            $cols,
        );
    }
    elsif ($format eq 'pod') {
        # FIXME: Tabellenformatierung
        return join('|',@$valA)."\n";
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
