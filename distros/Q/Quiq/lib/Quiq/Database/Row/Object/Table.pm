package Quiq::Database::Row::Object::Table;
use base qw/Quiq::Database::Row::Object Quiq::ClassConfig/;

use strict;
use warnings;
use v5.10.0;
use utf8;

our $VERSION = '1.149';

use Quiq::Perl;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Database::Row::Object::Table - Datensatz einer Tabelle

=head1 BASE CLASSES

=over 2

=item *

L<Quiq::Database::Row::Object>

=item *

L<Quiq::ClassConfig>

=back

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert einen Datensatz, der aus einer
einzelnen Datenbank-Tabelle stammt.

Die DML-Operationen (select, insert, update, delete) der Klasse
operieren auf der Tabelle. Entsprechend definiert die Klasse einen
Tabellennamen. Dieser wird von der Methode L<tableName|"tableName() - Liefere Namen der Datenbanktabelle">() geliefert.

Über eine Tabelle wird vorausgesetzt, dass diese eine
Primärschlüssel-Kolumne besitzt. Deren Name wird von der Methode
L<primaryKey|"primaryKey() - Liefere Namen der Primärschlüssel-Kolumne">() geliefert.

=head1 METHODS

=head2 Meta-Information

=head3 tableName() - Liefere Namen der Datenbanktabelle

=head4 Synopsis

    $tableName = $this->tableName;

=head4 Alias

table()

=head4 Returns

Tabellenname (String)

=head4 Description

Bestimme den Namen der Datenbanktabelle, welche die Klasse kapselt,
und liefere diesen zurück.

=head4 Example

Tabellenname wird aus Klassenname abgeleitet:

    Adb::Table::Person => person
    Adb::Person => person
    Person => person

Tabellenname per Klassenvariable definieren:

    our $TableName = 'adb.person';

=head4 Details

Der Tabellenname ist per Default die in Kleinschreibung gewandelte
letzte Komponente des Klassennamens.

Abweichend vom Default kann die Datensatzklasse den Tabellennamen
über die Klassenvariable

    our $TableName = '...';

festlegen.

Die Methode kann in abgeleiteten Klassen überschrieben werden,
um den Tabellennamen auf andere Weise zu bestimmen, z.B. um einen
Schemapräfix aus einer weiteren Klassennamen-Komponente hinzuzufügen.

=cut

# -----------------------------------------------------------------------------

my %cache;

sub tableName {
    my $class = ref $_[0] || $_[0];

    # FXIME: auf Klasse ClassConfig umstellen (?)

    # state %cache;

    if (!$cache{$class}) {
        no strict 'refs';
        my $found = 0;
        for ($class,Quiq::Perl->baseClassesISA($class)) {
            my $ref = *{"$_\::TableName"}{SCALAR};
            if ($$ref) {
                $cache{$class} = $$ref;
                $found = 1;
                last;
            }
        }
        if (!$found) {
            $class =~ /(\w+)$/;
            $cache{$class} = lc $1;
        }
    }

    return $cache{$class};
}

{
    no warnings 'once';
    *table = \&tableName;
}

# -----------------------------------------------------------------------------

=head3 primaryKey() - Liefere Namen der Primärschlüssel-Kolumne

=head4 Synopsis

    $title = $this->primaryKey($db);

=head4 Description

Bestimme den Namen der Primärschlüsselkolumne und liefere diesen zurück.
Der Name wird folgendermaßen ermittelt:

=over 4

=item 1.

...

=item 2.

Ist 1. nicht der Fall, wird als Primärschlüsselkolumne die
erste Kolumne der Ergebnistabelle angenommen.

=back

=cut

# -----------------------------------------------------------------------------

sub primaryKey {
    my ($this,$db) = @_;
    return $db->titles($this->tableName)->[0];
}

# -----------------------------------------------------------------------------

=head3 primaryKeyWhere() - Liefere Primary-Key Bedingung

=head4 Synopsis

    @where = $row->primaryKeyWhere($db);

=head4 Description

Liefere die WHERE-Bedingung ($key=>$value) für den Datensatz $row,
bestehend aus dem Namen der Primärschlüsselkolumne und deren Wert.
Hat die Primärschlüsselkolumne keinen Wert, wirf eine Exception.

Die Methode liefert die WHERE-Bedingung für UPDATEs und DELETEs
auf dem Datensatz.

=cut

# -----------------------------------------------------------------------------

sub primaryKeyWhere {
    my ($self,$db) = @_;

    my $key = $self->primaryKey($db);
    my $val = $self->$key;
    if ($val eq '') {
        $self->throw(
            'ROW-00005: Primärschlüsselkolumne ist NULL',
            PrimaryKeyColumn => $key,
            Row => $self->asString('|'),
        );
    }

    return ($key,$val);
}

# -----------------------------------------------------------------------------

=head3 nullRow() - Liefere Null-Datensatz

=head4 Synopsis

    $row = $class->nullRow($db);

=cut

# -----------------------------------------------------------------------------

sub nullRow {
    my ($class,$db) = @_;
    return $db->nullRow($class->tableName,-rowClass=>$class);
}

# -----------------------------------------------------------------------------

=head2 Statement-Generierung

=head3 selectStmt() - Liefere Select-Statement der Klasse

=head4 Synopsis

    $stmt = $class->selectStmt($db,@select);

=cut

# -----------------------------------------------------------------------------

sub selectStmt {
    my $class = shift;
    my $db = shift;
    # @_: @select

    return $db->stmt->select($class->tableName,@_);
}

# -----------------------------------------------------------------------------

=head3 insertStmt() - Liefere Insert-Statement für Datensatz

=head4 Synopsis

    $stmt = $row->insertStmt($db);

=cut

# -----------------------------------------------------------------------------

sub insertStmt {
    my ($self,$db) = @_;

    my @keyVal;
    for my $title ($self->titles) {
        push @keyVal,$title,$self->$title;
    }

    return $db->stmt->insert($self->tableName,@keyVal);
}

# -----------------------------------------------------------------------------

=head3 updateStmt() - Liefere Update-Statement für Datensatz

=head4 Synopsis

    $stmt = $row->updateStmt($db);

=cut

# -----------------------------------------------------------------------------

sub updateStmt {
    my ($self,$db) = @_;

    my @keyVal;
    for my $title ($self->titles) {
        push @keyVal,$title,$self->$title;
    }

    return $db->stmt->update($self->tableName,@keyVal,
        -where,$self->primaryKeyWhere($db),
    );
}

# -----------------------------------------------------------------------------

=head3 deleteStmt() - Liefere Delete-Statement für Datensatz

=head4 Synopsis

    $stmt = $row->deleteStmt($db);

=cut

# -----------------------------------------------------------------------------

sub deleteStmt {
    my ($self,$db) = @_;
    return $db->stmt->delete($self->tableName,$self->primaryKeyWhere($db));
}

# -----------------------------------------------------------------------------

=head2 Datenbank-Operationen

=head3 load() - Lade Datensatz

=head4 Synopsis

    $row = $class->load($db,$pkValue);

=head4 Description

Lade Datensatz mit Primärschlüssel $pkValue. Ist $pkValue nicht
angegeben oder Null (Leerstring oder undef), liefere einen leeren
Datensatz.

Diese Methode ist nützlich, um ein Formular mit einem neuen
oder existierenden Datensatz zu versorgen.

=cut

# -----------------------------------------------------------------------------

sub load {
    my $class = shift;
    my $db = shift;
    my $pkValue = shift;

    if (defined $pkValue && $pkValue ne '') {
        my $pkName = $class->primaryKey($db);
        return $class->lookup($db,$pkName=>$pkValue);
    }

    return $class->nullRow($db);
}

# -----------------------------------------------------------------------------

=head3 insert() - Füge Datensatz zur Datenbank hinzu

=head4 Synopsis

    $cur = $row->insert($db);

=head4 Description

Füge den Datensatz zur Datenbank hinzu und liefere das Resultat der
Ausführung zurück.

Nach der Ausführung hat der Datensatz den Rowstatus 0.

=cut

# -----------------------------------------------------------------------------

sub insert {
    my ($self,$db) = @_;

    my $stmt = $self->insertStmt($db);
    my $cur = $db->sql($stmt);
    $self->rowStatus(0);

    return $cur;
}

# -----------------------------------------------------------------------------

=head3 update() - Aktualisiere Datensatz auf der Datenbank

=head4 Synopsis

    $cur = $row->update($db);

=head4 Description

Aktualisiere den Datensatz auf der Datenbank und liefere das Resultat der
Ausführung zurück.

Nach der Ausführung hat der Datensatz den Rowstatus 0.

=cut

# -----------------------------------------------------------------------------

sub update {
    my ($self,$db) = @_;

    my $stmt = $self->updateStmt($db);
    my $cur = $db->sql($stmt);
    $self->rowStatus(0);

    return $cur;
}

# -----------------------------------------------------------------------------

=head3 delete() - Lösche Datensatz von der Datenbank

=head4 Synopsis

    $cur = $row->delete($db);

=head4 Description

Lösche den Datensatz von der Datenbank und liefere das Resultat der
Ausführung zurück.

Nach der Ausführung hat der Datensatz den Rowstatus 'I'.

=cut

# -----------------------------------------------------------------------------

sub delete {
    my ($self,$db) = @_;

    my $stmt = $self->deleteStmt($db);
    my $cur = $db->sql($stmt);
    $self->rowStatus('I');

    return $cur;
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
