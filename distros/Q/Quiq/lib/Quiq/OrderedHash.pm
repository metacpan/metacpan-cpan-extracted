package Quiq::OrderedHash;
use base qw/Quiq::Object/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.147';

use Quiq::Hash;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::OrderedHash - Hash mit geordneten Elementen

=head1 BASE CLASS

L<Quiq::Object>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert einen geordneten Hash. Ein
geordneter Hash ist ein Hash, bei dem die Schlüssel/Wert-Paare
eine definierte Reihenfolge haben. Initial ist dies die
Hinzufügereihenfolge.

=head1 METHODS

=head2 Konstruktor

=head3 new() - Konstruktor

=head4 Synopsis

    $oh = $class->new(@keyVal);

=head4 Description

Instantiiere einen geordneten Hash, setze die betreffenden
Schlüssel/Wert-Paare und liefere eine Referenz auf dieses Objekt
zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;

    my $self = bless [Quiq::Hash->new->unlockKeys,[]],$class;
    $self->set(@_);

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Getter/Setter

=head3 get() - Liefere Werte

=head4 Synopsis

    @arr|$val = $oh->get(@keys);

=head4 Description

Liefere die Liste der Werte zu den angebenen Schlüsseln. Ist kein
Schlüssel angegeben, liefere alle Werte. In Skalarkontext liefere
keine Liste, sondern den Wert des ersten Schlüssels.

=cut

# -----------------------------------------------------------------------------

sub get {
    my $self = shift;

    my $hash = $self->[0];
    my $keys = @_? \@_: $self->[1];

    my @arr;
    for (@$keys) {
        push @arr,$hash->{$_};
    }

    return wantarray? @arr: $arr[0];
}

# -----------------------------------------------------------------------------

=head3 set() - Setze Schlüssel/Wert-Paare

=head4 Synopsis

    $oh->set(@keyVal);

=head4 Returns

nichts

=head4 Description

Setze die angegebenen Schlüssel/Wert-Paare.

=cut

# -----------------------------------------------------------------------------

sub set {
    my $self = shift;

    my ($hash,$arr) = @$self;

    while (@_) {
        my $key = shift;
        my $val = shift;

        push @$arr,$key if !exists $hash->{$key};
        $hash->{$key} = $val;
    }

    return;
}

# -----------------------------------------------------------------------------

=head3 setDelete() - Setze bzw. lösche Schlüssel/Wert-Paare

=head4 Synopsis

    $oh->setDelete(@keyVal);

=head4 Description

Setze die angegebenen Schlüssel auf die angegebenen Werte. Wenn $val
undef ist, lösche den betreffenden Schlüssel. Die Methode liefert
keinen Wert zurück.

=cut

# -----------------------------------------------------------------------------

sub setDelete {
    my $self = shift;

    my ($hash,$arr) = @$self;

    while (@_) {
        my $key = shift;
        my $val = shift;

        unless (defined $val) {
            $self->delete($key);
            next;
        }

        push @$arr,$key unless exists $hash->{$key};
        $hash->{$key} = $val;
    }

    return;
}

# -----------------------------------------------------------------------------

=head2 Miscellaneous

=head3 clear() - Lösche Inhalt und setze Schlüssel/Wert-Paare

=head4 Synopsis

    $obj->clear(@keyVal);

=head4 Description

Lösche Inhalt und setze Schlüssel/Wert-Paare. Ist kein
Schlüssel/Wert-Paar angegeben, wird nur der Inhalt gelöscht.
Die Methode liefert keinen Wert zurück.

=cut

# -----------------------------------------------------------------------------

sub clear {
    my $self = shift;

    $self->[0] = {};
    $self->[1] = [];

    return $self->set(@_);
}

# -----------------------------------------------------------------------------

=head3 copy() - Kopiere Hash

=head4 Synopsis

    $oh2 = $oh->copy;

=head4 Description

Kopiere Hashobjekt und liefere eine Referenz auf die Kopie zurück.

=cut

# -----------------------------------------------------------------------------

sub copy {
    my $self = shift;

    my %hash = %{$self->[0]};
    my @arr = @{$self->[1]};

    return bless [\%hash,\@arr],ref $self;
}

# -----------------------------------------------------------------------------

=head3 delete() - Lösche Schlüssel

=head4 Synopsis

    $oh->delete(@keys);

=head4 Description

Lösche die angegebenen Schlüssel. Die Methode liefert keinen Wert zurück.

=cut

# -----------------------------------------------------------------------------

sub delete {
    my $self = shift;
    # @_: @keys

    my ($hash,$arr) = @$self;

    for my $key (@_) {
        if (exists $hash->{$key}) {
            for (my $i = 0; $i < @$arr; $i++) {
                if ($arr->[$i] eq $key) {
                    splice @$arr,$i,1;
                    last;
                }
            }
            delete $hash->{$key};
        }
    }

    return;
}

# -----------------------------------------------------------------------------

=head3 increment() - Inkrementiere Wert

=head4 Synopsis

    $n = $hash->increment($key);

=head4 Description

Inkrementiere Wert zu Schlüssel $key und liefere das Resultat zurück.

=cut

# -----------------------------------------------------------------------------

sub increment {
    my ($self,$key) = @_;
    return $self->[0]->increment($key);
}

# -----------------------------------------------------------------------------

=head3 keys() - Liefere die Liste aller Schlüssel

=head4 Synopsis

    @keys|$keys = $oh->keys;

=head4 Description

Liefere die Liste der Schlüssel des Hash. In skalarem Kontext
liefere eine Referenz auf die Liste.

=cut

# -----------------------------------------------------------------------------

sub keys {
    my $self = shift;
    my $arr = $self->[1];
    return wantarray? @$arr: $arr;
}

# -----------------------------------------------------------------------------

=head3 hashSize() - Anzahl der Elemente

=head4 Synopsis

    $n = $oh->hashSize;

=head4 Description

Liefere die Anzahl der Elemente.

=cut

# -----------------------------------------------------------------------------

sub hashSize {
    my $self = shift;
    return scalar @{$self->[1]};
}

# -----------------------------------------------------------------------------

=head3 unshift() - Setze Schlüssel/Wert-Paar an den Anfang

=head4 Synopsis

    $oh->unshift($key=>$val);

=head4 Description

Setze das angegebene Schlüssel/Wert-Paar, sofern der Schlüssel noch nicht
existiert, an den Anfang. Existiert der Schlüssel, wird der Wert
ersetzt. Die Methode liefert keinen Wert zurück.

=cut

# -----------------------------------------------------------------------------

sub unshift {
    my ($self,$key,$val) = @_;

    my ($hash,$arr) = @$self;
    unshift @$arr,$key if !exists $hash->{$key};
    $hash->{$key} = $val;

    return;
}

# -----------------------------------------------------------------------------

=head3 values() - Liefere die Liste der Werte

=head4 Synopsis

    @arr|$arr = $oh->values;

=head4 Description

Liefere die Liste der Werte in Schlüsselreihenfolge. In skalarem Kontext
liefere eine Referenz auf die Liste.

=cut

# -----------------------------------------------------------------------------

sub values {
    my $self = shift;

    my ($hash,$arr) = @$self;

    my @arr;
    for (@$arr) {
        push @arr,$hash->{$_};
    }

    return wantarray? @arr: \@arr;
}

# -----------------------------------------------------------------------------

=head2 Test Methods

=head3 exists() - Prüfe Existenz eines Schlüssels

=head4 Synopsis

    $oh->exists($key);

=head4 Description

Liefere "wahr", wenn der Hash den Schlüssel $key enthält,
andernfalls "falsch".

=cut

# -----------------------------------------------------------------------------

sub exists {
    my $self = shift;
    my $key = shift;
    return exists $self->[0]->{$key}? 1: 0;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.147

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
