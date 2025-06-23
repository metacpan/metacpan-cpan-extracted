# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Database::Row::Object::Join - Datensatz eines Join

=head1 BASE CLASS

L<Quiq::Database::Row::Object>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert einen Datensatz, der über mehreren
Tabellen gebildet ist.

Die DML-Operationen C<select>, C<insert>, C<update>, C<delete>
werden entweder individuell implementiert oder durch Delegation an
andere Klassen realisiert.

Das zugrunde liegende Select-Statement wird typischerweise als
Template auf der Klassenvariable C<$Select> definiert.

=cut

# -----------------------------------------------------------------------------

package Quiq::Database::Row::Object::Join;
use base qw/Quiq::Database::Row::Object/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

use Quiq::Array;
use Quiq::Hash;

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Statement-Ermittelung

=head3 selectTemplate() - Liefere Select-Template der Klasse

=head4 Synopsis

  $tmpl = $class->selectTemplate;

=head4 Returns

Select-Template (String)

=head4 Description

Liefere das Select-Template der Klasse. Dieses ist auf der
Klassenvariablen C<$Select> definiert und enthält typischerweise
Platzhalter, die bei einer Selektion durch die Selektionsskriterien
ersetzt werden.

Die Einsetzung von Selektionskriterien in das Template nimmt
die Methode L<selectStmt|"selectStmt() - Liefere Select-Statement der Klasse">() vor.

=head4 Example

Beispiel für die Definition eines Select-Template auf der
Klassenvariable C<$select>:

  our $Select = <<'__SQL__';
  SELECT
      %SELECT%
  FROM
      odin.route rou
      LEFT JOIN odin.section sec
      ON rou.id = sec.route_id
      LEFT JOIN odin.passage pas
      ON sec.id = pas.section_id
      LEFT JOIN odin.passage_measseq pam
      ON pas.id = pam.passage_id
      LEFT JOIN odin.measseq mea
      ON pam.measseq_id = mea.id
  __SQL__

Die Select-Klausel ist notwendig, da das Statement sonst nicht
syntaktisch korrekt gebildet ist. Die Platzhalter C<%WHERE%>,
C<%ORDERBY%> usw. müssen nicht erscheinen, da optionale Klauseln
bei entsprechenden Selektionskriterien am Ende des Statement
hinzugefügt werden.

=cut

# -----------------------------------------------------------------------------

sub selectTemplate {
    my $class = shift;
    my $db = shift;
    # @_: @select

    # FIXME: auf Klasse ClassConfig umstellen

    no strict 'refs';
    my $ref = *{"$class\::Select"}{SCALAR};
    if (!$$ref) {
        $class->throw(
            'ROW-00001: Join-Klasse definiert kein Select-Statement',
            JoinClass => $class,
        );
    }

    return $$ref;
}

# -----------------------------------------------------------------------------

=head3 selectStmt() - Liefere Select-Statement der Klasse

=head4 Synopsis

  $stmt = $class->selectStmt($db,@select);

=head4 Returns

Select-Statement (String)

=head4 Description

Liefere ein Select-Statement der Klasse gemäß den Selektionskriterien
C<@select>. Die Selektionskriterien werden in das Muster-Statement
eingesetzt (siehe L<selectTemplate|"selectTemplate() - Liefere Select-Template der Klasse">().

=cut

# -----------------------------------------------------------------------------

sub selectStmt {
    my $class = shift;
    my $db = shift;
    # @_: @select

    return $db->stmt->select($class->selectTemplate,@_);
}

# -----------------------------------------------------------------------------

=head2 Verschiedenes

=head3 cast() - Wandele Datensatz in Datensatz einer anderen Klasse

=head4 Synopsis

  $newRow = $row->cast($db,$newClass);

=head4 Arguments

=over 4

=item $db

Datenbankverbindung

=item $newClass

Neue Datensatzklasse

=back

=head4 Returns

Datensatz

=head4 Description

Wandele den Datensatz $row in einen Datensatz der Klasse $newClass
und liefere das Resultat zurück. Es ist ein fataler Fehler, wenn der
Datensatz keine zur Klasse $newClass gehörende Kolumne besitzt.

=head4 Details

Die Umwandelung umfasst die Schritte:

=over 4

=item 1.

Kopiere $row nach $newRow

=item 2.

Schränke $newRow auf die Kolumnen von $newClass ein

=item 3.

bless $newRow auf $newClass

=back

=cut

# -----------------------------------------------------------------------------

sub cast {
    my ($self,$db,$newClass) = @_;

    # Kolumnen ermitteln

    my $titles = $self->[1];
    my $newTitles = $newClass->titles($db);

    # Titellisten vergleichen

    my ($onlyA,$onlyNewA,$bothA) =
        Quiq::Array->compare($titles,$newTitles);
    if (!@$bothA) {
        $self->throw(
            'ROW-00006: Datensatz-Klassen haben keine gemeinsamen Kolumnen',
            RowClass => ref($self),
            CastClass => $newClass,
        );
    }
    if (@$onlyNewA) {
        # Wenn $self nicht alle $newClass-Kolumnen besitzt,
        # nehmen wir die individuelle Titelliste.
        $newTitles = $bothA;
    }

    # Zu übertragende Werte ermitteln

    my @newValues;
    for my $key (@$newTitles) {
        push @newValues,$self->[0]->{$key};
    }

    # Neuen Datensatz instantiieren.
    my $newRow = $newClass->new($newTitles,\@newValues);

    # Datensatz-Status übertragen (im Falle von U' kann
    # er sich auf 0 ändern, wenn die Änderungen keine
    # $newClass-Kolumnen betreffen. Siehe unten.

    $newRow->[2] = $self->[2];

    # Änderungen ermitteln (falls vorhanden)

    if ($self->[3]) {
        my $newChangesH = Quiq::Hash->new->unlockKeys;
        for my $key (@$newTitles) {
            if (exists $self->[3]->{$key}) {
                $newChangesH->{$key} = $self->[3]->{$key};
            }
        }
        if (%$newChangesH) {
            # Änderungen übertragen
            $newRow->[3] = $newChangesH;
        }
        elsif ($newRow->[2] eq 'U') {
            # Keine Änderungen übertragen, Status auf 0 zurücksetzen
            $newRow->[2] = 0;
        }
    }

    return $newRow;
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
