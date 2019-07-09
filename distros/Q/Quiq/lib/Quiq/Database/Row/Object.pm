package Quiq::Database::Row::Object;
use base qw/Quiq::Database::Row/;

use strict;
use warnings;
use v5.10.0;
use utf8;

our $VERSION = '1.151';

use Quiq::Hash;
use Quiq::Option;
use Scalar::Util ();
use Quiq::Database::ResultSet;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Database::Row::Object - Datensatz als Objekt

=head1 BASE CLASS

L<Quiq::Database::Row>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert einen Datensatz.

=cut

# -----------------------------------------------------------------------------

# Default-Tabellenklasse
our $TableClass = 'Quiq::Database::ResultSet::Object';

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Konstructor

=head3 new() - Konstruktor

=head4 Synopsis

    $row = $class->new($db,@keyVal); # [1]
    $row = $class->new(\@titles,\@values,@keyVal); # [2]
    $row = $class->new(\@titles,@keyVal); # [3]
    $row = $class->new(@keyVal); # [4]

=head4 Description

Instantiiere ein Datensatz-Objekt mit den Kolumnen @titles und
den Kolumnenwerten @values und liefere eine Referenz auf
dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: Argumente

    my ($titleA,$valueA);

    if (ref $_[0]) {
        if (Scalar::Util::blessed($_[0]) &&
                $_[0]->isa('Quiq::Database::Connection')) {
            # Aufruf: $class->new($db,@keyVal);
            $titleA = $class->titles(shift);
        }
        else {
            # Aufruf: $class->new(\@titles,@keyVal);
            # Aufruf: $class->new(\@titles,\@values,@keyVal);
            $titleA = shift;
            if (ref $_[0]) {
                $valueA = shift;
            }
        }
    }
    else {
        # Aufruf: $row = $class->new(@keyVal);

        while (@_) {
            push @$titleA,shift;
            push @$valueA,shift;
        }
    }

    my $hash = Quiq::Hash->new($titleA,$valueA? $valueA: (),'')
        ->unlockKeys;

    my $self = bless [
        $hash,   # [0] Daten-Hash
        $titleA, # [1] Titel-Liste
        'I',     # [2] Datensatz-Status
        undef,   # [3] Änderungs-Hash
        undef,   # [4] Kind-Datensätze-Hash
        undef,   # [5] Eltern-Datensätze-Hash
    ],$class;

    # @keyVal setzen, falls vorhanden

    if (@_) {
        $self->set(@_);
        $self->[3] = undef;
    }

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Attributmethoden

=head3 exists() - Prüfe, ob Datensatz-Attribut existiert

=head4 Synopsis

    $bool = $row->exists($key);

=head4 Description

Liefere "wahr", wenn Datensatz-Attribut $key existiert,
anderfalls "falsch".

=cut

# -----------------------------------------------------------------------------

sub exists {
    my ($self,$key) = @_;
    return exists $self->[0]->{$key}? 1: 0;
}

# -----------------------------------------------------------------------------

=head3 get() - Liefere Datensatz-Attributwerte

=head4 Synopsis

    $val = $row->get($key);
    @vals = $row->get(@keys);

=head4 Description

Liefere die Datensatz-Attributwerte zu den angegebenen
Schlüsseln. In skalarem Kontext liefere keine Liste, sondern den
Wert des ersten Schlüssels.

Ein Datensatz-Wert kann der Wert einer Kolumne oder das Ergebnis
einer Berechnung sein.

=cut

# -----------------------------------------------------------------------------

sub get {
    my $self = shift;

    my @vals;
    while (@_) {
        my $key = shift;
        push @vals,$self->$key;
    }

    return wantarray? @vals: $vals[0];
}

# -----------------------------------------------------------------------------

=head3 try() - Liefere Wert oder undef

=head4 Synopsis

    $val = $row->try($key);

=head4 Description

Liefere den Wert des Attributs I<$key>, falls es existiert,
sonst C<undef>.

=cut

# -----------------------------------------------------------------------------

sub try {
    my ($self,$key) = @_;
    return exists $self->[0]->{$key}? $self->$key: undef;
}

# -----------------------------------------------------------------------------

=head3 set() - Setze Datensatz-Attribute

=head4 Synopsis

    $row->set(@keyVal);

=head4 Description

Setze die angegebenen Datensatz-Attribute. Es wird eine Exception
ausgelöst, wenn ein Attribut zu setzen versucht wird, das nicht existiert.
Die Methode liefert keinen Wert zurück.

=cut

# -----------------------------------------------------------------------------

sub set {
    my $self = shift;
    # @_: @keyVal

    while (@_) {
        my $key = shift;
        $self->$key(shift);
    }

    return;
}

# -----------------------------------------------------------------------------

=head3 init() - Initialisieren Datensatz-Attribute aus Objekt

=head4 Synopsis

    $row->init($obj);

=head4 Description

Setze die Datensatz-Komunen in $row auf die Werte der Attribute in $obj.
Eine Kolumne wird nur gesetzt, wenn $obj für sie einen Wert hat,
d.h. das Attribut muss existieren und es muss einen von '' und
undef verschiedenen Wert haben.

Die Methode liefert keinen Wert zurück.

=cut

# -----------------------------------------------------------------------------

sub init {
    my ($self,$obj) = @_;

    for my $key ($self->titles) {
        if ($obj->exists($key)) {
            my $val = $obj->get($key);
            if (defined($val) && $val ne '') {
                $self->$key($val);
            }
        }
    }

    return;
}

# -----------------------------------------------------------------------------

=head3 initFromCgi() - Initialisieren Datensatz-Attribute aus CGI-Objekt

=head4 Synopsis

    $row->initFromCgi($cgi);

=head4 Description

Wie init(), nur dass ein CGI-Objekt per Methode param() befragt wird.

=cut

# -----------------------------------------------------------------------------

sub initFromCgi {
    my ($self,$obj) = @_;

    for my $key ($self->titles) {
        my $val = $obj->param($key);
        if (defined $val) {
            $self->$key($val);
        }
    }

    return;
}

# -----------------------------------------------------------------------------

=head3 addAttribute() - Füge Datensatz-Attribute hinzu

=head4 Synopsis

    $row->addAttribute(@keys);

=head4 Description

Füge die Attribute @keys zum Datensatz hinzu, sofern noch nicht existent.
Die Methode liefert keinen Wert zurück.

=cut

# -----------------------------------------------------------------------------

sub addAttribute {
    my $self = shift;
    # @_: @keyVal

    while (@_) {
        my $key = shift;
        # erzeuge DS-Attribut, wenn es nicht existiert
        if (!exists $self->[0]->{$key}) {
             $self->[0]->{$key} = '';
        }
    }

    return;
}

# -----------------------------------------------------------------------------

=head3 removeColumn() - Entferne Datensatz-Kolumne(n)

=head4 Synopsis

    $row->removeColumn(@keys);

=head4 Description

Entferne die Kolumnen @keys aus dem Datensatz. Die Methode liefert
keinen Wert zurück.

=cut

# -----------------------------------------------------------------------------

sub removeColumn {
    my $self = shift;
    # @_: @keyVal

    my $valueH = $self->[0];
    my $titleA = $self->[1];
    while (@_) {
        my $key = shift;
        CORE::delete $valueH->{$key};
        for (my $i = 0; $i < @$titleA; $i++) {
            if ($titleA->[$i] eq $key) {
                CORE::splice @$titleA,$i,1;
                last;
            }
        }
    }

    return;
}

# -----------------------------------------------------------------------------

=head3 add() - Setze Datensatz-Attribute forciert

=head4 Synopsis

    $row->add(@keyVal);

=head4 Alias

setValue()

=head4 Description

Forciere das Setzen der Datensatz-Attribute @keyVal, d.h. erzeuge
ein Datensatz-Attribut, falls es nicht existiert.
Die Methode liefert keinen Wert zurück.

=cut

# -----------------------------------------------------------------------------

sub add {
    my $self = shift;
    # @_: @keyVal

    while (@_) {
        my $key = shift;
        # erzeuge DS-Attribut, wenn es nicht existiert
        if (!exists $self->[0]->{$key}) {
            $self->[0]->{$key} = '';
        }
        $self->$key(shift);
    }

    return;
}

{
    no warnings 'once';
    *setValue = \&add;
}

# -----------------------------------------------------------------------------

=head3 memoize() - Füge Datensatz-Attribute mit berechnetem Wert hinzu

=head4 Synopsis

    $val = $row->memoize($key,$sub);

=head4 Description

Existiert das Datensatz-Attribut $key, liefere seinen Wert.
Andernfalls berechne dessen Wert mittels der anonymen Subroutine $sub
und speichere ihn auf dem Attribut.

=cut

# -----------------------------------------------------------------------------

sub memoize {
    my ($self,$key,$sub) = @_;

    if (!$self->exists($key)) {
        my $val = $self->$sub($key);
        $self->add($key=>$val);
    }

    return $self->$key;
}

# -----------------------------------------------------------------------------

=head3 getSet() - Methode zum Liefern/Setzen eines einzelnen Datensatz-Attributs

=head4 Synopsis

    $val = $row->getSet($key);
    $val = $row->getSet($key,$val);

=head4 Examples

=over 2

=item *

Implementierung einer einfachen Attributmethode

Dies setzt voraus, dass das Attribut vorhanden ist. Falls dies
nicht der Fall ist, kann es mit $row->add(xxx=>$val) eingeführt
werden. Diese Form der Attributmethode wird von selbst per
AUTOLOAD erzeugt, braucht also nicht implementiert werden

    sub xxx {
        return shift->getSet(xxx=>@_);
    }

=item *

Eine Attributmethode, die eine Liste oder eine Arrayreferenz liefert

    sub xxx {
        my $self = shift;
        # @_: $arr
        my $arr = $self->getSet(xxx=>@_);
        return wantarray? @$arr: $arr;
    }

=back

=cut

# -----------------------------------------------------------------------------

sub getSet {
    my $self = shift;
    my $key = shift;
    # @_: $val

    if (@_) {
        my $val = shift;
        $val = '' if !defined $val;

        my $oldVal = $self->[0]->{$key};
        if (!$oldVal && !exists $self->[0]->{$key}) {
            $self->throw(
                'ROW-00004: Datensatz-Attribut existiert nicht',
                Key => $key,
            );
        }

        if ($val ne $oldVal) {
            # Daten-Hash
            $self->[0]->{$key} = $val;

            # Datensatz-Status setzen. Dieser ändert sich genau dann,
            # wenn der Datensatz-Status 0 ist und ein Kolumnen-Attribut
            # geändert wird. Das Ändern eines Nicht-Datenbank-Attributs
            # ändert den Datensatz-Status nicht!
            # FIXME: von grep auf effizientere Suche umstellen?

            if (!$self->[2] && grep {$key eq $_} @{$self->[1]}) {
                $self->[2] = 'U';
            }

            # Änderungs-Hash. Dieser umfasst alle Attribute, sowohl
            # Datensatz-Attribute als auch zusätzliche Attribute.

            unless ($self->[3]) {
                $self->[3] = Quiq::Hash->new->unlockKeys;
            }

            # warn "UPDATE $key: '$oldVal' => '$val'\n";
            $self->[3]->{$key} = $oldVal;
        }
    }

    return $self->[0]->{$key};
}

# -----------------------------------------------------------------------------

=head3 rowStatus() - Liefere/Setze Datensatzstatus

=head4 Synopsis

    $rowStatus = $row->rowStatus;
    $rowStatus = $row->rowStatus($rowStatus);

=head4 Description

Liefere/Setze den Status des Datensatzes. Der Status beschreibt
den Änderungsstand des Datensatzes hinsichtlich seiner Kolumnenwerte.

Folgende Status sind definiert:

=over 4

=item '0' (unverändert)

=back

Der Datensatz wurde von der Datenbank selektiert und nicht modifiziert.

=over 4

=item 'U' (modifiziert)

=back

Der Datensatz wurde von der Datenbank selektiert und durch eine der
Attributmethoden modifiziert.

=over 4

=item 'I' (neu)

=back

Der Datensatz wurde durch new() erzeugt. Er existiert auf der
Datenbank nicht.

=over 4

=item 'D' (zu löschen)

=back

Der Datensatz wurde zum Löschen markiert. Dies geschah durch Aufruf
von $row->rowStatus('D'). Mit dem nächsen Aufruf von $row->save($db);
wird die Löschoperation auf der Datenbank ausgeführt.

=cut

# -----------------------------------------------------------------------------

sub rowStatus {
    my $self = shift;
    # @_: $rowStatus

    if (@_) {
        my $rowStatus = shift;
        if ($rowStatus !~ /^[0IUD]$/) {
            $self->throw(
                'ROW-00005: Ungültiger Datensatz-Status',
                RowStatus => $rowStatus,
            );
        }
        $self->[2] = $rowStatus;
    }

    return $self->[2];
}

# -----------------------------------------------------------------------------

=head3 titles() - Liefere Kolumnentitel

=head4 Synopsis

    $titleA|@titles = $row->titles; # [1]
    $titleA|@titles = $class->titles($db); # [2]

=head4 Description

=over 4

=item 1.

Liefere die Liste der Kolumentitel des Datensatzes, entweder
als Referenz (Skalarkontext) oder als Array (Listkontext).

=item 2.

Liefere die Liste der Kolumnentitel der Datensatz-Klasse.

=back

=cut

# -----------------------------------------------------------------------------

sub titles {
    my $this = shift;
    # @_: $db bei Aufruf als Klassenmethode

    if (ref $this) {
        # Aufruf als Objektmethode
        return wantarray? @{$this->[1]}: $this->[1];
    }

    # Aufruf als Klassenmethode

    my $db = shift;
    my $stmt = $this->selectStmt($db);
    return $db->titles(-stmt=>$stmt);
}

# -----------------------------------------------------------------------------

=head3 isModified() - Prüfe, ob Kolumne modifiziert wurde

=head4 Synopsis

    $bool = $row->isModified($title);

=head4 Description

Liefere 1, wenn die Kolumnen $title modifiziert wurde, andernfalls 0.

=cut

# -----------------------------------------------------------------------------

sub isModified {
    my ($self,$key) = @_;
    return CORE::exists $self->[3]->{$key}? 1: 0;
}

# -----------------------------------------------------------------------------

=head3 modifiedColumns() - Liefere die Liste der geänderten Kolumnen

=head4 Synopsis

    @keys|$keyA = $row->modifiedColumns;
    @pairs|$pairA = $row->modifiedColumns(-withValue=>1);

=head4 Options

=over 4

=item -columns => @colSpec (Default: alle Kolumnen)

Einschränkung auf die angegebenen Kolumnen. Ist als Kolumnenname
eine Arrayreferenz

    [$key=>$retKey]

angegeben, wird Kolumne $key geprüft, aber $retKey als Kolumnenname
geliefert. Dies ist bei View-Datensätzen nützlich, wenn $row ein
View-Datensatz ist, aber ein Tabellen-Datensatz manipuliert
werden soll und die Kolumnennamen differieren.

=item -withValue => $bool (Default: 0)

Liefere nicht nur die Kolumnennamen, sondern auch deren Wert.
Die Methode liefert in dem Fall die Datensatz-Änderungen
als Schlüssel/Wert-Paare.

=back

=head4 Example

Generiere eine SET-Klausel für ein UPDATE-Statement aus einem
View-Datensatz, dessen Kolumnen teilweise anders beannt sind,
als die der zu aktualierenden Tabelle:

    @setClause = $row->modifiedColumns(
        -columns=>[
            lieferantid,
            [lieferantenartikelnr=>'liefernr'],
            [ekpreis=>'preis_ek'],
        ],
        -widthValues=>1,
    );

=cut

# -----------------------------------------------------------------------------

sub modifiedColumns {
    my $self = shift;
    # @_: @opt

    my $columns = $self->[1];
    my $modHash = $self->[3];
    my $datHash = $self->[0];
    my $withValue = 0;

    Quiq::Option->extract(\@_,
        -columns => \$columns,
        -withValue => \$withValue,
    );

    my @arr;

    for (@$columns) {
        (my $key) = (my $retKey) = $_;
        if (ref) {
            ($key,$retKey) = @$_;
        }
        if (!exists $self->[0]->{$key}) {
            $self->throw(
                'ROW-00001: Datensatz-Attribut existiert nicht',
                Key => $key,
            );
        }
        if (CORE::exists $modHash->{$key}) {
            push @arr,$retKey;
            if ($withValue) {
                push @arr,$datHash->{$key};
            }
        }
    }

    return wantarray? @arr: \@arr;
}

# -----------------------------------------------------------------------------

=head3 setClauseFromModifiedRow() - Liefere SET-Klausel über geänderten Kolumnen

=head4 Synopsis

    @clauses|$clauseA = $row->setClauseFromModifiedRow(@columns);

=head4 See Also

modifiedColumns()

=head4 Example

Auf einen View-Datensatz wurden Werte geschrieben. Wir wissen
nicht, welche Information sich geändert hat. Die Methode
setClauseFromModifiedRow() liefert uns die SET-Klausel für ein UPDATE:

    @setClause = $row->setClauseFromModifiedRow(
        [lieferantenid=>'lieferantid'],
        [lieferantenartikelnr=>'liefernr'],
        [ekpreis=>'preis_ek'],
        [lieferantenid1=>'lieferantid_1'],
        [lieferantenartikelnr1=>'liefernr_1'],
        [ekpreis1=>'preis_ek_1'],
        [lieferantenid2=>'lieferantid_2'],
        [lieferantenartikelnr2=>'liefernr_2'],
        [ekpreis2=>'preis_ek_2'],
    );
    $db->update('shopartikellieferanteninfo',
        @setClause,
        -where,artikelid => $artId,
    );

Wurde keine der Kolumnen geändert, liefert setClauseFromModifiedRow() eine leere
Liste und $db->update() ist eine Nulloperation.

=cut

# -----------------------------------------------------------------------------

sub setClauseFromModifiedRow {
    my $self = shift;
    # @_: @columns

    return $self->modifiedColumns(
        -columns => \@_,
        -withValue => 1,
    );
}

# -----------------------------------------------------------------------------

=head3 absorbModifications() - Absorbiere Datensatz-Änderungen

=head4 Synopsis

    $row->absorbModifications;

=head4 Description

Setze den Datensatz-Status auf 0 (unverändert) und lösche den
Änderungs-Hash. Nach Aufruf der Methode sind alle vorangegangenen
Änderungen am Datensatz nicht mehr feststellbar.

Die Methode kann benutzt werden, um Datenkorrekturen, z.B. durch
normalizeNumber(), verschwinden zu lassen.

=head4 See Also

$tab->absorbModifications()

=cut

# -----------------------------------------------------------------------------

sub absorbModifications {
    my $self = shift;

    $self->[2] = 0;     # setze Datensatz-Status auf 0 (unverändert)
    $self->[3] = undef; # entferne die Modifikationen

    return;
}

# -----------------------------------------------------------------------------

=head3 modificationInfo() - Liefere Information über Datensatz-Änderungen

=head4 Synopsis

    $str = $row->modificationInfo;

=cut

# -----------------------------------------------------------------------------

sub modificationInfo {
    my $self = shift;

    my $str = '';

    if ($self->[2]) { # Datensatz-Status
        my $datHash = $self->[0];
        my $modHash = $self->[3];
        for my $key (@{$self->[1]}) {
            if (CORE::exists $modHash->{$key}) {
                if ($str) {
                    $str .= ', ';
                }
                $str .= "$key: '$modHash->{$key}' => '$datHash->{$key}'";
            }
        }
    }

    return $str;
}

# -----------------------------------------------------------------------------

=head2 Eltern-Datensätze

=head3 parentExists() - Prüfe, ob Eltern-Datensatz existiert

=head4 Synopsis

    $row = $row->parentExists($type);

=head4 Description

Prüfe, ob ein Eltern-Datensätze vom Typ $type existiert.
Falls ja, liefere I<wahr>, andernfalls I<falsch>.

=cut

# -----------------------------------------------------------------------------

sub parentExists {
    my ($self,$type) = @_;
    return CORE::exists $self->[5]->{$type}? 1: 0;
}

# -----------------------------------------------------------------------------

=head3 addParent() - Füge Eltern-Datensatz hinzu

=head4 Synopsis

    $row->addParent($type,$parentRow);

=head4 Description

Füge Datensatz $parentRow als Eltern-Datensatz vom Typ $type hinzu.
Die Referenz wird als schwache Referenz gekennzeichnet.

=cut

# -----------------------------------------------------------------------------

sub addParent {
    my ($self,$type,$parentRow) = @_;
    $self->[5]->{$type} = $parentRow;
    Scalar::Util::weaken($self->[5]->{$type});
    return;
}

# -----------------------------------------------------------------------------

=head3 getParent() - Liefere Eltern-Datensatz

=head4 Synopsis

    $parentRow = $row->getParent($type);

=head4 Description

Liefere den Eltern-Datensatz vom Typ $type. Existiert keine
Elterndatensatz vom Typ $type, liefere undef.

=cut

# -----------------------------------------------------------------------------

sub getParent {
    my ($self,$type) = @_;
    return $self->[5]->{$type};
}

# -----------------------------------------------------------------------------

=head2 Kind-Datensätze

=head3 childTypeExists() - Prüfe, ob Kind-Datensatz-Typ existiert

=head4 Synopsis

    $bool = $row->childTypeExists($type);

=head4 Description

Prüfe, ob Kind-Datensätze des Typs $type zum Datensatz hinzugefügt
werden können. Falls ja, liefere I<wahr>, andernfalls I<falsch>.

=cut

# -----------------------------------------------------------------------------

sub childTypeExists {
    my ($self,$type) = @_;
    return CORE::exists $self->[4]->{$type}? 1: 0;
}

# -----------------------------------------------------------------------------

=head3 addChildType() - Füge Kind-Datensatz-Typ hinzu

=head4 Synopsis

    $tab = $row->addChildType($type,$rowClass,\@titles);

=head4 Description

Bevor Kind-Datensätze einem Datenstatz zugeordnet werden können, muss
ein entsprechendes ResultSet-Objekt hinzugefügt werden. Dieses wird
per $type angesprochen. Z.B. liefert

    $tab = $row->getChilds($type);

die Menge der zugeordenten Kind-Objekte vom Typ $type.

=cut

# -----------------------------------------------------------------------------

sub addChildType {
    my ($self,$type,$rowClass,$titleA) = @_;
    return $self->[4]->{$type} =
        Quiq::Database::ResultSet->new($rowClass,$titleA);
}

# -----------------------------------------------------------------------------

=head3 addChild() - Füge Kind-Datensatz hinzu

=head4 Synopsis

    $row->addChild($type,$childRow);

=head4 Description

Füge Datensatz $childRow als Kinddatensatz vom Typ $type hinzu.

=cut

# -----------------------------------------------------------------------------

sub addChild {
    my ($self,$type,$childRow) = @_;
    $self->[4]->{$type}->push($childRow);
    return;
}

# -----------------------------------------------------------------------------

=head3 getChilds() - Liefere Kind-Datensätze

=head4 Synopsis

    @rows|$rowT = $row->getChilds($type);

=head4 Description

Liefere die Kind-Datensätze vom Typ $type.

=cut

# -----------------------------------------------------------------------------

sub getChilds {
    my ($self,$type) = @_;
    my $tab = $self->[4]->{$type} || die;
    return wantarray? $tab->rows: $tab;
}

# -----------------------------------------------------------------------------

=head2 Subklassen-Methoden

Die folgenden Methoden implementieren die abstrakten Methoden der
Basisklasse Quiq::Database::Row. Die Methoden hat die Klasse mit
der Klasse Quiq::Database::Row::Array gemeinsam.

=head3 asArray() - Liefere Datensatz als Array

=head4 Synopsis

    $arr|@arr = $row->asArray;

=head4 Description

Liefere den Datensatz als Array, entweder in Form einer Referenz
(Skalarkontext) oder als Array von Werten (Listkontext).

=cut

# -----------------------------------------------------------------------------

sub asArray {
    my $self = shift;

    my @arr;
    my $titles = $self->titles;
    for my $key (@$titles) {
        push @arr,$self->$key;
    }

    return wantarray? @arr: \@arr;
}

# -----------------------------------------------------------------------------

=head3 asString() - Liefere Datensatz als Zeichenkette

=head4 Synopsis

    $str = $row->asString;
    $str = $row->asString($colSep);

=head4 Description

Liefere den Datensatz als Zeichenkette. Per Default werden die Kolumnen
per TAB getrennt. Der Trenner kann mittels $colSep explizit angegeben
werden.

=cut

# -----------------------------------------------------------------------------

sub asString {
    my $self = shift;
    my $colSep = @_? shift: "\t";

    my @arr;
    for my $key (@{$self->titles}) {
        push @arr,$self->$key;
    }

    return join $colSep,@arr;
}

# -----------------------------------------------------------------------------

=head3 copy() - Kopiere Datensatz

=head4 Synopsis

    $newRow = $row->copy;

=head4 Description

Erstelle eine Kopie des Datensatzes $row und liefere eine Referenz
auf die Kopie zurück.

Die Kopie ist identisch zum Original, bis darauf, dass der
Daten-Hash und der Änderungs-Hash kopiert werden:

    Daten-Hash.........................: kopiert
    Referenz auf Titel-Liste...........: identisch
    Datensatz-Status...................: identisch
    Änderungs-Hash.....................: kopiert
    Referenz auf Kind-Datensätze-Hash..: identisch
    Referenz auf Eltern-Datensätze-Hash: identisch

=cut

# -----------------------------------------------------------------------------

sub copy {
    my $self = shift;

    my @row = @$self; # Array kopieren
    $row[0] = $self->[0]->copy; # Daten-Hash kopieren
    if ($self->[3]) {
        $row[3] = $self->[3]->copy; # Änderungs-Hash kopieren
    }

    return bless \@row,ref($self);
}

# -----------------------------------------------------------------------------

=head3 isRaw() - Liefere, ob Klasse Raw-Datensätze repräsentiert

=head4 Synopsis

    $bool = $row->isRaw;

=cut

# -----------------------------------------------------------------------------

sub isRaw {
    return 0;
}

# -----------------------------------------------------------------------------

=head2 Sonstiges

=head3 asRecord() - Liefere Datensatz in Record-Darstellung

=head4 Synopsis

    $str = $row->asRecord;
    $str = $row->asRecord($null);
    $str = $row->asRecord($null,$indent);

=head4 Description

Liefere den Datensatz in mehrzeiliger Record-Darstellung.
Die Darstellung hat den Aufbau:

    <key1>:
        <val1>
    <key2>:
        <val2>
    ...

Der optionale Parameter $null gibt an, welcher Wert für einen Nullwert
ausgegeben wird. Per Default wird NULL ausgegeben. Ist $null undef,
wird das Attribut nicht ausgegeben (weder Name noch Wert).
Ist $null '' (Leerstring), wird nur der Wert nicht ausgegeben.

Der optionale Parameter $indent gibt an, wie tief die Werte
eingerückt werden. Per Default werden die Werte um 4 Leerzeichen
eingerückt.

=cut

# -----------------------------------------------------------------------------

sub asRecord {
    my $self = shift;
    # @_: $null,$indent

    my $null = @_? shift: 'NULL';

    my $indent = shift;
    $indent = 4 if !defined $indent;
    $indent = ' ' x $indent;

    my $str = '';
    for my $key (@{$self->titles}) {
        my $val = $self->$key;
        if ($val eq '') {
            if (!defined $null) {
                next;
            }
            $val = $null;
        }
        $str .= "$key:\n";
        $val =~ s/^/$indent/mg;
        $val .= "\n";
        $str .= $val;
    }

    return $str;
}

# -----------------------------------------------------------------------------

=head3 copyData() - Kopiere Attributwerte von Datensatz zu Datensatz

=head4 Synopsis

    $row->copyData($row0,@opt);

=head4 Options

=over 4

=item -ignore => \@keys (Default: [])

Übergehe die Attribute @keys, d.h. kopiere die Werte dieser
Attribute nicht.

=item -dontCopyNull => $bool (Default: 0)

Kopiere keine Nullwerte, d.h. im Falle eines Nullwerts in
Datensatz $row0 bleibt der Attributwert in $row erhalten.
Mögliche Erweiterung: Liste von Kolumnennamen.

=back

=head4 Description

Setze die Datensatz-Attribute in $row auf deren Werte in $row0.
Attribute, die in $row0 nicht vorkommen, werden nicht gesetzt.
Die Methode liefert keinen Wert zurück.

Die Methode ist nützlich, wenn ein Datensatz auf der Datenbank
aktualisiert werden soll und dessen neue Werte auf einem anderen
Datensatz stehen.

=cut

# -----------------------------------------------------------------------------

sub copyData {
    my $self = shift;
    my $row0 = shift;
    # @_: @opt

    # Optionen

    my $ignore = undef;
    my $dontCopyNull = 0;

    if (@_) {
        Quiq::Option->extract(\@_,
            -ignore => \$ignore,
            -dontCopyNull => \$dontCopyNull,
        );
    }

    if ($ignore) {
        $ignore = Quiq::Hash->new($ignore,1)->unlockKeys;
    }

    # Operation ausführen. Die Methode operiert allein auf den
    # Daten-Hashes der beteiligten Datensätze.

    for my $key (keys %{$self->[0]}) {
        next if $ignore && $ignore->{$key};
        next if !exists $row0->[0]->{$key};
        my $val = $row0->[0]->{$key};
        next if $dontCopyNull && $val eq '';
        $self->getSet($key,$val);
    }

    return;
}

# -----------------------------------------------------------------------------

=head3 save() - Aktualisiere Datensatz auf Datenbank

=head4 Synopsis

    $cur = $row->save($db);

=head4 Description

Aktualisiert den Datensatz $row gemäß seines Status auf der Datenbank
$db und liefere das Resultat der Statement-Ausführung zurück.

Welche Datenbankoperation konkret ausgeführt wird, ergibt sich aus
dem Status des Datensatzes.

B<Statuswerte>

=over 4

=item '0' (unverändert)

Es wird keine Datenbankoperation ausgeführt.

=item 'U' (modifiziert)

Es wird eine Update-Operation auf der Datenbank ausgeführt, d.h. es
wird die Methode $row->update() gerufen.

=item 'I' (neu)

Es wird eine Insert-Operation auf der Datenbank ausgeführt, d.h. es
wird die Methode $row->insert() gerufen.

=back

['D' (zu löschen)]

    Es wird eine Delete-Operation auf der Datenbank ausgeführt, d.h. es
    wird die Methode $row->delete() gerufen.

=cut

# -----------------------------------------------------------------------------

sub save {
    my ($self,$db) = @_;

    my $cur;
    my $stat = $self->rowStatus;
    if (!$stat) {              # Datensatz wurde selektiert und nicht geändert
        $cur = $db->sql;
    }
    elsif ($stat eq 'I') {     # Datensatz ist neu
        $cur = $self->insert($db);
    }
    elsif ($stat eq 'U') {     # Datensatz wurde modifiziert
        $cur = $self->update($db);
    }
    elsif ($stat eq 'D') {     # Datensatz wurde zum Löschen markiert
        $cur = $self->delete($db);
    }
    else {
        $self->throw(
            'ROW-00005: Ungültiger Datensatz-Status',
            RowStatus => $stat,
        );
    }
    $cur->{'rowOperation'} = $stat;

    return $cur;
}

# -----------------------------------------------------------------------------

=head3 weaken() - Erzeuge schwache Referenz

=head4 Synopsis

    $ref = $row->weaken($key);
    $ref = $row->weaken($key=>$ref);

=head4 Description

Mache die Referenz von Schlüssel $key zu einer schwachen Referenz
und liefere sie zurück. Ist eine Referenz $ref als Parameter angegeben,
setze die Referenz zuvor.

=cut

# -----------------------------------------------------------------------------

sub weaken {
    return shift->[0]->weaken(@_);
}

# -----------------------------------------------------------------------------

=head2 DML Statements

=head3 select() - Liefere Datensätze der Klasse

=head4 Synopsis

    $tab|@rows|$cur = $class->select($db,@select,@opt);

=head4 Options

=over 4

=item -cursor => $bool (Default: 0)

Liefere Cursor statt Liste der Datensätze.

=item -tableClass => $tableClass (Default: undef)

Name der Klasse, die die Ergebnismenge speichert.

=back

=cut

# -----------------------------------------------------------------------------

sub select {
    my $class = shift;
    my $db = shift;
    # @_: @select,@opt

    # Optionen

    my $cursor = 0;
    my $tableClass;

    Quiq::Option->extract(-mode=>'sloppy',\@_,
        -cursor => \$cursor,
        -tableClass => \$tableClass,
    );

    # Operation ausführen

    my $stmt = $class->selectStmt($db,@_);

    return $db->select(
        -cursor => $cursor,
        -rowClass => $class,
        -stmt => $stmt,
        -tableClass => $tableClass,
    );
}

# -----------------------------------------------------------------------------

=head3 lookup() - Liefere Datensatz der Klasse

=head4 Synopsis

    $row|@vals = $class->lookup($db,@select,@opt);

=head4 Options

=over 4

=item -sloppy => $bool (default: 0)

Wirf keine Exception, wenn der Datensatz nicht existiert, sondern
undef (Skalarkontext) bzw. eine leere Liste (Listkontext).

=back

=cut

# -----------------------------------------------------------------------------

sub lookup {
    my $class = shift;
    my $db = shift;
    # @_: @select,@opt

    # Optionen

    my $sloppy = 0;

    Quiq::Option->extract(-mode=>'sloppy',\@_,
        -sloppy => \$sloppy,
    );

    # Operation ausführen

    my $stmt = $class->selectStmt($db,@_);

    return $db->lookup(
        -stmt => $stmt,
        -rowClass => $class,
        -sloppy => $sloppy,
    );
}

# -----------------------------------------------------------------------------

=head3 value() - Liefere Kolumnenwert

=head4 Synopsis

    $val = $class->value($db,@select,@opt);

=head4 Options

Siehe $db->value().

=cut

# -----------------------------------------------------------------------------

sub value {
    my $class = shift;
    my $db = shift;
    # @_: @select,@opt

    return $db->value($class->table,@_);
}

# -----------------------------------------------------------------------------

=head2 Kompatibilität

=head3 toSbit() - Generiere Sbit-Datensatz

=head4 Synopsis

    $sbitRow = $row->toSbit($sbitClass);

=head4 Arguments

=over 4

=item $sbitClass

Datensatz-Klasse der Sbit-Klassenbibliothek

=back

=head4 Returns

Referenz auf Sbit-Datensatz

=head4 Description

Generiere aus Datensatz I<$row> einen Sbit-Datensatz der Klasse
I<$sbitClass> und liefere diesen zurück.

=head4 Details

Die Methode ist nützlich, wenn über die Klassenbibliothek
selektiert, aber die weitere Verarbeitung über Klassen auf
Basis der Sbit-Klassenbibliothek erfolgt.

=cut

# -----------------------------------------------------------------------------

sub toSbit {
    my ($self,$sbitClass) = @_;

    # Implementierung gemäß dem Konstruktor in der Sbit-Klassenbibliothek

    my $titles = $self->titles;

    my %hash;
    @hash{@$titles} = ('') x @$titles;
    for my $key (@$titles) {
        $hash{$key} = $self->$key;
    }

    return bless [\%hash,$titles,$self->rowStatus,0,undef,undef],$sbitClass;
}

# -----------------------------------------------------------------------------

=head2 Autoload

=head3 AUTOLOAD() - Generiere Attributmethode

=head4 Synopsis

    $val = $row->AUTOLOAD;
    $val = $row->AUTOLOAD($val);

=head4 Description

Generiere Attributmethode, rufe diese auf und liefere den Attributwert.

=cut

# -----------------------------------------------------------------------------

sub AUTOLOAD {
    my $this = shift;
    # @_: Methodenargumente

    my ($rowClass,$key) = our $AUTOLOAD =~ /^(.*)::(\w+)$/;
    if (!defined $key) {
        $this->throw(
            'ROW-00003: Methodenname enthält ungültige Zeichen',
            Method => $AUTOLOAD,
        );
    }
    return if $key !~ /[^A-Z]/;

    # Wir prüfen, dass eine Attributmethode nur einmal gerufen wird
    # warn "$AUTOLOAD\n";

    # Aufruf als Klassenmethode ist nicht vorgesehen

    if (!ref $this) {
        $this->throw(
            'ROW-00001: Klassen-Methode existiert nicht',
            Attribute => $key,
        );
    }

    # Methode nur generieren, wenn Attribut existiert

    if (!exists $this->[0]->{$key}) {
        $this->throw(
            'ROW-00002: Datensatz-Attribut oder Methode existiert nicht',
            Attribute => $key,
        );
    }

    # Attribut-Methode generieren

    no strict 'refs';
    *{$AUTOLOAD} = sub {
        return shift->getSet($key,@_);
    };

    # Methode aufrufen
    return $this->$key(@_);
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
