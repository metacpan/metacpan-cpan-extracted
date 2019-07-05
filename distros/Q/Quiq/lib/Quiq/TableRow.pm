package Quiq::TableRow;
use base qw/Quiq::Object/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.149';

use Scalar::Util ();

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::TableRow - Tabellenzeile

=head1 BASE CLASS

L<Quiq::Object>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert eine Tabellenzeile, bestehend aus
einem Verweis auf die Tabelle (ein Objekt der Klasse Quiq::Table)
und ein Verweis auf ein Array von Werten. Das Array muss keiner Klasse
angehören, kann also ungeblesst sein. Eine Tabellenzeile wird
typischerweise nicht direkt instantiiert, sondern von der Methode push()
der Klasse Quiq::Table. Details siehe dort.

=head1 METHODS

=head2 Klassenmethoden

=head3 new() - Konstruktor

=head4 Synopsis

    $row = $class->new($tab,\@arr);

=head4 Arguments

=over 4

=item $tab

Referenz auf Tabellenobjekt.

=item @arr

Liste von Werten (Daten der Tabellenzeile).

=back

=head4 Returns

Referenz auf Zeilen-Objekt

=head4 Description

Instantiiere ein Zeilen-Objekt für Tabelle $tab mit den Zeilendaten @arr.

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$tab,$valueA) = @_;

    if (@$valueA != $tab->{'width'}) {
        $class->throw(
            'TABLE-00099: Unexpected array length',
            TableWidth => scalar @{$tab->{'columnA'}},
            ArrayLength => scalar @$valueA,
        );
    }
    Scalar::Util::weaken($tab);

    return bless [$tab,$valueA];
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 get() - Wert einer Kolumne

=head4 Synopsis

    $value = $row->get($column);

=head4 Arguments

=over 4

=item $column

Kolumnenname (String)

=back

=head4 Returns

Kolumnenwert (String)

=head4 Description

Liefere den Wert der Kolumne $column. Existiert die Kolumne nicht,
wird eine Exception geworfen.

=cut

# -----------------------------------------------------------------------------

sub get {
    my ($self,$column) = @_;
    return $self->[1]->[$self->[0]->{'columnH'}->{$column}];
}

# -----------------------------------------------------------------------------

=head3 values() - Liste der Zeilenwerte

=head4 Synopsis

    @values | $valueA = $row->values;

=head4 Returns

Liste der Zeilenwerte (Strings). Im Skalarkontext eine Referenz
auf die Liste.

=head4 Description

Liefere die Liste der Werte der Zeile.

=cut

# -----------------------------------------------------------------------------

sub values {
    my $self = shift;
    my $valueA = $self->[1];
    return wantarray? @$valueA: $valueA;
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
