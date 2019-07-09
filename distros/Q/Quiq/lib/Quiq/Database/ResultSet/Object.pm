package Quiq::Database::ResultSet::Object;
use base qw/Quiq::Database::ResultSet/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.151';

use Quiq::Option;
use Quiq::Hash;
use Quiq::Array;
use Quiq::Formatter;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Database::ResultSet::Object - Liste von Datensätzen in Objekt-Repräsentation

=head1 BASE CLASS

L<Quiq::Database::ResultSet>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert eine Liste von gleichartigen
Datensätzen in Objekt-Repräsentation.

=head1 METHODS

=head2 Subklassenfunktionalität

=head3 lookupSub() - Suche Datensatz

=head4 Synopsis

    $row = $tab->lookupSub($key=>$val);

=head4 Description

Durchsuche die Tabelle nach dem ersten Datensatz, dessen
Attribut $key den Wert $val besitzt und liefere diesen zurück.
Erfüllt kein Datensatz das Kriterium, liefere undef.

=cut

# -----------------------------------------------------------------------------

sub lookupSub {
    my ($self,$key,$val) = @_;

    for my $row (@{$self->rows}) {
        if ($row->$key eq $val) {
            return $row;
        }
    }

    return undef;
}

# -----------------------------------------------------------------------------

=head3 values() - Liefere Kolumnenwerte als Liste oder Hash

=head4 Synopsis

    @vals|$valA = $tab->values($key,@opt);
    %vals|$valH = $tab->values($key,@opt,-hash=>1);

=head4 Options

=over 4

=item -distinct => $bool (Default: 0)

Liefere in der Resultatliste nur verschiedene Kolumenwerte. Wird ein
Hash geliefert, ist dies zwangsläufig der Fall. Der Wert findet
sich in der Resultatliste an der Stelle seines ersten Auftretens.

=item -hash => $bool (Default: 0)

Liefere einen Hash bzw. eine Hashreferenz (Quiq::Hash) mit den
Kolumnenwerten als Schlüssel und 1 als Wert.

=item -notNull => $bool (Default: 0)

Ignoriere Nullwerte, d.h. nimm sie nicht ins Resultat auf.

=back

=cut

# -----------------------------------------------------------------------------

sub values {
    my $self = shift;
    my $key = shift;
    # @_: @opt

    my $distinct = 0;
    my $hash = 0;
    my $notNull = 0;

    if (@_) {
        Quiq::Option->extract(\@_,
            -distinct => \$distinct,
            -hash => \$hash,
            -notNull => \$notNull,
        );
    }

    my (@arr,%seen);
    for my $row (@{$self->rows}) {
        my $val = $row->$key;
        if ($notNull && $val eq '') {
            next;
        }
        if ($distinct && $seen{$val}++) {
            next;
        }
        CORE::push @arr,$val;
        if ($hash) {
            CORE::push @arr,1;
        }
    }

    if (wantarray) {
        return @arr;
    }
    elsif ($hash) {
        return Quiq::Hash->new({@arr})->unlockKeys;
    }
    else {
        return Quiq::Array->new(\@arr);
    }
}

# -----------------------------------------------------------------------------

=head3 index() - Indiziere Tabelle nach Kolumne(n)

=head4 Synopsis

    %idx|$idxH = $tab->index(@keys,@opts);

=head4 Options

=over 4

=item -unique => $bool (Default: 1)

Sollte auf 0 gesetzt werden, wenn die @keys nicht eindeutig sind.
Dann ist der Hashwert nicht die jeweilige Row, sondern eine
Referenz auf ein Array von Rows (auch wenn nur eine Row enthalten
ist).

=back

=head4 Description

Generiere einen Hash mit den Werten der Kolumen @keys als Schlüssel
und mit dem Datensatz als Wert. Im skalaren Kontext liefere eine
Referenz auf den Hash.

Wird der Index über mehreren Keys gebildet, werden die einzelnen
Werte im Hash mit einem senkrechten Strich ('|') getrennt.

=cut

# -----------------------------------------------------------------------------

sub index {
    my $self = shift;
    # @_: @keys,@opts

    # Optionen

    my $unique = 1;

    Quiq::Option->extract(\@_,
        -unique => \$unique,
    );

    # Verarbeitung

    my %idx;
    for my $row (@{$self->rows}) {
        my $indexKey;
        for my $key (@_) {
            if ($indexKey) {
                $indexKey .= '|';
            }
            $indexKey .= $row->$key;
        }
        if ($unique) {
            # FIXME: Eindeutigkeit prüfen?
            $idx{$indexKey} = $row;
        }
        else {
            my $arr = $idx{$indexKey} ||= [];
            push @$arr,$row;
        }
    }

    return wantarray? %idx: Quiq::Hash->new(\%idx)->unlockKeys;
}

# -----------------------------------------------------------------------------

=head3 min() - Numerisches Minimum der Kolumne

=head4 Synopsis

    $min = $tab->min($key);

=cut

# -----------------------------------------------------------------------------

sub min {
    my ($self,$key) = @_;

    my $min;
    for my $row (@{$self->rows}) {
        my $x = $row->$key;
        if ($x ne '' && (!defined($min) || $x < $min)) {
            $min = $x;
        }
    }

    return $min;
}

# -----------------------------------------------------------------------------

=head3 maxLength() - Maximale Länge der Kolumnenwerte

=head4 Synopsis

    $len = $tab->maxLength($key);
    @len = $tab->maxLength(@keys);

=cut

# -----------------------------------------------------------------------------

sub maxLength {
    my $self = shift;
    # @_: @keys

    my @len = (0) x @_;
    for my $row (@{$self->rows}) {
        for (my $i = 0; $i < @_; $i++) {
            my $key = $_[$i];
            my $l = length $row->$key;
            if ($l > $len[$i]) {
                $len[$i] = $l;
            }
        }
    }

    return wantarray? @len: $len[0];
}

# -----------------------------------------------------------------------------

=head3 max() - Numerisches Maximum der Kolumne

=head4 Synopsis

    $max = $tab->max($key);

=cut

# -----------------------------------------------------------------------------

sub max {
    my ($self,$key) = @_;

    my $max;
    for my $row (@{$self->rows}) {
        my $x = $row->$key;
        if ($x ne '' && (!defined($max) || $x > $max)) {
            $max = $x;
        }
    }

    return $max;
}

# -----------------------------------------------------------------------------

=head3 minStr() - Alphaumerisches Minimum der Kolumne

=head4 Synopsis

    $min = $tab->minStr($key);

=cut

# -----------------------------------------------------------------------------

sub minStr {
    my ($self,$key) = @_;

    my $min;
    for my $row (@{$self->rows}) {
        my $x = $row->$key;
        if ($x ne '' && (!defined($min) || $x le $min)) {
            $min = $x;
        }
    }

    return $min;
}

# -----------------------------------------------------------------------------

=head3 maxStr() - Alphanumerisches Maximum der Kolumne

=head4 Synopsis

    $max = $tab->maxStr($key);

=cut

# -----------------------------------------------------------------------------

sub maxStr {
    my ($self,$key) = @_;

    my $max;
    for my $row (@{$self->rows}) {
        my $x = $row->$key;
        if ($x ne '' && (!defined($max) || $x gt $max)) {
            $max = $x;
        }
    }

    return $max;
}

# -----------------------------------------------------------------------------

=head2 Verschiedenes

=head3 sort() - Sortiere Datensätze

=head4 Synopsis

    $tab->sort($sub);

=head4 Description

Sortiere die Datensätze gemäß der anonymen Sortierfunktion $sub.

ACHTUNG: Die Sortierfunktion muss mit Prototype ($$) vereinbart
werden, damit die Elemente per Parameter und nicht mittels
der globalen Variablen $a und $b übergeben werden. Denn die globalen
Variablen befinden sich in einem anderen Package als dem, in dem
die Sortierfunktion aufgerufen wird. Für eine korrekte
Definition siehe Beispiel.

=head4 Example

    $tab->sort(sub ($$) {
        my ($a,$b) = @_;
        uc($a->pfad) cmp uc($b->pfad);
    });

=cut

# -----------------------------------------------------------------------------

sub sort {
    my ($self,$sub) = @_;

    my $rowA = $self->{'rows'};
    @$rowA = sort $sub @$rowA;

    return;
}

# -----------------------------------------------------------------------------

=head3 absorbModifications() - Absorbiere Datensatz-Änderungen

=head4 Synopsis

    $tab->absorbModifications;

=head4 Returns

nichts

=head4 See Also

$row->absorbModifications()

=cut

# -----------------------------------------------------------------------------

sub absorbModifications {
    my $self = shift;

    for my $row (@{$self->rows}) {
        $row->absorbModifications;
    }

    return;
}

# -----------------------------------------------------------------------------

=head3 addAttribute() - Füge Attribut zu allen Datensätzen hinzu

=head4 Synopsis

    $tab->addAttribute($key);
    $tab->addAttribute($key=>$val);

=head4 Arguments

=over 4

=item $key

Attributname.

=item $val

Attributwert.

=back

=head4 Description

Füge Attribut $key mit Wert $val zu allen Datensätzen der
Ergebnismenge hinzu. Ist $val nicht angegeben, setze den Wert auf
den Nullwert (Leerstring).

=cut

# -----------------------------------------------------------------------------

sub addAttribute {
    my ($self,$key) = splice @_,0,2;
    my $val = shift // '';

    for my $row (@{$self->rows}) {
        $row->addAttribute($key=>$val);
    }

    return;
}

# -----------------------------------------------------------------------------

=head3 normalizeNumber() - Normalisiere Zahldarstellung

=head4 Synopsis

    $tab->normalizeNumber(@titles);

=head4 Alias

fixNumber()

=head4 Returns

nichts

=head4 Description

Normalisiere die Zahldarstellung der genannten Kolumnen. D.h. entferne
unnötige Nullen und forciere als Dezimaltrennzeichen einen Punkt
(anstelle eines Komma).

=cut

# -----------------------------------------------------------------------------

sub normalizeNumber {
    my $self = shift;
    # @_: @titles

    for my $row (@{$self->rows}) {
        for my $title (@_) {
            my $val = $row->$title;
            $val = Quiq::Formatter->normalizeNumber($val);
            $row->$title($val);
        }
    }

    return;
}

{
    no warnings 'once';
    *fixNumber = \&normalizeNumber;
}

# -----------------------------------------------------------------------------

=head3 addChildType() - Füge Kind-Datensatz-Typ zu allen Datensätzen hinzu

=head4 Synopsis

    $tab->addChildType($type);
    $tab->addChildType($type,$rowClass,\@titles);

=head4 Description

Füge Kind-Datensatz-Typ $type mit Datensatz-Klasse $rowClass und
den Kolumnentiteln @titles zu allen Datensätzen des ResultSet $tab
hinzu.

Findet die Verknüfung zwischen den Datensätzen des ResultSet
selbst statt, müssen $rowClass und \@titles nicht angegeben
werden. Es werden dann die Angaben aus $tab genommen.

=cut

# -----------------------------------------------------------------------------

sub addChildType {
    my $self = shift;
    my $type = shift;
    my $rowClass = shift || $self->rowClass;
    my $titleA = shift || $self->titles;

    for my $row (@{$self->rows}) {
        $row->addChildType($type,$rowClass,$titleA);
    }

    return;
}

# -----------------------------------------------------------------------------

=head3 selectChilds() - Selektiere Kind-Datensätze

=head4 Synopsis

    @rows|$rowT = $tab->selectChilds($db,$primaryKeyColumn,
        $foreignTable,$foreignKeyColumn,@opt);

=head4 Options

=over 4

=item -type => $type (Default: "$foreignTable.$foreignKeyColumn")

Bezeichner für den Satz an Kind-Objekten.

=item I<Select-Optionen>

Select-Optionen, die der Selektion der Kinddatensätze
hinzugefügt werden.

=back

=head4 Description

Selektiere alle Datensätze der Tabelle $foreignTable, deren
Kolumne $foreignKeyColumn auf die Kolumne $primaryKeyColumn
verweist und liefere diese zurück.

Die Kind-Datensätze werden ihren Eltern-Datensätzen zugeordnet
und können per

    @childRows = $row->childs("$foreignTable,$foreignKeyColumn");

oder

    $childRowT = $row->childs("$foreignTable,$foreignKeyColumn");

abgefragt werden. Z.B.

    -select=>@titles oder -oderBy=>@titles

Mittels der Option C<< -type=>$type >> kann ein anderer Typbezeichner
anstelle von "$foreignTable,$foreignKeyColumn" für den Satz an
Kinddatensätzen vereinbart werden.

=cut

# -----------------------------------------------------------------------------

sub selectChilds {
    my $self = shift;
    my $db = shift;
    my $primaryKeyColumn = shift;
    my $foreignTable = shift;
    my $foreignKeyColumn = shift;
    # @_: @opt

    # Optionen

    my $type = "$foreignTable.$foreignKeyColumn";

    Quiq::Option->extract(-mode=>'sloppy',\@_,
        -type => \$type,
    );

    # Subselect generieren

    my $stmt = $self->stmtBody;
    $stmt = "SELECT\n    $primaryKeyColumn\n$stmt";
    $stmt =~ s/^/    /gm;

    # Kind-Datensätze selektieren
    # (die restlichen Optionen sind Select-Optionen)

    my $tab = $db->select($foreignTable,
        -where,"$foreignKeyColumn IN (\n$stmt\n)",
        @_,
    );

    # Kind-Datensätze zuordnen

    my $rowClass = $tab->rowClass;
    my $titleA = $tab->titles;

    # Eltern-Datensätze um Kind-Typ erweitern

    for my $row ($self->rows) {
        $row->addChildType($type,$rowClass,$titleA);
    }

    # Indiziere Eltern-Datensätze nach Primärschlüssel
    my %idx = $self->index($primaryKeyColumn);

    for my $childRow ($tab->rows) {
        my $key = $childRow->$foreignKeyColumn;
        my $parentRow = $idx{$key} || die;

        # Kind-Datensatz zum Elterndatensatz hinzufügen
        $parentRow->addChild($type,$childRow);
    }

    return wantarray? $tab->rows: $tab;
}

# -----------------------------------------------------------------------------

=head3 selectParents() - Selektiere Parent-Datensätze

=head4 Synopsis

    @rows|$rowT = $tab->selectParents($db,$foreignKeyColumn,
        $parentTable,$primaryKeyColumn,@opt);

=head4 Options

=over 4

=item -type => $type (Default: $foreignKeyColumn)

Bezeichner für den Parent-Datensatz beim Child-Datensatz.

=item I<Select-Optionen>

Select-Optionen, die der Selektion der Parent-Datensatzes
hinzugefügt werden.

=back

=head4 Description

Selektiere alle Datensätze der Tabelle $parentTable, auf die
von der Kolumne $foreignKeyColumn aller in Tabelle $tab
enthaltenen Datensätze verwiesen wird und liefere diese zurück.

Der Parent-Datensatz wird jeweils seinem Kind-Datensatz
zugeordnet und kann per

    $parentRow = $row->getParent($foreignKeyColumn);

abgefragt werden.

Mittels der Option C<< -type=>$type >> kann ein anderer Typbezeichner
anstelle von "$foreignKeyColumn" für den Parent-Datensatz
vereinbart werden.

=cut

# -----------------------------------------------------------------------------

sub selectParents {
    my $self = shift;
    my $db = shift;
    my $foreignKeyColumn = shift;
    my $parentTable = shift;
    my $primaryKeyColumn = shift;
    # @_: @opt

    # Optionen

    my $type = $foreignKeyColumn;

    Quiq::Option->extract(-mode=>'sloppy',\@_,
        -type => \$type,
    );

    # Subselect generieren

    my $stmt = $self->stmtBody;
    $stmt = "SELECT\n    $foreignKeyColumn\n$stmt";
    $stmt =~ s/^/    /gm;

    # Parent-Datensätze selektieren
    # (die restlichen Optionen sind Select-Optionen)

    my $tab = $db->select($parentTable,
        -where,"$primaryKeyColumn IN (\n$stmt\n)",
        @_,
    );
    my %idx = $tab->index('id');

    # Datensätze mit Eltern-Datensatz verknüpfen erweitern

    for my $row ($self->rows) {
        my $parentRow;
        if (my $parentId = $row->$foreignKeyColumn) {
           $parentRow = $idx{$parentId} || $self->throw;
        }
        $row->addParent($foreignKeyColumn=>$parentRow);
    }

    return wantarray? $tab->rows: $tab;
}

# -----------------------------------------------------------------------------

=head3 selectParentRows() - Selektiere Datensätze via Schlüsselkolumne

=head4 Synopsis

    @rows|$rowT = $tab->selectParentRows($db,$fkTitle,$pClass,@select);

=head4 Returns

=over 4

=item Array-Kontext

Liste von Datensätzen

=item Skalar-Kontext

Tabellenobjekt (Quiq::Database::ResultSet::Object)

=back

=head4 Description

Die Methode ermöglicht es, Fremschlüsselverweise einer Selektion
durch effiziente Nachselektion aufzulösen.

Die Methode selektiert die Elterndatensätze der Tabellen-Klasse
C<$pClass> zu den Fremdschlüsselwerten der Kolumne C<$fkTitle> und
den zusätzlichen Selektionsdirektiven C<@select>. Die
Selektionsdirektiven sind typischerweise C<-select> und C<-orderBy>.

Die Klasse C<$pClass> muss eine Tabellenklasse sein, denn nur diese
definiert eine Primäschlüsselkolumne.

=head4 Example

Bestimme Informationen zu Route, Abschnitt, Fahrt, Fahrt_Parameter
und Parameter zu der Kombination aus Fahrten und Parametern:

    my @pas_id = $req->getArray('pas_id');
    my @mea_id = $req->getArray('mea_id');
    
    my $tab = FerryBox::Model::Join::RouSecPasPamMea->select($db2,
        -select => 'rou.id rou_id','sec.id sec_id','pas.id pas_id',
            'pam.id pam_id','mea.id mea_id',
        -where,
            'pas.id' => ['IN',@pas_id],
            'mea.id' => ['IN',@mea_id],
    );
    
    my $rouT = $tab->selectParentRows($db2,
        rou_id => 'FerryBox::Model::Table::Route',
        -select => qw/id name/,
    );
    
    my $secT = $tab->selectParentRows($db2,
        sec_id => 'FerryBox::Model::Table::Section',
        -select => qw/id route_id secname/,
    );
    
    my $pasT = $tab->selectParentRows($db2,
        pas_id => 'FerryBox::Model::Table::Passage',
        -select => qw/id section_id starttime/,
    );
    
    my $pamT = $tab->selectParentRows($db2,
        pam_id => 'FerryBox::Model::Table::Passage_Measseq',
        -select => qw/id passage_id measseq_id/,
    );
    
    my $meaT = $tab->selectParentRows($db2,
        mea_id => 'FerryBox::Model::Table::Measseq',
        -select => qw/id route_id meas/,
    );

=cut

# -----------------------------------------------------------------------------

sub selectParentRows {
    my ($self,$db,$fkTitle,$pClass,@select) = @_;

    # Bestimme alle Foreign-Key-Werte
    my @pkValues = $self->values($fkTitle,-notNull=>1,-distinct=>1);

    # Bestimme PK-Kolumne der Parent-Tabelle
    my $pkTitle = $pClass->primaryKey($db);

    # Selektiere alle Parent-Datensätze

    return $pClass->select($db,
        -where,'+null',$pkTitle=>['IN',@pkValues],
        @select,
    );
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.151

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
