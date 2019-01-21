package Quiq::Sdoc::KeyValRow;
use base qw/Quiq::Sdoc::Node/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = 1.131;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Sdoc::KeyValRow - Zeile einer Schlüssel/Wert-Tabelle

=head1 BASE CLASS

L<Quiq::Sdoc::Node>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert eine Zeile einer KeyValue-Tabelle.

=head1 ATTRIBUTES

=over 4

=item parent => $parent

Verweis auf den Elternknoten

=item key => $str

Schlüssel

=item value => $str

Wert

=back

=head1 METHODS

=head2 Konstruktor

=head3 new() - Konstruktor

=head4 Synopsis

    $node = $class->new($doc,$parent,$att,$rowNum);

=head4 Description

Lies eine KeyValue-Zeile aus Textdokument $doc und liefere
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

    # 2. Schritt: Schlüssel und Wert bestimmen

    my ($key,$val) = $text =~ /(.*)=>(.*)/;
    $key =~ s/^\s+//;
    $val =~ s/^\s+//;
    $key =~ s/\s+$//;
    $val =~ s/\s+$//;

    # Objekt instantiieren

    my $self = $class->SUPER::new(
        parent=>undef,
        type=>'KeyValRow',
        key=>$key,
        value=>$val,
    );
    $self->parent($parent);
    # $self->lockKeys;

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Methods

=head3 dump() - Erzeuge externe Repräsentation für eine KeyValue-Zeile

=head4 Synopsis

    $str = $node->dump($format);

=cut

# -----------------------------------------------------------------------------

sub dump {
    my $self = shift;
    my $format = shift;
    # @_: @args

    my $key = $self->{'key'};
    my $val = $self->{'value'};

    if ($format eq 'debug') {
        return "KEYVALROW '$key' => '$val'\n";
    }
    elsif ($format =~ /^e?html$/) {
        my $h = shift;

        my $cssPrefix = $self->rootNode->get('cssPrefix');

        return $h->tag('tr',
            class=>"$cssPrefix-keyval-tr",
            $h->tag('td',
                class=>"$cssPrefix-keyval-td-key",
                $key
            ).
            $h->tag('td',
                class=>"$cssPrefix-keyval-td-value",
                $self->expand($format,$val,1,$h),
            )
        );
    }
    elsif ($format eq 'pod') {
        # FIXME: Tabellenformatierung
        return "$key => $val\n";
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
