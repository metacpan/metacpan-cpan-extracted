package Quiq::Table;
use base qw/Quiq::Hash/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.140';

use Quiq::Hash;
use Quiq::Properties;
use Quiq::TableRow;
use Quiq::Parameters;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Table - Tabelle

=head1 BASE CLASS

L<Quiq::Hash>

=head1 SYNOPSIS

    use Quiq::Table;
    
    # Objekt
    $tab = Quiq::Table->new(['a','b','c','d']);
    
    # Kolumnen
    
    $width = $tab->width;
    # 4
    
    @columns = $tab->columns;
    # ('a','b','c','d')
    
    $columnA = $tab->columns;
    # ['a','b','c','d']
    
    $i = $tab->columnIndex('c');
    # 2
    
    $i = $tab->columnIndex('z');
    # Exception
    
    # Zeilen
    
    @rows = $tab->rows;
    # ()
    
    $rowA = $tab->rows;
    # []
    
    $count = $tab->count;
    # 0
    
    $tab->push([1,2,3,4]);
    $tab->push([5,6,7,8]);
    $tab->push([1,9,10,11]);
    $count = $tab->count;
    # 3
    
    # Über alle Zeilen und Kolumnen iterieren
    
    for my $row ($tab->rows) {
        for my $value ($row->values) {
            # ...
        }
    }
    
    # Werte
    
    @values = $tab->values('a');
    # (1,5,1)
    
    $valueA = $tab->values('a');
    # [1,5,1]
    
    @values = $tab->values('a',-distinct=>1);
    # (1,5)

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert eine Tabelle, also eine Liste
von gleichförmigen Zeilen. Die Namen der Kolumnen werden dem Konstruktor
der Klasse übergeben. Sie bezeichnen die Komponenten der Zeilen. Die
Zeilen sind Objekte der Klasse Quiq::TableRow.

=head1 METHODS

=head2 Klassenmethoden

=head3 new() - Konstruktor

=head4 Synopsis

    $tab = $class->new(\@columns);

=head4 Arguments

=over 4

=item @columns

Liste der Kolumnennamen (Strings).

=back

=head4 Returns

Referenz auf Tabellen-Objekt

=head4 Description

Instantiiere ein Tabellen-Objekt mit den Kolumnennamen @columns und
liefere eine Referenz auf das Objekt zurück. Die Kolumnennamen werden
nicht kopiert, die Referenz wird im Objekt gespeichert. Die
Liste der Zeilen ist zunächst leer.

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$columnA) = @_;

    my $i = 0;
    return $class->SUPER::new(
        columnA => $columnA,
        columnH => Quiq::Hash->new({map {$_ => $i++} @$columnA}),
        rowA => [],
    );
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 columns() - Liste der Kolumnennamen

=head4 Synopsis

    @columns | $columnA = $tab->columns;

=head4 Returns

Liste der Kolumnennamen (Strings). Im Skalarkontext eine Referenz
auf die Liste.

=head4 Description

Liefere die Liste der Kolumnennamen der Tabelle.

=cut

# -----------------------------------------------------------------------------

sub columns {
    my $self = shift;

    my $columnA = $self->{'columnA'};
    return wantarray? @$columnA: $columnA;
}

# -----------------------------------------------------------------------------

=head3 count() - Anzahl der Zeilen

=head4 Synopsis

    $count = $tab->count;

=head4 Returns

Integer

=head4 Description

Liefere die Anzahl der Zeilen der Tabelle.

=cut

# -----------------------------------------------------------------------------

sub count {
    my $self = shift;
    return scalar @{$self->{'rowA'}};
}

# -----------------------------------------------------------------------------

=head3 columnProperties() - Eigenschaften der Werte einer Kolumne

=head4 Synopsis

    $prp = $tab->columnProperties($column);

=head4 Arguments

=over 4

=item $column

Kolumnenname (String).

=back

=head4 Returns

Properties-Objekt (Quiq::Properties)

=head4 Description

Ermittele die Eigenschaften der Werte der Kolumne $column und liefere
ein Objekt, das diese Eigenschaften abfragbar zur Verfügung stellt,
zurück.

=cut

# -----------------------------------------------------------------------------

sub columnProperties {
    my ($self,$column) = @_;

    my $prp = Quiq::Properties->new;
    for my $val ($self->values($column,-distinct=>1)) {
        $prp->analyze($val);
    }

    return $prp;
}

# -----------------------------------------------------------------------------

=head3 columnIndex() - Index einer Kolumne

=head4 Synopsis

    $i = $tab->columnIndex($column);

=head4 Arguments

=over 4

=item $column

Kolumnenname (String).

=back

=head4 Returns

Integer

=head4 Description

Liefere den Index der Kolumne $column. Der Index einer Kolumne ist ihre
Position innerhalb des Kolumnen-Array.

=cut

# -----------------------------------------------------------------------------

sub columnIndex {
    my ($self,$column) = @_;
    return $self->{'columnH'}->{$column};
}

# -----------------------------------------------------------------------------

=head3 push() - Füge Zeile hinzu

=head4 Synopsis

    $tab->push(\@arr);

=head4 Arguments

=over 4

=item @arr

Liste von Zeilendaten (Strings).

=back

=head4 Description

Füge eine Zeile mit den Daten @arr zur Tabelle hinzu. Die Anzahl der
Elemente in @arr muss mit der Anzahl der Kolumnen übereinstimmen,
sonst wird eine Exception geworfen.

=cut

# -----------------------------------------------------------------------------

sub push {
    my ($self,$valueA) = @_;

    my $row = Quiq::TableRow->new($self,$valueA);
    $self->SUPER::push('rowA',$row);

    return;
}

# -----------------------------------------------------------------------------

=head3 rows() - Liste der Zeilen

=head4 Synopsis

    @rows | $rowA = $tab->rows;

=head4 Returns

Liste der Zeilen (Objekte der Klasse Quiq::TableRow). Im Skalarkontext
eine Referenz auf die Liste.

=head4 Description

Liefere die Liste der Zeilen der Tabelle.

=cut

# -----------------------------------------------------------------------------

sub rows {
    my $self = shift;

    my $rowA = $self->{'rowA'};
    return wantarray? @$rowA: $rowA;
}

# -----------------------------------------------------------------------------

=head3 values() - Werte einer Kolumne

=head4 Synopsis

    @values | $valueA = $tab->values($column,@opt);

=head4 Arguments

=over 4

=item $column

Kolumnenname (String).

=back

=head4 Options

=over 4

=item -distinct => $bool (Default: 0)

Liste der I<verschiedenen> Werte.

=back

=head4 Returns

Liste der Werte (Strings). Im Skalarkontext eine Referenz auf die Liste.

=head4 Description

Liefere die Liste der Werte der Kolumne $column. Per Default wird die
Liste I<aller> Werte geliefert, auch wenn sie mehrfach vorkommen. Siehe
auch Option C<-distinct>.

=cut

# -----------------------------------------------------------------------------

sub values {
    my $self = shift;
    my $column = shift;
    # @_: @opt

    # Optionen

    my $distinct = 0;

    Quiq::Parameters->extractToVariables(\@_,0,0,
        -distinct => \$distinct,
    );

    # Erstelle Werteliste

    my (@arr,%seen);
    my $i = $self->columnIndex($column);
    for my $row (@{$self->{'rowA'}}) {
        my $val = $row->[1][$i];
        if ($distinct && $seen{$val}++) {
            next;
        }
        CORE::push @arr,$val;
    }

    return wantarray? @arr: \@arr;
}

# -----------------------------------------------------------------------------

=head3 width() - Anzahl der Kolumnen

=head4 Synopsis

    $width = $tab->width;

=head4 Returns

Integer

=head4 Description

Liefere die Anzahl der Kolumnen der Tabelle.

=cut

# -----------------------------------------------------------------------------

sub width {
    my $self = shift;
    return scalar @{$self->{'columnA'}};
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.140

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
