# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Database::Row - Basisklasse Datensatz (abstrakt)

=head1 BASE CLASS

L<Quiq::Object>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert einen Datensatz.

=cut

# -----------------------------------------------------------------------------

package Quiq::Database::Row;
use base qw/Quiq::Object/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

use Quiq::Perl;
use Quiq::Database::ResultSet::Object;

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Miscellaneous

=head3 tableClass() - Liefere Namen der Tabellenklasse

=head4 Synopsis

  $tableClass = $this->tableClass;

=head4 Returns

Name der Tabellenklasse (String)

=head4 Description

Ermittele den Namen der Tabellenklasse zur Datensatzklasse
und liefere diesen zurück.

=head4 Details

Eine Tabellenklasse speichert die Ergebnismenge einer Selektion.

Die bei einer Selektion verwendete Tabellenklasse hängt von der
Datensatz-Klasse ab. Es gelten die Defaults:

=over 2

=item *

Tabellenklasse bei Objekt-Datensätzen: C<< Quiq::Database::ResultSet::Object >>

=item *

Tabellenklasse bei Array-Datensätzen: C<< Quiq::Database::ResultSet::Array >>

=back

Abweichend vom Default kann eine abgeleitete Datensatzklasse die
Tabellenklasse über die Klassenvariable

  our $TableClass = '...';

festlegen.

Ferner ist es möglich, die Tabellenklasse bei der Selektion per
Option festzulegen:

  $tab = $rowClass->select($db,
      -tableClass => $tableClass,
  );

=cut

# -----------------------------------------------------------------------------

my %cache;

sub tableClass {
    my $class = ref $_[0] || $_[0];

    # FXIME: auf Klasse ClassConfig umstellen (?)

    # state %cache;

    if (!$cache{$class}) {
        no strict 'refs';
        my $found = 0;
        for ($class,Quiq::Perl->baseClassesISA($class)) {
            my $ref = *{"$_\::TableClass"}{SCALAR};
            if ($$ref) {
                $cache{$class} = $$ref;
                $found = 1;
                last;
            }
        }
        # Paranoia-Test
        if (!$found) {
            $class->throw(
                'ROW-00001: Datensatz-Klasse definiert keine Tabellenklasse',
                RowClass => $class,
            );
        }
    }

    return $cache{$class};
}

# -----------------------------------------------------------------------------

=head3 makeTable() - Erzeuge Datensatz-Tabelle

=head4 Synopsis

  $tab = $class->makeTable(\@titles,\@data);

=head4 Description

Erzeuge eine Datensatz-Tabelle mit Kolumnentiteln @titles und den
Datensätzen @rows und liefere eine Referenz auf dieses Objekt zurück.

=head4 Example

Instanttierung über spezifische Datensatz-Klasse:

  $tab = Person->makeTable(
      [qw/per_id per_vorname per_nachname per_geburtsdatum/],
      qw/1 Rudi Ratlos 1971-04-23/,
      qw/2 Erika Mustermann 1955-03-16/,
      qw/3 Harry Hirsch 1948-07-22/,
      qw/3 Susi Sorglos 1992-10-23/,
  );

Instanttierung über anonyme Datensatz-Klasse:

  $tab = Quiq::Database::Row::Object->makeTable(
      [qw/per_id per_vorname per_nachname per_geburtsdatum/],
      qw/1 Rudi Ratlos 1971-04-23/,
      qw/2 Erika Mustermann 1955-03-16/,
      qw/3 Harry Hirsch 1948-07-22/,
      qw/3 Susi Sorglos 1992-10-23/,
  );

=cut

# -----------------------------------------------------------------------------

sub makeTable {
    my $class = shift;
    my $titles = shift;
    # @_: @rows;

    my $n = scalar @$titles;

    my @rows;
    while (@_) {
        my @arr = splice @_,0,$n;
        push @rows,$class->new($titles,\@arr);
    }

    return $class->tableClass->new($class,$titles,\@rows);
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.228

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2025 Frank Seitz

=head1 LICENSE

This code is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# -----------------------------------------------------------------------------

1;

# eof
