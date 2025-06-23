# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Database::Tree - Baum von Datensätzen

=head1 BASE CLASS

L<Quiq::Hash>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert eine Menge von Datensätzen,
die mittels zweier Attribute $pkColumn und $fkColumn in einer
hierarchischen Beziehung zueinander stehen und somit eine
Baumstruktur bilden. Die Klasse bietet Methoden, um auf dieser
Baumstruktur operieren zu können.

=cut

# -----------------------------------------------------------------------------

package Quiq::Database::Tree;
use base qw/Quiq::Hash/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

use Time::HiRes ();

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Baum von Datensätzen

=head4 Synopsis

  $tree = $class->new($tab,$pkColumn,$fkColumn,@opt);

=head4 Options

=over 4

=item -whenNoParentRow => 'removeRow'|'removeReference'|'throwException' \

(Default: 'throwException')
Was getan werden soll, wenn der Parent eines Child-Datensatzes in
der Ergebnismenge nicht enthalten ist:

=over 4

=item 'removeRow'

Entferne den Datensatz aus der Ergebnismenge.

=item 'removeReference'

Setze die Referenz auf NULL (Leerstring). Der Child-Datensatz
wird damit logisch zu einem Parent-Datensatz.

=item 'throwException'

Wirf eine Exception.

=back

Die Varianten 'removeRow' und 'removeReference' sind nützlich, wenn
die Ergebnismenge nicht alle Sätze enthält, sondern nur eine Teilmenge,
z.B. aufgrund einer Selektion mit -limit.

=back

=head4 Description

Instantiiere ein Baum-Objekt aus den Datensätzen des ResultSet
$tab. Die Datensätze stehen über die Attribute $pkColumn und
$fkColumn in einer hierarchischen Beziehung.

=head4 Example

Datensätze:

  id parent_id name
  -- --------- ----
  1  NULL      A
  2  1         B
  3  2         C
  4  1         D

Pfade:

  A
  A/B
  A/B/C
  A/D

Baum:

  A
  +-B
  | \-C
  +-D

Aufruf:

  $tree = Quiq::Database::Tree->new($tab,'id','parent_id');

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$tab,$pkColumn,$fkColumn) = splice @_,0,4;

    # Optionen

    my $whenNoParentRow = 'throwException';

    $class->parameters(\@_,
        -whenNoParentRow => \$whenNoParentRow,
    );

    # Operation ausführen

    # Typbezeichner für Baumverknüpfung erzeugen
    my $type = sprintf 'Tree%s',scalar Time::HiRes::gettimeofday;

    # Kind-Typ zu allen Datensätzen hinzufügen
    $tab->addChildType($type);

    # Primary-Key-Index erzeugen
    my $h = $tab->index($pkColumn)->lockKeys;

    # Datensätze miteinander verknüpfen

    my $rowA = $tab->rows;
    for (my $i = 0; $i < @$rowA; $i++) {
        my $row = $rowA->[$i];
        if (my $pk = $row->$fkColumn) {
            my $par = $h->try($pk);
            if (!$par) {
                if ($whenNoParentRow eq 'removeRow') {
                    splice @$rowA,$i--,1;
                    next;
                }
                elsif ($whenNoParentRow eq 'removeReference') {
                    $row->$fkColumn('');
                    next;
                }
                $class->throw(
                    'TREE-00099: Parent row not found',
                    $pkColumn => $pk,
                );
            }
            $row->addParent($type,$par);
            $par->addChild($type,$row);
        }
    }

    return $class->SUPER::new(
        table => $tab,
        fkColumn => $fkColumn,
        type => $type,
        pkIndex => $h,
    );
}

# -----------------------------------------------------------------------------

=head2 Akzessoren

=head3 table() - ResultSet-Objekt

=head4 Synopsis

  $tab = $tree->table;

=head4 Description

Liefere das ResultSet-Objekt, das beim Konstruktor angegeben wurde.

=head3 pkIndex() - Primary-Key-Index

=head4 Synopsis

  $h = $tree->pkIndex;

=head4 Description

Liefere eine Referenz auf den Hash, der die Datensätze nach
Primary-Key-Index indiziert.

=head3 type() - Typ-Bezeichner

=head4 Synopsis

  $type = $tree->type;

=head4 Description

Liefere den (intern generierten) Typ-Bezeichner, für den die
Datensatz-Verknüpfung definiert ist.

=head2 Objektmethoden

=head3 childs() - Kind-Datensätze

=head4 Synopsis

  @rows|$tab = $tree->childs($row);
  @rows|$tab = $tree->childs($pk);

=head4 Description

Liefere die Liste der Kind-Datensätze - also der I<unmittelbar>
untergeordneten Datensätze - zum Datensatz $row bzw. zum Datensatz
mit dem Primärschlüssel $pk. Besitzt der Datensatz keine
Kind-Datensätze, ist die Liste leer. Im Skalarkontext liefere ein
ResultSet-Objekt mit den Datensätzen.

=head4 Example

Aufruf:

  @rows = $tree->childs(1);

Resultat:

  id parent_id name
  -- --------- ----
  2  1         B
  4  1         D

=cut

# -----------------------------------------------------------------------------

sub childs {
    my $self = shift;
    my $row = $self->lookup(shift);
    my @rows = $row->getChilds($self->type);
    return wantarray? @rows: $self->table->new(\@rows);
}

# -----------------------------------------------------------------------------

=head3 descendants() - Untergeordnete Datensätze

=head4 Synopsis

  @rows = $tree->descendants($row);
  @rows = $tree->descendants($pk);

=head4 Description

Liefere die Liste I<aller> untergeordneten Datensätze zum
Datensatz $row bzw. zum Datensatz mit dem Primärschlüssel
$pk. Besitzt der Datensatz keine untergeordneten Datensätze, ist
die Liste leer. Die Reihenfolge der Datensätze entspricht der
einer Tiefensuche. Im Skalarkontext liefere ein ResultSet-Objekt
mit den Datensätzen.

=head4 Example

Aufruf:

  @rows = $tree->descendants(1);

Resultat:

  id parent_id name
  -- --------- ----
  2  1         B
  3  2         C
  4  1         D

=cut

# -----------------------------------------------------------------------------

sub descendants {
    my ($self,$arg) = @_;

    my @rows;
    for my $row ($self->childs($arg)) {
        push @rows,$row,$self->childs($row);
    }

    return wantarray? @rows: $self->table->new(\@rows);
}

# -----------------------------------------------------------------------------

=head3 generatePathAttribute() - Erzeuge Pfad-Attribut

=head4 Synopsis

  $tree->generatePathAttribute($key,$valColumn,$sep);

=head4 Description

Füge zu allen Datensätzen das Attribut $key hinzu und setze
es auf den Pfad gemäß Datensatz-Attribut $valColumn mit
der Trenn-Zeichenkette $sep. Die Methode liefert keinen Wert zurück.

=head4 Example

Aufruf:

  $tree->generatePathAttribute('path','name','/');

Erweitert alle Datensätze um das Attribut 'path':

  id parent_id name path
  -- --------- ---- -----
  1  NULL      A    A
  2  1         B    A/B
  3  2         C    A/B/C
  4  1         D    A/D

=cut

# -----------------------------------------------------------------------------

sub generatePathAttribute {
    my ($self,$key,$valColumn,$sep) = @_;

    for my $row (@{$self->rows}) {
        $row->add($key=>$self->path($row,$valColumn,$sep));
    }

    return;
}

# -----------------------------------------------------------------------------

=head3 hierarchy() - Datensätze als Hierarchie

=head4 Synopsis

  @rows|$rowA = $tree->hierarchy(@opt);

=head4 Options

=over 4

=item -childSort => $sub (Default: sub {0})

Sortierfunktion für die Kind-Datensätze (die Wurzel-Datensätze bleiben
in ihrer gegebenen Reihenfolge).

ACHTUNG: Die Sortierfunktion muss mit Prototype ($$) vereinbart werden,
damit die Elemente per Parameter und nicht mittels der globalen Variablen
$a und $b übergeben werden. Denn die globalen Variablen befinden sich
in einem anderen Package als dem, in dem die Sortierfunktion aufgerufen
wird. Beispiel:

  -childSort => sub ($$) {
      $_[0]->id <=> $_[1]->id;
  }

=item -setTable => $bool (Default: 0)

Setze die hierarchische Reihenfolge auf der zugrunde liegenden Tabelle.
D.h. $tree->table->rows() liefert die Datensätze fortan in dieser
Reihenfolge.

=back

=head4 Description

Liefere die Datensätze der Ergebnismenge in hierarchischer Reihenfolge,
also die Kind-Sätze in der Reihenfolge einer Tiefensuche.

=cut

# -----------------------------------------------------------------------------

sub hierarchy {
    my $self = shift;

    # Optionen

    my $childSort = sub {0};
    my $setTable = 0;

    $self->parameters(\@_,
        -childSort => \$childSort,
        -setTable => \$setTable,
    );

    # Eingebettete rekursive Funktion

    my $treeSub; # Vorab-Deklaration wg. Rekursion
    $treeSub = sub {
        my $row = shift;

        my @rows = ($row);
        for my $row (sort $childSort $self->childs($row)) {
            push @rows,$treeSub->($row);
        }

        return @rows;
    };

    # Wurzelknoten in ihrer gegebenen Reihenfolge

    my @rows;
    for my $row (@{$self->roots}) {
        push @rows,$treeSub->($row);
    }

    if ($setTable) {
        # Setze die Reihenfolge der Datensätze auf der
        # zugrunde liegenden Tabelle
        $self->table->set(rows=>\@rows);
    }

    return wantarray? @rows: \@rows;
}

# -----------------------------------------------------------------------------

=head3 level() - Anzahl der übergeordneten Knoten

=head4 Synopsis

  $level = $tree->level($pk);
  $level = $tree->level($row);

=cut

# -----------------------------------------------------------------------------

sub level {
    my ($self,$arg) = @_;

    my $row = ref $arg? $arg: $self->pkIndex->get($arg);
    my $type = $self->type;

    my $i = 0;
    while ($row = $row->getParent($type)) {
        $i++;
    }

    return $i;
}

# -----------------------------------------------------------------------------

=head3 lookup() - Datensatz-Lookup

=head4 Synopsis

  $row = $tree->lookup($pk);
  $row = $tree->lookup($row);

=head4 Description

Liefere den Datensatz mit dem Primärschlüssel $pk. Wird ein
Datensatz $row übergeben, wird dieser unmittelbar
zurückgeliefert. Dies ist nützlich, wenn die Methode genutzt wird
um eine Variable zu einem Datensatz aufzulösen, die ein
Primärschlüssel oder Datensatz sein kann. Die Klasse selbst nutzt
die Methode zu diesem Zweck.

=cut

# -----------------------------------------------------------------------------

sub lookup {
    my ($self,$arg) = @_;
    return ref $arg? $arg: $self->pkIndex->get($arg);
}

# -----------------------------------------------------------------------------

=head3 parent() - Eltern-Datensatz

=head4 Synopsis

  $par = $tree->parent($row);
  $par = $tree->parent($pk);

=head4 Description

Liefere den Eltern-Datensatz zum Datensatz $row bzw. zum
Datensatz mit dem Primärschlüssel $pk. Besitzt der Datensatz
keinen Eltern-Datensatz, liefere undef.

=head4 Example

Aufruf:

  $row = $tree->parent(3);

Resultat (ein Datensatz):

  id parent_id name
  -- --------- ----
  2  1         B

=cut

# -----------------------------------------------------------------------------

sub parent {
    my $self = shift;
    my $row = $self->lookup(shift);
    return $row->getParent($self->type);
}

# -----------------------------------------------------------------------------

=head3 path() - Datensatz-Pfad (Datensatz-Liste, Wert-Liste, Zeichenkette)

=head4 Synopsis

  @rows = $tree->path($row);
  @rows = $tree->path($pk);
  
  @values = $tree->path($row,$key);
  @values = $tree->path($pk,$key);
  
  $path = $tree->path($row,$key,$sep);
  $path = $tree->path($pk,$key,$sep);

=head4 Description

Ermittele die Pfad-Datensätze, die Pfad-Werte oder den Pfad des
Datensatzes $row bzw. des Datensatzes mit dem Primärschlüssel $pk
gemäß der Datensatz-Hierarchie und liefere das Resultat zurück.

Ist Argument $key angegeben, wird die Liste der Werte des
Attributs $key geliefert.

Ist zusätzlich Argument $sep angegeben, wird die Liste der Werte
mit $sep getrennt zu einer Zeichenkette zusammengefügt.

=head4 Examples

=over 2

=item *

Pfad als Liste von id-Werten

Aufruf:

  @values = $tree->path(3,'id');

Resultat:

  (1,2,3)

Datensätze und ihre id-Wert-Pfade:

  id parent_id name @values
  -- --------- ---- -------
  1  NULL      A    (1)
  2  1         B    (1,2)
  3  2         C    (1,2,3)
  4  1         D    (1,4)

=item *

Pfad als Zeichenkette

Aufruf:

  $path = $tree->path(3,'name','/');

Resultat:

  'A/B/C'

Datensätze und ihre name-Pfade:

  id parent_id name $path
  -- --------- ---- -----
  1  NULL      A    A
  2  1         B    A/B
  3  2         C    A/B/C
  4  1         D    A/D

=back

=cut

# -----------------------------------------------------------------------------

sub path {
    my $self = shift;
    my $row = $self->lookup(shift);
    # @_: $key -or- $key,$sep

    # Liste der Pfad-Datensätze

    my @rows = ($row);
    while ($row = $self->parent($row)) {
        unshift @rows,$row;
    }
    if (!@_) {
        return @rows;
    }

    # Liste der Pfad-Werte

    my $key = shift;
    my @values = map {$_->$key} @rows;
    if (!@_) {
        return @values;
    }

    # Pfad-Zeichenkette

    my $sep = shift;
    return join($sep,@values);
}

# -----------------------------------------------------------------------------

=head3 rows() - Alle Datensätze (Knoten) des Baums

=head4 Synopsis

  @rows|$rowA = $tree->rows;

=head4 Description

Liefere die Datensätze des Baums. Die Reihenfolge entspricht
der Reihenfolge der zugrundeliegenden Tabelle $tab (s. Konstruktor).

=cut

# -----------------------------------------------------------------------------

sub rows {
    shift->table->rows;
}

# -----------------------------------------------------------------------------

=head3 roots() - Alle Wurzel-Datensätze

=head4 Synopsis

  @rows|$rowA = $tree->roots;

=head4 Description

Liefere die Liste der Wurzel-Datensätze, also alle Datensätze, die
keinen Parent haben. Die Reihenfolge entspricht der Reihenfolge der
zugrundeliegenden Tabelle $tab (s. Konstruktor).

=cut

# -----------------------------------------------------------------------------

sub roots {
    my $self = shift;
    my @rows = grep {!$self->parent($_)} $self->rows;
    return wantarray? @rows: \@rows;
}

# -----------------------------------------------------------------------------

=head3 siblings() - Geschwister-Datensätze

=head4 Synopsis

  @rows|$tab = $tree->siblings($row);
  @rows|$tab = $tree->siblings($pk);

=head4 Description

Liefere die Liste der Geschwister-Datensätze zum Datensatz $row
bzw. zum Datensatz mit dem Primärschlüssel $pk. Besitzt der
Datensatz keine Geschwister-Datensätze, ist die Liste leer.
Im Skalarkontext liefere ein ResultSet-Objekt mit den Datensätzen.

=cut

# -----------------------------------------------------------------------------

sub siblings {
    my $self = shift;
    my $row = $self->lookup(shift);

    my @rows;
    if (my $par = $self->parent($row)) {
        @rows = $self->childs($par);
        for (my $i = 0; $i < @rows; $i++) {
            if ($rows[$i] == $row) {
                splice @rows,$i,1;
                last;
            }
        }
    }

    return wantarray? @rows: $self->table->new(\@rows);
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
