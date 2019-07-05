package Quiq::Database::ResultSet::Array;
use base qw/Quiq::Database::ResultSet/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.149';

use Quiq::Hash;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Database::ResultSet::Array - Liste von Datensätzen in Array-Repräsentation

=head1 BASE CLASS

L<Quiq::Database::ResultSet>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert eine Liste von gleichartigen
Datensätzen in Array-Repräsentation.

=head1 METHODS

=head2 Miscellaneous

=head3 columnIndex() - Liefere Index des Kolumnentitels

=head4 Synopsis

    $idx = $tab->columnIndex($title);

=head4 Description

Liefere den Index der Kolumne mit dem Titel $title. Existiert die
Kolumne nicht, löse eine Exception aus.

=cut

# -----------------------------------------------------------------------------

sub columnIndex {
    my ($self,$key) = @_;

    my $titleA = $self->{'titles'};
    for (my $i = 0; $i < @$titleA; $i++) {
        if ($titleA->[$i] eq $key) {
            return $i;
        }
    }

    $self->throw('TAB-00002: Kolumne existiert nicht',Column=>$key);
}

# -----------------------------------------------------------------------------

=head3 defaultRowClass() - Liefere Namen der Default-Rowklasse

=head4 Synopsis

    $rowClass = $class->defaultRowClass;

=head4 Description

Liefere den Namen der Default-Rowklasse: 'Quiq::Database::Row::Array'

Auf die Default-Rowklasse werden Datensätze instantiiert, für die
bei der Instantiierung einer Table-Klasse keine Row-Klasse
explizit angegeben wurde.

=cut

# -----------------------------------------------------------------------------

sub defaultRowClass {
    return 'Quiq::Database::Row::Array';
}

# -----------------------------------------------------------------------------

=head2 Subclass Implementation

=head3 lookupSub() - Suche Datensatz

=head4 Synopsis

    $row = $tab->lookupSub($key=>$val);

=head4 Description

Durchsuche die Tabelle nach dem ersten Datensatz, dessen
Attribut $key den Wert $val besitzt und liefere diesen zurück.
Erfüllt kein Datensatz das Kriterium, liefere undef.

=head4 Details

Wird durch Basisklasse getestet

=cut

# -----------------------------------------------------------------------------

sub lookupSub {
    my ($self,$key,$val) = @_;

    my $idx = $self->columnIndex($key);

    for my $row (@{$self->rows}) {
        if ($row->[$idx] eq $val) {
            return $row;
        }
    }

    return undef;
}

# -----------------------------------------------------------------------------

=head3 values() - Liefere die Werte einer Kolumne

=head4 Synopsis

    @vals|$valA = $tab->values($key);

=cut

# -----------------------------------------------------------------------------

sub values {
    my ($self,$key) = @_;

    my $idx = $self->columnIndex($key);

    my @arr;
    for my $row (@{$self->rows}) {
        CORE::push @arr,$row->[$idx];
    }

    return wantarray? @arr: \@arr;
}

# -----------------------------------------------------------------------------

=head3 index() - Indiziere Tabelle nach Kolumne

=head4 Synopsis

    %idx|$idxH = $tab->index($key);

=cut

# -----------------------------------------------------------------------------

sub index {
    my ($self,$key) = @_;

    my $idx = $self->columnIndex($key);

    my %idx;
    for my $row (@{$self->rows}) {
        $idx{$row->[$idx]} = $row;
    }

    return wantarray? %idx: Quiq::Hash->new(\%idx)->unlockKeys;
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
