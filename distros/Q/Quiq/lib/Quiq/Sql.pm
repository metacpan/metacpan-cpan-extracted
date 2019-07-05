package Quiq::Sql;
use base qw/Quiq::Hash/;

use strict;
use warnings;
use v5.10.0;
use utf8;

our $VERSION = '1.149';

use Quiq::Hash;
use Quiq::Option;
use Quiq::String;
use Scalar::Util ();
use Quiq::Unindent;
use Quiq::Reference;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Sql - Klasse zur Generierung von SQL

=head1 BASE CLASS

L<Quiq::Hash>

=head1 SYNOPSIS

Das Programm

    use Quiq::Sql;
    
    my $sql = Quiq::Sql->new('Oracle');
    
    my $stmt = $sql->createTable('person',
        ['per_id',type=>'INTEGER',primaryKey=>1],
        ['per_vorname',type=>'STRING(30)'],
        ['per_nachname',type=>'STRING(30)',notNull=>1],
    );
    
    print $stmt,"\n";

generiert das CREATE TABLE Statement

    CREATE TABLE person (
        per_id NUMBER PRIMARY KEY,
        per_vorname STRING2(30),
        per_nachname STRING2(30) NOT NULL
    )

(man beachte die Abbildung der Kolumnentypen)

=head1 DESCRIPTION

=head2 Zweck der Klasse

Die Klasse unterstützt die Entwicklung von portablen
Datenbankanwendungen, d.h. Anwendungen, die unter mehreren DBMSen
lauffähig sind, indem sie Methoden zur Verfügung stellt, die zum
DBMS den passenden SQL-Code erzeugen.

=head2 Unterstützte Datenbanksysteme

Folgende DBMSe werden von der Klasse unterstützt:

    Oracle
    PostgreSQL
    SQLite
    MySQL

=head1 ATTRIBUTES

=over 4

=item dbms => $dbmsName (Default: keiner)

Name des DBMS.

=back

=head1 METHODS

=head2 Konstruktor

=head3 new() - Konstruktor

=head4 Synopsis

    $sql = $class->new($dbms);
    $sql = $class->new($dbms,$version);

=head4 Description

Instantiiere SQL-Objekt und liefere eine Referenz auf dieses Objekt
zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$dbms,$version) = @_;

    # DBMS-Name case-insensitiv suchen

    my $dbmsName;
    for ($class->dbmsNames) {
        if (lc($dbms) eq lc($_)) {
            $dbmsName = $_;
            last;
        }
    }

    if (!$dbmsName) {
        $class->throw('SQL-00001: Unbekanntes DBMS',Dbms=>$dbms);
    }

    # Objekt instantiieren

    return $class->SUPER::new(
        dbms => $dbmsName,
        version => $version,
    );
}

# -----------------------------------------------------------------------------

=head2 Akzessoren

=head3 dbms() - Name des DBMS in kanonischer Form

=head4 Synopsis

    $name = $sql->dbms;

=cut

# -----------------------------------------------------------------------------

sub dbms {
    return shift->{'dbms'};
}

# -----------------------------------------------------------------------------

=head2 DBMS Names

=head3 dbmsNames() - Liste der Namen der unterstützten Datenbanksysteme

=head4 Synopsis

    $namesA | @names = $this->dbmsNames;

=head4 Description

Liefere folgende Liste von DBMS-Namen (in dieser Reihenfolge):

    Oracle
    PostgreSQL
    SQLite
    MySQL
    Access
    MSSQL

=cut

# -----------------------------------------------------------------------------

my @DbmsNames = qw/Oracle PostgreSQL SQLite MySQL Access MSSQL/;

sub dbmsNames {
    my $this = shift;
    return wantarray? @DbmsNames: \@DbmsNames;
}

# -----------------------------------------------------------------------------

=head2 DBMS Tests

=head3 dbmsTestVector() - Vektor für DBMS-Tests

=head4 Synopsis

    ($oracle,$postgresql,$sqlite,$mysql,$access,$mssql) = $self->dbmsTestVector;

=head4 Description

Liefere einen Vektor von boolschen Werten, von denen genau einer den
Wert "wahr" besitzt, und zwar der, der dem DBMS entspricht,
auf den das Objekt instantiiert ist.

Die Methode ist für Programmcode nützlich, der DBMS-spezifische
Unterscheidungen macht. Der Code braucht dann lediglich auf den
Wert einer Variable prüfen

    if ($oracle) ...

statt einen umständlichen und fehleranfälligen Stringvergleich
durchzuführen

    if ($dbms eq 'Oracle') ...

=cut

# -----------------------------------------------------------------------------

sub dbmsTestVector {
    my $self = shift;
    return map { $_ eq $self->{'dbms'}? 1: 0 } $self->dbmsNames;
}

# -----------------------------------------------------------------------------

=head3 isOracle() - Teste auf Oracle

=head4 Synopsis

    $bool = $class->isOracle;

=cut

# -----------------------------------------------------------------------------

sub isOracle {
    my $self = shift;
    return $self->{'dbms'} eq 'Oracle'? 1: 0;
}

# -----------------------------------------------------------------------------

=head3 isPostgreSQL() - Teste auf PostgreSQL

=head4 Synopsis

    $bool = $class->isPostgreSQL;

=cut

# -----------------------------------------------------------------------------

sub isPostgreSQL {
    my $self = shift;
    return $self->{'dbms'} eq 'PostgreSQL'? 1: 0;
}

# -----------------------------------------------------------------------------

=head3 isSQLite() - Teste auf SQLite

=head4 Synopsis

    $bool = $class->isSQLite;

=cut

# -----------------------------------------------------------------------------

sub isSQLite {
    my $self = shift;
    return $self->{'dbms'} eq 'SQLite'? 1: 0;
}

# -----------------------------------------------------------------------------

=head3 isMySQL() - Teste auf MySQL

=head4 Synopsis

    $bool = $class->isMySQL;

=cut

# -----------------------------------------------------------------------------

sub isMySQL {
    my $self = shift;
    return $self->{'dbms'} eq 'MySQL'? 1: 0;
}

# -----------------------------------------------------------------------------

=head3 isAccess() - Teste auf Access

=head4 Synopsis

    $bool = $class->isAccess;

=cut

# -----------------------------------------------------------------------------

sub isAccess {
    my $self = shift;
    return $self->{'dbms'} eq 'Access'? 1: 0;
}

# -----------------------------------------------------------------------------

=head3 isMSSQL() - Teste auf MSSQL

=head4 Synopsis

    $bool = $class->isMSSQL;

=cut

# -----------------------------------------------------------------------------

sub isMSSQL {
    my $self = shift;
    return $self->{'dbms'} eq 'MSSQL'? 1: 0;
}

# -----------------------------------------------------------------------------

=head2 Utilities

=head3 split() - Zerlege SQL-Statement in Rumpf und Stringliteral-Werte

=head4 Synopsis

    ($stmt1,@arr) = $this->split($stmt);

=head4 Description

Zerlege $stmt in den Statement-Rumpf und eine Liste von
Stringliteral-Werten und liefere diese beiden Bestandteile zurück.

Statement-Rumpf und Stringliteralwerte können unabhängig bearbeitet
und anschließend mit sprintf() wieder zusammengefügt werden.

=head4 Example

Zerlege Statement in Bestandteile:

    $stmt1 = "SELECT 'a', 'b' FROM x WHERE x = 'c' AND y = 'd''e'";
    ($stmt2,@arr) = $class->split($stmt1);
    =>
    "SELECT '%s', '%s' FROM x WHERE x = '%s' AND y = '%s''%s'"
    ('a','b','c','d','e')

Füge Bestandteile wieder zusammen:

    $stmt2 = sprintf($stmt2,@arr);
    =>
    "SELECT 'a', 'b' FROM x WHERE x = 'c' AND y = 'd''e'"

=cut

# -----------------------------------------------------------------------------

sub split {
    my $class = shift;
    my $stmt = shift;

    my @arr = $stmt =~ /'(.*?)'/gs;
    $stmt =~ s/'.*?'/'%s'/gs;

    return ($stmt,@arr);
}

# -----------------------------------------------------------------------------

=head3 resolve() - Ersetze SQL-Platzhalter durch Werte

=head4 Synopsis

    $stmtResolved = $sql->resolve($stmt,@vals);

=head4 Description

Ersetze die Platzhalter ? in SQL-Statement $stmt durch die
Werte @val und liefere das resultierende Statement zurück.

Diese Methode ist für Debugging-Zwecke nützlich, wenn mit
Platzhaltern gearbeitet wird, aber man das aufgelöste Statement
sehen möchte.

=head4 Example

    $stmt = 'SELECT * FROM t WHERE x = ? AND y > ?';
    @vals = (47,11);
    $stmtResolved = $sql->resolve($stmt,@vals);
    =>
    "SELECT * FROM t WHERE x = '47' AND y > '11'"

=cut

# -----------------------------------------------------------------------------

sub resolve {
    my $self = shift;
    my $stmt = shift;
    # @_: @vals

    # Stringliteral-Werte herausziehen
    ($stmt,my @arr) = $self->split($stmt);

    while (@_) {
        my $val = shift;
        if ($val =~ /%s/) {
            $self->throw(
                'SQL-00099: Wert enthält %s',
                Value => $val,
            );
        }
        $stmt =~ s/\?/$self->stringLiteral($val,'NULL')/e;
    }

    # Stringliteral-Werte einsetzen
    return sprintf $stmt,@arr;
}

# -----------------------------------------------------------------------------

=head3 removeSelectClause() - Entferne SELECT-Klausel

=head4 Synopsis

    $newStmt = $sql->removeSelectClause($stmt);

=head4 Description

Entferne die Select-Klausel am Anfang von Select-Statement $stmt
und liefere das resultierende Statement zurück.

Als Select-Klausel wird alles vom Beginn des Statement
bis zur FROM-Klausel angesehen.

=cut

# -----------------------------------------------------------------------------

sub removeSelectClause {
    my ($self,$stmt) = @_;
        $stmt =~ s|^.*?(?=FROM)||si;
        return $stmt;
}

# -----------------------------------------------------------------------------

=head3 removeOrderByClause() - Entferne ORDER BY-Klausel

=head4 Synopsis

    $newStmt = $sql->removeOrderByClause($stmt);

=head4 Description

Entferne die Order By-Klausel vom Ende des Select-Statement $stmt
und liefere das resultierende Statement zurück.

Als Select-Klausel wird alles von der ORDER BY-Klausel bis zum
Ende des Statment angesehen.

=cut

# -----------------------------------------------------------------------------

sub removeOrderByClause {
    my ($self,$stmt) = @_;
        $stmt =~ s|\s+ORDER\s+BY.*$||si;
        return $stmt;
}

# -----------------------------------------------------------------------------

=head3 checkName() - Prüfe Bezeichner

=head4 Synopsis

    $name = $sql->checkName($name);
    $sql->checkName(\$name);

=head4 Description

Prüfe und manipuliere Bezeichner $name, so dass er den Konventionen
des DBMS entspricht.

B<Oracle>

=over 2

=item *

Ist der Bezeichner länger als 30 Zeichen, kürze ihn auf 29
Zeichen und ersetze das 30. Zeichen durch #.

=back

=cut

# -----------------------------------------------------------------------------

sub checkName {
    my $self = shift;
    my $arg = shift;

    my $ref = ref $arg? $arg: \$arg;
    if ($self->isOracle) {
         if (length $$ref > 30) {
             $$ref = substr($$ref,0,29).'$';
         }
         $$ref =~ s/[^\w#\$]/_/g;
    }
    elsif ($self->isPostgreSQL) {
         if (length $$ref > 63) {
             $$ref = substr($$ref,0,63).'$';
         }
         $$ref =~ s/[^\w\$]/_/g;
    }

    return ref $arg? (): $arg;
}

# -----------------------------------------------------------------------------

=head3 stmtListToScript() - Generiere aus Liste von SQL-Statements ein Skript

=head4 Synopsis

    $script = $class->stmtListToScript(@stmt)

=head4 Description

Erzeuge aus einer Liste von SQL-Statements ein einzelnes Skript,
das von einem Client-Programm wie SQL*Plus, psql bzw. mysql
ausgeführt werden kann.

Die SQL-Statements bzw. SQL-Kommentare in @stmt haben am Ende
weder Newline noch Semikolon. Diese Methode fügt sie hinzu
und konkateniert alle Statements zu einer Zeichenkette.

Folgende Manipulationen werden vorgenommen:

=over 2

=item *

SQL-Statements erhalten am Ende ein Semikolon und ein Newline.

=item *

Kommentare erhalten am Ende ein Newline und werden von den umgebenden
SQL-Statements abgesetzt, indem vor und nach ihnen eine Leerzeile
eingefügt wird.

=back

Diverse Details werden unterschieden (siehe EXAMPLES).

=head4 Example

So verhält es sich im Detail:

    $script = Quiq::Sql->stmtListToScript(
        '-- TEXT1',
        'STMT1',
        "STMT2\n...',
        "STMT3 (\n....\n)",
        '-- TEXT2',
        'STMT4',
        '-- eof',
    );

wird zu:

    -- TEXT1     Kommentar am Anfang => danach "\n\n"
    
    STMT1;       einzeiliges Statement => danach ";\n\n")
    
    STMT2        mehrzeilges Statement => danach "\n;\n")
        ...
    ;
    STMT3 (      mehrzeiles Statement mit ) => danach ";\n")
        ...
    );
    
    -- TEXT2     innerer Kommentar => davor "\n", danach "\n\n"
    
    STMT4;       (wie einzeiliges Statement oben)
    
    -- eof       Kommentar am Ende, nach einzeiligem Statement
                 => davor nichts, danach "\n"

=cut

# -----------------------------------------------------------------------------

sub stmtListToScript {
    my $this = shift;
    my @stmt = @_;

    # Kommentare nachbearbeiten und Statement-Trenner hinzufügen
    # 1. Leerzeile vor und hinter jeden Kommentar
    # 2. Erste Zeile kein \n am Anfang und nur ein \n am Ende

    for (my $i = 0; $i < @stmt; $i++) {
        if (substr($stmt[$i],0,2) eq '--') {
            $stmt[$i] .= "\n\n";
        }
        else {
            $stmt[$i] .= ";\n\n";
        }
    }
    $stmt[-1] =~ s/\n+$/\n/;

    return join('',@stmt);
}

# -----------------------------------------------------------------------------

=head2 Commands

=head3 commands() - Liste der Kommandos des DBMS

=head4 Synopsis

    @commands | $commandA = $sql->commands;

=cut

# -----------------------------------------------------------------------------

my %Commands = (
    Oracle => [
    ],
    PostgreSQL => [qw/
        ABORT
        ALTER
        ANALYZE
        BEGIN
        CALL
        CHECKPOINT
        CLOSE
        CLUSTER
        COMMENT
        COMMIT
        COPY CREATE
        DEALLOCATE
        DECLARE
        DELETE
        DISCARD
        DO
        DROP
        END
        EXECUTE
        EXPLAIN
        FETCH
        GRANT
        IMPORT FOREIGN SCHEMA
        INSERT
        LISTEN
        LOAD
        LOCK
        MOVE
        NOTIFY
        PREPARE
        REASSIGN OWNED
        REFRESH MATERIALIZED VIEW
        REINDEX
        RELEASE SAVEPOINT
        ROLLBACK
        SAVEPOINT
        SECURITY LABEL
        SELECT
        SET
        SHOW
        START TRANSACTION
        TRUNCATE
        UNLISTEN
        UPDATE
        VACUUM
        VALUES
    /],
    SQLite => [
    ],
    MySQL => [
    ],
    Access => [
    ],
    MSSQL => [
    ],
);

sub commands {
    my $self = shift;

    my $dbms = $self->{'dbms'};
    my $cmdA = $Commands{$dbms};
    if (!@$cmdA) {
        $self->throw(
            'SQL-00099: No commands defined for DBMS',
            Dbms => $dbms,
        );
    }

    return wantarray? @$cmdA: $cmdA;
}

# -----------------------------------------------------------------------------

=head2 Data Types

Methoden für die portable Spezifikation von Kolumnen-Datentypen.

=head3 dataType() - Wandele portablen Datentyp-Bezeichner in DBMS-Typ-Bezeichner

=head4 Synopsis

    $dbmsType = $sql->dataType($portableType);
    ($dbmsType,$args) = $sql->dataType($portableType);

=head4 Description

Wandele den portablen Datentyp $portableType in den entsprechenden
DBMS-spezifischen Typ und liefere diesen zurück. Im Skalarkontext
liefere den Typbezeichner einschließlich etwaiger Argumente,
im Listkontext liefere Typ und Argumente getrennt.

B<Typ-Abbildung>

    Portabel   Oracle     PostgreSQL SQLite    MySQL
    ---------- ---------- ---------- --------- ----------
    STRING     VARCHAR2   VARCHAR    TEXT      VARCHAR
    TEXT       CLOB       TEXT       TEXT      LONGTEXT
    INTEGER    NUMBER     NUMERIC    INTEGER   (TINY|SMALL|MEDIUM|BIG)INT
    REAL       NUMBER     NUMERIC    REAL      DECIMAL
    DATETIME   TIMESTAMP  TIMESTAMP  TIMESTAMP TIMESTAMP
    BLOB       BLOB       BYTEA      BLOB      LONGBLOB

=over 2

=item *

VARCHAR2 kann bei Oracle max 4000 Zeichen lang sein

=back

=head4 Example

Einige Konvertierungen im Falle von Oracle:

    $type = $sql->dataType('STRING');
    # => 'VARCHAR2'
    
    $type = $sql->dataType('STRING(20)');
    # => 'VARCHAR2(20)'
    
    ($type,$args) = $sql->dataType('STRING');
    # => ('VARCHAR2','')
    
    ($type,$args) = $sql->dataType('STRING(20)');
    # => ('VARCHAR2','(20)')
    
    ($type,$args) = $sql->dataType('DATETIME');
    # => ('TIMESTAMP','(0)')

=cut

# -----------------------------------------------------------------------------

my %DataType = (
    Oracle => {
        STRING => 'VARCHAR2',
        TEXT => 'CLOB',
        INTEGER => 'NUMBER',
        REAL => 'NUMBER',
        DATETIME => 'TIMESTAMP',
        BLOB => 'BLOB',
    },
    PostgreSQL => {
        STRING => 'VARCHAR',
        TEXT => 'TEXT',
        INTEGER => 'NUMERIC',
        REAL => 'NUMERIC',
        DATETIME => 'TIMESTAMP',
        BLOB => 'BYTEA',
    },
    SQLite => {
        STRING => 'TEXT',
        TEXT => 'TEXT',
        INTEGER => 'INTEGER',
        REAL => 'REAL',
        DATETIME => 'TIMESTAMP',
        BLOB => 'BLOB',
    },
    MySQL => {
        STRING => 'VARCHAR',
        TEXT => 'LONGTEXT',
        INTEGER => 'BIGINT',
        REAL => 'DECIMAL',
        DATETIME => 'TIMESTAMP',
        BLOB => 'LONGBLOB',
    },
    Access => {
        STRING => 'TEXT',
        TEXT => 'MEMO',
        INTEGER => 'LONG',
        REAL => 'DOUBLE',
        DATETIME => 'DATETIME',
        BLOB => 'LONGBINARY',
    },
    MSSQL => {
        # FIXME: Ungeprüft
        STRING => 'TEXT',
        TEXT => 'MEMO',
        INTEGER => 'LONG',
        REAL => 'DOUBLE',
        DATETIME => 'DATETIME',
        BLOB => 'LONGBINARY',
    },
);

sub dataType {
    my ($self,$portableType) = @_;

    # Typ-Argumente abschneiden, falls vorhanden.
    # Mögliche Erweiterung: Argumente auswerten und bei DBMS-Typ
    # berücksichtigen.

    $portableType =~ s/(\(([\d,]+)\))//;
    my $args = $1 || '';
    my $argVal = $2 || 0;

    my $dbms = $self->{'dbms'};
    if (!exists $DataType{$dbms}{$portableType}) {
        $self->throw(
            'SQL-00003: Unbekannter Datentyp',
            Type => $portableType,
        );
    }

    my $dbmsType = $DataType{$dbms}{$portableType};
    unless ($dbmsType) {
        $self->throw(
            'SQL-00004: Datentyp von DBMS nicht unterstützt',
            Dbms => $dbms,
            Type => $portableType,
        );
    }

    if ($self->isPostgreSQL) {
        if ($portableType eq 'REAL') {
            $args = ''; # Nachkommastellen werden sonst mit 0en aufgefüllt
        }
    }
    elsif ($self->isSQLite) {
        if ($portableType eq 'INTEGER') {
            $args = ''; # da AUTOINCREMENT nur INTEGER erlaubt
        }
    }
    elsif ($self->isMySQL) {
        if ($portableType eq 'INTEGER') {
            if ($argVal == 0) {
                $dbmsType = 'BIGINT';
            }
            elsif ($argVal <= 2) {
                $dbmsType = 'TINYINT';
            }
            elsif ($argVal <= 4) {
                $dbmsType = 'SMALLINT';
            }
            elsif ($argVal <= 6) {
                $dbmsType = 'MEDIUMINT';
            }
            elsif ($argVal <= 9) {
                $dbmsType = 'INT';
            }
            else  {
                $dbmsType = 'BIGINT';
            }
            $args = '';
        }
    }

    if ($portableType eq 'DATETIME' && $dbmsType eq 'TIMESTAMP') {
        $args = '(0)';
    }

    return wantarray? ($dbmsType,$args): "$dbmsType$args";
}

# -----------------------------------------------------------------------------

=head3 columnDef() - Generiere Kolumnen-Definition

=head4 Synopsis

    $colDef = $sql->columnDef(@colDef);
    $colDef = $sql->columnDef($portableType,@colDef);

=head4 Description

Generiere aus der portablen Kolumnen-Spezifikation @colDef eine
DBMS-spezifische Kolumnen-Definition, die als Zeichenkette
nach dem Kolumnennamen in ein CREATE TABLE oder ALTER TABLE Statement
eingesetzt werden kann, und liefere diese zurück.

Die Methode wird von den Methoden createTable() und addColumn()
genutzt.

Die Kolumnen-Spezifikation @colDef besteht aus einer
nicht-leeren Aufzählung von folgenden Schlüssel/Wert-Paaren:

=over 4

=item default => $value

Defaultwert der Kolumne.

=item null => $bool

Kolumne ist kein Pflichtfeld. Diese explizite Setzung wird bei
MySQL gebraucht, wenn ein TIMESTAMP-Feld nicht
'0000-00-00 00:00:00' als Defaultwert erhalten soll.

=item notNull => $bool

Kolumne ist Pflichtfeld.

=item autoIncrement => $bool

Das DBMS erzeugt beim Einfügen eines Datensatzes einen
eindeutigen Wert (SQLite und MySQL).

=item primaryKey => $bool

Kolumne ist Primärschlüsselkolumne.

=item type => $type

Portabler Kolumnentyp.

=item oracleType => $oracleType

Kolumnentyp für Oracle.

=item postgresqlType => $postgresqlType

Kolumnentyp für PostgreSQL.

=item sqliteType => $sqliteType

Kolumnentyp für SQLite.

=item mysqlType => $mysqlType

Kolumnentyp für MySQL.

=back

Der Kolumnentyp ist für eine Kolumnenspezifikation zwingend. Er
wird als portabler Typ (type=>$type) oder als DBMS-spezifischer
Typ (<dbms>Type=>$type) angegeben. Ist beides angegeben, hat der
DBMS-spezifische Typ Vorrang.

Das Attribut autoIncrement ist nicht portabel, es ist

=head4 Example

=over 2

=item *

Portabler Typ wird verwendet, wenn nichts anderes
für das DBMS angegeben ist:

    $sql = Quiq::Sql->new('Oracle');
    $type = $sql->columnDef(
        type => 'STRING(20)',
    );
    ==>
    'VARCHAR2(20)'

=item *

DBMS-Typ wird verwendet, wenn angegeben:

    $sql = Quiq::Sql->new('Oracle');
    $type = $sql->columnDef(
        type => 'INTEGER(5)',
        oracleType => 'NUMBER(5)',
    );
    ==>
    'NUMBER(5)'

=back

=cut

# -----------------------------------------------------------------------------

sub columnDef {
    my $self = shift;
    # @_: @typeSpec

    my $keyVal = Quiq::Hash->new(
        default => undef,
        null => undef,
        notNull => undef,
        primaryKey => undef,
        autoIncrement => undef, # unportabel, nicht Oracle und PostgreSQL
        type => undef,
        oracleType => undef,
        postgresqlType => undef,
        sqliteType => undef,
        mysqlType => undef,
    );
    if (@_%2 == 1) {
        unshift @_,'type';
    }
    $keyVal->set(@_);

    # Datentyp der Kolumne bestimmen

    my $dbms = lc $self->{'dbms'};
    my $type = $keyVal->{"${dbms}Type"};
    if (!$type) {
        if ($type = $keyVal->{'type'}) {
            $type = $self->dataType($type);
        }
    }
    if (!$type) {
        $self->throw(
            'SQL-00007: Kein Kolumnen-Typ für DBMS angegeben',
            DBMS => $dbms,
        );
    }

    my $colDef = $type;

    # weitere, optionale Kolumnen-Attribute

    my $val;
    if (defined($val = $keyVal->{'default'}) && $val ne '') {
        $val = $self->valExpr($val);
        $colDef .= " DEFAULT $val"; # FIXME: ggf. allgemeiner machen
    }
    if ($val = $keyVal->{'null'}) {
        $colDef .= ' NULL';
    }
    if ($val = $keyVal->{'notNull'}) {
        $colDef .= ' NOT NULL';
    }
    if ($val = $keyVal->{'primaryKey'}) {
        $colDef .= ' PRIMARY KEY';
    }
    if ($val = $keyVal->{'autoIncrement'}) {
        if ($self->isMySQL) {
            $colDef .= ' AUTO_INCREMENT';
        }
        elsif ($self->isSQLite) {
            $colDef .= ' AUTOINCREMENT';
        }
        #  kein Autoinkrement bei Oracle und PostgreSQL
    }

    return $colDef;
}

# -----------------------------------------------------------------------------

=head2 Comments

=head3 comment() - Generiere SQL-Kommentar

=head4 Synopsis

    $stmt = $sql->comment($text);

=head4 Description

Setze an den Anfang jeder Zeile in $text die Zeichenfolge '-- '
und liefert das Resultat zurück.

Whitespace am Ende wird entfernt, d.h. der SQL-Kommentar endet
wie die SQL-Statements per Default nicht mit einem Newline.

=head4 Example

    Lorem ipsum dolor sit amet, consetetur sadipscing
    elitr, sed diam nonumy eirmod tempor invidunt ut
    labore et dolore magna

wird zu

    -- Lorem ipsum dolor sit amet, consetetur sadipscing
    -- elitr, sed diam nonumy eirmod tempor invidunt ut
    -- labore et dolore magna

=cut

# -----------------------------------------------------------------------------

sub comment {
    my $self = shift;
    my $text = shift;

    if (!defined $text || $text eq '') {
        return '';
    }

    $text =~ s/\s+$//;
    $text =~ s/^/-- /gm;
    $text =~ s/^-- $/--/gm;

    return $text;
}

# -----------------------------------------------------------------------------

=head2 Session

=head3 setDateFormat() - Generiere Statements zum Setzen des Datumsformats

=head4 Synopsis

    @stmt = $class->setDateFormat;
    @stmt = $class->setDateFormat($format);

=head4 Description

Setze als Default-Datumsformat $format. Ist $format nicht angegeben,
setzte iso-Format.

Folgende Datumsformate sind definiert:

=over 4

=item iso

YYYY-MM-DD HH:MM:SS

=back

B<Oracle>

    (iso)
    ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD HH24:MI:SS'
    ALTER SESSION SET NLS_TIMESTAMP_FORMAT = 'YYYY-MM-DD HH24:MI:SSXFF'

B<PostgreSQL>

    (iso)
    SET datestyle TO iso, ymd

B<SQLite>

unbekannt

B<MySQL>

unbekannt

=cut

# -----------------------------------------------------------------------------

sub setDateFormat {
    my $self = shift;
    my $format = shift || 'iso';

    my ($oracle,$postgresql,$sqlite,$mysql,$access,$mssql) =
        $self->dbmsTestVector;

    # Statement generieren

    my @stmt;
    if ($oracle) {
        if ($format eq 'iso') {
            my $dateFmt = 'YYYY-MM-DD HH24:MI:SS';
            my $timestampFmt = 'YYYY-MM-DD HH24:MI:SSXFF';
            return ("ALTER SESSION SET NLS_DATE_FORMAT = '$dateFmt'",
                "ALTER SESSION SET NLS_TIMESTAMP_FORMAT = '$timestampFmt'");
        }
    }
    elsif ($postgresql) {
        if ($format eq 'iso') {
            return ('SET datestyle TO iso, ymd');
        }
    }
    elsif ($sqlite || $mysql || $access || $mssql) {
        return; # FIXME: bislang nicht untersucht
    }

    $self->throw('Not implemented');
}

# -----------------------------------------------------------------------------

=head3 setNumberFormat() - Generiere Statements zum Setzen des Zahlenformats

=head4 Synopsis

    @stmt = $class->setNumberFormat;
    @stmt = $class->setNumberFormat($format);

=head4 Description

Setze als Default-Zahlenformat $format. Ist $format nicht angegeben,
setzte angloamerikanisches Format.

B<Oracle>

    ALTER SESSION SET NLS_NUMERIC_CHARACTERS = '.,'

B<PostgreSQL>

unbekannt

B<SQLite>

unbekannt

B<MySQL>

unbekannt

=cut

# -----------------------------------------------------------------------------

# FIXME: (1) portable Lösung, (2) eventuell alle Setzungen in einem
#        Aufruf zusammenfassen

sub setNumberFormat {
    my $self = shift;
    my $format = shift || '.,';

    my ($oracle,$postgresql,$sqlite,$mysql,$access,$mssql) =
        $self->dbmsTestVector;

    # Statement generieren

    my @stmt;
    if ($oracle) {
        return ("ALTER SESSION SET NLS_NUMERIC_CHARACTERS = '$format'");
    }
    elsif ($postgresql || $sqlite || $mysql || $access || $mssql) {
        return; # FIXME: bislang nicht untersucht
    }

    $self->throw('Not implemented');
}

# -----------------------------------------------------------------------------

=head3 setSchema() - Generiere Statement zum Setzen des aktuellen Schema

=head4 Synopsis

    $class->setSchema($schema);

=head4 Description

B<Oracle>

    ALTER SESSION SET CURRENT_SCHEMA = <schema>

B<PostgreSQL>

    SET search_path TO <schema>

=over 2

=item *

Anstelle eines einzelnen Schema können mehrere Schemata, mit Komma
getrennt, aufgezählt werden.

=item *

Die Setzung sollte sofort mit COMMIT bestätigt werden, da
sie im Falle eines ROLLBACK sonst verfällt.

=back

B<SQLite>

    <leer>

SQLite hat das Konzept mehrerer Schemata, von denen eins das
Default-Schema ist, nicht.

Bei einer SQLite-Datenbank gibt es per Default keinen Schema-Präfix,
dieser wird erst durch ATTACH einer Datenbank eingeführt.

Ein Tabellenname ohne Schema wird immer über allen Attachten Datenbanken
aufgelöst. Die zuerst hinzugefügte Tabelle ist der Dafault.

B<MySQL>

    USE <schema>

=cut

# -----------------------------------------------------------------------------

sub setSchema {
    my $self = shift;
    my $schema = shift;

    my ($oracle,$postgresql,$sqlite,$mysql) = $self->dbmsTestVector;

    # Statement generieren

    my $stmt;
    if ($oracle) {
        $stmt = "ALTER SESSION SET CURRENT_SCHEMA = $schema";
    }
    elsif ($postgresql) {
        $stmt = "SET search_path TO $schema";
    }
    elsif ($sqlite) {
        $stmt = '';
    }
    elsif ($mysql) {
        $stmt = "USE $schema";
    }
    else {
        $self->throw('Not implemented');
    }

    return $stmt;
}

# -----------------------------------------------------------------------------

=head3 setSearchPath() - Generiere Statement zum Setzen des Search Path

=head4 Synopsis

    $stmt = $class->setSearchPath(@schemas);

=head4 Description

B<Oracle>

    <not implemented>

B<PostgreSQL>

    SET search_path TO SCHEMA, ...

B<SQLite>

    <not implemented>

B<MySQL>

    <not implemented>

=cut

# -----------------------------------------------------------------------------

sub setSearchPath {
    my ($self,@schemas) = @_;

    my ($oracle,$postgresql,$sqlite,$mysql) = $self->dbmsTestVector;

    # Statement generieren

    my $stmt;
    if ($oracle) {
        $self->throw('Not implemented');
    }
    elsif ($postgresql) {
        $stmt = sprintf 'SET search_path TO %s',join(', ',@schemas);
    }
    elsif ($sqlite) {
        $self->throw('Not implemented');
    }
    elsif ($mysql) {
        $self->throw('Not implemented');
    }
    else {
        $self->throw('Not implemented');
    }

    return $stmt;
}

# -----------------------------------------------------------------------------

=head3 setEncoding() - Generiere Statement zum Setzen des Client-Encodings

=head4 Synopsis

    $stmt = $class->setEncoding($charset);

=head4 Description

Werte für $charset:

    iso-8859-1
    utf-8

B<Oracle>

    <not implemented>

B<PostgreSQL>

    SET client_encoding TO <charset>

B<SQLite>

    <not implemented>

B<MySQL>

    <not implemented>

=cut

# -----------------------------------------------------------------------------

sub setEncoding {
    my ($self,$charset) = @_;

    my ($oracle,$postgresql,$sqlite,$mysql) = $self->dbmsTestVector;

    # Statement generieren

    my $stmt;
    if ($oracle) {
        $self->throw('Not implemented');
    }
    elsif ($postgresql) {
        if ($charset eq 'iso-8859-1') {
            $charset = 'latin1';
        }
        elsif ($charset eq 'utf-8') {
            $charset = 'utf8';
        }
        $stmt = "SET client_encoding TO $charset";
    }
    elsif ($sqlite) {
        $self->throw('Not implemented');
    }
    elsif ($mysql) {
        $self->throw('Not implemented');
    }
    else {
        $self->throw('Not implemented');
    }

    return $stmt;
}

# -----------------------------------------------------------------------------

=head2 Locking

=head3 lockTable() - Generiere LOCK TABLE Statement

=head4 Synopsis

    $stmt = $class->lockTable($table);

=head4 Description

B<Oracle>

    LOCK TABLE <table> IN EXCLUSIVE MODE NOWAIT

B<PostgreSQL>

    LOCK TABLE <table> IN EXCLUSIVE MODE NOWAIT

B<SQLite>

    nicht implementiert

B<MySQL>

    nicht implementiert

=cut

# -----------------------------------------------------------------------------

sub lockTable {
    my ($self,$table) = @_;

    # Statement generieren

    my ($oracle,$postgresql,$sqlite,$mysql) = $self->dbmsTestVector;

    if ($oracle || $postgresql) {
        return "LOCK TABLE $table IN EXCLUSIVE MODE NOWAIT";
    }

    $self->throw('Not implemented');
}

# -----------------------------------------------------------------------------

=head2 User

=head3 createUser() - Generiere CREATE USER Statement

=head4 Synopsis

    $stmt = $class->createUser($name,$password,@opt);

=head4 Options

=over 4

=item -defaultTableSpace => $name (Default: keiner)

Name des Default-Tablespace

=item -tempTableSpace => $name (Default: keiner)

Name des Temporary-Tablespace

=back

=cut

# -----------------------------------------------------------------------------

sub createUser {
    my $self = shift;
    my $name = shift;
    my $password = shift;

    # Optionen

    my $defaultTableSpace = undef;
    my $tempTableSpace = undef;

    if (@_) {
        Quiq::Option->extract(\@_,
             -defaultTableSpace => \$defaultTableSpace,
             -tempTableSpace => \$tempTableSpace,
        );
    }

    # Statement generieren

    my $stmt;

    my ($oracle,$postgresql,$sqlite,$mysql) = $self->dbmsTestVector;

    if ($oracle) {
        $stmt = "CREATE USER $name\n".
            "    IDENTIFIED BY $password";

        if ($defaultTableSpace) {
            $stmt .= "\n    DEFAULT TABLESPACE $defaultTableSpace";
        }
        if ($tempTableSpace) {
            $stmt .= "\n    TEMPORARY TABLESPACE $tempTableSpace";
        }
    }
    else {
        die;
    }

    return $stmt;
}

# -----------------------------------------------------------------------------

=head2 Schema

=head3 createSchema() - Generiere CREATE SCHEMA Statement

=head4 Synopsis

    $stmt = $class->createSchema($name);

=cut

# -----------------------------------------------------------------------------

sub createSchema {
    my $self = shift;
    my $name = shift;

    # Statement generieren

    my $stmt;

    my ($oracle,$postgresql,$sqlite,$mysql) = $self->dbmsTestVector;

    if ($postgresql) {
        $stmt = "CREATE SCHEMA $name";
    }
    else {
        die;
    }

    return $stmt;
}

# -----------------------------------------------------------------------------

=head3 dropSchema() - Generiere DROP SCHEMA Statement

=head4 Synopsis

    $stmt = $class->dropSchema($name);

=cut

# -----------------------------------------------------------------------------

sub dropSchema {
    my $self = shift;
    my $name = shift;

    # Statement generieren

    my $stmt;

    my ($oracle,$postgresql,$sqlite,$mysql) = $self->dbmsTestVector;

    if ($oracle) {
        $stmt = "DROP USER $name CASCADE";
    }
    elsif ($postgresql) {
        $stmt = "DROP SCHEMA $name CASCADE";
    }
    else {
        die;
    }

    return $stmt;
}

# -----------------------------------------------------------------------------

=head2 Table

=head3 splitTableName() - Zerlege Tabellennamen

=head4 Synopsis

    ($schema,$table) = $class->splitTableName($name);
    ($schema,$table) = $class->splitTableName($name,$sloppy);

=head4 Alias

splitTablename()

=head4 Description

Zerlege den Tabellennamen $name in die Komponenten $schema und $table.
Besitzt der Tabellennamen keinen Schema-Präfix, wird eine Exception
geworfen. Dies geschieht nicht, wenn der Parameter $sloppy gesetzt
und wahr ist. In dem Fall wird keine Exception geworfen, sondern als
Schemaname C<undef> geliefert.

=cut

# -----------------------------------------------------------------------------

sub splitTableName {
    my ($class,$name,$sloppy) = @_;

    my ($schema,$table) = split /\./,$name;
    if (!$table) {
        if (!$sloppy) {
            $class->throw(
                'SQL-00099: Tablename without schema prefix',
                Tablename => $name,
            );
        }
        $table = $schema;
        $schema = undef;
    }

    return ($schema,$table);
}

{
    no warnings 'once';
    *splitTablename = \&splitTableName;
}

# -----------------------------------------------------------------------------

=head3 createTable() - Generiere CREATE TABLE Statement

=head4 Synopsis

    $stmt = $sql->createTable($table,
        [$colName,@colDef],
        ...
        @opt,
    );

=head4 Options

=over 4

=item -tableSpace => $tableSpaceName (Default: keiner)

Name des Tablespace, in dem die Tabelle erzeugt wird
(Oracle und PostgreSQL).

=item -tableType => $tableType (Default: 'InnoDB')

Tabellentyp bei MySQL: 'InnoDb', 'MyISAM'.

=back

=head4 Description

Generiere ein CREATE TABLE Statement und liefere dieses zurück.

Für jede Kolumne wird ihr Name $colName und ihr Typ.

Der Kolumnentyp wird als portabler Typ (type=>$type)
oder als DBMS-spezifischer Typ (<dbms>Type=>$type) angegeben.
Ist beides angegeben, hat der DBMS-spezifische Typ Priorität.
Für die portablen Typen siehe Methode columnType().

Alle weiteren Angaben in @colOpts sind optional.

Folgende Kolumnen-Optionen sind definiert:

=over 4

=item notNull => $bool

Kolumne ist Pflichtfeld.

=item autoIncrement => $bool

Das DBMS erzeugt beim Einfügen eines Datensatzes einen
eindeutigen Wert (nicht Oracle und PostgreSQL, diese
haben das Konzept der Sequenz).

=item primaryKey => $bool

Kolumne ist Primärschlüsselkolumne.

=item type => $type

Portabler Kolumnentyp.

=item oracleType => $oracleType

Kolumnentyp für Oracle.

=item postgresqlType => $postgresqlType

Kolumnentyp für PostgreSQL.

=item sqliteType => $sqliteType

Kolumnentyp für SQLite.

=item mysqlType => $mysqlType

Kolumnentyp für MySQL.

=back

MySQL-Tabellen werden per Default als InnoDB-Tabellen erzeugt
und erhalten als Zusatz die Angabe "TYPE = InnoDB". Der
Tabellentyp kann mit der Option -tableType abweichend gesetzt werden.

Die Typ-Attribute type und <dbms>Type werden von columnTypeSpec()
in den DBMS-Typ umgewandelt.

=cut

# -----------------------------------------------------------------------------

sub createTable {
    my $self = shift;
    my $table = shift;
    # @_: @cols

    # Optionen

    my $tableSpace = undef;
    my $tableType = 'InnoDB';

    if (@_) {
        Quiq::Option->extract(-mode=>'sloppy',\@_,
             -tableSpace => \$tableSpace,
             -tableType => \$tableType,
        );
    }

    # Statement generieren

    my ($oracle,$postgresql,$sqlite,$mysql) = $self->dbmsTestVector;

    my $cols;
    for (@_) {
        my ($colName,@keyVal) = @$_;
        $cols .= $cols? "\n    , ": '    ';
        $cols .= $colName.' '.$self->columnDef(@keyVal);
    }

    my $stmt = "CREATE TABLE $table (";
    if ($cols) {
        $stmt .= "\n$cols\n";
    }
    $stmt .= ')';

    if ($tableSpace && ($oracle || $postgresql)) {
        $stmt .= "\nTABLESPACE $tableSpace";
    }

    # MySQL-Tabellen mit $tableType kreieren

    if ($mysql) {
        # Ab MySQL 5.5 ist InnoDB die Default-Storage-Engine.
        # Das Schlüsselwort ist nicht mehr TYPE, sondern ENGINE.
        # $stmt .= "\nTYPE = $tableType";
        $stmt .= "\nENGINE = $tableType";
    }

    return $stmt;
}

# -----------------------------------------------------------------------------

=head3 dropTable() - Generiere DROP TABLE Statement

=head4 Synopsis

    $stmt = $sql->dropTable($table);

=cut

# -----------------------------------------------------------------------------

sub dropTable {
    my $self = shift;
    my $table = shift;

    my $stmt = "DROP TABLE $table";

    my ($oracle,$postgresql,$sqlite,$mysql) = $self->dbmsTestVector;
    if ($oracle) {
        $stmt .= ' CASCADE CONSTRAINTS';
    }
    elsif ($postgresql) {
        $stmt .= ' CASCADE';
    }

    return $stmt;
}

# -----------------------------------------------------------------------------

=head3 analyzeTable() - Generiere ANALYZE TABLE Statement

=head4 Synopsis

    $stmt = $sql->analyzeTable($table);

=cut

# -----------------------------------------------------------------------------

sub analyzeTable {
    my ($self,$table) = @_;

    my ($oracle,$postgresql,$sqlite,$mysql) = $self->dbmsTestVector;

    # Für DBMSe, die kein ANALYZE kennen, liefern wir ein
    # leeres Statement.

    my $stmt = '';
    if ($postgresql) {
        $stmt = "ANALYZE $table";
    }

    return $stmt;
}

# -----------------------------------------------------------------------------

=head3 legalizeTablename() - Legalisiere Tabellennamen

=head4 Synopsis

    $table = $sql->legalizeTablename($table);

=head4 Description

Legalisiere Tabellennamen durch Quotierung, wenn dieser Sonderzeichen
enthält. Dies geschieht bei MySQL durch Backticks, z.B. bei Tabellen,
deren Name einen Bindestrich enthält:

    Meine-Tabelle -> `Meine-Tabelle`
    Mein-Schema.Meine-Tabelle -> `Meine-Schema`.`Meine-Tabelle`

Für die anderen DBMSe ist das Feature aktuell nicht implementiert,
d.h. es wird immer der unveränderte Tabellenname zurückgegeben.

=cut

# -----------------------------------------------------------------------------

sub legalizeTablename {
    my ($self,$table) = @_;

    my ($oracle,$postgresql,$sqlite,$mysql) = $self->dbmsTestVector;

    if ($mysql) {
        if ($table =~ /[^\w.\$]/) {
            $table =~ s/([^.]+)/`$1`/g;
        }
    }

    return $table;
}

# -----------------------------------------------------------------------------

=head2 Columns

=head3 addColumn() - Generiere ALTER TABLE Statement, das eine Kolumne erzeugt

=head4 Synopsis

    $stmt = $sql->addColumn($table,$column,@colDef);

=head4 Description

Erzeuge SQL-Statement, das der Tabelle $table die Kolumne $column
mit der Spezifikation @colDef hinzufügt. Die portable
Kolumnen-Spezifikation @colDef wird von Methode columnDef()
in die DBMS-spezifische Zeichenkette gewandelt.

B<PostgreSQL Syntax>

    ALTER TABLE table ADD COLUMN column type ...

B<Oracle Syntax>

    ALTER TABLE table ADD (column type ...)

B<SQLite Syntax>

    ALTER TABLE table ADD COLUMN column type ...

B<MySQL Syntax>

    ALTER TABLE table ADD COLUMN column type ...

Die Punkte stehen für zusätzliche optionale Kolumnen-Angaben, wie
"DEFAULT expr", "NOT NULL", "PRIMARY KEY" usw.

=cut

# -----------------------------------------------------------------------------

sub addColumn {
    my $self = shift;
    my $table = shift;
    my $column = shift;
    # @_: @typeSpec

    # Statement generieren

    my ($oracle,$postgresql,$sqlite,$mysql) = $self->dbmsTestVector;

    my $colDef = $self->columnDef(@_);

    my $stmt;
    if ($oracle) {
        $stmt = sprintf "ALTER TABLE $table ADD ($column $colDef)";
    }
    elsif ($postgresql || $sqlite || $mysql) {
        $stmt = sprintf "ALTER TABLE $table ADD COLUMN $column $colDef";
    }
    else {
        $self->throw('Not implemented');
    }

    return $stmt;
}

# -----------------------------------------------------------------------------

=head3 dropColumn() - Generiere ALTER TABLE Statement, das eine Kolumne entfernt

=head4 Synopsis

    $stmt = $sql->dropColumn($table,$column);

=head4 Description

Erzeuge SQL-Statement, das aus der Tabelle $table die Kolumne $column
entfernt.

B<Oracle, PostgreSQL, MySQL Syntax>

    ALTER TABLE table DROP COLUMN column

B<SQLite Syntax>

    Eine Kolumne kann nicht entfernt werden (geprüft 3.6.13)

=cut

# -----------------------------------------------------------------------------

sub dropColumn {
    my $self = shift;
    my $table = shift;
    my $column = shift;

    my ($oracle,$postgresql,$sqlite,$mysql) = $self->dbmsTestVector;

    # Statement generieren

    my $stmt;
    if ($oracle || $postgresql || $sqlite || $mysql) {
        $stmt = sprintf "ALTER TABLE $table DROP COLUMN $column";
    }
    else {
        $self->throw('Not implemented');
    }

    return $stmt;
}

# -----------------------------------------------------------------------------

=head3 modifyColumn() - Generiere ALTER TABLE Statement, das eine Kolumne modifiziert

=head4 Synopsis

    $stmt = $sql->modifyColumn($table,$column,$property=>$value);

=head4 Description

Erzeuge SQL-Statement, das in Tabelle $table die Kolumne $column
modifiziert. Verändert wird die Eigenschaft $property auf Wert
$value.

B<NULL>

=over 4

=item PostgreSQL:

    ALTER TABLE t ALTER COLUMN c DROP NOT NULL

=item Oracle:

    ALTER TABLE t MODIFY c NULL

=item MySQL:

    NOT NULL scheint nicht ohne Kenntnis des Kolumnentyps
    manipuliert werden zu können (5.1.41).

=item SQLite:

    Eine Kolumne kann nicht modifiziert werden (geprüft 3.6.22)

=back

B<NOT NULL>

=over 4

=item PostgreSQL:

    ALTER TABLE t ALTER COLUMN c SET NOT NULL

=item Oracle:

    ALTER TABLE t MODIFY COLUMN c NULL

=item MySQL:

    NOT NULL scheint nicht ohne Kenntnis des Kolumnentyps
    manipuliert werden zu können (5.1.41).

=item SQLite:

    Eine Kolumne kann nicht modifiziert werden (geprüft 3.6.22)

=back

B<TYPE>

=over 4

=item PostgreSQL:

    nicht implementiert

=item Oracle:

    ALTER TABLE <t> MODIFY COLUMN <c> <type>

=item MySQL:

    nicht implementiert

=item SQLite:

    Eine Kolumne kann nicht modifiziert werden (geprüft 3.6.22)

=back

=cut

# -----------------------------------------------------------------------------

sub modifyColumn {
    my ($self,$table,$column,$property,$value) = @_;

    my ($oracle,$postgresql,$sqlite,$mysql) = $self->dbmsTestVector;

    # Statement generieren

    my $stmt;
    if ($property eq 'notNull') {
        if ($value) { # NOT NULL
            if ($postgresql) {
                $stmt = "ALTER TABLE $table ALTER COLUMN $column SET NOT NULL";
            }
            elsif ($oracle) {
                $stmt = "ALTER TABLE $table MODIFY $column NOT NULL";
            }
            elsif ($sqlite || $mysql) {
                $self->throw('Not implemented');
            }
        }
        else { # NULL
            if ($postgresql) {
                $stmt = "ALTER TABLE $table ALTER COLUMN $column".
                    ' DROP NOT NULL';
            }
            elsif ($oracle) {
                $stmt = "ALTER TABLE $table MODIFY $column NULL";
            }
            elsif ($sqlite || $mysql) {
                $self->throw('Not implemented');
            }
        }
    }
    elsif ($property eq 'type') {
        my $type = $self->dataType($value);

        if ($postgresql) {
            $stmt = "ALTER TABLE $table ALTER COLUMN $column TYPE $type";
        }
        elsif ($oracle) {
            $stmt = "ALTER TABLE $table MODIFY $column $type";
        }
        elsif ($sqlite || $mysql) {
            $self->throw('Not implemented');
        }
    }
    else {
        $self->throw('Not implemented');
    }

    return $stmt;
}

# -----------------------------------------------------------------------------

=head3 renameColumn() - Generiere ALTER TABLE Statement, das eine Kolumne umbenennt

=head4 Synopsis

    $stmt = $sql->renameColumn($table,$oldName,$newName)

=head4 Description

Erzeuge SQL-Statement, das in Tabelle $table die Kolumne $oldName
in $newName umbenennt.

B<Syntax>

=over 4

=item PostgreSQL:

    ALTER TABLE t RENAME COLUMN c1 TO c2

=item Oracle:

    ALTER TABLE t RENAME COLUMN c1 TO c2

=item MySQL:

    nicht implementiert

=item SQLite:

    nicht implementiert

=back

=cut

# -----------------------------------------------------------------------------

sub renameColumn {
    my ($self,$table,$oldName,$newName) = @_;

    my ($oracle,$postgresql,$sqlite,$mysql) = $self->dbmsTestVector;

    # Statement generieren

    my $stmt;
    if ($postgresql || $oracle) {
        $stmt = "ALTER TABLE $table RENAME COLUMN $oldName TO $newName";
    }
    elsif ($sqlite || $mysql) {
        $self->throw('Not implemented');
    }

    return $stmt;
}

# -----------------------------------------------------------------------------

=head2 Constraints

=head3 addPrimaryKeyConstraint() - Generiere PRIMARY KEY Constraint Statement

=head4 Synopsis

    $stmt = $sql->addPrimaryKeyConstraint($tableName,\@colNames,@opt);

=head4 Options

=over 4

=item -constraintName => $str (Default: <TABLE>_PK)

Name des Constraint.

=item -exceptionTable => $tableName (Default: keiner)

Constraint-Verletzende Datensätze werden in Tabelle $tableName
protokollliert (nur Oracle).

=item -tableSpace => $tableSpaceName (Default: keiner)

Name des Tablespace, in dem der Index erzeugt wird
(Oracle und PostgreSQL).

=back

=head4 Description

B<Oracle Syntax>

    ALTER TABLE <TABLE_NAME> ADD
        CONSTRAINT <CONSTRAINT_NAME>
        PRIMARY KEY (<TABLE_COLUMNS>)
        USING INDEX TABLESPACE <TABLESPACE_NAME>
        EXCEPTIONS INTO <EXCEPTION_TABLE_NAME>

B<PostgreSQL Syntax>

    ALTER TABLE <TABLE_NAME> ADD
        CONSTRAINT <CONSTRAINT_NAME>
        PRIMARY KEY (<TABLE_COLUMNS>)
        USING INDEX TABLESPACE <TABLESPACE_NAME>

=cut

# -----------------------------------------------------------------------------

sub splitObjectName {
    my $this = shift;
    my $objectName = shift;
    return reverse split /\./,$objectName;
}

sub addPrimaryKeyConstraint {
    my $self = shift;
    my $tableName = shift;
    my $colNameA = shift;

    # Optionen

    my $constraintName = undef;
    my $exceptionTable = undef;
    my $tableSpace = undef;

    if (@_) {
        Quiq::Option->extract(\@_,
             -constraintName => \$constraintName,
             -exceptionTable => \$exceptionTable,
             -tableSpace => \$tableSpace,
        );
    }

    if (!$constraintName) {
        my ($table) = $self->splitObjectName($tableName);
        $constraintName = $table.'_PK';
        $self->checkName(\$constraintName);
    }

    # Statement generieren

    my ($oracle,$postgresql,$sqlite,$mysql) = $self->dbmsTestVector;

    my $stmt;
    if ($oracle || $postgresql) {
        $stmt = sprintf "ALTER TABLE %s ADD\n".
            "    CONSTRAINT %s\n".
            "    PRIMARY KEY (%s)",
            $tableName,$constraintName,join(', ',@$colNameA);

        if ($tableSpace) {
            $stmt .= "\n    USING INDEX TABLESPACE $tableSpace";
        }

        if ($oracle && $exceptionTable) {
            $stmt .= "\n    EXCEPTIONS INTO $exceptionTable";
        }
    }
    else {
        die;
    }

    return $stmt;
}

# -----------------------------------------------------------------------------

=head3 addForeignKeyConstraint() - Generiere FOREIGN KEY Constraint Statement

=head4 Synopsis

    $stmt = $sql->addForeignKeyConstraint($tableName,\@tableCols,
        $refTableName,@opt);

=head4 Options

=over 4

=item -constraintName => $str (Default: <TABLE>_FK_<REFTABLE>)

Name des Constraint.

=item -defer => $bool (Default: 0)

Constraint-Fehler wird verzögert gemeldet.

=item -disable => $bool (Default: 0)

Constraint wird erzeugt, ist aber abgeschaltet.

=item -exceptionTable => $tableName (Default: keiner)

Constraint-Verletzende Datensätze werden in Tabelle $tableName
protokollliert (nur Oracle).

=item -onDelete => 'cascade'|'null' (Default: keiner)

Legt fest, was bei Löschung des Parent-Datensatzes passieren soll.

=item -refTableCols => \@refTableCols (Default: undef)

Liste der Kolumnen in der referenzierten Tabelle.
Bei MySQL müssen die referenzierten Kolumnen aufgezählt werden, auch wenn
ein Primary Key auf der referenzierten Tabelle definiert ist.

=back

=head4 Description

B<Oracle Syntax>

    ALTER TABLE <TABLE_NAME> ADD
        CONSTRAINT <CONSTRAINT_NAME>
        FOREIGN KEY (<TABLE_COLUMNS>)
        REFERENCES <REF_TABLE_NAME>
        ON DELETE <ACTION>
        DEFERRABLE INITIALLY DEFERRED
        EXCEPTIONS INTO <EXCEPTION_TABLE_NAME>
        DISABLE

B<PostgreSQL Syntax>

    ALTER TABLE <TABLE_NAME> ADD
        CONSTRAINT <CONSTRAINT_NAME>
        FOREIGN KEY (<TABLE_COLUMNS>)
        REFERENCES <REF_TABLE_NAME>
        ON DELETE <ACTION>
        DEFERRABLE INITIALLY DEFERRED

B<MySQL Syntax>

    ALTER TABLE <TABLE_NAME> ADD
        CONSTRAINT <CONSTRAINT_NAME>
        FOREIGN KEY (<TABLE_COLUMNS>)
        REFERENCES <REF_TABLE_NAME> (REF_TABLE_COLUMNS)
        ON DELETE <ACTION>

=cut

# -----------------------------------------------------------------------------

sub addForeignKeyConstraint {
    my $self = shift;
    my $fromName = shift;
    my $cols = shift;
    my $toName = shift;

    # Optionen

    my $constraintName = undef;
    my $defer = 0;
    my $disable = 0;
    my $exceptionTable = undef;
    my $onDelete = undef;
    my $refTableColumns = undef;

    if (@_) {
        Quiq::Option->extract(\@_,
            -constraintName => \$constraintName,
            -defer => \$defer,
            -disable => \$disable,
            -exceptionTable => \$exceptionTable,
            -onDelete => \$onDelete,
            -refTableColumns => \$refTableColumns,
        );
    }

    if (!$constraintName) {
        my ($fromTable) = $self->splitObjectName($fromName);
        my ($toTable) = $self->splitObjectName($toName);
        $constraintName = $fromTable.'_FK_'.$toTable;
        $self->checkName(\$constraintName);
    }

    # Statement generieren

    my ($oracle,$postgresql,$sqlite,$mysql) = $self->dbmsTestVector;

    my $stmt;
    if ($postgresql || $oracle || $mysql) {
        # ALTER TABLE

        $stmt = sprintf "ALTER TABLE %s ADD\n".
            "    CONSTRAINT %s\n".
            "    FOREIGN KEY (%s)\n".
            "    REFERENCES %s",
            $fromName,
            $constraintName,
            join(', ',@$cols),
            $toName;

        if ($refTableColumns) {
            my $str = '';
            for (@$refTableColumns) {
                if ($str) {
                    $str .= ', ';
                }
                $str .= $_;
            }
            if ($str) {
                $stmt .= " ($str)";
            }
        }

        # ON DELETE

        if ($onDelete) {
            $stmt .= "\n    ON DELETE ";
            if ($onDelete eq 'cascade') {
                $stmt .= 'CASCADE';
            }
            elsif ($onDelete eq 'null') {
                $stmt .= 'SET NULL';
            }
            else {
                $self->throw;
            }
        }

        # DEFERRABLE

        if ($defer) {
            $stmt .= "\n    DEFERRABLE INITIALLY DEFERRED";
        }

        if ($oracle) {
            if ($exceptionTable) {
                $stmt .= "\n    EXCEPTIONS INTO $exceptionTable";
            }
            if ($disable) {
                $stmt .= "\n    DISABLE";
            }
        }
    }
    else {
        $self->throw;
    }

    return $stmt;
}

# -----------------------------------------------------------------------------

=head3 addNotNullConstraint() - Generiere NOT NULL Constraint Statement

=head4 Synopsis

    $stmt = $sql->addNotNullConstraint($tableName,$colName,@opt);

=head4 Options

=over 4

=item -constraintName => $str (Default: <TABLE>_CK)

Name des Constraint (nicht PostgreSQL).

=item -exceptionTable => $tableName (Default: keiner)

Constraint-Verletzende Datensätze werden in Tabelle $tableName
protokollliert (nur Oracle).

=back

=head4 Description

B<Oracle Syntax>

    ALTER TABLE <TABLE_NAME> MODIFY (
        <COLUMN NAME>
        CONSTRAINT <CONSTRAINT_NAME>
        NOT NULL
        EXCEPTIONS INTO <EXCEPTION_TABLE_NAME>
    )

B<PostgreSQL Syntax>

    ALTER TABLE <TABLE_NAME>
        ALTER COLUMN <COLUMN_NAME>
        SET NOT NULL

=cut

# -----------------------------------------------------------------------------

sub addNotNullConstraint {
    my $self = shift;
    my $tableName = shift;
    my $columnName = shift;

    # Optionen

    my $constraintName = undef;
    my $exceptionTable = undef;

    if (@_) {
        Quiq::Option->extract(\@_,
             -constraintName => \$constraintName,
             -exceptionTable => \$exceptionTable,
        );
    }

    if (!$constraintName) {
        my ($table) = $self->splitObjectName($tableName);
        $constraintName = $table.'_NN_'.$columnName;
        $self->checkName(\$constraintName);
    }

    my ($oracle,$postgresql,$sqlite,$mysql) = $self->dbmsTestVector;

    # Statement generieren

    my $stmt;
    if ($postgresql) {
        $stmt = "ALTER TABLE $tableName\n".
            "    ALTER COLUMN $columnName\n".
            "    SET NOT NULL";
    }
    elsif ($oracle) {
        $stmt = "ALTER TABLE $tableName\n".
            "    MODIFY $columnName\n".
            "    CONSTRAINT $constraintName\n".
            "    NOT NULL";

        if ($exceptionTable) {
            $stmt .= "\n    EXCEPTIONS INTO $exceptionTable";
        }
    }
    else {
        die;
    }

    return $stmt;
}

# -----------------------------------------------------------------------------

=head3 addCheckConstraint() - Generiere CHECK Constraint Statement

=head4 Synopsis

    $stmt = $sql->addCheckConstraint($tableName,$clause,@opt);

=head4 Options

=over 4

=item -constraintName => $str (Default: <TABLE>_CK)

Name des Constraint.

=item -exceptionTable => $tableName (Default: keiner)

Constraint-Verletzende Datensätze werden in Tabelle $tableName
protokollliert (nur Oracle).

=back

=head4 Description

B<Oracle Syntax>

    ALTER TABLE <TABLE_NAME> ADD
        CONSTRAINT <CONSTRAINT_NAME>
        CHECK (<CHECK_CLAUSE>)
        EXCEPTIONS INTO <EXCEPTION_TABLE_NAME>

B<PostgreSQL Syntax>

    ALTER TABLE <TABLE_NAME> ADD
        CONSTRAINT <CONSTRAINT_NAME>
        CHECK (<CHECK_CLAUSE>)

=cut

# -----------------------------------------------------------------------------

sub addCheckConstraint {
    my $self = shift;
    my $tableName = shift;
    my $clause = shift;

    # Optionen

    my $constraintName = undef;
    my $exceptionTable = undef;

    if (@_) {
        Quiq::Option->extract(\@_,
             -constraintName => \$constraintName,
             -exceptionTable => \$exceptionTable,
        );
    }

    if (!$constraintName) {
        # ACHTUNG: generierter Name bei mehreren Check-Constraints
        # nicht eindeutig
        my ($table) = $self->splitObjectName($tableName);
        $constraintName = "${table}_CK";
        $self->checkName(\$constraintName);
    }

    my ($oracle,$postgresql,$sqlite,$mysql) = $self->dbmsTestVector;

    # Statement generieren

    my $stmt;
    if ($oracle || $postgresql) {
        $stmt = sprintf "ALTER TABLE %s ADD\n".
            "    CONSTRAINT %s\n".
            "    CHECK (%s)",
            $tableName,
            $constraintName,
            $clause;

        if ($oracle && $exceptionTable) {
            $stmt .= "\n    EXCEPTIONS INTO $exceptionTable";
        }
    }
    else {
        die;
    }

    return $stmt;
}

# -----------------------------------------------------------------------------

=head3 addUniqueConstraint() - Generiere UNIQUE Constraint Statement

=head4 Synopsis

    $stmt = $sql->addUniqueConstraint($tableName,\@colNames,@opt);

=head4 Options

=over 4

=item -constraintName => $str (Default: <TABLE>_UQ_<COLUMNS>)

Name des Constraint.

=item -exceptionTable => $tableName (Default: keiner)

Constraint-Verletzende Datensätze werden in Tabelle $tableName
protokollliert (nur Oracle).

=item -tableSpace => $tableSpaceName (Default: keiner)

Name des Tablespace, in dem der Index erzeugt wird
(Oracle und PostgreSQL).

=back

=head4 Description

Liefere ein SQL-Statement zur Erzeugung eines UNIQUE-Constraint
auf Tabelle $tableName über den Kolumnen @colNames und liefere
dieses zurück.

B<Oracle Syntax>

    ALTER TABLE <TABLE_NAME> ADD
        CONSTRAINT <CONSTRAINT_NAME>
        UNIQUE (<TABLE_COLUMNS>)
        USING INDEX TABLESPACE <TABLESPACE_NAME>
        EXCEPTIONS INTO <EXCEPTION_TABLE_NAME>

B<PostgreSQL Syntax>

    ALTER TABLE <TABLE_NAME> ADD
        CONSTRAINT <CONSTRAINT_NAME>
        UNIQUE (<TABLE_COLUMNS>)
        USING INDEX TABLESPACE <TABLESPACE_NAME>

=cut

# -----------------------------------------------------------------------------

sub addUniqueConstraint {
    my $self = shift;
    my $tableName = shift;
    my $colNameA = shift;

    # Optionen

    my $constraintName = undef;
    my $exceptionTable = undef;
    my $tableSpace = undef;

    if (@_) {
        Quiq::Option->extract(\@_,
             -constraintName => \$constraintName,
             -exceptionTable => \$exceptionTable,
             -tableSpace => \$tableSpace,
        );
    }

    if (!$constraintName) {
        my ($table) = $self->splitObjectName($tableName);
        $constraintName = $table.'_UQ_'.join('_',@$colNameA);
        $self->checkName(\$constraintName);
    }

    # Statement generieren

    my ($oracle,$postgresql,$sqlite,$mysql) = $self->dbmsTestVector;

    my $stmt;
    if ($oracle || $postgresql) {
        $stmt = sprintf "ALTER TABLE %s ADD\n".
            "    CONSTRAINT %s\n".
            "    UNIQUE (%s)",
            $tableName,$constraintName,join(', ',@$colNameA);

        if ($tableSpace) {
            $stmt .= "\n    USING INDEX TABLESPACE $tableSpace";
        }

        if ($oracle && $exceptionTable) {
            $stmt .= "\n    EXCEPTIONS INTO $exceptionTable";
        }
    }
    else {
        die;
    }

    return $stmt;
}

# -----------------------------------------------------------------------------

=head2 Index

=head3 indexName() - Liefere Namen für Index

=head4 Synopsis

    $indexName = $sql->indexName($table,\@colNames);

=cut

# -----------------------------------------------------------------------------

sub indexName {
    my $self = shift;
    my $tableName = shift;
    my $colNameA = shift;

    my ($table) = $self->splitObjectName($tableName);
    my $indexName = lc $table.'_ix_'.join('_',@$colNameA);
    $self->checkName(\$indexName);

    return $indexName;
}

# -----------------------------------------------------------------------------

=head3 createIndex() - Generiere CREATE INDEX Statement

=head4 Synopsis

    $stmt = $sql->createIndex($tableName,\@colNames,@opt);

=head4 Options

=over 4

=item -indexName => $str (Default: <TABLE>_ix_<COLUMNS>)

Name des Index.

=item -tableSpace => $tableSpaceName (Default: keiner)

Name des Tablespace, in dem der Index erzeugt wird
(Oracle und PostgreSQL).

=item -unique => $bool (Default: 0)

Statement für Unique Index.

=back

=head4 Description

Generiere ein CREATE INDEX Statement und liefere dieses zurück.

B<Oracle Syntax>

    CREATE [UNIQUE] INDEX <INDEX_NAME> ON <TABLE_NAME>
        (<TABLE_COLUMNS>)
        TABLESPACE <TABLESPACE_NAME>

B<PostgreSQL Syntax>

    CREATE [UNIQUE] INDEX <INDEX_NAME> ON <TABLE_NAME>
        (<TABLE_COLUMNS>)
        TABLESPACE <TABLESPACE_NAME>

B<SQLite Syntax>

    CREATE [UNIQUE] INDEX <INDEX_NAME> ON <TABLE_NAME>
        (<TABLE_COLUMNS>)

B<MySQL Syntax>

    CREATE [UNIQUE] INDEX <INDEX_NAME> ON <TABLE_NAME>
        (<TABLE_COLUMNS>)

=cut

# -----------------------------------------------------------------------------

sub createIndex {
    my $self = shift;
    my $tableName = shift;
    my $colNameA = shift;

    # Optionen

    my $indexName = undef;
    my $tableSpace = undef;
    my $unique = 0;

    if (@_) {
        Quiq::Option->extract(\@_,
             -indexName => \$indexName,
             -tableSpace => \$tableSpace,
             -unique => \$unique,
        );
    }

    # FIXME: Methode indexName() implementieren

    if (!$indexName) {
        #my ($table) = $self->splitObjectName($tableName);
        #$indexName = $table.'_ix_'.join('_',@$colNameA);
        $indexName = $self->indexName($tableName,$colNameA);
    }
    else {
        $self->checkName(\$indexName);
    }

    # Statement generieren

    my ($oracle,$postgresql,$sqlite,$mysql) = $self->dbmsTestVector;

    my $stmt;
    if ($oracle || $postgresql || $sqlite || $mysql) {
        $stmt = sprintf "CREATE%s INDEX %s\n".
            "    ON %s\n".
            "    (%s)",
            $unique? ' UNIQUE': '',
            $indexName,
            $tableName,
            join(', ',@$colNameA);

        if ($tableSpace && !$mysql && !$sqlite) {
            $stmt .= "\n    TABLESPACE $tableSpace";
        }

    }
    else {
        $self->throw('Not implemented');
    }

    return $stmt;
}

# -----------------------------------------------------------------------------

=head3 dropIndex() - Generiere DROP INDEX Statement

=head4 Synopsis

    $stmt = $sql->dropIndex($tableName,\@colNames);

=head4 Description

Generiere ein DROP INDEX Statement und liefere dieses zurück.

B<Syntax>

    DROP INDEX <INDEX_NAME>

=cut

# -----------------------------------------------------------------------------

sub dropIndex {
    my $self = shift;
    my $tableName = shift;
    my $colNameA = shift;

    #!! FIXME: Methode indexName() implementieren
    #
    #my ($table) = $self->splitObjectName($tableName);
    #my $indexName = $table.'_ix_'.join('_',@$colNameA);
    #$self->checkName(\$indexName);

    my $indexName = $self->indexName($tableName,$colNameA);
    return "DROP INDEX $indexName";
}

# -----------------------------------------------------------------------------

=head2 Sequence

=head3 createSequence() - Generiere SQL-Statements zur Erzeugung einer Sequenz

=head4 Synopsis

    @stmt = $sql->createSequence($name,@opt);

=head4 Options

=over 4

=item -startWith => $n (Default: 1)

Lasse die Sequenz mit Startwert $n beginnen.

=back

=head4 Description

Generiere Statements zur Erzeugung von Sequenz $name und liefere
diese zurück.

Unter Oracle und PostgreSQL, die das Konzept der Sequenz haben,
wird ein CREATE SEQUENCE Statement generiert.

Unter MySQL und SQLite, die das Konzept der Sequenz nicht haben,
wird eine Tabelle (CREATE TABLE) mit Autoinkrement-Kolumne zur
Simulation einer Sequenz erzeugt. Ist die Option -startWith angegeben,
wird zusätzlich ein INSERT-Statement generiert.

=cut

# -----------------------------------------------------------------------------

sub createSequence {
    my $self = shift;
    my $name = shift;

    # Optionen

    my $startWith = 1;
    if (@_) {
        Quiq::Option->extract(\@_,
             -startWith => \$startWith,
        );
    }

    # FIXME: Test $startWith auf >= 1

    # Statement(s) generieren

    my @stmt;
    my ($oracle,$postgresql,$sqlite,$mysql) = $self->dbmsTestVector;
    if ($oracle || $postgresql) {
        push @stmt,"CREATE SEQUENCE $name START WITH $startWith";
    }
    elsif ($mysql || $sqlite) {
        push @stmt,$self->createTable($name,
            ['n',type=>'INTEGER(10)',notNull=>1,primaryKey=>1,
                autoIncrement=>1],
        );
        if ($startWith != 1) {
            push @stmt,$self->insert($name,n=>$startWith-1);
        }
    }

    return @stmt;
}

# -----------------------------------------------------------------------------

=head3 dropSequence() - Generiere SQL-Statement zum Löschen einer Sequenz

=head4 Synopsis

    $stmt = $sql->dropSequence($name);

=head4 Description

Generiere SQL-Statement zum Löschen von Sequenz $name und liefere
dieses zurück.

Unter Oracle und PostgreSQL, die das Konzept der Sequenz haben,
wird ein DROP SEQUENCE Statement generiert.

Unter MySQL und SQLite, die das Konzept der Sequenz nicht haben,
wird ein DROP TABLE Statement generiert.

=cut

# -----------------------------------------------------------------------------

sub dropSequence {
    my ($self,$name) = @_;

    my ($oracle,$postgresql,$sqlite,$mysql) = $self->dbmsTestVector;

    # Statement generieren

    if ($mysql || $sqlite) {
        return $self->dropTable($name);
    }

    return "DROP SEQUENCE $name";
}

# -----------------------------------------------------------------------------

=head3 setSequence() - Generiere SQL-Statements zum Setzen einer Sequenz

=head4 Synopsis

    @stmt = $sql->setSequence($name,$n);

=head4 Description

Generiere SQL-Statements zum Setzen von Sequenz $name auf Wert $n.

=over 2

=item *

Unter Oracle wird die Sequenz gedroppt und neu erzeugt.

=item *

Unter PostgreSQL wird der Wert mit ALTER SEQUENCE gesetzt.

=item *

Unter MySQL und SQLite, die das Konzept der Sequenz nicht haben,
wird die Sequenz-Tabelle geleert und der Wert als neuer
Datensatz hinzugefügt. Einschränkung: Der Sequenzwert kann
hochgesetzt, aber nicht verringert werden!

=back

=cut

# -----------------------------------------------------------------------------

sub setSequence {
    my ($self,$sequence,$n) = @_;

    my ($oracle,$postgresql,$sqlite,$mysql) = $self->dbmsTestVector;

    # Statements generieren

    my @stmt;
    if ($oracle) {
        push @stmt,"DROP SEQUENCE $sequence";
        push @stmt,"CREATE SEQUENCE $sequence START WITH $n";
    }
    elsif ($postgresql) {
        push @stmt,"ALTER SEQUENCE $sequence RESTART WITH $n";
    }
    elsif ($mysql || $sqlite) {
        push @stmt,"DELETE FROM $sequence";
        push @stmt,sprintf "INSERT INTO $sequence VALUES (%d)",$n-1;
    }
    else {
        die; # FIXME
    }

    return @stmt;
}

# -----------------------------------------------------------------------------

=head2 Trigger

=head3 createFunction() - Generiere Statement zum Erzeugen einer Funktion

=head4 Synopsis

    $stmt = $sql->createFunction($name,$body,@opt);

=head4 Options

=over 4

=item -replace => $bool (Default: 0)

Generiere "OR REPLACE" Klausel.

=item -returns => $type (Default: undef)

Generiere "RETURNS $type" Klausel.

=back

=head4 Description

B<PostgreSQL>

    CREATE OR REPLACE FUNCTION <name>()
    RETURNS <returns>
    AS $SQL$
      <body>
    $SQL$ LANGUAGE plpgsql

=over 2

=item *

<name> kann Schema enthalten

=back

=cut

# -----------------------------------------------------------------------------

sub createFunction {
    my $self = shift;
    # @_: $name,$body,@opt

    # Argumente

    my $replace = 0;
    my $returns = undef;

    Quiq::Option->extract(\@_,
        -replace => \$replace,
        -returns => \$returns,
    );
    my $name = shift;
    my $body = Quiq::String->removeIndentation(shift);

    my ($oracle,$postgresql,$sqlite,$mysql) = $self->dbmsTestVector;

    my $stmt;
    if ($postgresql) {
        $stmt = 'CREATE';
        if ($replace) {
            $stmt .= ' OR REPLACE';
        }
        $stmt .= " FUNCTION $name()";
        if ($returns) {
            $stmt .= "\nRETURNS $returns";
        }
        $stmt .= "\nAS \$SQL\$";
        $stmt .= "\n$body";
        $stmt .= "\n\$SQL\$ LANGUAGE plpgsql";
    }
    else {
        $self->throw('Not implemented');
    }

    return $stmt;
}

# -----------------------------------------------------------------------------

=head3 dropFunction() - Generiere Statement zum Entfernen einer Funktion

=head4 Synopsis

    $stmt = $sql->dropFunction($name);

=head4 Description

B<PostgreSQL>

    DROP FUNCTION <name>() CASCADE

=cut

# -----------------------------------------------------------------------------

sub dropFunction {
    my $self = shift;
    # @_: $name,@opt

    # Argumente

    my $cascade = 0;

    Quiq::Option->extract(\@_,
        -cascade => \$cascade,
    );
    my $name = shift;

    my ($oracle,$postgresql,$sqlite,$mysql) = $self->dbmsTestVector;

    if ($postgresql) {
        my $stmt = "DROP FUNCTION $name()";
        if ($cascade) {
            $stmt .= ' CASCADE';
        }
        return $stmt;
    }

    $self->throw('Not implemented');
}

# -----------------------------------------------------------------------------

=head3 createTrigger() - Generiere Statement zum Erzeugen eines Triggers

=head4 Synopsis

    $stmt = $sql->createTrigger($table,$name,$when,$event,$level,
        $body,@opt);
    $stmt = $sql->createTrigger($table,$name,$when,$event,$level,
        -execute => $proc,@opt);

=head4 Options

=over 4

=item -replace => $bool (Default: 0)

Generiere "OR REPLACE" Klausel (Oracle).

=item -execute => $proc (Default: undef)

Generiere "EXECUTE PROCEDURE $proc()" Klausel.

=back

=head4 Description

B<Oracle>

    $stmt = $sql->createTrigger(
        '<table>',
        '<name>',
        'before',
        'insert|update',
        'row',
        -replace => 1,'
        <body>
        '
    );
    
    CREATE OR REPLACE TRIGGER <name>
    BEFORE INSERT OR UPDATE ON <table>
    FOR EACH ROW
    <body>

=over 2

=item *

Oracle-Trigger können eine Prozedur können einen
Trigger-Body definieren.

=back

B<PostgreSQL>

    $stmt = $sql->createTrigger(
        '<table>',
        '<name>',
        'before',
        'insert|update',
        'row',
        -execute => '<proc>',
    );
    
    CREATE TRIGGER <name>
    BEFORE INSERT OR UPDATE ON <table>
    FOR EACH ROW
    EXECUTE PROCEDURE <proc>()

=over 2

=item *

Trigger können eine Prozedur aufrufen (-execute=>$proc) aber keinen
Trigger-Body definieren.

=item *

Keine Klausel "OR REPLACE" bei Triggern (-replace=>1 wird ignoriert)

=back

=cut

# -----------------------------------------------------------------------------

sub createTrigger {
    my $self = shift;
    my $table = shift;
    my $trigger = shift;
    my $when = shift;
    my $event = shift;
    my $level = shift;
    # @_: @opt

    # Optionen

    my $execute = undef;
    my $replace = 0;

    Quiq::Option->extract(\@_,
        -execute => \$execute,
        -replace => \$replace,
    );
    my $body = Quiq::String->removeIndentation(shift);

    my ($oracle,$postgresql,$sqlite,$mysql) = $self->dbmsTestVector;

    my $stmt;
    if ($oracle || $postgresql) {
        $stmt = 'CREATE';
        if ($replace && !$postgresql) { # PostgreSQL kennt REPLACE nicht
            $stmt .= ' OR REPLACE';
        }
        $stmt .= " TRIGGER $trigger";
        $stmt .= "\n".uc($when);
        $stmt .= ' '.join(' OR ',map {uc} split /\|/,$event)." ON $table";
        $stmt .= "\nFOR EACH ".uc($level);
        if ($body && !$postgresql) { # PostgreSQL kennt keinen Trigger-Body
            $stmt .= "\n$body";
        }
        if ($execute) {
            $stmt .= "\nEXECUTE PROCEDURE $execute()";
        }
    }
    else {
        $self->throw('Not implemented');
    }

    return $stmt;
}

# -----------------------------------------------------------------------------

=head3 dropTrigger() - Generiere Statement zum Entfernen eines Triggers

=head4 Synopsis

    $stmt = $sql->dropTrigger($name);

=head4 Description

B<Oracle>

    DROP TRIGGER <name>

=cut

# -----------------------------------------------------------------------------

sub dropTrigger {
    my ($self,$name) = @_;

    my ($oracle,$postgresql,$sqlite,$mysql) = $self->dbmsTestVector;

    if ($oracle) {
        return "DROP TRIGGER $name";
    }

    $self->throw('Not implemented');
}

# -----------------------------------------------------------------------------

=head3 enableTrigger() - Generiere Statement zum Anschalten eines Triggers

=head4 Synopsis

    $stmt = $sql->enableTrigger($table,$tigger);

=head4 Description

B<PostgreSQL>

    ALTER TABLE <table> ENABLE TRIGGER <trigger>

=cut

# -----------------------------------------------------------------------------

sub enableTrigger {
    my ($self,$table,$trigger) = @_;

    my ($oracle,$postgresql,$sqlite,$mysql) = $self->dbmsTestVector;

    my $stmt;
    if ($postgresql) {
        return "ALTER TABLE $table ENABLE TRIGGER $trigger";
    }
    else {
        $self->throw('Not implemented');
    }

    return $stmt;
}

# -----------------------------------------------------------------------------

=head3 disableTrigger() - Generiere Statement zum Abschalten eines Triggers

=head4 Synopsis

    $stmt = $sql->disableTrigger($table,$tigger);

=head4 Description

B<PostgreSQL>

    ALTER TABLE <table> DISABLE TRIGGER <trigger>

=cut

# -----------------------------------------------------------------------------

sub disableTrigger {
    my ($self,$table,$trigger) = @_;

    my ($oracle,$postgresql,$sqlite,$mysql) = $self->dbmsTestVector;

    my $stmt;
    if ($postgresql) {
        return "ALTER TABLE $table DISABLE TRIGGER $trigger";
    }
    else {
        $self->throw('Not implemented');
    }

    return $stmt;
}

# -----------------------------------------------------------------------------

=head2 View

=head3 createView() - Generiere CREATE VIEW Statement

=head4 Synopsis

    $stmt = $sql->createView($viewName,$selectStmt);

=head4 Description

Generiere ein CREATE VIEW Statement und liefere dieses zurück.

=cut

# -----------------------------------------------------------------------------

sub createView {
    my ($self,$viewName,$selectStmt) = @_;
    return "CREATE VIEW $viewName AS\n$selectStmt";
}

# -----------------------------------------------------------------------------

=head3 dropView() - Generiere DROP VIEW Statement

=head4 Synopsis

    $stmt = $sql->dropView($viewName);

=head4 Description

Generiere ein DROP VIEW Statement und liefere dieses zurück.

=cut

# -----------------------------------------------------------------------------

sub dropView {
    my ($self,$viewName) = @_;
    return "DROP VIEW $viewName";
}

# -----------------------------------------------------------------------------

=head2 Privileges

=head3 grant() - Generiere GRANT Statement

=head4 Synopsis

    $stmt = $sql->grant($objType,$objName,$privs,$roles);

=head4 Description

Generiere ein GRANT-Statement und liefere dieses zurück.

=head4 Example

=over 2

=item *

PostgreSQL GRANT auf Tabelle

    $stmt = $sql->grant('TABLE','tab1','ALL','PUBLIC');

generiert

    GRANT ALL
        ON TABLE tab1
        TO PUBLIC

=back

=cut

# -----------------------------------------------------------------------------

sub grant {
    my $self = shift;
    my $objType = shift;
    my $objName = shift;
    my $privs = shift;
    my $roles = shift;

    # Statement generieren

    my ($oracle,$postgresql,$sqlite,$mysql) = $self->dbmsTestVector;

    my $stmt;
    if ($oracle) {
        $stmt = "GRANT $privs\n".
            "    ON $objName\n".
            "    TO $roles";
    }
    elsif ($postgresql) {
        $stmt = "GRANT $privs\n".
            "    ON $objType $objName\n".
            "    TO $roles";
    }
    else {
        die;
    }

    return $stmt;
}

# -----------------------------------------------------------------------------

=head3 grantUser() - Generiere GRANT Statement für Benutzerrechte

=head4 Synopsis

    $stmt = $sql->grantUser($userName,$privs);

=head4 Example

=over 2

=item *

Oracle GRANT für Benutzer

    $stmt = $sql->grantUser('user1','connect, resource, dba');

generiert

    GRANT connect, resource, dba
        TO user1

=back

=cut

# -----------------------------------------------------------------------------

sub grantUser {
    my $self = shift;
    my $userName = shift;
    my $privs = shift;

    # Statement generieren

    my ($oracle,$postgresql,$sqlite,$mysql) = $self->dbmsTestVector;

    my $stmt;
    if ($oracle) {
        $stmt = "GRANT $privs\n".
            "    TO $userName";
    }
    else {
        die;
    }

    return $stmt;
}

# -----------------------------------------------------------------------------

=head2 Transactions

=head3 begin() - Generiere BEGIN Statement

=head4 Synopsis

    $stmt = $sql->begin;

=cut

# -----------------------------------------------------------------------------

sub begin {
    return 'BEGIN';
}

# -----------------------------------------------------------------------------

=head3 commit() - Generiere COMMIT Statement

=head4 Synopsis

    $stmt = $sql->commit;

=cut

# -----------------------------------------------------------------------------

sub commit {
    return 'COMMIT';
}

# -----------------------------------------------------------------------------

=head3 rollback() - Generiere ROLLBACK Statement

=head4 Synopsis

    $stmt = $sql->rollback;

=cut

# -----------------------------------------------------------------------------

sub rollback {
    return 'ROLLBACK';
}

# -----------------------------------------------------------------------------

=head2 Data Manipulation

=head3 select() - Generiere SELECT Statement

=head4 Synopsis

    $stmt = $sql->select($stmt,@opt);
    $stmt = $sql->select($table,@opt);
    $stmt = $sql->select(@opt);

=head4 Options

=over 4

=item -args, $name => $value, ...

=item -args => "$name=$value,..."

Ersetze im SELECT-Statement den Platzhalter "__$name__" durch $value.
Mehrere Name/Wert-Kombinationen können angegeben werden.

=item -comment => $text (Default: keiner)

Setze Kommentar mit dem ein- oder mehrzeiligen Text $text an den
Anfang des Statement.

=item -select => @selectExpr (Default: '*')

Generiere eine SELECT-Klausel aus den Ausdrücken @selectExpr.  Die
Ausdrücke werden mit Komma separiert. Ist kein Select-Ausdrück
spezifiziert, wird '*' angenommen.

Platzhalter: %SELECT%

=item -distinct => $bool (Default: keiner)

Generiere "SELECT DISTINCT" statement.

Schlüsselwort "DISTINCT" wird in %SELECT%-Platzhalter mit eingsetzt.

=item -hint => $hint (Default: keiner)

Setze im Statement hinter das Schlüsselwort SELECT einen
Hint, d.h. einen Kommentar in der Form /*+ ... */. (nur Oracle)

hint wird in %SELECT%-Platzhalter mit eingsetzt.

=item -from => @fromExpr (Default: keiner)

Generiere eine FROM-Klausel aus den Ausdrücken @fromExpr.
Die Ausdrücke werden mit Komma separiert. Die FROM-Klausel ist
bei Oracle eine Pflichtangabe.

Platzhalter: %FROM%

-from ist die Defaultoption, d.h. ist als erster Parameter keine
Option angegeben, werden die folgenden Parameter als
Tabellennamen interpretiert.

=item -where => @whereExpr (Default: keiner)

Generiere eine WHERE-Klausel aus den Ausdrücken @whereExpr.
Die Ausdrücke werden mit 'AND' separiert.

Platzhalter: %WHERE%

=item -groupBy => @groupExpr (Default: keiner)

Generiere eine GROUP BY-Klausel aus den Ausdrücken @groupExpr.
Die Ausdrücke werden mit Komma separiert.

Platzhalter: %GROUPBY%

=item -having => @havingExpr (Default: keiner)

Generiere eine HAVING-Klausel aus den Ausdrücken @havingExpr.
Die Ausdrücke werden mit Komma separiert.

Platzhalter: %HAVING%

=item -orderBy => @orderExpr (Default: keiner)

Generiere eine ORDER BY-Klausel aus den Ausdrücken @orderExpr.
Die Ausdrücke werden mit Komma separiert.

Platzhalter: %ORDERBY%

=item -limit => $n (Default: keiner)

Generiere eine LIMIT-Klausel.

Platzhalter: %LIMIT%

=item -offset => $n (Default: keiner)

Generiere eine OFFSET-Klausel.

Platzhalter: %OFFSET%

=item -stmt => $stmt (Default: keiner)

Liefere $stmt als Statement. Enthält $stmt Platzhalter,
werden diese durch die entsprechenden Komponenten ersetzt
(noch nicht implementiert).

=back

=head4 Description

Konstruiere ein SELECT-Statement aus den Parametern und liefere
dieses zurück.

Ist das erste Argument keine Option und enthält es Whitespace,
wird es als SQL-Statement interpretiert. Enthält es kein Whitespace, wird
es als Tabellenname interpretiert.

B<Besonderheiten>

=over 2

=item *

Oracle: FROM-Klausel

Bei Oracle ist die FROM-Klausel eine Pflichtangabe, fehlt sie,
wird "FROM dual" generiert.

=item *

Oracle: LIMIT und OFFSET

Oracle unterstützt weder LIMIT noch OFFSET.

Im Falle von Oracle wird keine LIMIT-Klausel generiert, sondern
die WHERE-Klausel um "ROWNUM <= $n" erweitert.

Ist im Falle von Oracle OFFSET angegeben, wird eine Exception
ausgelöst.

=back

B<FROM-Aliase>

Bei PostgreSQL ist ein FROM-Alias zwingend erforderlich, wenn die
FROM-Klausel ein Ausdruck ist statt ein Tabellenname, z.B.

    ... FROM (<SELECT_STMT>) AS x ...

Bei Oracle ist ein Alias in dem Fall nicht erforderlich, kann aber
angegeben werden. Ein FROM-Alias wird bei Oracle aber IL<lt>nicht> mit
"AS" eingeleitet. Das "AS" muss weggelassen werden.

=head4 Example

=over 2

=item *

SELECT ohne Option mit einem Argument

    $stmt = $sql->select('x');
    =>
    SELECT
        *
    FROM
        x

=item *

SELECT ohne Option mit mehreren Argumenten

    $stmt = $sql->select('x',vorname=>'Elli',nachname=>'Pirelli');
    =>
    SELECT
        *
    FROM
        x
    WHERE
        vorname = 'Elli'
        AND nachname = 'Pirelli'

=item *

SELECT mit Statement-Platzhaltern

    $stmt = $sql->select("
        SELECT
            *
        FROM
            x
        WHERE
            vorname = '__VORNAME__'
            AND nachname = '__NACHNAME__'
        ",
        -args =>
             VORNAME => 'Elli',
             NACHNAME => 'Pirelli'
    );
    =>
    SELECT
        *
    FROM
        x
    WHERE
        vorname = 'Elli'
        AND nachname = 'Pirelli'

=item *

SELECT mit Statement-Muster

    my $select = <<'__SQL__';
    SELECT
        %SELECT%
    FROM
        station sta LEFT JOIN parameter par
        ON par_station_id = sta_id
    __SQL__
    
    $stmt = $sql->select(
        -stmt => $select,
        -select => qw/sta_id sta_name par_id par_name/,
        -orderBy => qw/sta_name par_name/,
    );
    =>
    SELECT
        sta_id,
        sta_name,
        par_id,
        par_name
    FROM
        station sta LEFT JOIN parameter par
        ON par_station_id = sta_id
    ORDER BY
        sta_name,
        par_name

=back

=cut

# -----------------------------------------------------------------------------

sub select {
    my $self = shift;
    # @_: @opt

    if (@_ && substr($_[0],0,1) ne '-') {
        # -stmt ist Default-Option für erstes Argument, wenn Whitespace,
        # -from ist Default-Option sonst
        unshift @_,$_[0] =~ /\s/? '-stmt': '-from';
        if (@_ > 2 && substr($_[2],0,1) ne '-') {
            # -where ist Default-Option für die weiteren Argumente
            splice @_,2,0,'-where';
        }
    }

    # Optionen

    my @args;
    my $comment;
    my @select;
    my $distinct;
    my $hint;
    my @from;
    my @where;
    my @groupBy;
    my @having;
    my @orderBy;
    my $limit;
    my $offset;
    my $stmt = '';

    Quiq::Option->extractMulti(\@_,
        -args => \@args,
        -comment => \$comment,
        -select => \@select,
        -distinct => \$distinct,
        -hint => \$hint,
        -from => \@from,
        -where => \@where,
        -groupBy => \@groupBy,
        -having => \@having,
        -orderBy => \@orderBy,
        -limit => \$limit,
        -offset => \$offset,
        -stmt => \$stmt,
    );

    my ($oracle,$postgresql,$sqlite,$mysql,$access,$mssql) =
        $self->dbmsTestVector;

    if (defined $offset && $oracle) {
        die;
    }

    # Statementbestandteile generieren

    # Für alle Statementbestandteile gilt:
    # 1) Sie haben kein Whitespace am Anfang und am Ende
    # 2) Jedes Subelement (Select-Kolumne, Where-Bedingung usw.) steht auf
    #    einer eigenen Zeile
    # 3) ab dem zweiten Subelement sind alle Subelemente um
    #    vier Leerzeichen eingerückt

    # Anfangs-Kommentar ($comment)

    if (defined $comment && length $comment) {
        $comment =~ s/\s+$//;  # Whitespace am Ende entfernen
        $comment =~ s/^/  /mg; # Text einrücken
        $comment = "/*\n$comment\n*/";
    }

    # Select-Klausel ($selectClause)

    if (@select == 1 && (!defined $select[0] || $select[0] eq '')) {
        # Wenn die SELECT-Liste aus einem einzigen leeren Wert
        # besteht, leeren wir sie.
        @select = ();
    }

    my $selectClause;
    if (@select) {
        if ($distinct) {
            $selectClause .= 'DISTINCT';
        }
        if ($hint && $oracle) {
            if ($selectClause) {
                $selectClause .= "\n    ";
            }
            $selectClause .= "/*+ $hint */";
        }
        if ($selectClause) {
            $selectClause .= "\n    ";
        }
        $selectClause .= $self->selectClause(@select);
    }

    # From-Klausel ($fromClause)
    my $fromClause = $self->fromClause(@from);

    # Where-Klausel ($whereClause)

    # Im Falle von $limit u.U. @where erweitern

    if (defined($limit) && $limit ne '') {
        if ($limit == 0) {
            push @where,'1 = 0';
            $limit = undef; # keine zusätzliche LIMIT-Klausel generieren
        }
        elsif ($oracle) {
            push @where,"ROWNUM <= $limit";
        }
    }

    # MEMO: auch existente WHERE-Klauseln können einen Leerstring ergeben
    my $whereClause = $self->whereClause(@where);

    # GroupBy-Klausel ($groupByClause)
    my $groupByClause = join(",\n    ",@groupBy);

    # Having-Klausel ($havingClause)
    my $havingClause = join(",\n    ",@having);

    # OrderBy-Klausel ($orderByClause)
    my $orderByClause = join(",\n    ",@orderBy);

    # Statement generieren

    # if ($comment) {
    #     $stmt .= "$comment\n";
    # }
    # $selectClause ||= '*';
    # $stmt .= "SELECT\n    $selectClause";
    # if ($fromClause) {
    #     $stmt .= "\nFROM\n    $fromClause";
    # }
    # if ($whereClause) {
    #     $stmt .= "\nWHERE\n    $whereClause";
    # }
    # if ($groupByClause) {
    #     $stmt .= "\nGROUP BY\n    $groupByClause";
    # }
    # if ($havingClause) {
    #     $stmt .= "\nHAVING\n    $havingClause";
    # }
    # if ($orderByClause) {
    #     $stmt .= "\nORDER BY\n    $orderByClause";
    # }
    # unless ($oracle) {
    #     if (defined $limit) {
    #         $stmt .= "\nLIMIT\n    $limit";
    #     }
    #     if (defined $offset) {
    #         $stmt .= "\nOFFSET\n    $offset";
    #     }
    # }

    # Der folgende Code beherrscht die vollständige Generierung
    # und die Ergänzung eines Statement-Musters per -stmt.

    # 1) Wenn Platzhalter (nur bei -stmt), diesen *ersetzen*
    # 2) Wenn Platzhalter nicht vorhanden und Klausel-Schlüsselwort auch
    #    nichgt (bei vollständifer Statement-Generierung und bei -stmt)
    #    Klausel *hinzufügen*
    # 3) Andernfalls (Klausel-Schlüsselwort vorhanden, aber kein Platzhalter),
    #    Exception, da die Klauseloption sonst ohne Wirkung bliebe

    Quiq::String->removeIndentation(\$stmt);
    my ($body) = ref($self)->split($stmt);

    if ($body =~ /%SELECT%/) {
        $selectClause ||= '*';
        $stmt =~ s/%SELECT%/$selectClause/g;
    }
    elsif (!$stmt) {
        $selectClause ||= '*';
        $stmt .= "SELECT\n    $selectClause";
    }
    elsif ($selectClause) {
        $self->throw(
            'SELECT-00001: Kein Platzhalter für SELECT-Kolumnen',
            Stmt => $stmt,
            SelectClause => $selectClause,
        );
    }

    if ($fromClause) {
        if ($body =~ /%FROM%/) {
            $stmt =~ s/%FROM%/$fromClause/g;
        }
        elsif ($body !~ /\bFROM\b/i) {
            $stmt .= "\nFROM\n    $fromClause";
        }
        else {
            $self->throw(
                'SELECT-00002: Kein Platzhalter für FROM-Klausel',
                Stmt => $stmt,
                FromClause => $fromClause,
            );
        }
    }

    if ($body =~ /%WHERE%/) {
        $whereClause ||= '1 = 1';
        $stmt =~ s/%WHERE%/$whereClause/g;
    }
    elsif ($whereClause) {
        if ($body !~ /\bWHERE\b/i) {
            $stmt .= "\nWHERE\n    $whereClause";
        }
        else {
            $self->throw(
                'SELECT-00003: Kein Platzhalter für WHERE-Klausel',
                Stmt => $stmt,
                WhereClause => $whereClause,
            );
        }
    }

    if ($groupByClause) {
        if ($body =~ /%GROUPBY%/) {
            $stmt =~ s/%GROUPBY%/$groupByClause/g;
        }
        elsif ($body !~ /\bGROUP\s+BY\b/i) {
            $stmt .= "\nGROUP BY\n    $groupByClause";
        }
        else {
            $self->throw(
                'SELECT-00003: Kein Platzhalter für GROUP BY-Klausel',
                Stmt => $stmt,
                GroupByClause => $groupByClause,
            );
        }
    }

    if ($havingClause) {
        if ($body =~ /%HAVING%/) {
            $stmt =~ s/%HAVING%/$havingClause/g;
        }
        elsif ($body !~ /\bHAVING\b/i) {
            $stmt .= "\nHAVING\n    $havingClause";
        }
        else {
            $self->throw(
                'SELECT-00003: Kein Platzhalter für HAVING-Klausel',
                Stmt => $stmt,
                HavingClause => $havingClause,
            );
        }
    }

    if ($orderByClause) {
        if ($body =~ /%ORDERBY%/) {
            $stmt =~ s/%ORDERBY%/$orderByClause/g;
        }
        elsif ($body !~ /\bORDER\s+BY\b/i) {
            $stmt .= "\nORDER BY\n    $orderByClause";
        }
        else {
            $self->throw(
                'SELECT-00003: Kein Platzhalter für ORDER BY-Klausel',
                Stmt => $stmt,
                OrderByClause => $orderByClause,
            );
        }
    }
    elsif ($mssql && ($offset || $limit)) {
        # Bei MSSQL sind OFFSET und LIMIT Ergänzungen zu ORDER BY.
        # Wir brauchen also eine ORDER BY Klausel, wenn -offset
        # und/oder -limit angegeben sind
        $stmt .= "\nORDER BY\n    1";
    }

    unless ($oracle) {
        if (defined $offset) {
            if ($body =~ /%OFFSET%/) {
                $stmt =~ s/%OFFSET%/$offset/g;
            }
            elsif ($body !~ /\bOFFSET\b/i) {
                $stmt .= "\nOFFSET\n    $offset";
                if ($mssql) {
                    $stmt .= ' ROWS';
                }
            }
            else {
                $self->throw(
                    'SELECT-00003: Kein Platzhalter für OFFSET',
                    Stmt => $stmt,
                    Offset => $offset,
                );
            }
        }
        if ($limit) {
            if ($body =~ /%LIMIT%/) {
                $stmt =~ s/%LIMIT%/$limit/g;
            }
            elsif ($body !~ /\bLIMIT\b/i) {
                if ($mssql) {
                    if (!$offset) {
                        # Bei MSSQL ist FETCH eine Ergänzug zu OFFSET.
                        # Wir brauchen also eine OFFSET-Klausel, wenn
                        # -limit angegeben ist.
                        $stmt .= "\nOFFSET\n    0 ROWS";
                    }
                    $stmt .= "\nFETCH\n    NEXT $limit ROWS ONLY";
                }
                else {
                    $stmt .= "\nLIMIT\n    $limit";
                }
            }
            else {
                $self->throw(
                    'SELECT-00003: Kein Platzhalter für LIMIT',
                    Stmt => $stmt,
                    Limit => $limit,
                );
            }
        }
    }

    # Anfangs-Kommentar als letztes voranstellen

    if ($comment) {
        # Kommentar dem Statement voranstellen
        $stmt = "$comment\n$stmt";
    }

    # Statement-Argumente einsetzen. Übergabemöglichkeiten:
    # -args => 'NAME=VALUE,..."
    # -args, $name => $value, ...

    if (@args == 1) {
        @args = map {split /\s*=\s*/} split /\s*,\s*/,$args[0];
    }
    for (my $i = 0; $i < @args; $i += 2) {
         $stmt =~ s/__$args[$i]__/$args[$i+1]/g;
    }

    return $stmt;
}

# -----------------------------------------------------------------------------

=head3 insert() - Generiere INSERT-Statement

=head4 Synopsis

    $stmt = $sql->insert($table,$row);
    $stmt = $sql->insert($table,%keyVal);
    $stmt = $sql->insert($table,@keyVal);
    $stmt = $sql->insert($table,\@keys,\@vals);

=head4 Description

Generiere ein INSERT-Statement für Tabelle $table mit den Kolumnen
und Werten %keyVal bzw. @keyVal bzw. @keys,@vals und liefere
dieses zurück.

Schlüssel/Wert-Paare ohne Wert (Leerstring, undef) werden
ausgelassen. Damit ist sichergestellt, dass der Defaultwert der
Kolumne verwendet wird, wenn einer auf der Datenbank deklariert
ist.

Ist der Kolumnenwert eine String-Referenz, wird der Wert ohne
Anführungsstriche in das Statement eingesetzt. Auf diese Weise
können per SQL berechnete Werte (Expressions) eingesetzt werden.

Ist die Liste der Schlüssel/Wert-Paare leer oder sind alle
Werte leer, wird ein Null-Statement (Leerstring) geliefert.

=head4 Example

=over 2

=item *

Normales INSERT, Schlüssel/Wert-Paare

    $stmt = $sql->insert('person',
        per_id => 10,
        per_vorname => 'Hanno',
        per_nachname => 'Seitz',
        per_geburtstag => undef,
    );
    
    =>
    
    INSERT INTO person
    (
        per_id,
        per_vorname,
        per_nachname,
    )
    VALUES
    (
        '10',
        'Hanno',
        'Seitz',
    )

=item *

Normales Insert, Schlüssel und Werte als getrennte Listen

    @keys = qw/per_id per_vorname per_nachname per_geburtstag/;
    @vals = (10,'Hanno','Seitz',undef);
    $stmt = $sql->insert('person',\@keys,\@vals);
    
    =>
    
    INSERT INTO person
    (
        per_id,
        per_vorname,
        per_nachname,
    )
    VALUES
    (
        '10',
        'Hanno',
        'Seitz',
    )

=item *

INSERT mit berechnetem Kolumnenwert

    $stmt = $sql->insert('objekt',
        obj_id => 4711,
        obj_letzteaenderung => \'SYSDATE',
    );
    
    =>
    
    INSERT INTO objekt
    (
        obj_id,
        obj_letzteaenderung
    )
    VALUES
    (
        '4711',
        SYSDATE
    )

=item *

Null-Statements

    $stmt = $sql->insert('person');
    
    =>
    
    ''
    
    $stmt = $sql->insert('person',
        per_id => '',
        per_vorname => '',
        per_nachname => '',
        per_geburtstag => '',
    );
    
    =>
    
    ''

=item *

INSERT mit Platzhaltern

    $stmt = $sql->insert('person',
        per_id => \'?',
        per_vorname => \'?',
        per_nachname => \'?',
        per_geburtstag => \'?',
    );
    
    INSERT INTO person
    (
        per_id,
        per_vorname,
        per_nachname,
        per_geburtstag
    )
    VALUES
    (
        ?,
        ?,
        ?,
        ?
    )

=back

=cut

# -----------------------------------------------------------------------------

sub insert {
    my $self = shift;
    my $table = shift;
    # @_: $row -or- @keyVal -or- \@keys,\@vals

    my ($titles,$values);

    if (ref $_[0]) {
        if (Scalar::Util::blessed($_[0]) &&
                $_[0]->isa('Quiq::Database::Row::Object')) { # $row
            my $row = shift;
            for my $key ($row->titles) {
                my $val = $self->valExpr($row->$key);
                if ($val ne '') {
                    $titles .= "\n    $key,";
                    $values .= "\n    $val,";
                }
            }
        }
        else { # \@keys,\@vals
            my ($keys,$vals) = @_;
            for (my $i = 0; $i < @$keys; $i++) {
                my $val = $self->valExpr($vals->[$i]);
                if ($val ne '') {
                    my $key = $keys->[$i];
                    $titles .= "\n    $key,";
                    $values .= "\n    $val,";
                }
            }
        }
    }
    else { # @keyVal
        while (@_) {
            my $key = shift;
            my $val = $self->valExpr(shift);
            if ($val ne '') {
                $titles .= "\n    $key,";
                $values .= "\n    $val,";
            }
        }
    }

    # Abbruch: Keine Daten
    return '' unless $titles;

    chop $titles;
    chop $values;

    return "INSERT INTO $table ($titles\n)\nVALUES ($values\n)";
}

# -----------------------------------------------------------------------------

=head3 insertMulti() - Generiere INSERT-Statement mit mehreren Zeilen

=head4 Synopsis

    $stmt = $sql->insertMulti($table,\@keys,[
            [@vals1],
            [@vals2],
            ...
        ]
    );

=head4 Description

Generiere ein INSERT-Statement für Tabelle $table mit den Kolumnen
@keys  und den Datensätzen @records. @records ist eine Liste von
Arrays mit gleich vielen Elementen wie @keys.

=head4 Example

    $stmt = $sql->insertMulti('person',
        [qw/per_id per_vorname per_nachname per_geburtstag/],[
            [qw/1 Linus Seitz 2002-11-11/],
            [qw/2 Hanno Seitz 2000-04-07/],
            [qw/3 Emily Philippi 1997-05-05/],
        ]
    );
    =>
    INSERT INTO person
        (per_id, per_vorname, per_nachname, per_geburtstag)
    VALUES
        ('1', 'Linus', 'Seitz', '2002-11-11'),
        ('2', 'Hanno', 'Seitz', '2000-04-07')
        ('3', 'Emily', 'Philippi', '1997-05-05')

=cut

# -----------------------------------------------------------------------------

sub insertMulti {
    my ($self,$table,$keyA,$recA) = @_;

    if (!@$recA) {
        # Keine Daten => kein Statement
        return '';
    }

    my $sql = sprintf Quiq::Unindent->string('
        INSERT INTO %s
            (%s)
        VALUES
    '),$table,join(', ',@$keyA);

    my $i = 0;
    my $fmt = sprintf '    (%s)',join ', ',('%s') x @$keyA;
    for my $rec (@$recA) {
        if ($i++) {
            $sql .= ",\n";
        }
        $sql .= sprintf $fmt,map {$self->valExpr($_)} @$rec;
    }
    $sql .= "\n";    

    return $sql;
}

# -----------------------------------------------------------------------------

=head3 update() - Generiere UPDATE Statement

=head4 Synopsis

    $stmt = $sql->update($table,@keyVal,-where,@where);

=head4 Example

    $stmt = $sql->update('person',
        per_geburtstag => '7.4.2000',
        -where,per_id => 4711,
    );

=cut

# -----------------------------------------------------------------------------

sub update {
    my $self = shift;
    my $table = shift;
    # @_: @keyVal,-where,@where

    my @where;
    Quiq::Option->extractMulti(\@_,
        -where => \@where,
    );

    unless (@_) {
        # Ohne SET-Klausel liefern wir ein leeres Statement
        return '';
    }

    my $stmt = "UPDATE $table SET\n    ";
    $stmt .= $self->setClause(@_);

    # FIXME: Exception, wenn keine WHERE-Klausel?

    if (@where) {
        $stmt .= "\nWHERE\n    ";
        $stmt .= $self->whereClause(@where);
    }

    return $stmt;
}

# -----------------------------------------------------------------------------

=head3 delete() - Generiere DELETE Statement

=head4 Synopsis

    $stmt = $sql->delete($table,@opt,@where);

=head4 Options

=over 4

=item -hint => $hint (Default: undef)

Füge Hint (Oracle) in Statement ein.

=back

=cut

# -----------------------------------------------------------------------------

sub delete {
    my $self = shift;
    my $table = shift;
    # @_: @where

    my $hint;

    Quiq::Option->extractMulti(\@_,
        -hint => \$hint,
    );

    my $stmt = 'DELETE';
    if ($hint) {
        $stmt .= " /*+ $hint */";
    }
    $stmt .= " FROM $table";

    if (@_) {
        $stmt .= "\nWHERE\n    ";
        $stmt .= $self->whereClause(@_);
    }

    return $stmt;
}

# -----------------------------------------------------------------------------

=head2 Operators and Functions

=head3 Vergleichsoperatoren: <EXPR> <OP> <EXPR>

    !=
    <
    <=
    =
    >
    >=
    (NOT) BETWEEN
    (NOT) IN
    (NOT) LIKE

=head3 Aggregatfunktionen: <OP>(<EXPR>)

    Implement.
    ------------
    AVG
    COUNT
    MAX
    MIN
    SUM
                  Oracle       PostgreSQL   SQLite       MySQL
                  ------------ ------------ ------------ ------------
                                            GROUP_CONCAT
                                            TOTAL

=head3 Funktionen: <OP>(<EXPR>,...)

    Implement.    Oracle       PostgreSQL   SQLite       MySQL
    ------------- ------------ ------------ ------------ ------------
                                            ABS
                                            COALESCE
                                            GLOB
                                            IFNULL
                                            HEX
                                            LENGTH
    LOWER         LOWER        LOWER        LOWER
                                            LTRIM
                                            MAX
                                            MIN
                                            NULLIF
                                            QUOTE
                                            RANDOM
                                            RANDOMBLOB
                                            REPLACE
                                            ROUND
                                            RTRIM
    SUBSTR        SUBSTR       SUBSTR       SUBSTR
                                            TRIM
                                            TYPEOF
    UPPER         UPPER        UPPER        UPPER
    CAT           ||                        ||

=head3 opFunc() - Generiere Funktionsaufruf

=head4 Synopsis

    $sqlExpr = $sql->opFunc($op,@args);

=head4 Description

Generiere Funktionsaufruf "<OP>(<EXPR1>, <EXPR2>, ...)" und
liefere diesen zurück.

Diese Methode wird zur Generierung von portablen Funktionsausdrücken
wie UPPER, LOWER, MIN, MAX, SUBSTR, etc. benutzt.

=cut

# -----------------------------------------------------------------------------

sub opFunc {
    my $self = shift;
    my $op = shift;
    # @_: @args

    return sprintf '%s(%s)',$op,join(',',@_);
}

# -----------------------------------------------------------------------------

=head3 opRel() - Generiere rechte Seite eines Vergleichsausdrucks

=head4 Synopsis

    $sqlExpr = $sql->opRel($op,$arg);

=head4 Description

Generiere Ausdruck "<OP> <EXPR>" und liefere diesen zurück.

=cut

# -----------------------------------------------------------------------------

sub opRel {
    my $self = shift;
    my $op = shift;
    my $str = shift;

    return "$op $str";
}

# -----------------------------------------------------------------------------

=head3 opAS() - Generiere AS-Ausdruck (Alias)

=head4 Synopsis

    $sqlExpr = $sql->opAS($op,$arg,$name);

=head4 Description

Generiere Ausdruck "<EXPR> AS <NAME>" und liefere diesen zurück.

=cut

# -----------------------------------------------------------------------------

sub opAS {
    my $self = shift;
    my $op = shift;
    my $arg = shift;
    my $name = shift;

    return "$arg AS $name";
}

# -----------------------------------------------------------------------------

=head3 opBETWEEN() - Generiere BETWEEN-Ausdruck

=head4 Synopsis

    $sqlExpr = $sql->opBETWEEN($op,$arg1,$arg2);

=head4 Description

Generiere Ausdruck "BETWEEN <EXPR1> AND <EXPR2>" und liefere diesen zurück.

=cut

# -----------------------------------------------------------------------------

sub opBETWEEN {
    my $self = shift;
    my $op = shift;
    my $arg1 = shift;
    my $arg2 = shift;

    return "BETWEEN $arg1 AND $arg2";
}

# -----------------------------------------------------------------------------

=head3 opCASEXPR() - Generiere CASE-Ausdruck

=head4 Synopsis

    $sqlExpr = $sql->opCASEXPR($op,@args);

=head4 Description

Für diff() implementiert, funktioniert aber nicht.

=cut

# -----------------------------------------------------------------------------

sub opCASEXPR {
    my $self = shift;
    my $op = shift;
    my $expr = shift;
    # @_: @pairs

    my $stmt = 'CASE '.$self->keyExpr($expr);
    while (@_ > 1) {
        my $val1 = shift;
        my $val2 = shift;
        $stmt .= ' WHEN '.$self->valExpr($val1).' THEN '.$self->valExpr($val2);
    }
    $stmt .= ' END';

    return $stmt;
}

# -----------------------------------------------------------------------------

=head3 opCAST() - Generiere CAST-Ausdruck (Wandlung Datentyp)

=head4 Synopsis

    $sqlExpr = $sql->opCAST($op,$dataType,$arg);

=cut

# -----------------------------------------------------------------------------

sub opCAST {
    my $self = shift;
    my $op = shift;
    my $dataType = shift;
    my $arg = shift;

    # FIXME: Datentypen konvertieren

    if ($self->isPostgreSQL || $self->isSQLite) {
        return "CAST($arg AS $dataType)";
    }
    $self->throw('Not implemented');
}

# -----------------------------------------------------------------------------

=head3 opIN() - Generiere IN-Ausdruck

=head4 Synopsis

    $sqlExpr = $sql->opIN($op,@arr);

=head4 Description

Generiere Ausdruck "IN (VAL1, VAL2, ...)" und liefere diesen zurück.

=cut

# -----------------------------------------------------------------------------

sub opIN {
    my $self = shift;
    my $op = shift;
    # @_: Werte

    my $str;
    if (@_ == 1 && $_[0] =~ /SELECT/i) {
        # Subselect
        $str = Quiq::String->removeIndentationNl($_[0]);
        $str =~ s/^/        /mg;
        return "IN (\n$str    )";
    }

    for (@_) {
        if ($str) {
            $str .= ', ';
        }
        $str .= $_;
        # $str .= $self->valExpr($_); Problem: STRING wird zu '''STRING'''
    }

    return $str?  "IN ($str)": '';
}

# -----------------------------------------------------------------------------

=head2 Expressions

=head3 keyExpr() - Generiere SQL Identifier-Ausdruck

=head4 Synopsis

    $sqlExpr = $sql->keyExpr($expr);

=head4 Description

Generiere einen SQL Bezeichner-Ausdruck zum portablen Ausdruck $expr
und liefere den generierten Ausdruck zurück.

Ein Bezeichner-Ausdruck ist ein Ausdruck, wie er in der Select-Liste
und auf der linken Seite von WHERE-Klausel-Bedingungen vorkommt.
Er zeichnet sich dadurch aus, dass seine elementaren Komponenten
ungequotete Bezeichner sind (und keine Werte).

=head4 Example

=over 2

=item *

Einfacher Bezeichner

    $sql->keyExpr('per_id');
    ==>
    "per_id"

=item *

Ausdruck als Zeichenkette (nicht empfohlen, da nicht portabel)

    $sql->keyExpr('UPPER(per_nachname)');
    ==>
    "UPPER(per_nachname)"

=item *

Portabler Ausdruck

    $sql->keyExpr(['UPPER',['per_nachname']]);
    ==>
    "UPPER(per_nachname)"

=item *

Portabler Ausdruck mit Stringreferenz (wird String-Literal)

    $sql->keyExpr(['UPPER',[\'Ratlos']]);
    ==>
    "UPPER('Ratlos')"

=back

=cut

# -----------------------------------------------------------------------------

sub keyExpr {
    my ($self,$expr) = @_;

    my $refType = ref $expr;
    if (!$refType) {
        if (!defined $expr || $expr eq '') {
            $self->throw('SQL-00005: Identifier fehlt');
        }
        return $expr;
    }
    elsif ($refType eq 'SCALAR') {
        return $self->stringLiteral($$expr);
    }

    return $self->expr('key',@$expr);
}

# -----------------------------------------------------------------------------

=head3 valExpr() - Generiere SQL Wert-Ausdruck

=head4 Synopsis

    $sqlExpr = $sql->valExpr($expr);

=head4 Description

Generiere einen SQL Wert-Ausdruck zum portablen Ausdruck $expr
und liefere den generierten Ausdruck zurück.

Ein Wert-Ausdruck ist ein Ausdruck, wie er auf der rechten Seite
von WHERE-Klausel-Bedingungen vorkommt. Er zeichnet sich dadurch aus,
dass seine elementaren Komponenten Literale, keine Bezeichner sind.

=head4 Example

=over 2

=item *

Literal

    $sql->valExpr('Kai Nelust');
    ==>
    "'Kai Nelust'"

=item *

Ausdruck

    $sql->valExpr(\'USERNAME');
    ==>
    "USERNAME"

=item *

Portabler Ausdruck

    $sql->valExpr(['UPPER','Kai Nelust']);
    ==>
    "UPPER('Kai Nelust')"

=item *

Portabler Ausdruck mit Stringreferenz (wird Identifier-Ausdruck)

    $sql->valExpr(['LOWER',\'USERNAME']);
    ==>
    "LOWER(USERNAME)"

=back

=cut

# -----------------------------------------------------------------------------

sub valExpr {
    my ($self,$expr) = @_;

    my $refType = ref $expr;
    if (!$refType) {
        return $self->stringLiteral($expr);
    }
    elsif ($refType eq 'SCALAR') {
        return $$expr;
    }

    return $self->expr('val',@$expr);
}

# -----------------------------------------------------------------------------

=head3 whereExpr() - Generiere rechte Seite eines WHERE-Ausdrucks

=head4 Synopsis

    $sqlExpr = $sql->whereExpr($expr);

=head4 Description

Generiere die rechte Seite eines WHERE-Ausdrucks zum portablen
Ausdruck $expr und liefere den generierten Ausdruck zurück.

Der Ausdruck besteht aus einem Operator gefolgt von einem Wert-Ausdruck.

=head4 Example

=over 2

=item *

Literal

    $sql->whereExpr('Kai Nelust');
    ==>
    "= 'Kai Nelust'"

=item *

Ausdruck

    $sql->whereExpr(\'USERNAME');
    ==>
    "= USERNAME"

=item *

Portabler Ausdruck

    $sql->whereExpr(['!=',['UPPER','Kai Nelust']]);
    ==>
    "!= UPPER('Kai Nelust')"

=item *

Portabler Ausdruck mit Stringreferenz (wird Identifier-Ausdruck)

    $sql->whereExpr(['!=',['LOWER',\'USERNAME']]);
    ==>
    "!= LOWER(USERNAME)"

=back

=cut

# -----------------------------------------------------------------------------

sub whereExpr {
    my ($self,$expr) = @_;

    my $opExpr = $self->valExpr($expr);
    if ($opExpr eq '') {
        return '';
    }
    elsif (Quiq::Reference->isArrayRef($expr)) {
        return $opExpr;
    }
    else {
        return "= $opExpr";
    }
}

# -----------------------------------------------------------------------------

=head3 expr() - Wandele portablen Ausdruck in SQL-Ausdruck

=head4 Synopsis

    $str = $sql->expr($type,$op,@args);

=cut

# -----------------------------------------------------------------------------

my %opMethod = (
    '!=' => 'opRel',
    '<' => 'opRel',
    '<=' => 'opRel',
    '=' => 'opRel',
    '>' => 'opRel',
    '>=' => 'opRel',
    'LIKE' => 'opRel',
    'AS' => 'opAS',
    'BETWEEN' => 'opBETWEEN',
    'CAST' => 'opCAST',
    'IN' => 'opIN',
    'LOWER' => 'opFunc',
    'MAX' => 'opFunc',
    'MIN' => 'opFunc',
    'SUBSTR' => 'opFunc',
    'UPPER' => 'opFunc',
    'COALESCE' => 'opFunc',
    'CASEXPR' => 'opCASEXPR',
);

sub expr {
    my $self = shift;
    my $type = shift;
    my $op = shift;
    # @_: @args

    my $meth = $opMethod{$op};
    if (!$meth) {
        $self->throw('SQL-00006: Unbekannte SQL-Operation',Operation=>$op);
    }

    # Argumente (indirekt rekursiv) auflösen

    my $resMeth = $self->can($type.'Expr');
    for my $arg (@_) {
        $arg = $self->$resMeth($arg);
        if ($arg eq '' && $type eq 'val') {
            # Wenn ein Argument leer ist, ist der gesamte Ausdruck leer
            return '';
        }
    }

    return $self->$meth($op,@_)
}

# -----------------------------------------------------------------------------

=head3 stringLiteral() - Generiere SQL Stringliteral

=head4 Synopsis

    $literal = $sql->stringLiteral($str);
    $literal = $sql->stringLiteral($str,$default);

=head4 Description

Verdoppele alle in $str enthaltenen einfachen Anführungsstriche,
fasse den gesamten String in einfache Anführungsstriche ein und
liefere das Resultat zurück.

Ist der String leer ('' oder undef) liefere einen Leerstring
(kein leeres String-Literal!). Ist $default angegeben, liefere diesen
Wert.

B<Anmerkung>: PostgreSQL erlaubt aktuell Escape-Sequenzen in
String-Literalen. Wir behandeln diese nicht. Escape-Sequenzen sollten in
postgresql.conf abgeschaltet werden mit der Setzung:

    standard_conforming_strings = on

=head4 Examples

Eingebettete Anführungsstriche:

    $sel->stringLiteral('Sie hat's');
    =>
    "'Sie hat''s'"

Leerstring, wenn kein Wert:

    $sel->stringLiteral('');
    =>
    ""

'NULL', wenn kein Wert:

    $sel->stringLiteral('','NULL');
    =>
    "NULL"

=cut

# -----------------------------------------------------------------------------

sub stringLiteral {
    my $self = shift;
    my $str = shift;
    # @_: $default

    if (!defined $str || $str eq '') {
        return @_? shift: '';
    }
    if ($self->isMySQL) {
        $str =~ s|\\|\\\\|g;
    }
    $str =~ s/'/''/g;

    return "'$str'";
}

# -----------------------------------------------------------------------------

=head3 selectClause() - Liefere SELECT-Klausel

=head4 Synopsis

    $selectClause = $sql->selectClause(@select);

=cut

# -----------------------------------------------------------------------------

sub selectClause {
    my $self = shift;
    my @select = @_;

    for my $expr (@select) {
        $expr = $self->keyExpr($expr);
    }

    return join ",\n    ",@select;
}

# -----------------------------------------------------------------------------

=head3 fromClause() - Liefere FROM-Klausel

=head4 Synopsis

    $fromClause = $sql->fromClause(@from);

=head4 Description

Wandele die Liste von From-Elementen, @from, in eine FROM-Klausel
und liefere diese zurück.

Die Elemente werden mit Komma als Trennzeichen konkateniert und
folgendermaßen behandelt:

=over 4

=item 'string'

Eine Zeichenkette wird nicht verändert.

=item ['AS',$fromExpr,$alias]

Es wird ein FROM-Alias erzeugt. Dieser hat entweder den Aufbau
"expr AS alias" oder "fromExpr alias", abhängig vom DBMS.
Oracle akzeptiert "fromExpr AS alias" nicht.

=back

=cut

# -----------------------------------------------------------------------------

sub fromClause {
    my $self = shift;
    my @from = @_;

    for my $expr (@from) {
        if (ref $expr) {
            if ($expr->[0] eq 'AS') {
                if ($self->isOracle) {
                    $expr = "$expr->[1] $expr->[2]";
                }
                else {
                    $expr = "$expr->[1] AS $expr->[2]";
                }
            }
            else {
                $self->throw('Not implemented');
            }
        }
        $expr = Quiq::String->removeIndentation($expr);
        $expr =~ s/\n/\n    /g;
    }

    return join ",\n    ",@from;
}

# -----------------------------------------------------------------------------

=head3 whereClause() - Liefere WHERE-Klausel

=head4 Synopsis

    $where = $sql->whereClause(@where);

=head4 Description

Wenn +null in @where vorkommt, werden alle folgenden
leeren Bedingungen nicht übergangen.

=cut

# -----------------------------------------------------------------------------

sub whereClause {
    my $self = shift;
    # @_: @where

    my $plusNull = 0; # Wenn gesetzt, übergehen wir leere Bedingungen nicht

    # FIXME: Logische Operatoren OR und NOT und Klammern

    my @where;
    while (@_) {
        if (defined($_[0]) && $_[0] =~ /[\s=><]/) {
            # Enthält das Argument Leerzeichen oder einen der
            # Vergleichsoperatoren =, >, <, betrachten wir es als
            # vollständige Klausel und übernehmen es in die WHERE-Klausel.

            my $clause = Quiq::String->removeIndentation(shift);
            if ($clause =~ /\n/) {
                # Einrücken, wenn mehrzeilig (z.B. EXISTS-Klausel)
            
                $clause =~ s/^/    /gm;
                $clause =~ s/^\s+//;
            }
            push @where,$clause;
            next;
        }

        # Wir betrachten das Argument als Kolumnenname und das
        # nächste Argument als Vergleichswert mit Operator.

        my $key = shift;
        if (!defined $key || $key eq '') {
            # leere Exists/Not Exists-Klauseln übergehen
            next;
        }
        elsif ($key eq '+null') {
            $plusNull = 1;
            next;
        }

        $key = $self->keyExpr($key);
        my $opVal = $self->whereExpr(shift);
        if ($opVal eq '') {
            unless ($plusNull) {
                # Wir übergehen die Bedingung
                next;
            }
            $opVal = 'IS NULL';
        }
        push @where,"$key $opVal";
    }

    # return join " AND\n    ",@where;
    return join "\n    AND ",@where;
}

# -----------------------------------------------------------------------------

=head3 setClause() - Liefere SET-Klausel für UPDATE-Statement

=head4 Synopsis

    $set = $sql->setClause(@keyVal);

=cut

# -----------------------------------------------------------------------------

sub setClause {
    my $self = shift;
    # @_: @keyVal

    my @set;
    while (@_) {
        my $key = shift;
        my $val = $self->valExpr(shift);
        if ($val eq '') {
            $val = 'NULL';
        }
        push @set,"$key = $val";
    }

    return join ",\n    ",@set;
}

# -----------------------------------------------------------------------------

=head3 exists() - Liefere EXISTS-Klausel

=head4 Synopsis

    $str = $sql->exists(@opt,@select);

=head4 Options

=over 4

=item -active => $bool (Default: 1)

Bedingung, unter der die EXISTS-Klausel gilt. Ist $bool falsch, liefert
die Methode eine leere Liste (Array-Kontext) oder einen Leerstring
(Skalar-Kontext), d.h. die Klausel kann in der Verarbeitung
ignoriert werden.

=item -not => $bool (Default: 0)

Liefere NOT EXISTS Klausel.

=back

=cut

# -----------------------------------------------------------------------------

sub exists {
    my $self = shift;
    # @_: @opt,@select

    my $active = 1;
    my $not = 0;

    Quiq::Option->extract(-mode=>'sloppy',\@_,
        -active => \$active,
        -not => \$not,
    );

    if (!$active) {
        return wantarray? (): '';
    }

    my $stmt = $self->select(@_);
    $stmt =~ s/^/    /gm;

    return ($not? 'NOT ': '')."EXISTS (\n$stmt\n)";
}

# -----------------------------------------------------------------------------

=head3 notExists() - Liefere NOT EXISTS-Klausel

=head4 Synopsis

    $str = $sql->notExists(@select);

=cut

# -----------------------------------------------------------------------------

sub notExists {
    return shift->exists(-not=>1,@_);
}

# -----------------------------------------------------------------------------

=head2 Spezielle Konstrukte

=head3 diff() - Liefere SELECT zur Differenzermittlung

=head4 Synopsis

    $stmt = $sql->diff(
        $keyCol,
        $fromClause,
        [$type,$col1,$col2,$col2Expr],
        ...
        @where,
        @selOpts
    );

=head4 Example

    $tab = $db->diff(
        't.id',
        "de_ticket t LEFT OUTER JOIN spielgemeinschaftanteil s\n".
        'ON t.id = s.spielid*65536+1',
        ['N','t.subscription'=>'s.dauerschein'],
        ['N','t.product_id'=>'s.spielgemeinschaftid',
            \'CASE %C WHEN 9685 THEN 24 WHEN 9684 THEN 26 WHEN 9687 THEN 28 END',
        ],
        't.product_ticket_type'=>'LOTTERY_CLUB_TICKET',
        -limit => 100,
    );

=cut

# -----------------------------------------------------------------------------

sub diff {
    my $self = shift;
    my $keyCol = shift;
    my $fromClause = shift;
    # @_: @colSpecs,@where 

    # Schlüssel-Kolumne
    (my $keyColAlias = $keyCol) =~ s/\./_/;

    # Kolumnenspezifikation auswerten

    my @select = (['AS',$keyCol,$keyColAlias]);
    my @or;
    while (ref $_[0]) {
        my $colSpec = shift;

        # FIXME: DefaultVal-Typen erweitern

        my $type = $colSpec->[0];
        my $defaultVal;
        if ($type eq 'S') {
            $defaultVal = \'(null)';
        }
        elsif ($type eq 'N') {
            $defaultVal = '-1';
        }
        else {
            $self->throw(
                'SQL-00003: Unbekannter Datentyp',
                Type => $type,
            );
        }

        my $col1Name = $colSpec->[1];
        (my $col1Alias = $col1Name) =~ s/\./_/;
        push @select,['AS',$col1Name,$col1Alias];

        my $col2Name = $colSpec->[2];
        my $col2Expr;
        if ($colSpec->[3]) {
           $col2Expr = $self->valExpr($colSpec->[3]);
           $col2Expr =~ s/%C/$col2Name/g;
        }
        else {
           $col2Expr = $col2Name;
        }
        (my $col2Alias = $col2Name) =~ s/\./_/;
        push @select,['AS',$col2Expr,$col2Alias];
        # push @select,['AS',$col2Name,$col2Alias];

        push @or,$self->keyExpr(['COALESCE',$col1Name,$defaultVal]).' <> '.
            $self->keyExpr(['COALESCE',$col2Expr,$defaultVal]);
    }

    # WHERE-Klausel und Statement-Optionen wie -limt (welche
    # am Ende stehen müssen)

    my @opt = Quiq::Option->extractAll(\@_);
    my @where = (@_,'('.join(" OR\n    ",@or).')');

    return $self->select(
        -select => @select,
        -from => $fromClause,
        -where => @where,
        @opt,
    );
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
