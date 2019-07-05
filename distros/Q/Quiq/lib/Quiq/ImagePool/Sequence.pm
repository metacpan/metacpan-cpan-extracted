package Quiq::ImagePool::Sequence;
use base qw/Quiq::Hash/;

use strict;
use warnings;
use v5.10.0;
use utf8;

our $VERSION = '1.149';

use Quiq::OrderedHash;
use Quiq::FileHandle;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::ImagePool::Sequence - Bild-Sequenz und -Ranges

=head1 BASE CLASS

L<Quiq::Hash>

=head1 ATTRIBUTES

=over 4

=item file

Pfad der Datei.

=item oHash

Geordneter Hash der Schlüssel/Definitions-Paare.

=item imageList

Liste aller Bilder.

=back

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Objekt aus Datei

=head4 Synopsis

    $ims = $class->new($file,$lst);

=head4 Arguments

=over 4

=item $file

Pfad der Sequenz-Liste.

=item $lst

Liste aller Bilder.

=back

=head4 Description

Instantiiere ein Sequenz-Objekt aus Datei $file, verknüpfe es mit
Bildliste $lst und liefere eine Referenz auf dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$file,$lst) = @_;

    # Leeres Objekt instantiieren

    my $oh = Quiq::OrderedHash->new;
    my $self = $class->SUPER::new(
        file => $file,
        oHash => $oh,
        imageList => $lst,
    );

    # Sequenz-Definitionen einlesen.

    my $fh = Quiq::FileHandle->new('<',$file);
    while (<$fh>) {
        chomp;

        if (/^\s*#/) {
            # Kommentarzeile
            next;
        }

        # Sequenz-Definitionszeile hinzufügen

        my @arr = split /\s+/,$_;
        if (@arr < 2 || @arr > 3) {
            # Prüfe Dateiaufbau
            $self->throw(
                'SEQ-00001: Falsche Kolumnen-Anzahl',
                File => $file,
                Line => $.,
                MaxColumns => 3,
                Columns => scalar(@arr),
            );
        }
        my $key = shift @arr;
        $oh->set($key=>\@arr);
    }
    $fh->close;

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 count() - Anzahl der Range-Definitionen

=head4 Synopsis

    $n = $ims->count;

=head4 Description

Liefere die Anzahl der Range-Definitionen.

=cut

# -----------------------------------------------------------------------------

sub count {
    return shift->oHash->hashSize;
}

# -----------------------------------------------------------------------------

=head3 keys() - Array der Range-Namen

=head4 Synopsis

    @keys|$keyA = $ims->keys;

=head4 Description

Liefere die Liste aller Range-Bezeichner. Im Skalarkontext liefere
eine Referenz auf die Liste.

=cut

# -----------------------------------------------------------------------------

sub keys {
    return shift->oHash->keys;
}

# -----------------------------------------------------------------------------

=head3 exists() - Prüfe, ob Range existiert

=head4 Synopsis

    $bool = $ims->exists($key);

=head4 Description

Prüfe, ob Range $key existiert. Wenn ja, liefere 1, sonst 0.

=cut

# -----------------------------------------------------------------------------

sub exists {
    my ($self,$key) = @_;
    return $self->oHash->get($key)? 1: 0;
}

# -----------------------------------------------------------------------------

=head3 def() - Liefere Range-Definition

=head4 Synopsis

    @def|$defA = $ims->def($key);

=head4 Description

Liefere die Definition ($spec,$modifier) des Range $key.

=cut

# -----------------------------------------------------------------------------

sub def {
    my ($self,$key) = @_;
    my $arr = $self->oHash->get($key) || do {
        $self->throw(
            'IMGSET-00002: Schlüssel existiert nicht',
            File => $self->file,
            Key => $key,
        );
    };
    return wantarray? @$arr: $arr;
}

# -----------------------------------------------------------------------------

=head3 spec() - Liefere Range-Spezifikation

=head4 Synopsis

    $range = $ims->spec($key);

=head4 Description

Liefere die Spezifikation (Aufzählung der Bildnummern) für Range $key.

=cut

# -----------------------------------------------------------------------------

sub spec {
    my ($self,$key) = @_;
    return $self->def($key)->[0] // '';
}

# -----------------------------------------------------------------------------

=head3 specImages() - Liefere die Bilder eines Range

=head4 Synopsis

    @images|$imageA = $ims->specImages($key);

=head4 Arguments

=over 4

=item $key

Range-Bezeichner.

=back

=head4 Description

Liefere die Liste der Bilder des Range $key. Im Skalarkontext liefere
eine Referenz auf die Liste.

=cut

# -----------------------------------------------------------------------------

sub specImages {
    my ($self,$key) = @_;

    my $lst = $self->imageList;

    my @images;
    for (split /,/,$self->spec($key)) {
        push @images,$lst->images($_);
    }

    # Bildsequenz modifizieren
    # Operationen: pick-N, dup-N, reverse, shuffle

    for (split /,/,$self->modifier($key)) {
        my ($cmd,$n) = split /-/;
        if ($cmd eq 'pick') {
            for (my $i = 0; $i < @images; $i++) {
                splice @images,$i+1,$n-1;
            }
        }
        elsif ($cmd eq 'dup') {
            my @tmp;
            for my $img (@images) {
                push @tmp,($img)x$n;
            }
            @images = @tmp;
        }
        elsif ($cmd eq 'reverse') {
            @images = reverse @images;
        }
        elsif ($cmd eq 'shuffle') {
            my @tmp;
            while (@images) {
                push @tmp,splice @images,int(rand(scalar @images)),1;
            }
            @images = @tmp;
        }
        else {
            $self->throw;
        }
    }

    return wantarray? @images: \@images;
}

# -----------------------------------------------------------------------------

=head3 modifier() - Liefere/Setze Range-Modifier

=head4 Synopsis

    $modifier = $ims->modifier($key);
    $modifier = $ims->modifier($key=>$modifier);

=head4 Description

Liefere oder setze den Modifier für Range $key.

=cut

# -----------------------------------------------------------------------------

sub modifier {
    my $self = shift;
    my $key = shift;
    # @_: $modifier

    my $defA = $self->def($key);
    if (@_) {
        $defA->[1] = shift;
    }

    return $defA->[1] // '';
}

# -----------------------------------------------------------------------------

=head2 Bilder

=head3 images() - Liefere Bilder der Sequenz

=head4 Synopsis

    @images|$imageA = $ims->images;
    @images|$imageA = $ims->images($key);

=head4 Arguments

=over 4

=item $key

Range-Bezeichner.

=back

=head4 Description

Liefere alle Bilder der Sequenz oder die Bilder des Range $key. Ist $key
undef oder ein Leerstring (''), werden ebenfalls alle Bilder geliefert.

=cut

# -----------------------------------------------------------------------------

sub images {
    my ($self,$key) = @_;

    my @images;
    for my $key ($key? ($key): $self->keys) {
        push @images,$self->specImages($key);
    }

    return wantarray? @images: \@images;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.149

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
