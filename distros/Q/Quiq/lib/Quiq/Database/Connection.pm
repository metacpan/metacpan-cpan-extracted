package Quiq::Database::Connection;
use base qw/Quiq::Hash/;

use strict;
use warnings;
use v5.10.0;
use utf8;

our $VERSION = '1.147';

use Quiq::Sql;
use Quiq::Object;
use Quiq::Option;
use Quiq::Udl;
use Quiq::Database::Api;
use Quiq::Hash;
use POSIX ();
use Quiq::FileHandle;
use Quiq::Array;
use Quiq::String;
use Quiq::Path;
use Quiq::Digest;
use Quiq::TempFile;
use Quiq::Database::Cursor;
use Time::HiRes ();
use Quiq::Parameters;
use Quiq::Database::ResultSet;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Database::Connection - Verbindung zu einer Relationalen Datenbank

=head1 BASE CLASS

L<Quiq::Hash>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert eine Verbindung zu einer
Relationalen Datenbank.

=head1 METHODS

=head2 Konstruktor/Destruktor

=head3 new() - Öffne Datenbankverbindung

=head4 Synopsis

    $db = $class->new(@opt);
    $db = $class->new($udl,@opt);
    $db = $class->new($udlObj,@opt);
    $db2 = $db->new(@opt);

=head4 Alias

connect()

=head4 Options

=over 4

=item -cacheDir => $path

In diesem Verzeichnis werden Ergebnismengen gecacht, wenn dies
bei Selektionen angefordert wird.

=item -handle => $dbh (Default: undef)

Bereits aufgebaute Low-Level Datenbankverbindung zuweisen.

=item -log => $bool (Default: 0)

Logging von SQL-Statements.

=item -logfile => $filename (Default: '-')

Logdatei. Wenn nicht angegeben oder '-' wird auf STDOUT gelogged.

=item -sqlClass => $class (Default: 'Quiq::Sql')

Name der Sql-Klasse zur Statementgenerierung.

=item -strict => $bool (Default: undef)

Aktiviere oder deaktiviere automatische Fehlerbehandlung.

=item -utf8 => $bool (Default: 0)

Definiere das clientseitige Character Encoding als UTF-8.

=back

=head4 Description

Instantiiere eine Datenbankverbindung und liefere eine Referenz auf
dieses Objekt zurück.

Ist $udl nicht angegeben, wird der Wert der Environment-Variable
$UDL verwendet.

Wird die Methode als Objektmethode einer bestehenden Datenbankverbindung
gerufen, wird eine weitere Verbindung zur selben Datenbank aufgebaut.
Dies ist nützlich, wenn eine parallele Transaktion benötigt wird.

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$self) = Quiq::Object->this(shift);

    # Optionen

    my $cacheDir = undef;
    my $handle = undef;
    my $log = undef;
    my $logfile = '-';
    my $sqlClass = undef;
    my $strict = undef;
    my $utf8 = undef;

    Quiq::Option->extract(\@_,
        -cacheDir => \$cacheDir,
        -handle => \$handle,
        -log => \$log,
        -logfile => \$logfile,
        -sqlClass => \$sqlClass,
        -strict => \$strict,
        -utf8 => \$utf8,
    );

    # Objektmethode: Wir erzeugen eine parallele Datenbankverbindung

    if ($self) {
        # Defaults der neuen Verbindung

        $log = $self->{'log'} if !defined $log;
        $logfile = $self->{'logfile'} if !defined $logfile;
        $sqlClass = $self->{'sqlClass'} if !defined $sqlClass;
        $strict = $self->strict if !defined $strict;
        $utf8 = $self->{'utf8'} if !defined $utf8;

        # FIXME: alle Attribute kopieren
        return $class->new($self->{'udlObj'},
            -log => $log,
            -logfile => $logfile,
            -sqlClass => $sqlClass,
            -strict => $strict,
            -utf8 => $utf8,
        );
    }

    # Defaults im Falle einer neuen Verbindung

    $log = 0 if !defined $log;
    $sqlClass = 'Quiq::Sql' if !defined $sqlClass;
    $utf8 = 0 if !defined $utf8;

    my $udl = @_? shift: $ENV{'UDL'};

    if (!defined $udl || $udl eq '') {
        $class->throw('DB-00002: Kein UDL');
    }
    elsif (@_) {
        $class->throw(
            'DB-00002: Zu viele Parameter',
            Parameters => join(',',@_),
        );
    }

    # Klassenmethode: Wir erzeugen eine Datenbankverbindung

    my $udlObj = ref $udl? $udl: Quiq::Udl->new($udl);
    my $apiObj = Quiq::Database::Api->connect($udlObj,
        -utf8 => $utf8,
        -handle => $handle,
    );
    my $sqlObj = $sqlClass->new($udlObj->dbms);

    $self = $class->SUPER::new(
        startTime => scalar(Time::HiRes::gettimeofday),
        apiObj => $apiObj,
        udlObj => $udlObj,
        sqlClass => $sqlClass,
        sqlObj => $sqlObj,
        titleListCache => Quiq::Hash->new->unlockKeys,
        nullRowCache => Quiq::Hash->new->unlockKeys,
        utf8 => $utf8,
        schema => undef,
        log => $log,
        logfile => $logfile,
        logSeparator => '===',
        logMsgSeparator => '---',
        logMsgPrefix => '# ',
        logProgressStep => 1000,
        logProgressCount => 0,
        cacheDir => $cacheDir,
    );

    if ($self->isLog) {
        $self->msgToLog(sprintf "CONNECT %s (%s)",
            $udlObj->asString(-secure=>1),
            POSIX::strftime('%Y-%m-%d %H:%M:%S',localtime),
        );
    }

    if (defined $cacheDir) {
        # Wir ergänzen den Cache-Verzeichnispfad um den UDL-String
        $cacheDir .= '/'.$udlObj->asString(-secure=>1);
        $self->set(cacheDir=>$cacheDir);
    }

    # Strict-Modus aktivieren

    if (defined $strict) {
        $self->strict($strict);
    }

    # Default-Schema setzen

    if (my $schema = $udlObj->options->get('schema')) {
        $self->setSchema($schema);
    }

    # Datumsformat einstellen (nur, wenn wir die Verbindung
    # selbst aufgebaut haben, sonst belassen wir das eingestellte
    # Datumsformat)

    if (!$handle) {
        $self->setDateFormat;
        $self->setNumberFormat;
    }

    return $self;
}

{
    no warnings 'once';
    *connect = \&new;
}

# -----------------------------------------------------------------------------

=head3 newFromSbit() - Instantiiere Quiq::Database::Connection-Datenbankobjekt aus Sbit-Datenbankobjekt

=head4 Synopsis

    $db = $class->newFromSbit($db);

=cut

# -----------------------------------------------------------------------------

sub newFromSbit {
    my ($class,$db) = @_;

    return $class->new($db->udlDbms,
        -handle => $db->dbh,
        -log => 0,
        -logfile => '/tmp/tsplot.log',
    );
}

# -----------------------------------------------------------------------------

=head3 disconnect() - Schließe Datenbankverbindung

=head4 Synopsis

    $db->disconnect;
    $db->disconnect($commit);

=head4 Alias

destroy()

=head4 Description

Schließe Datenbankverbindung. Ist $commit "wahr", committe die Daten
vor dem Schließen der Verbindung. Die Methode liefert keinen Wert zurück.

Die Objektreferenz $db ist  nach Aufruf der Methode ungültig und kann
nicht mehr verwendet werden.

=cut

# -----------------------------------------------------------------------------

sub disconnect {
    my ($self,$commit) = @_;

    #!! FIXME
    #
    #if ($self->isSQLite) {
    #    $self->begin; # für SQLite, da sonst (auch ohne Aufruf von commit):
    #                  # SQLITE-00001: cannot commit - no transaction is
    #                  # active
    #    $self->commit;
    #}

    $self->commit($commit) if @_ == 2;
    $_[0] = undef;

    return;
}

{
    no warnings 'once';
    *destroy = \&disconnect;
}

# -----------------------------------------------------------------------------

=head3 dbExists() - Prüfe, ob Datenbankverbindung aufgebaut werden kann

=head4 Synopsis

    $bool = $class->dbExists($udl);

=head4 Description

Prüfe, ob Verbindung zur Datenbank $udl möglich ist.
Liefere "wahr", wenn dies der Fall ist, andernfalls "falsch".

=cut

# -----------------------------------------------------------------------------

sub dbExists {
    my ($class,$udl) = @_;
    my $db = eval { $class->new($udl) };
    return $db? 1: 0;
}

# -----------------------------------------------------------------------------

=head2 Akzessoren

=head3 maxBlobSize() - Liefere/Setze max. Größe von BLOB/TEXT (Oracle)

=head4 Synopsis

    $n = $db->maxBlobSize;
    $n = $db->maxBlobSize($n);

=head4 Description

Liefere/Setze die maximale Größe eines BLOB/TEXT-Werts auf $n Bytes.
Defaulteinstellung ist 1024*1024 Bytes (1MB).

Dieser Wert ist nur für Oracle relevant und wird bei der Selektion
von BLOB/TEXT-Kolumnen benötigt. Ist der Wert einer BLOB/TEXT-Kolumne
größer als die angegebene Anzahl an Bytes wird eine Exception
ausgelöst.

Bei anderen DBMSen als Oracle hat das Setzen keinen Effekt und der
Returnwert der Methode ist immer 0.

=cut

# -----------------------------------------------------------------------------

sub maxBlobSize {
    return shift->{'apiObj'}->maxBlobSize(@_);
}

# -----------------------------------------------------------------------------

=head3 strict() - Strict-Modus abfragen oder umschalten

=head4 Synopsis

    $bool = $db->strict;
    $bool = $db->strict($bool);

=head4 Description

Bei eingeschaltetem Strict-Modus wird eine Exception

=head4 Example

    my $db = Quiq::Database::Connection->new('dbi#mysql',
        -handle => $main::dbh,
    );
    
    ...
    
    $db->strict(1);
    
    # bei Datenbank-Fehler wird Exception geworfen
    
    $db->strict(0)

=cut

# -----------------------------------------------------------------------------

sub strict {
    return shift->{'apiObj'}->strict(@_);
}

# -----------------------------------------------------------------------------

=head3 stmt() - Liefere das Sql-Objekt

=head4 Synopsis

    $sqlObj = $db->stmt;

=head4 Alias

sqlEngine()

=head4 Description

Liefere das Sql-Objekt der Datenbankverbindung. Mit dem Sql-Objekt
lassen sich SQL-Statements generieren, z.B.

    $stmt = $db->stmt->dropTable($table);

=cut

# -----------------------------------------------------------------------------

sub stmt {
    return shift->{'sqlObj'};
}

{
    no warnings 'once';
    *sqlEngine = \&stmt;
}

# -----------------------------------------------------------------------------

=head3 udl() - Liefere das Udl-Objekt

=head4 Synopsis

    $udlObj = $db->udl;

=head4 Description

Liefere das Udl-Objekt der Datenbankverbindung. Das Udl-Objekt
hält Information über die Datenbankverbindung, z.B.

    $user = $db->udl->user;

=cut

# -----------------------------------------------------------------------------

sub udl {
    return shift->{'udlObj'};
}

# -----------------------------------------------------------------------------

=head2 Time Measurement

=head3 startTime() - Liefere Zeitpunkt des Verbindungsaufbaus

=head4 Synopsis

    $time = $cur->startTime;

=cut

# -----------------------------------------------------------------------------

sub startTime {
    return shift->{'startTime'};
}

# -----------------------------------------------------------------------------

=head3 time() - Liefere Dauer seit Beginn des Verbindungsaufbaus

=head4 Synopsis

    $time = $cur->time;

=cut

# -----------------------------------------------------------------------------

sub time {
    my $self = shift;
    return Time::HiRes::gettimeofday-$self->{'startTime'};
}

# -----------------------------------------------------------------------------

=head2 DBMS-Tests

Die folgenden Methoden testen auf das DBMS. Sie werden angewendet, wenn
DBMS-spezifische Unterscheidungen vorgenommen werden müssen.

=head3 dbms() - Liefere den Namen des DBMS

=head4 Synopsis

    $dbms = $db->dbms;

=cut

# -----------------------------------------------------------------------------

sub dbms {
    return shift->{'sqlObj'}->dbms;
}

# -----------------------------------------------------------------------------

=head3 dbmsTestVector() - Vektor für DBMS-Tests

=head4 Synopsis

    ($oracle,$postgresql,$sqlite,$mysql,$access,$mssql) = $db->dbmsTestVector;

=cut

# -----------------------------------------------------------------------------

sub dbmsTestVector {
    return shift->{'sqlObj'}->dbmsTestVector;
}

# -----------------------------------------------------------------------------

=head3 isOracle() - Prüfe auf Oracle-DBMS

=head4 Synopsis

    $bool = $db->isOracle;

=head4 Description

Liefere "wahr", wenn die Datenbank eine Oracle-Datenbank ist,
sonst "falsch".

=cut

# -----------------------------------------------------------------------------

sub isOracle {
    return shift->{'sqlObj'}->isOracle;
}

# -----------------------------------------------------------------------------

=head3 isPostgreSQL() - Prüfe auf PostgreSQL-DBMS

=head4 Synopsis

    $bool = $db->isPostgreSQL;

=head4 Description

Liefere "wahr", wenn die Datenbank eine PostgreSQL-Datenbank ist,
sonst "falsch".

=cut

# -----------------------------------------------------------------------------

sub isPostgreSQL {
    return shift->{'sqlObj'}->isPostgreSQL;
}

# -----------------------------------------------------------------------------

=head3 isSQLite() - Prüfe auf SQLite-DBMS

=head4 Synopsis

    $bool = $db->isSQLite;

=head4 Description

Liefere "wahr", wenn die Datenbank eine SQLite-Datenbank ist,
sonst "falsch".

=cut

# -----------------------------------------------------------------------------

sub isSQLite {
    return shift->{'sqlObj'}->isSQLite;
}

# -----------------------------------------------------------------------------

=head3 isMySQL() - Prüfe auf MySQL-DBMS

=head4 Synopsis

    $bool = $db->isMySQL;

=head4 Description

Liefere "wahr", wenn die Datenbank eine MySQL-Datenbank ist,
sonst "falsch".

=cut

# -----------------------------------------------------------------------------

sub isMySQL {
    return shift->{'sqlObj'}->isMySQL;
}

# -----------------------------------------------------------------------------

=head3 isAccess() - Prüfe auf Access-DBMS

=head4 Synopsis

    $bool = $db->isAccess;

=head4 Description

Liefere "wahr", wenn die Datenbank eine Access-Datenbank ist,
sonst "falsch".

=cut

# -----------------------------------------------------------------------------

sub isAccess {
    return shift->{'sqlObj'}->isAccess;
}

# -----------------------------------------------------------------------------

=head3 isMSSQL() - Prüfe auf MSSQL-DBMS

=head4 Synopsis

    $bool = $db->isMSSQL;

=head4 Description

Liefere "wahr", wenn die Datenbank eine MSSQL-Datenbank ist,
sonst "falsch".

=cut

# -----------------------------------------------------------------------------

sub isMSSQL {
    return shift->{'sqlObj'}->isMSSQL;
}

# -----------------------------------------------------------------------------

=head2 Handle

=head3 handle() - Lowlevel (DBI-)Handle

=head4 Synopsis

    $dbh = $db->handle;

=cut

# -----------------------------------------------------------------------------

sub handle {
    return shift->get('apiObj')->get('dbh');
}

# -----------------------------------------------------------------------------

=head2 Information

=head3 defaultRowClass() - Liefere Namen der Default-Rowklasse

=head4 Synopsis

    $rowClass = $this->defaultRowClass($raw);

=head4 Description

Liefere den Namen der Default-Rowklasse:

    Quiq::Database::Row::Object  ($raw ist "falsch")
    Quiq::Database::Row::Array   ($raw ist "wahr")

Auf die Default-Rowklasse werden Datensätze instantiiert, für die
bei einer Datenbank-Selektion oder einer Instantiierung einer
Table-Klasse keine Row-Klasse explizit angegeben wurde.

=cut

# -----------------------------------------------------------------------------

sub defaultRowClass {
    return $_[1]? 'Quiq::Database::Row::Array': 'Quiq::Database::Row::Object';
}

# -----------------------------------------------------------------------------

=head2 Logging

Alle Statements einer Session oder ein gewisser Abschnitt kann
gelogged werden.

Für die gesamte Session:

    $db = Quiq::Database::Connection->new($udl,-log=>1);

Innerhalb eines Abschnitts:

    $db->openLog;
    ...
    $db->closeLog;

Testen, ob Db-Logging eingeschaltet ist:

    $db->isLog;

Schreiben eigener Meldungen ins Log:

    $db->printLog($msg);

Scheiben von Fortschrittsmeldungen ins Log:

    $db->startProgressLog($n);
    while (...) {
        $db->printProgressLog($msg);
    }
    $db->endProgressLog;

=head3 isLog() - Prüfe, ob Logging eingeschaltet ist

=head4 Synopsis

    $bool = $db->isLog;

=cut

# -----------------------------------------------------------------------------

sub isLog {
    return shift->{'log'};
}

# -----------------------------------------------------------------------------

=head3 openLog() - Öffne SQL-Log

=head4 Synopsis

    $db->openLog;

=cut

# -----------------------------------------------------------------------------

sub openLog {
    my $self = shift;
    $self->{'log'} = 1;
    return;
}

# -----------------------------------------------------------------------------

=head3 writeLog() - Schreibe Zeichenkette ins SQL-Log

=head4 Synopsis

    $db->writeLog(@str);

=head4 Description

Schreibe Argumente @str ins geöffnete SQL-Log.
Ist das SQL-Log nicht geöffnet, wird nichts geschrieben.
Die Methode liefert keinen Wert zurück.

=cut

# -----------------------------------------------------------------------------

sub writeLog {
    my $self = shift;
    # @_: @str

    if ($self->{'log'}) {
        my $file = $self->{'logfile'};
        my $fh;
        if ($file eq '-') {
            $fh = *STDOUT;
        }
        elsif (ref($file) eq 'GLOB') {
            $fh = $file;
        }
        else {
            $fh = Quiq::FileHandle->new('>>',$file);
        }
        print $fh @_;
    }

    return;
}

# -----------------------------------------------------------------------------

=head3 msgToLog() - Schreibe Meldung ins SQL-Log

=head4 Synopsis

    $db->msgToLog($msg);

=head4 Alias

printLog()

=head4 Description

Schreibe Meldung $msg ins SQL-Log.
Die Methode liefert keinen Wert zurück.

Der Logfileeintrag hat folgenden Aufbau:

    <LogMsgSeparator>
    <LogMsgPrefix> <msg>

Mit Defaultwerten:

    ---
    # <msg>

Ist die Meldung mehrzeilig, wird der LogMsgPrefix jeder
Zeile vorangestellt.

=cut

# -----------------------------------------------------------------------------

sub msgToLog {
    my $self = shift;
    my $msg = shift;

    if ($self->{'log'}) {
        $msg =~ s/\s+$//;
        if (my $sep = $self->{'logMsgSeparator'}) {
             $self->writeLog($sep,"\n");
        }
        if (my $prefix = $self->{'logMsgPrefix'}) {
            $msg =~ s/^/$prefix/mg;
        }
        $self->writeLog($msg,"\n");
    }

    return;
}

{
    no warnings 'once';
    *printLog = \&msgToLog;
}

# -----------------------------------------------------------------------------

=head3 stmtToLog() - Schreibe SQL Statement ins SQL-Log

=head4 Synopsis

    $db->stmtToLog($stmt);

=head4 Description

Schreibe SQL Statement $stmt ins SQL-Log.
Die Methode liefert keinen Wert zurück.

Der Logfileeintrag hat folgenden Aufbau:

    <LogMsgSeparator>
    <stmt>

Mit Defaultwerten:

    ===
    <stmt>

Ist die Meldung mehrzeilig, wird der LogMsgPrefix jeder
Zeile vorangestellt.

=cut

# -----------------------------------------------------------------------------

sub stmtToLog {
    my $self = shift;
    my $stmt = shift;

    if ($self->{'log'}) {
        $stmt =~ s/\s+$//;
        $stmt = '(no statement)' if !$stmt;
        my $sep = $self->{'logSeparator'};
        $self->writeLog($sep,"\n",$stmt,"\n");
    }

    return;
}

# -----------------------------------------------------------------------------

=head3 timeToLog() - Schreibe Ausführungszeit ins SQL-Log

=head4 Synopsis

    $db->timeToLog($time);

=head4 Description

Schreibe Ausführungszeit $time ins SQL-Log.
Die Methode liefert keinen Wert zurück.

Der Logfileeintrag hat per Default folgenden Aufbau:

    /* <time> */

=cut

# -----------------------------------------------------------------------------

sub timeToLog {
    my $self = shift;
    my $time = shift;

    if ($self->{'log'}) {
        $self->writeLog(sprintf "/* %s, %s */\n",
            $time,
            POSIX::strftime('%Y-%m-%d %H:%M:%S',localtime)
        );
    }

    return;
}

# -----------------------------------------------------------------------------

=head3 closeLog() - Schließe SQL-Log

=head4 Synopsis

    $db->closeLog;

=cut

# -----------------------------------------------------------------------------

sub closeLog {
    my $self = shift;
    $self->{'log'} = 0;
    return;
}

# -----------------------------------------------------------------------------

=head3 startProgressLog() - Beginne Fortschrittsmeldungen

=head4 Synopsis

    $db->startProgressLog($n);

=cut

# -----------------------------------------------------------------------------

sub startProgressLog {
    my $self = shift;
    my $n = shift;

    if ($self->{'log'}) {
        if (my $sep = $self->{'logMsgSeparator'}) {
            $self->writeLog($sep,"\n");
        }
    }
    if ($n) {
        $self->{'logProgressStep'} = $n;
    }

    return;
}

# -----------------------------------------------------------------------------

=head3 printProgressLog() - Schreibe Fortschrittsmeldung ins SQL-Log

=head4 Synopsis

    $db->printProgressLog($msg);

=head4 Description

Schreibe Fortschrittsmeldung $msg ins SQL-Log.
Die Methode liefert keinen Wert zurück.

Der Logfileeintrag hat folgenden Aufbau:

    <LogMsgPrefix> <msg>

Mit Defaultwerten:

    # <msg>

Ist die Meldung mehrzeilig, wird sie einzeilig gemacht, indem
NEWLINE durch SPACE ersetzt wird.

=cut

# -----------------------------------------------------------------------------

sub printProgressLog {
    my $self = shift;
    my $msg = shift;

    if ($self->{'log'} &&
            ++$self->{'logProgressCount'}%$self->{'logProgressStep'} == 0) {
        $msg =~ s/\n+/ /;
        $msg =~ s/\s+$//;
        if (my $prefix = $self->{'logMsgPrefix'}) {
            $msg =~ s/^/$prefix/mg;
        }
        $self->writeLog($msg,"\r");
    }

    return;
}

# -----------------------------------------------------------------------------

=head3 endProgressLog() - Beende Fortschrittsmeldungs-Folge im SQL-Log

=head4 Synopsis

    $db->endProgressLog($msg);

=cut

# -----------------------------------------------------------------------------

sub endProgressLog {
    my $self = shift;
    my $msg = shift;

    if ($self->{'log'}) {
        $msg =~ s/\n+/ /;
        $msg =~ s/\s+$//;
        if (my $prefix = $self->{'logMsgPrefix'}) {
            $msg =~ s/^/$prefix/mg;
        }
        $self->writeLog($msg,"\n");
    }

    return;
}

# -----------------------------------------------------------------------------

=head2 Export/Import

=head3 exportTable() - Exportiere Tabelle

=head4 Synopsis

    $db->exportTable($table,$file);

=head4 Description

Exportiere die Daten der Tabelle $table in Datei $file.

=cut

# -----------------------------------------------------------------------------

sub exportTable {
    my ($self,$table,$file) = @_;

    my $colSep = '|';
    my $cur = $self->select($table,
        -cursor => 1,
        -raw => 1,
    );
    my $titleA = $cur->titles;

    my $fh = Quiq::FileHandle->new('>',$file);
    $fh->setEncoding('utf-8');
    $fh->print(Quiq::Array->dump($titleA,$colSep),"\n");
    while (my $rowA = $cur->fetch) {
        $fh->print(Quiq::Array->dump($rowA,$colSep),"\n");
    }
    $fh->close;
    $cur->close;

    return;
}

# -----------------------------------------------------------------------------

=head3 importTable() - Importiere Tabelle

=head4 Synopsis

    $db->importTable($table,$file);

=head4 Description

Importiere die Daten aus Datei $file in Tabelle $table.

=cut

# -----------------------------------------------------------------------------

sub importTable {
    my ($self,$table,$file) = @_;

    my $colSep = '|';
    my $fh = Quiq::FileHandle->new('<',$file);
    $fh->setEncoding('utf-8');

    my $line = scalar <$fh>;
    chomp $line;
    my $titleA = Quiq::Array->restore($line,$colSep);

    my @placeholders;
    for (@$titleA) {
        push @placeholders,\(my $s = '?');
    }
    my $stmt = $self->stmt->insert($table,$titleA,\@placeholders);
    my $cur = $self->sql($stmt);

    while (my $line = <$fh>) {
        chomp $line;
        $cur->bind(Quiq::Array->restore($line,$colSep));
    }
    $fh->close;
    $cur->close;

    $self->commit;

    return;
}

# -----------------------------------------------------------------------------

=head2 Locking

=head3 lockTable() - Locke Tabelle

=head4 Synopsis

    $db->lockTable($table);

=cut

# -----------------------------------------------------------------------------

sub lockTable {
    my ($self,$table) = @_;
    my $stmt = $self->stmt->lockTable($table);
    return $self->sqlAtomic($stmt);
}

# -----------------------------------------------------------------------------

=head2 SQL Execution

=head3 sql() - Führe SQL-Statement aus

=head4 Synopsis

    $cur = $db->sql($stmt,@opt);

=head4 Options

=over 4

=item cache => $n (Default: undef)

Cache die Datensätze, die das Statement $stmt liefert, für $n Sekunden.
D.h. hole die Datensätze innerhalb dieser Zeitspanne nicht erneut
von der Datenbank, sondern lies sie aus dem Cache. Ist $n 0,
werden die Datensätze unbegrenzt lange gecacht.

=item -chunkSize => $n (Default: 500)

Fetche Datensätze in Chunks von $n Sätzen. Diese Option hat aktuell
nur bei PostgreSQL und -fetchMode 1 oder 2 eine Bedeutung.

=item -fetchMode => 0 | 1 | 2 (Default: 1)

Der Parameter hat nur im Falle PostgreSQL eine Auswirkung. Siehe
auch Abschnitt "SELECT mit PostgreSQL".

=over 4

=item Z<>0

Normaler DBI::Pg-Fetchmodus, d.h. die gesamte Ergebnismenge wird
zum Client transferiert, bevor dieser den ersten Datensatz erhält.
Dieser Modus ist für große Datenmengen schlecht geeignet.

=item Z<>1

Die Datensätze werden in Chunks von -chunkSize Sätzen gefetcht.
Dies ist der Default-Modus.

=item Z<>2

Wie 1, wobei zusätzlich eine eigene Connection für die Selektion
geöffnet wird. Dies ist notwendig, wenn während der
Datensatz-Verarbeitung COMMITs oder ROLLBACKs ausgeführt werden sollen.
Eine Cursor-basierte Selektion wird bei PostgreSQL ohne eigene
Connection wird mit dem ersten COMMIT oder ROLLBACK ungültig.

=back

=item -forceExec => $bool (Default: 0)

Forciere die Ausführung des Statement. Dies kann bei Oracle PL/SQL
Code notwendig sein, wenn Konstrukte enthalten sind,
die von DBI/DBD irrtümlich als Bind-Variablen interpretiert werden.
Z.B. bei folgender Trigger-Definition das ":new":

    CREATE OR REPLACE TRIGGER x_before_insert
    BEFORE INSERT
        ON x
        FOR EACH ROW
    BEGIN
        :new.create_date := sysdate;
    END;

Ohne -forceExec=>1 würde das Statement lediglich präpariert,
nicht ausgeführt.

=item -log => 0|1 (Default: -log der Connection)

Schreibe SQL-Statement und Ausführungszeit nach STDOUT.

=item -raw => $bool (Default: 0)

Fetche die Datensätze als einfache Arrays statt als komplexe
Row-Objekte. Als Default-Rowklasse verwende Quiq::Database::Row::Array
statt Quiq::Database::Row::Object (der Parameter -rowClass überschreibt
diesen Default).

=item -rowClass => $rowClass (Default: 'Quiq::Database::Row::Object')

Name der Datensatzklasse, auf die die Datensätze der Ergebnismenge
geblesst werden.

=item -tableClass => $tableClass (Default: siehe Text)

Name der Tabellenklasse, die die Ergebnismenge speichert.
Bei Raw-Datensätzen ist Quiq::Database::ResultSet::Array der Default,
ansonsten Quiq::Database::ResultSet::Object.

=back

=head4 Returns

Referenz auf Cursor-Objekt (Quiq::Database::Cursor)

=head4 Description

Führe SQL-Statement $stmt über Datenbankverbindung $db aus,
instantiiere ein Resultat-Objekt (Cursor), und liefere eine Referenz
auf dieses Objekt zurück.

=head4 Details

B<SELECT mit PostgreSQL>

Bei PostgreSQL (DBD::Pg) holt ein SELECT erst die gesamte Ergebnismenge
zum Client. Das ist für große Ergebnismengen fatal.

Um die Datensätze in Chunks zu holen, muss ein CURSOR verwendet
werden:

    DECLARE <cursor> CURSOR FOR <stmt>;
    FETCH <n> FROM <cursor>;
    ...
    CLOSE <cursor>;

Hierbei ist:

    <cursor> der Name des Cursors
    <stmt> das SELECT-Statement
    <n> die Anzahl der zu fetchenden Datensätze

Die Methode $db->sql() implementiert im Falle von PostgreSQL
SELECTs durch obige Anweisungsfolge, wenn die Option -fetchMode
gesetzt ist.

    -fetchMode=>0|1|2 (Default: 0)
        0=Defaultverhalten, 1=dekl. Cursor, 2=dekl. Cursor + extra Session
    -chunkSize=>$n (Default: 500)
        Fetche Datensätze in Chunks von $n Stück

=cut

# -----------------------------------------------------------------------------

sub sql {
    my $self = shift;
    # @_: $stmt,@opt

    # FIXME: Methode einführen, mit der es von fremden Methoden aus
    # möglich ist, die sql()-Optionen aus der Argumentliste zu extrahieren.
    # Anforderung: die Optionsliste soll nur einmal definiert werden, d.h.
    # die Methode sollte auch von sql() selbst benutzt werden können.
    # Gesucht ist ein allgemeines Konzept für diese Aufgabe.

    # Optionen

    my $cache = undef;
    my $chunkSize = 500;
    my $fetchMode = 0;
    my $forceExec = 0;
    my $raw = 0;
    my $rowClass;
    my $tableClass;
    my $log = $self->{'log'};

    Quiq::Option->extract(\@_,
        -cache => \$cache,
        -chunkSize => \$chunkSize,
        -fetchMode => \$fetchMode,
        -forceExec => \$forceExec,
        -raw => \$raw,
        -rowClass => \$rowClass,
        -tableClass => \$tableClass,
        -log => \$log,
    );

    # Leeres Statement ergibt Pseudocursor
    (my $stmt) = (my $origStmt) = shift || '';
    Quiq::String->removeIndentation(\$stmt);

    # Ergebnismenge im Cache holen?

    my $cacheOp = ''; # damit per eq verglichen werden kann
    my $cacheFile;
    if (defined($cache) && $stmt) {
        my $p = Quiq::Path->new;
        my $cacheDir = $self->{'cacheDir'};
        $p->mkdir($cacheDir);
        $cacheFile = $cacheDir.'/'.Quiq::Digest->md5($stmt);
        if ((my $exists = $p->exists($cacheFile)) &&
                ($cache == 0 || CORE::time-$p->mtime($cacheFile) < $cache)) {
            # Cachedatei existiert und ist noch gültig (0 = ewige
            # Gültigkeit), d.h. wir lesen die Datensätze aud dem Cache.
            $cacheOp = 'r';
        }
        else {
            if ($exists) {
                # Cache-Datei ist abgelaufen, wir löschen sie
                $p->delete($cacheFile);
            }

            # Wír bauen die Cachedatei auf. Damit im Falle eines Fehlers
            # keine unvollständige Cachedatei entsteht, schreiben
            # wir die Datensätze zunächst in eine Temporäre Datei.
            # Diese benennen wir am Ende der Fetch-Sequenz in die
            # richtige Cache-Datei um, siehe $cur->fetch().

            $cacheOp = 'w';
            $cacheFile = Quiq::TempFile->new(-dir=>$cacheDir);
        }
    }

    if ($log) {
        $self->stmtToLog($stmt);
    }

    my $startTime = Time::HiRes::gettimeofday;

    # Statement ausführen

    my ($curName,$apiCur,$err,$titles,$id);
    my $bindVars = 0;
    my $hits = 0;    

    if ($cacheOp ne 'r') {
        # FIXME: Select-Statement- und Bind-Varibalen-Erkennung verbessern
        if ($self->isPostgreSQL && $fetchMode &&
                $stmt !~ /^DECLARE/ && $stmt =~ /\bSELECT\b/i &&
                $stmt !~ /\?/) {
            if ($fetchMode == 2) {
                $self = $self->new; # parallele Connection
            }

            # FIXME: Logik auf API-Ebene verlagern? Idee: $curName,
            # $chunkSize als Parameter an Methode sql() übergeben.
            # Code in fetch() und destroy() ebenfalls auf API-Ebene verlagern.
            # Gegen dieses Konzept spricht, dass dann FETCH und CLOSE
            # nicht protokolliert werden.

            my $time = Time::HiRes::gettimeofday;
            $time =~ s/\.//;
            $curName = sprintf 'csr%s',$time;
            $self->sql("DECLARE $curName CURSOR FOR\n$stmt",-log=>0);
            $stmt = "FETCH $chunkSize FROM $curName";
        }

        $apiCur = eval { $self->get('apiObj')->sql($stmt,$forceExec) };
        $err = $@;

        if (!$err) {
            # Attribute Lowlevel-Cursor abfragen

            $bindVars = $apiCur->bindVars;
            $hits = $apiCur->hits;
            $titles = $apiCur->titles;
            $id = $apiCur->id;

            # Lowlevel-Cursor schließen, falls er nicht mehr gebraucht wird

            if (!$bindVars && !@$titles) {
                $apiCur->destroy;
            }
        }
    }

    my $execTime = Time::HiRes::gettimeofday-$startTime;

    # FIXME: Fetch-Zeit auch loggen

    if ($log) {
        $self->timeToLog(sprintf '%.6f sec, %s rows%s',$execTime,
            $apiCur? $apiCur->hits: 0,$@? ' ERROR': '');
    }

    # Exception nach Log-Protokollierung werfen

    if ($err) {
        die $err;
    }

    # Cache schreiben oder lesen

    my $cacheFh;
    if ($cacheOp eq 'w') {
        # Cache schreiben

        $cacheFh = Quiq::FileHandle->new('>',$cacheFile,-createDir=>1);
        my $width = @$titles;
        $cacheFh->writeData($width);
        for (@$titles) {
            $cacheFh->writeData($_);
        }
    }
    elsif ($cacheOp eq 'r') {
        # Cache lesen

        $cacheFh = Quiq::FileHandle->new('<',$cacheFile);
        my $width = $cacheFh->readData;
        my @titles;
        for (my $i = 0; $i < $width; $i++) {
            push @titles,$cacheFh->readData;
        }
        $titles = \@titles;
    }

    $rowClass ||= $self->defaultRowClass($raw);

    return Quiq::Database::Cursor->new(
        apiCur => $apiCur,
        bindVars => $bindVars,
        cacheFile => $cacheFile,
        cacheFh => $cacheFh,
        cacheOp => $cacheOp,
        db => $self, # schwache Referenz, siehe Cursor-Konstruktor
        stmt => $origStmt,
        hits => $hits,
        id => $id,
        rowClass => $rowClass,
        tableClass => $tableClass || $rowClass->tableClass,
        titles => $titles,
        startTime => $startTime,
        execTime => $execTime,
        curName => $curName,
        chunkSize => $chunkSize,
        chunkPos => 0,
    );
}

# -----------------------------------------------------------------------------

=head3 sqlAtomic() - Führe SQL-Statement atomar aus

=head4 Synopsis

    $cur = $db->sqlAtomic($stmt,@opt);

=head4 Description

Führe DDL-Statement $stmt aus, instantiiere ein Resultat-Objekt (Cursor),
und liefere eine Referenz auf dieses Objekt zurück.

Das Statement wird atomar ausgeführt, d.h. ist das Statement
erfolgreich, wird anschließend ein COMMIT ausgeführt, schlägt das
Statement fehl, wird ein ROLLBACK ausgeführt.

Dieses Verhalten ist insbesondere im Falle von PostgreSQL wichtig,
da bei PostgreSQL praktisch alles einer Transaktionskontrolle unterliegt.
Z.B. können erzeugte Objekte nicht zugriffen werden, solange
ihre Erzeugung nicht abgeschlossen ist, d.h. der Zugriff auf die erzeugten
Objekte wird blockiert. Oder das Setzen von Session-Einstellungen
verfällt mit einem ROLLBACK. usw.

=cut

# -----------------------------------------------------------------------------

sub sqlAtomic {
    my $self = shift;
    my $stmt = shift;
    # @_: @opt

    # Öffne neue Datenbankverbindung (darauffolgender Code
    # hängt bei PostgreSQL: wieso?)
    # $self = $self->new;

    my $cur = eval { $self->sql($stmt,@_) };
    if ($@) {
        my $err = $@;
        $self->rollback;
        die $err;
    }
    $self->commit;

    return $cur;
}

# -----------------------------------------------------------------------------

=head2 Sessions

=head3 setSchema() - Setze Default-Schema

=head4 Synopsis

    $cur = $db->setSchema($schema);

=head4 Description

Setze das Default-Schema der Session und liefere das Resultat
der Ausführung zurück.

Das Datenbank-Objekt merkt sich das Default-Schema. Von mehreren
Aufrufen hintereinander mit dem selben Schema, wird nur der
erste Aufruf gegenüber dem DBMS ausgeführt, die anderen sind
Null-Operationen.

=cut

# -----------------------------------------------------------------------------

sub setSchema {
    my ($self,$schema) = @_;

    if (defined $self->{'schema'} && $schema eq $self->{'schema'}) {
        # $schema ist bereits Defaultschema
        return $self->sql;
    }

    my $cur;
    if ($self->isSQLite) {
        # Hack, damit SQLite keinen Transaktionsfehler meldet
        my $stmt = sprintf "ATTACH '%s' AS %s",$self->{'udlObj'}->db,$schema;
        # $self->{'apiObj'}->{'dbh'}->{AutoCommit} = 1;
        $cur = $self->sql($stmt);
        # $self->{'apiObj'}->{'dbh'}->{AutoCommit} = 0;
    }
    else {
        my $stmt = $self->stmt->setSchema($schema);
        $cur = $self->sqlAtomic($stmt);
    }
    $self->{'schema'} = $schema;

    return $cur;
}

# -----------------------------------------------------------------------------

=head3 setEncoding() - Definiere Client-Encoding

=head4 Synopsis

    $cur = $db->setEncoding($charset);

=cut

# -----------------------------------------------------------------------------

sub setEncoding {
    my ($self,$charset) = @_;

    my $stmt = $self->stmt->setEncoding($charset);
    my $cur = $self->sqlAtomic($stmt);

    return $cur;
}

# -----------------------------------------------------------------------------

=head3 setDateFormat() - Setze Default-Datumsformat

=head4 Synopsis

    $cur = $db->setDateFormat;

=cut

# -----------------------------------------------------------------------------

sub setDateFormat {
    my $self = shift;

    my $cur;
    for my $stmt ($self->stmt->setDateFormat) {
        $cur = $self->sqlAtomic($stmt);
    }

    return $cur;
}

# -----------------------------------------------------------------------------

=head3 setNumberFormat() - Setze Default-Zahlenformat

=head4 Synopsis

    $cur = $db->setNumberFormat;

=cut

# -----------------------------------------------------------------------------

sub setNumberFormat {
    my $self = shift;

    my $cur;
    for my $stmt ($self->stmt->setNumberFormat) {
        $cur = $self->sqlAtomic($stmt);
    }

    return $cur;
}

# -----------------------------------------------------------------------------

=head2 Transactions

=head3 begin() - Beginne Transaktion

=head4 Synopsis

    $cur = $db->begin;

=head4 Description

Beginne Transaktion und liefere das Resultat der Ausführung zurück.

=cut

# -----------------------------------------------------------------------------

sub begin {
    my $self = shift;

    my ($oracle,$postgresql,$sqlite,$mysql) = $self->dbmsTestVector;

    # Oracle kennt keinen expliziten Transaktionsbeginn
    # PostgreSQL benötigt keinen expliziten Transaktionsbeginn

    if ($oracle || $postgresql) {
        return $self->sql;
    }

    # SQLite produziert Fehler, wenn Transaktion bereits offen ist.
    # Wir ignorieren den Fehler und liefern einen Pseudo-Cursor.

    my $stmt = $self->stmt->begin;
    my $cur = eval { $self->sql($stmt) };
    if ($self->isSQLite && $@ =~ /within a transaction/i) {
        return $self->sql;
    }
    if ($@) {
        die $@;
    }

    return $cur;
}

# -----------------------------------------------------------------------------

=head3 commit() - Bestätige Datenänderungen

=head4 Synopsis

    $cur = $db->commit;
    $cur = $db->commit($commit);

=head4 Description

Bestätige alle auf der Datenbank durchgeführten Änderungen
und liefere das Resultat der Ausführung zurück.

Wird die Methode mit Argument aufgerufen, entscheidet dessen
Wahrheitswert, ob ein COMMIT oder ein ROLLBACK ausgeführt wird. Im
Falle von "wahr" wird ein COMMIT ausgeführt, im Falle von "falsch"
ein ROLLBACK.

=cut

# -----------------------------------------------------------------------------

sub commit {
    my $self = shift;

    # Führe ROLLBACK aus, wenn $bool "falsch" ist

    if (@_ && !$_[0]) {
        return $self->rollback;
    }

    # SQLite generiert Fehler, wenn COMMIT ohne offene Transaktion
    # ausgeführt wird. Wir ignorieren den Fehler und liefern einen
    # Pseudo-Cursor.

    my $stmt = $self->stmt->commit;
    my $cur = eval { $self->sql($stmt) };
    if ($self->isSQLite && $@ =~ /no transaction/i) {
        return $self->sql;
    }
    if ($@) {
        die $@;
    }

    return $cur;
}

# -----------------------------------------------------------------------------

=head3 rollback() - Verwirf Datenänderungen

=head4 Synopsis

    $cur = $db->rollback;

=head4 Description

Verwirf alle auf der Datenbank durchgeführten Datenänderungen.

=cut

# -----------------------------------------------------------------------------

sub rollback {
    my $self = shift;

    # SQLite generiert Fehler, wenn ROLLBACK ohne offene Transaktion
    # ausgeführt wird. Wir ignorieren den Fehler und liefern einen
    # Pseudo-Cursor.

    my $stmt = $self->stmt->rollback;
    my $cur = eval { $self->sql($stmt) };
    if ($self->isSQLite && $@ =~ /no transaction/i) {
        return $self->sql;
    }
    if ($@) {
        die $@;
    }

    return $cur;
}

# -----------------------------------------------------------------------------

=head3 save() - Aktualisiere Datensatz auf Datenbank

=head4 Synopsis

    $cur = $db->save($table,$row,@where);

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

=item 'D' (zu löschen)

Es wird eine Delete-Operation auf der Datenbank ausgeführt, d.h. es
wird die Methode $row->delete() gerufen.

=back

=cut

# -----------------------------------------------------------------------------

# FIXME: Methode in Quiq::Database::Row::Object::Table auf diese zurückführen?

sub save {
    my $self = shift;
    my $table = shift;
    my $row = shift;
    # @_: @where

    my $cur;
    my $stat = $row->rowStatus;
    if (!$stat) {              # Datensatz wurde selektiert und nicht geändert
        $cur = $self->sql;
    }
    elsif ($stat eq 'I') {     # Datensatz ist neu
        $cur = $self->insert($table,$row);
    }
    elsif ($stat eq 'U') {     # Datensatz wurde modifiziert
        $cur = $self->update($table,$row,@_);
    }
    elsif ($stat eq 'D') {     # Datensatz wurde zum Löschen markiert
        $cur = $self->delete($table,$row,@_);
    }
    else {
        $self->throw(
            'DB-00003: Ungültiger Datensatz-Status',
            RowStatus => $stat,
        );
    }
    $cur->{'rowOperation'} = $stat;

    return $cur;
}

# -----------------------------------------------------------------------------

=head2 Kolumnentitel

=head3 titles() - Liefere Liste der Kolumnentitel

=head4 Synopsis

    $titleA|@titles = $db->titles(@select);

=head4 Description

Ermittele die Liste der Kolumentitel zum Statement @select
und liefere diese zurück. In skalaren Kontext liefere
eine Referenz auf die Liste.

Anmerkung: Die Titelliste wird gecacht. Je Statement wird die Datenbank nur
einmal befragt. Alle weiteren Aufrufe werden aus dem Cache befriedigt.

=cut

# -----------------------------------------------------------------------------

sub titles {
    my $self = shift;
    # @_: @select

    # Wir wollen keine Daten, daher -limit=>0
    my $stmt = $self->stmt->select(-from,@_,-limit=>0);

    my $titleA = $self->{'titleListCache'}->{$stmt};
    unless ($titleA) {
        my $cur = $self->sql($stmt);
        $titleA = $self->{'titleListCache'}->{$stmt} = $cur->titles;
        $cur->close;
    }

    return wantarray? @$titleA: $titleA;
}

# -----------------------------------------------------------------------------

=head3 primaryKey() - Liefere Primärschlüssel-Kolumne

=head4 Synopsis

    $title = $db->primaryKey($table);

=head4 Description

Liefere die Primärschlüsselkolumne der Tabelle $table.

Die Primärschlüsselkolumne ist per Definition die erste Kolumne der
Tabelle. Datenmodelle mit zusammengesetzten Primärschlüsseln werden
nicht unterstützt.

=cut

# -----------------------------------------------------------------------------

sub primaryKey {
    my ($self,$table) = @_;
    return $self->titles($table)->[0];
}

# -----------------------------------------------------------------------------

=head2 Select Operations

=head3 select() - Liefere Liste von Datensätzen

=head4 Synopsis

    $tab|@rows|$cur = $db->select(@select,@opt);

=head4 Options

=over 4

=item -cache => $n

Siehe Quiq::Database::Connection/sql().

=item -chunkSize => $n

Siehe Quiq::Database::Connection/sql().

=item -cursor => $bool (Default: 0)

Siehe Quiq::Database::Connection/sql().

=item -fetchMode => 0|1|2

Siehe Quiq::Database::Connection/sql().

=item -raw => $bool (Default: 0)

Siehe Quiq::Database::Connection/sql().

=item -rowClass => $rowClass

Siehe Quiq::Database::Connection/sql().

=item -tableClass => $tableClass

Siehe Quiq::Database::Connection/sql().

=back

=cut

# -----------------------------------------------------------------------------

sub select {
    my $self = shift;
    # @_: @select,@opt

    # Optionen

    my $cache = undef;
    my $chunkSize = undef;
    my $cursor = 0;
    my $fetchMode = 1;
    my $raw = 0;
    my $rowClass = undef;
    my $tableClass = undef;

    Quiq::Option->extract(-mode=>'sloppy',\@_,
        -cache => \$cache,
        -chunkSize => \$chunkSize,
        -cursor => \$cursor,
        -fetchMode => \$fetchMode,
        -raw => \$raw,
        -rowClass => \$rowClass,
        -tableClass => \$tableClass,
    );

    my $stmt = $self->stmt->select(@_);
    my $cur = $self->sql($stmt,
        -cache => $cache,
        -chunkSize => $chunkSize,
        -fetchMode => $fetchMode,
        -raw => $raw,
        -rowClass => $rowClass,
        -tableClass => $tableClass,
    );
    if ($cursor || $cur->bindVars) {
        return $cur;
    }

    return $cur->fetchAll(1);
}

# -----------------------------------------------------------------------------

=head3 lookup() - Liefere Datensatz

=head4 Synopsis

    $row|@vals = $db->lookup(@select,@opt);

=head4 Options

=over 4

=item -new => $bool (Default: 0)

Liefere einen leeren Neu-Datensatz, wenn der Datensatz
nicht gefunden wird.

=item -raw => $bool (Default: 0)

Liefere Datensatz in Array-Repräsentation

=item -rowClass => $class (Default: 'Quiq::Database::Row::Object')

Default Datensatz-Klasse. Im Falle von -raw=>1 ist
'Quiq::Database::Row::Array' der Default.

=item -sloppy => 0|1|2|3 (default: 0)

=over 4

=item Z<>0

Es muss genau ein Datensatz getroffen werden.

=item Z<>1

Es darf 0 oder 1 Datensatz getroffen werden.

=item Z<>2

Es muss mindestens ein Datensatz getroffen werden.

=item Z<>3

Es dürfen beliebig viele Datensätze getroffen werden.

=back

Wird kein Datensatz getroffen und ist dies erlaubt, wird undef geliefert.
Wird mehr als ein Datensatz getroffen und ist dies erlaubt, wird der
erste geliefert.

=back

=cut

# -----------------------------------------------------------------------------

sub lookup {
    my $self = shift;
    # @_: @select,@opt

    # Optionen

    # -raw bei select()
    # -rowClass bei select()
    my $new = 0;
    my $sloppy = 0;

    Quiq::Option->extract(-mode=>'sloppy',\@_,
        -new => \$new,
        -sloppy => \$sloppy,
    );

    # Operation ausführen

    my $row2;
    # -limit=>2 führt bei Oracle zu falschen Ergebnissen, wenn eine
    # Aggregatfunktion verwendet wird. Denn Oracles ROWNUM limitiert die
    # Ergebnismenge *vor* Anwendung der Aggregatfunktion.
    # my $cur = $self->select(@_,-limit=>2,-cursor=>1);
    my $cur = $self->select(@_,-cursor=>1);
    my $row = $cur->fetch;
    if ($row) {
        $row2 = $cur->fetch;
    }
    my $stmt = $cur->stmt;
    $cur->close;

    if ($row2 && !($sloppy & 2)) {
        $self->throw(
            'DB-00003: Mehr als ein Datensatz gefunden',
            Sql => $stmt,
        );
    }

    unless ($row) {
        if ($new) {
            return $self->nullRow(@_);
        }
        elsif ($sloppy & 1) {
            return;
        }
        $self->throw(
            'DB-00001: Datensatz nicht gefunden',
            Sql => $stmt,
        );
    }

    return wantarray? $row->asArray: $row;
}

# -----------------------------------------------------------------------------

=head3 loadRow() - Lade Datensatz

=head4 Synopsis

    $row = $db->loadRow($table,@keyVal);

=head4 Description

Lade Datensatz mit WHERE-Bedingung @keyVal. Ist @keyVal leer oder
einer der Werte leer, liefere einen Null-Datensatz.

Diese Methode ist nützlich, um ein Formular mit einem neuen
oder existierenden Datensatz zu versorgen.

=cut

# -----------------------------------------------------------------------------

sub loadRow {
    my $self = shift;
    my $table = shift;
    # @_: @keyVal

    if (@_) {
        my $sql = $self->stmt;
        my $lookup = 1;
        for (my $i = 1; $i < @_; $i += 2) {
            if (!$sql->whereExpr($_[$i])) { # evaluiert Wert zu ''?
                $lookup = 0;
                last;
            }
        }
        if ($lookup) {
            return $self->lookup($table,-where,@_);
        }
    }

    return $self->nullRow($table);
}

# -----------------------------------------------------------------------------

=head3 nullRow() - Liefere Null-Datensatz

=head4 Synopsis

    $row = $db->nullRow(@select,@opt);

=head4 Options

=over 4

=item -raw => $bool (Default: 0)

Liefere Datensatz in Array-Repräsentation

=item -rowClass => $class (Default: 'Quiq::Database::Row::Object')

Default Datensatz-Klasse. Im Falle von -raw=>1 ist
'Quiq::Database::Row::Array' der Default.

=back

=head4 Description

Liefere Null-Datensatz zu Select-Statement @select und der
spezifizierten Klasse.

Anmerkung: Die Row-Instantiierung wird gecacht. Je Statement und
Klasse wird beim ersten Aufruf eine Row instantiiert. Bei allen
weiteren Aufrufen wird diese Row kopiert.

=head4 Example

=over 2

=item *

Null-Datensatz einer Tabelle instantiieren

    $per = Quiq::Database::Connection->nullRow('person');

=back

=cut

# -----------------------------------------------------------------------------

sub nullRow {
    my $self = shift;
    # @_: @select,@opt

    my $key = join '|',@_;
    my $row = $self->{'nullRowCache'}->{$key};
    unless ($row) {
        # Optionen

        my $raw = 0;
        my $rowClass = undef;

        Quiq::Option->extract(-mode=>'sloppy',\@_,
            -raw => \$raw,
            -rowClass => \$rowClass,
        );

        unless ($rowClass) {
            $rowClass = $self->defaultRowClass($raw);
        }

        # Operation ausführen

        my $titles = $self->titles(@_);
        $row = $self->{'nullRowCache'}->{$key} = $rowClass->new($titles);
    }

    return $row->copy;
}

# -----------------------------------------------------------------------------

=head3 values() - Liefere Kolumnenwerte als Liste oder Hash

=head4 Synopsis

    @keyVal|%hash|$arr = $db->values(@select);
    $hash = $db->values(@select,-hash=>1);

=head4 Options

=over 4

=item -hash => $bool (Default: 0)

Liefere Hashreferenz.

=back

=head4 Description

Selektiere Kolumnenwerte und liefere sie als Liste oder Hash
zurück. Im Skalarkontext liefere eine Referenz auf die Liste bzw.
den Hash.

=over 2

=item *

Die Select-Liste kann aus ein oder mehreren Kolumnen bestehen.
Bei einer Kolumne wird die Liste der Werte der Kolumne geliefert.
bei mehreren Kolumnen werden die Werte zu einer flachen Liste
vereinigt. Bei zwei, vier, ... Kolumnen, kann das Resultat an einen
Hash zugewiesen werden.

=item *

Soll die Liste nicht alle, sondern nur verschiedene Werte
enthalten, wird C<DISTINCT> selektiert.

=item *

Sollen C<NULL>-Werte nicht berücksichtigt werden, wird der
WHERE-Klausel eine entsprechende C<IS NOT NULL>-Bedingung hinzugefügt.

=item *

Sollen die Werte sortiert geliefert werden, wird dem Statement
eine C<ORDER BY> Klausel hinzugefügt.

=item *

Im Skalarkontext wird ein Objekt der Klasse C<< Quiq::Array >> oder
der Klasse C<< Quiq::Hash >> geliefert. Letzteres, wenn Option
C<< -hash=>1 >> angegeben ist.

=back

=head4 Examples

Alle Werte einer Kolumne (sortiert):

    @arr = $db->values(
        -select => 'per_nachname',
        -from => 'person',
        -orderBy => 1,
    );

Nur verschiedene Werte (sortiert):

    @arr = $db->values(
        -select => 'per_nachname',
        -distinct => 1,
        -from => 'person',
        -orderBy => 1,
    );

Abbildung von Id auf Nachname:

    %hash = $db->values(
        -select => 'per_id','per_nachname',
        -from => 'person',
    );

Dasselbe, nur dass eine Referenz (Hash-Objekt) geliefert wird:

    $hash = $db->values(
        -select => 'per_id','per_nachname',
        -from => 'person',
        -hash => 1,
    );

Lookup-Hash für Nachname:

    $hash = $db->values(
        -select => 'per_nachname',1,
        -from => 'person',
        -hash => 1,
    );

Array mit Paaren:

    @arr = $db->values(
        -select => 'per_id','per_nachname',
        -from => 'person',
    );

Dasselbe, nur dass eine Referenz (Array-Objekt) geliefert wird:

    $arr = $db->values(
        -select => 'per_id','per_nachname',
        -from => 'person',
    );

Array mit Abfolge von Tripeln:

    @arr = $db->values(
        -select => 'per_id','per_nachname','per_vorname',
        -from => 'person',
    );

=cut

# -----------------------------------------------------------------------------

sub values {
    my $self = shift;
    # @_: @select,@opt

    # Optionen

    my $hash = 0;

    Quiq::Option->extract(-mode=>'sloppy',\@_,
        -hash => \$hash,
    );

    # Operation ausführen

    my @arr;
    my $cur = $self->select(@_,-raw=>1,-cursor=>1);
    while (my $row = $cur->fetch) {
        push @arr,@$row;
    }
    $cur->close;

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

=head3 value() - Liefere Wert einer Kolumne eines Datensatzes

=head4 Synopsis

    $val = $db->value(@select,@opt);

=head4 Options

=over 4

=item -sloppy => $bool (Default: 0)

Wirf keine Exception, wenn die Ergebnismenge leer ist, sondern C<undef>.

=item -default => $val (Default: undef)

Wenn auf einen Wert ungleich undef gesetzt, wirf keine Exception,
wenn die Ergebnismenge leer ist, sondern $val.

=back

=head4 Description

Lies den ersten Datensatz der Ergebnismenge und liefere den Wert der
ersten Kolumne zurück.

B<Anmerkungen>

=over 2

=item *

Die Select-Liste des Statement sollte sinnvollerweise aus
einer Kolumne bestehen. Mehr als eine Kolumne ist zulässig,
allerdings ist dies eine Verschwendung von Platz und Zeit, denn
auch wenn mehrere Kolumnen angegeben sind, wird nur der Wert der
ersten geliefert.

=item *

Ist die Ergebnismenge leer, wird eine Exception ausgelöst.

=item *

Es ist kein Fehler, wenn mehr als ein Datensatz getroffen wird.
Es wird allerdings nur der erste Datensatz geliefert.

=back

=cut

# -----------------------------------------------------------------------------

sub value {
    my $self = shift;
    # @_: @select,@opt

    # Optionen

    my $default = undef;

    Quiq::Option->extract(-mode=>'sloppy',\@_,
        -default => \$default,
    );

    # Operation ausführen

    my ($val) = $self->lookup(@_,
        defined $default? (-sloppy=>1): (),
        -raw => 1,
    );

    return defined $val? $val: $default;
}

# -----------------------------------------------------------------------------

=head2 Insert Operations

=head3 insert() - Füge Datensatz zu Tabelle hinzu

=head4 Synopsis

    $cur = $db->insert($table,@opt,$row);
    $cur = $db->insert($table,@opt,@keyVal);
    $cur = $db->insert($table,@opt,\@keys,\@values);

=head4 Options

=over 4

=item -sloppy => $bool (Default: 0)

Ignoriere Doubletten-Fehler.

=back

=head4 Description

Füge Datensatz zu Tabelle $table hinzu und liefere das Resultat
der Ausführung zurück.

=cut

# -----------------------------------------------------------------------------

sub insert {
    my $self = shift;
    my $table = shift;
    # @_:  @opt,$row -or- @opt,@keyVal -or- @opt,\@keys,\@vals

    # Optionen

    my $sloppy = 0;

    Quiq::Option->extract(\@_,
        -sloppy => \$sloppy,
    );

    my $stmt = $self->stmt->insert($table,@_);
    my $cur = eval { $self->sql($stmt) };
    if ($@) {
        if ($sloppy && $@ =~ /DB-00004/) {
            return $self->sql; # liefere Null-Cursor
        }
        die $@;
    }

    return $cur;
}

# -----------------------------------------------------------------------------

=head3 insertRows() - Füge mehrere Datensätze zu Tabelle hinzu

=head4 Synopsis

    $cur = $db->insertRows($table,\@keys,
        [@vals1],
        [@vals2],
        ...
    );
    
    $cur = $db->insertRows($table,\@keys,
        @vals1,
        @vals2,
        ...
    );

=head4 Description

Füge mehrere Datensätze zu Tabelle $table hinzu. Die Datensätze
haben die Kolumnen @keys und die Werte @vals. Die Methode liefert
das Resultat der Ausführung (Cursor) zurück

=head4 Example

=over 2

=item *

Datensätze als Arrays

    $db->insertRows('person',
        [qw/per_id per_vorname per_nachname per_geburtstag/],
        [qw/1 Frank Seitz 31.1.1961/],
        [qw/2 Hanno Seitz 7.4.2000/],
        [qw/3 Linus Seitz 11.11.2002/],
    );

=item *

Datensätze als Abfolge von Werten

    $db->insertRows('person',
        [qw/per_id per_vorname per_nachname per_geburtstag/],
        qw/1 Frank Seitz 31.1.1961/,
        qw/2 Hanno Seitz 7.4.2000/,
        qw/3 Linus Seitz 11.11.2002/,
    );

=back

=cut

# -----------------------------------------------------------------------------

sub insertRows {
    my $self = shift;
    my $table = shift;
    my $keyA = shift;
    # @_: @data

    return $self->insert($table,$keyA,[(\'?') x @$keyA])->bind(@_);
}

# -----------------------------------------------------------------------------

=head2 Update Operation

=head3 update() - Aktualisiere Datensätze

=head4 Synopsis

    $cur = $db->update($table,$row); [1]
    $cur = $db->update($table,$row,@where); [2]
    $cur = $db->update($table,@keyVal,-where,@where); # [3]

=head4 Description

[1] Aktualisiere Datensatz $row und liefere das Resultat
der Ausführung zurück. Als Where-Bedingung wird der Name/Wert
der ersten Kolumne von Tabelle $table genommen.

[2] Wie [1], nur dass die Where-Bedingung explizit angegeben ist.

[2] Aktualisiere 0, einen oder mehrere Datensatze in Tabelle $table
und liefere das Resultat der Ausführung zurück.

=cut

# -----------------------------------------------------------------------------

sub update {
    my $self = shift;
    my $table = shift;
    # @_: $row,@where -or- @keyVal,-where,@where

    if (ref $_[0]) {
        my $row = shift;
        # @_: @where

        unless (@_) {
            my $key = $self->titles($table)->[0];
            push @_,$key=>$row->$key;
        }

        #!! FIXME: Wenn keine Where-Bedingung angegeben ist, versuchen,
        #!!    Primärschlüssel zu ermitteln

        #unless (@_) {
        #    $self->throw(
        #        'DB-00002: Keine WHERE-Bedingung für Datensatz-Update',
        #        Table => $table,
        #        Row => $row->asString('|'),
        #    );
        #}

        my @keyVal;
        for my $key ($row->titles) {
            push @keyVal,$key,$row->$key;
        }
        unshift @_,@keyVal,-where;
    }

    my $stmt = $self->stmt->update($table,@_);
    return $self->sql($stmt);
}

# -----------------------------------------------------------------------------

=head2 Delete Operation

=head3 delete() - Lösche Datensatz bzw. Datensätze aus Tabelle

=head4 Synopsis

    $cur = $db->delete($table,$row,@where);
    $cur = $db->delete($table,@where);

=head4 Description

Lösche Datensatz bzw. Datensätze aus Tabelle $table und liefere
das Resultat der Ausführung zurück.

=cut

# -----------------------------------------------------------------------------

sub delete {
    my $self = shift;
    my $table = shift;
    # @_: $row,@where -or- @where

    if (ref $_[0]) {
        my $row = shift;
        # @_: @where

        # FIXME: Wenn keine Where-Bedingung angegeben ist, versuchen,
        #    Primärschlüssel zu ermitteln

        unless (@_) {
            $self->throw(
                'DB-00002: Keine WHERE-Bedingung für Datensatz-Delete',
                Table => $table,
                Row => $row->asString('|'),
            );
        }
    }

    my $stmt = $self->stmt->delete($table,'+null',@_);
    return $self->sql($stmt);
}

# -----------------------------------------------------------------------------

=head2 Schemas

=head3 schemas() - Liste der Schemata

=head4 Synopsis

    @schemas | $schemaA = $db->schemas(@opt);
    %schemas | $schemaH = $db->schemas(-hash=>1,@opt);

=head4 Options

=over 4

=item -cache => $bool (Default: 1)

Cache die Liste.

=item -hash => $bool (Default: 0)

Liefere einen Hash mit den Schemanamen als Schlüssel und 1 als Wert.

=back

=head4 Returns

=over 4

=item @schemas, $schemaA

Liste der Schemanamen (Liste von Strings) oder eine Referenz auf
die Liste.

=item %schemas, $schemaH

Hash der Schemanamen oder eine Referenz auf den Hash. Der Hashwert ist 1.

=back

=head4 Description

Ermittele die Schemata der Datenbank und liefere die Liste
oder den Hash der Namen zurück.

=cut

# -----------------------------------------------------------------------------

sub schemas {
    my $self = shift;

    # Optionen

    my $cache = 1;
    my $hash = 0;

    Quiq::Parameters->extractToVariables(\@_,0,0,
        -cache => \$cache,
        -hash => \$hash,
    );

    state $schemaA;
    if (!$schemaA || !$cache) {
        if ($self->isPostgreSQL) {
            $schemaA = $self->values(
                -select => 'nspname',
                -from => 'pg_namespace',
                -orderBy => 1,
            );
        }
        else {
            $self->throw;
        }
    }

    if ($hash) {
        return Quiq::Array->toHash($schemaA);
    }

    return wantarray? @$schemaA: $schemaA;
}

# -----------------------------------------------------------------------------

=head2 Tables

=head3 createTable() - Erzeuge Tabelle

=head4 Synopsis

    $cur = $db->createTable($table,
        [$colName,@colOpts],
        ...
        @opt,
    );

=head4 Options

=over 4

=item -replace => $bool (Default: 0)

Erzeuge Tabelle neu, falls sie bereits existiert.

=item -sloppy => $bool (Default: 0)

Erzeuge Tabelle nicht, falls sie bereits existiert.

=back

=head4 Description

Erzeuge Tabelle $table auf der Datenbank.

=cut

# -----------------------------------------------------------------------------

sub createTable {
    my $self = shift;
    my $table = shift;
    # @_: @cols,@opt

    # Optionen

    my $replace = 0;
    my $sloppy = 0;

    Quiq::Option->extract(-mode=>'sloppy',\@_,
        -reCreate => \$replace, # Rückwärtskompatibilität
        -recreate => \$replace, # Rückwärtskompatibilität
        -replace => \$replace,
        -sloppy => \$sloppy,
    );

    # Tabelle droppen

    if ($replace) {
        $self->dropTable($table);
    }

    # Keine Tabellenerzeugung, wenn Tabelle bereits existiert

    if ($sloppy && $self->tableExists($table)) {
        return $self->sql;
    }

    # Tabelle erzeugen

    my $stmt = $self->stmt->createTable($table,@_);
    my $cur = $self->sqlAtomic($stmt);

    return $cur;
}

# -----------------------------------------------------------------------------

=head3 dropTable() - Lösche Tabelle

=head4 Synopsis

    $cur = $db->dropTable($table);

=head4 Description

Lösche die Tabelle $table (name mit oder ohne
Schemaanteil) von der Datenbank $db und liefere das Resultat-Objekt
der Statementausführung zurück.

Es wird vorab geprüft, ob die Tabelle existiert. Ist dies nicht
der Fall, wird keine Löschung versucht und ein Null-Cursor
zurückgeliefert.

Wird die Tabelle erfolgreich gedroppt, führt die Methode ein COMMIT
durch. Schlägt dies fehl, führt sie ein ROLLBACK durch.
Dies ist für PostgreSQL und SQLite notwendig.

=cut

# -----------------------------------------------------------------------------

sub dropTable {
    my $self = shift;
    my $table = shift;

    # Wenn zu droppende Tabelle nicht existiert, brauchen wir nichts
    # tun und liefern einen Null-Cursor.

    unless ($self->tableExists($table)) {
        return $self->sql;
    }

    my $stmt = $self->stmt->dropTable($table);
    my $cur = $self->sqlAtomic($stmt);

    return $cur;
}

# -----------------------------------------------------------------------------

=head3 tableExists() - Prüfe, ob Tabelle existiert

=head4 Synopsis

    $bool = $db->tableExists($table);

=head4 Description

Prüfe, ob Tabelle $table existiert. Wenn ja, liefere "wahr",
sonst "falsch".

=cut

# -----------------------------------------------------------------------------

sub tableExists {
    my ($self,$table) = @_;

    # Wir öffnen im Falle von PostgreSQL ein parallele Verbindung,
    # damit der Statement-Fehler im Falle einer nicht-exitierenden
    # Tabelle die aktuelle Transaction nicht stört

    if ($self->isMySQL) {
        my ($row) = $self->select("SHOW TABLES LIKE '$table'");
        return $row? 1: 0;
    }
    elsif ($self->isPostgreSQL) {
        $self = $self->new;
    }

    local $@;
    my $stmt = $self->stmt->select(
        -select => 0,
        -from => $table,
        -limit => 0,
    );
    eval { $self->sql($stmt) };
    return $@? 0: 1;
}

# -----------------------------------------------------------------------------

=head3 analyzeTable() - Analysiere Tabelle

=head4 Synopsis

    $db->analyzeTable($table);

=head4 Description

Analysiere Tabelle $table und liefere einen Cursor zurück.

=cut

# -----------------------------------------------------------------------------

sub analyzeTable {
    my ($self,$table) = @_;
    my $stmt = $self->stmt->analyzeTable($table);
    return $self->sql($stmt);
}

# -----------------------------------------------------------------------------

=head3 addForeignKeyConstraint() - Füge FOREIGN KEY Constraint zu Tabelle hinzu

=head4 Synopsis

    $cur = $db->addForeignKeyConstraint($tableName,\@tableCols,
        $refTableName,@opt);

=head4 Description

Siehe Quiq::Sql::addForeignKeyConstraint()

=cut

# -----------------------------------------------------------------------------

sub addForeignKeyConstraint {
    my $self = shift;
    # @_: Argumente
    my $stmt = $self->stmt->addForeignKeyConstraint(@_);
    return $self->sql($stmt);
}

# -----------------------------------------------------------------------------

=head3 countRows() - Zähle die Anzahl der Datensätze in der Tabelle

=head4 Synopsis

    $n = $db->countRows($tableName);

=cut

# -----------------------------------------------------------------------------

sub countRows {
    my ($self,$table) = @_;
    $table = $self->stmt->legalizeTablename($table);
    return $self->value($table,-select=>'COUNT(*)');
}

# -----------------------------------------------------------------------------

=head3 tableDiff() - Daten-Differenzen zwischen zwei Tabellen

=head4 Synopsis

    $tab = $db->tableDiff($table1,$table2,@opt);

=head4 Arguments

=over 4

=item $table1

Tabellenname, mit oder ohne Schema-Präfix.

=item $table2

Tabellenname, mit oder ohne Schema-Präfix.

=back

=head4 Options

Im folgenden ist @titles ein Array von Kolumnennamen und $titles
eine kommaseparierte Liste von Kolumnennamen.

=over 4

=item -columns => \@titles | $titles (Default: I<Kolumnen Tabelle 1>)

Kolumnen, die verglichen werden.

=item -ignoreColumns => \@titles | $titles

Kolumnen, die ignoriert werden. Diese Option ist nützlich, wenn
alle Kolumnen verglichen werden sollen, bis auf die mit dieser
Option genannten.

=item -limit => $n (Default: 10)

Begrenze die Größe der beiden Differenzmengen (s.u.) auf jeweils N Zeilen.
D.h. es werden maximal 2 * N Zeilen geliefert. Darüber hinausgehende
Differenzen werden nicht berücksichtigt. Limit 0 bedeutet, es
gibt keine Begrenzung.

=item -sortColumns => \@titles | $titles (Default: I<Kolumnen>)

Kolumnen, nach denen die Gesamt-Differenzliste sortiert wird.

=back

=head4 Description

Die Methode untersucht zwei strukturell identische Tabellen hinsichtlich
etwaig vorhandener Daten-Differenzen. Sie tut dies mittels SQL und ist
dadurch auch auf großen Datenmengen sehr schnell. Der Vergleich
geschieht durch die Bildung der zwei Differenzmengen

    -- Alle Zeilen in Tabelle 1, die nicht in Tabelle 2 vorkommen
    
    SELECT
        COLUMNS1
    FROM
        TABLE1
    EXCEPT
    SELECT
        COLUMNS2
    FROM
        TABLE2
    ORDER BY
        COLUMNS1

und

    -- Alle Zeilen in Tabelle 2, die nicht in Tabelle 1 vorkommen
    
    SELECT
        COLUMNS2
    FROM
        TABLE2
    EXCEPT
    SELECT
        COLUMNS1
    FROM
        TABLE1
    ORDER BY
        COLUMNS2

Sind beide Differenzmengen leer, sind die Tabellen identisch.

Die beiden Differenzmengen werden in einer Ergebnismenge zusammengefasst
und als ResultSet-Objekt zurückgeliefert. Die Herkunft einer Row wird
durch das Zeilenattribut sourceTable angezeigt. Tabelle 1 wird mit 'A'
bezeichnet, Tabelle 2 mit 'B'.

=head4 Example

Vergleich der Tabelle q68t999 in den Schemata xv882js und xv882js_test_01
über das Programm quiq-db-table-diff, das ein Frontend zur Methode
tableDiff() darstellt:

    $ quiq-db-table-diff dbi#postgresql:dsstest%xv882js:*@tdca.ruv.de:5432 xv882js.q68t999 xv882js_test_01.q68t999
     1 sourceTable
     2 pgmname
     3 tabname
     4 jobname
     5 anz_ins
     6 anz_upd
     7 anz_del
     8 upd_dat
     9 status
    10 runtime
    
    1   2                 3         4   5          6   7    8                            9   10
    | A | xv882js_160538  | q68t340 |   | 37806420 | 0 | -1 | 2019-04-25 09:30:12.034297 |   | 2019-04-25 09:29:51 |
    | B | xv882js_2285224 | q68t340 |   | 37806420 | 0 | -1 | 2019-04-25 09:33:33.987502 |   | 2019-04-25 09:33:11 |
    
    2 rows

=cut

# -----------------------------------------------------------------------------

sub tableDiff {
    my $self = shift;

    # Optionen und Argumente

    my $columns = undef;
    my $ignoreColumns = undef;
    my $limit = 10;
    my $sortColumns = undef;

    my $argA = Quiq::Parameters->extractToVariables(\@_,2,2,
        -columns => \$columns,
        -ignoreColumns => \$ignoreColumns,
        -limit => \$limit,
        -sortColumns => \$sortColumns,
    );
    my ($table1,$table2) = @$argA;

    # Select-Kolumnen

    my @columns;
    if (ref $columns) {
        @columns = @$columns;
    }
    elsif ($columns) {
        @columns = split /\s*,\s*/,$columns;
    }
    else {
        @columns = $self->titles($table1);
    }

    # Ignore-Kolumnen

    my @ignoreColumns;
    if (ref $ignoreColumns) {
        @ignoreColumns = @$ignoreColumns;
    }
    elsif ($ignoreColumns) {
        for my $ignoreTitle (split /\s*,\s*/,$ignoreColumns) {
            for (my $i = 0; $i < @columns; $i++) {
                if ($ignoreTitle eq $columns[$i]) {
                    splice @columns,$i--,1;
                }
            }
        }
    }

    # Sortier-Kolumnen

    my @sortColumns;
    if (ref $sortColumns) {
        @sortColumns = @$sortColumns;
    }
    elsif ($sortColumns) {
        @sortColumns = split /\s*,\s*/,$sortColumns;
    }
    else {
       @sortColumns = @columns;
    }

    # Differenzen ermitteln

    my @rows; # Differierende Kolumnen aus beiden Mengen

    # TABLE1 EXCEPT TABLE2

    my $sql = $self->stmt;
    my $stmt = $sql->select("
        SELECT
            __TITLES1__
        FROM
            __TABLE1__
        EXCEPT
        SELECT
            __TITLES2__
        FROM
            __TABLE2__
        ORDER BY
            __TITLES1__
        ",
        -args =>
            TABLE1 => $table1,
            TITLES1 => join(', ',@columns),
            TABLE2 => $table2,
            TITLES2 => join(', ',@columns),
    );

    my $i = 0;
    my $cur = $self->sql($stmt);
    while (my $row = $cur->fetch) {
        if ($limit && $i++ > $limit) {
            last;
        }
        $row->add(sourceTable=>'A');
        push @rows,$row;
    }
    $cur->close;

    # TABLE2 EXCEPT TABLE1

    $stmt = $sql->select("
        SELECT
            __TITLES2__
        FROM
            __TABLE2__
        EXCEPT
        SELECT
            __TITLES1__
        FROM
            __TABLE1__
        ORDER BY
            __TITLES2__
        ",
        -args =>
            TABLE1 => $table1,
            TITLES1 => join(', ',@columns),
            TABLE2 => $table2,
            TITLES2 => join(', ',@columns),
    );

    $i = 0;
    $cur = $self->sql($stmt);
    while (my $row = $cur->fetch) {
        if ($limit && $i++ > $limit) {
            last;
        }
        $row->add(sourceTable=>'B');
        push @rows,$row;
    }
    $cur->close;

    # Zeilen beider Differenzmengen gemäß @sortColumns sortieren

    my $sub = sub ($$) {
        my ($a,$b) = @_;
        my $sort = 0;
        for my $title (@sortColumns) {
            if ($sort = $a->$title cmp $b->$title) {
                last;
            }
        }
        return $sort || $a->sourceTable cmp $b->sourceTable;
    };
    @rows = sort $sub @rows;

    unshift @columns,'sourceTable';
    return Quiq::Database::ResultSet->new(\@columns,\@rows);
}

# -----------------------------------------------------------------------------

=head3 doublets() - Dubletten in einer Tabelle

=head4 Synopsis

    $tab = $db->doublets($table,@opt);

=head4 Arguments

=over 4

=item $table

Tabellenname, mit oder ohne Schema-Präfix.

=back

=head4 Options

Im folgenden ist @titles ein Array von Kolumnennamen und $titles
eine kommaseparierte Liste von Kolumnennamen.

=over 4

=item -columns => \@titles | $titles (Default: I<Alle Kolumnen der Tabelle>)

Kolumnen, die auf Dubletten hin untersucht werden.

=item -ignoreColumns => \@titles | $titles

Kolumnen, die ignoriert werden. Diese Option ist nützlich, wenn
alle Kolumnen betrachtet werden sollen, bis auf die mit dieser
Option genannten.

=item -limit => $n (Default: 10)

Begrenze die Anzahl der gemeldeten Dubletten.

=item -sortColumns => \@titles | $titles (Default: I<Kolumnen>)

Kolumnen, nach denen die Gesamt-Differenzliste sortiert wird.

=back

=head4 Returns

Ergebnismengen-Objekt (Quiq::ResultSet::Object)

=head4 Description

Suche Dubletten in der Tabelle $table und liefere ein Ergebnisobjekt
mit den Treffern zurück.

=head4 Example

    $  perl -MQuiq::Database::Connection -E 'print Quiq::Database::Connection\
         ->new("dbi#postgresql:dsstest%xv882js:*\@tdca.ruv.de:5432")\
         ->doublets("dss_meta.cpm_load_objects",-columns=>"load_object,\
         target_object",-limit=>10)->asTable'

=cut

# -----------------------------------------------------------------------------

sub doublets {
    my $self = shift;

    # Optionen und Argumente

    my $columns = undef;
    my $ignoreColumns = undef;
    my $limit = 10;
    my $sortColumns = undef;

    my $argA = Quiq::Parameters->extractToVariables(\@_,1,1,
        -columns => \$columns,
        -ignoreColumns => \$ignoreColumns,
        -limit => \$limit,
        -sortColumns => \$sortColumns,
    );
    my ($table) = @$argA;

    # Select-Kolumnen

    my @columns;
    if (ref $columns) {
        @columns = @$columns;
    }
    elsif ($columns) {
        @columns = split /\s*,\s*/,$columns;
    }
    else {
        @columns = $self->titles($table);
    }

    # Ignore-Kolumnen

    my @ignoreColumns;
    if (ref $ignoreColumns) {
        @ignoreColumns = @$ignoreColumns;
    }
    elsif ($ignoreColumns) {
        for my $ignoreTitle (split /\s*,\s*/,$ignoreColumns) {
            for (my $i = 0; $i < @columns; $i++) {
                if ($ignoreTitle eq $columns[$i]) {
                    splice @columns,$i--,1;
                }
            }
        }
    }

    # Sortier-Kolumnen

    my @sortColumns;
    if (ref $sortColumns) {
        @sortColumns = @$sortColumns;
    }
    elsif ($sortColumns) {
        @sortColumns = split /\s*,\s*/,$sortColumns;
    }
    else {
       @sortColumns = @columns;
    }

    # Dubletten ermitteln

    return $self->select(
        -select => @columns,'COUNT(1)',
        -from => $table,
        -groupBy => @columns,
        -having => 'COUNT(1) > 1',
        -orderBy => @sortColumns,
        -limit => $limit,
    );
}

# -----------------------------------------------------------------------------

=head2 Columns

=head3 columnExists() - Prüfe, ob Kolumne existiert

=head4 Synopsis

    $cur = $db->columnExists($table,$column);

=head4 Description

Prüfe, ob Kolumne existiert. Wenn ja, liefere "wahr", sonst "falsch".

=cut

# -----------------------------------------------------------------------------

sub columnExists {
    my ($self,$table,$column) = @_;

    # Wir öffnen im Falle von PostgreSQL ein parallele Verbindung,
    # damit der Statement-Fehler bei einer nicht-exitierenden
    # Kolumne die aktuelle Transaction nicht stört

    if ($self->isPostgreSQL) {
        $self = $self->new;
    }

    local $@;
    my $stmt = $self->stmt->select(
        -select => $column,
        -from => $table,
        -limit => 0,
    );
    eval { $self->sql($stmt) };
    return $@? 0: 1;
}

# -----------------------------------------------------------------------------

=head3 addColumn() - Füge Kolumne zu Tabelle hinzu

=head4 Synopsis

    $cur = $db->addColumn($table,$column,@colDef,@opt);

=head4 Options

=over 4

=item -sloppy => $bool (Default: 0)

Wirf keine Exception, wenn die Kolumne bereits existiert, sondern
liefere undef.

=back

=head4 Example

    $cur = $db->addColumn('person','mag_eis',
        type => 'STRING(1)',
        notNull => 1,
        default => 1,
    );

=cut

# -----------------------------------------------------------------------------

sub addColumn {
    my $self = shift;
    # @_: $table,$column,@colDef

    # Optionen

    my $sloppy = 0;

    Quiq::Option->extract(-mode=>'sloppy',\@_,
        -sloppy => \$sloppy,
    );

    # Statement ausführen

    my $stmt = $self->stmt->addColumn(@_);
    my $cur = eval { $self->sqlAtomic($stmt) };
    if ($@) {
        if ($sloppy &&
                $@ =~ /ORA-01430|PGSQL-00007|SQLITE-00001|MYSQL-01060/) {
            return undef;
        }
        die $@;
    }

    return $cur;
}

# -----------------------------------------------------------------------------

=head3 dropColumn() - Entferne Kolumne aus Tabelle

=head4 Synopsis

    $cur = $db->dropColumn($table,$column);

=head4 Description

Entferne Kolumne $column aus Tabelle $table und liefere das
Resultat der Statement-Ausführung zurück.

Es ist kein Fehler, wenn die Kolumne nicht existiert. In dem Fall
wird undef geliefert.

=cut

# -----------------------------------------------------------------------------

sub dropColumn {
    my ($self,$table,$column) = @_;

    # Statement ausführen

    my $stmt = $self->stmt->dropColumn($table,$column);
    my $cur = eval { $self->sqlAtomic($stmt) };
    if ($@) {
        if ($@ =~ /ORA-00904|PGSQL-00007|SQLITE-00001|MYSQL-01091/) {
            return undef;
        }
        die $@;
    }

    return $cur;
}

# -----------------------------------------------------------------------------

=head3 modifyColumn() - Modifiziere Kolumne

=head4 Synopsis

    $cur = $db->modifyColumn($table,$column,$property=>$value);

=head4 Description

Modifiziere Kolumne $column in Tabelle $table und liefere das
Resultat der Statement-Ausführung zurück.

=cut

# -----------------------------------------------------------------------------

sub modifyColumn {
    my $self = shift;
    # @_: $table,$column,$property,$value

    # Statement ausführen

    my $stmt = $self->stmt->modifyColumn(@_);
    return $self->sqlAtomic($stmt);
}

# -----------------------------------------------------------------------------

=head3 renameColumn() - Benenne Kolumne um

=head4 Synopsis

    $cur = $db->renameColumn($table,$oldName,$newName;

=head4 Description

Benenne Tabelle $table die Kolumne $oldName in $newName um und
liefere das Resultat der Statement-Ausführung zurück.

=cut

# -----------------------------------------------------------------------------

sub renameColumn {
    my $self = shift;
    # @_: $table,$oldName,$newName

    # Statement ausführen

    my $stmt = $self->stmt->renameColumn(@_);
    return $self->sqlAtomic($stmt);
}

# -----------------------------------------------------------------------------

=head3 distinctValues() - Liefere die Anzahl der unterschiedlichen Werte

=head4 Synopsis

    $n = $db->distinctValues($table,$column);

=cut

# -----------------------------------------------------------------------------

sub distinctValues {
    my ($self,$table,$column) = @_;
    $table = $self->stmt->legalizeTablename($table);
    return $self->value($table,-select=>"COUNT(DISTINCT $column)");
}

# -----------------------------------------------------------------------------

=head3 minValue() - Liefere den kleinsten Kolumnenwert

=head4 Synopsis

    $val = $db->minValue($table,$column);

=cut

# -----------------------------------------------------------------------------

sub minValue {
    my ($self,$table,$column) = @_;
    $table = $self->stmt->legalizeTablename($table);
    return $self->value($table,-select=>"MIN($column)");
}

# -----------------------------------------------------------------------------

=head3 maxValue() - Liefere den größten Kolumnenwert

=head4 Synopsis

    $val = $db->maxValue($table,$column);

=cut

# -----------------------------------------------------------------------------

sub maxValue {
    my ($self,$table,$column) = @_;
    return $self->value($table,-select=>"MAX($column)");
}

# -----------------------------------------------------------------------------

=head3 countDistinctMinMax() - Liefere Count/Count Distinct/Min/Max

=head4 Synopsis

    ($count,$distinctCount,$min,$max) = $db->countDistinctMinMax($table,$column);

=head4 Description

Die Methode liefert Information über den Inhalt einer Tabellenkolumne.
Sie ist für das Reverse Engineering einer unbekannte Datenbanktabelle
nützlich.

=cut

# -----------------------------------------------------------------------------

sub countDistinctMinMax {
    my ($self,$table,$column) = @_;

    $table = $self->stmt->legalizeTablename($table);
    return $self->lookup(
        -select => "COUNT($column)","COUNT(DISTINCT $column)",
            "MIN($column)","MAX($column)",
        -from => $table,
        -raw => 1,
    );
}

# -----------------------------------------------------------------------------

=head2 Indexes

=head3 indexExists() - Prüfe, ob Index existiert

=head4 Synopsis

    $bool = $db->indexExists($table,\@colNames);

=head4 Description

Prüfe, ob Index existiert. Wenn ja, liefere "wahr", sonst "falsch".

=cut

# -----------------------------------------------------------------------------

sub indexExists {
    my $self = shift;
    my $tableName = shift;
    my $colNameA = shift;

    my $indexName = $self->stmt->indexName($tableName,$colNameA);

    #!! FIXME: Methode indexName() implementieren
    #
    #my ($table) = $self->stmt->splitObjectName($tableName);
    #my $indexName = lc $table.'_IX_'.join('_',@$colNameA);
    #$self->stmt->checkName(\$indexName);

    my $row;
    if ($self->isPostgreSQL) {
        ($row) = $self->lookup(
            -from => 'pg_class',
            -where,relname => $indexName,
                relkind => 'i',
            -raw => 1,
            -sloppy => 1,
        );
    }
    else {
        $self->throw('Not implemented');
    }

    return $row? 1: 0;
}

# -----------------------------------------------------------------------------

=head3 createIndex() - Erzeuge Index

=head4 Synopsis

    $cur = $db->createIndex($table,\@colNames,@opt);

=head4 Options

=over 4

=item -indexName => $str (Default: <TABLE>_ix_<COLUMNS>)

Name des Index.

=item -reCreate => $bool (Default: 0)

Erzeuge Index neu, falls er bereits existiert.

=item -tableSpace => $tableSpaceName (Default: keiner)

Name des Tablespace, in dem der Index erzeugt wird
(Oracle und PostgreSQL).

=item -unique => $bool (Default: 0)

Statement für Unique Index.

=back

=head4 Description

Erzeuge Index für Tabelle $table und Kolumnen @colNames auf der Datenbank.

=cut

# -----------------------------------------------------------------------------

sub createIndex {
    my $self = shift;
    my $tableName = shift;
    my $colNameA = shift;
    # @_: @opt

    # Optionen

    my $indexName = undef;
    my $reCreate = 0;
    my $tableSpace = undef;
    my $unique = 0;

    if (@_) {
        Quiq::Option->extract(\@_,
             -indexName => \$indexName,
             -reCreate => \$reCreate,
             -tableSpace => \$tableSpace,
             -unique => \$unique,
        );
    }

    # Index droppen

    if ($reCreate) {
        $self->dropIndex($tableName,$colNameA);
    }

    # Index erzeugen

    my $stmt = $self->stmt->createIndex($tableName,$colNameA,
        -indexName => $indexName,
        -tableSpace => $tableSpace,
        -unique => $unique,
    );

    return $self->sqlAtomic($stmt,@_);
}

# -----------------------------------------------------------------------------

=head3 createUniqueIndex() - Erzeuge Unique Index

=head4 Synopsis

    $cur = $db->createUniqueIndex($table,\@colNames,@opt);

=head4 Options

Siehe $db->createIndex()

=head4 Description

Erzeuge Unique Index für Tabelle $table und Kolumnen @colNames
auf der Datenbank.

=cut

# -----------------------------------------------------------------------------

sub createUniqueIndex {
    my $self = shift;
    my $tableName = shift;
    my $colNameA = shift;
    # @_: @opt

    return $self->createIndex($tableName,$colNameA,-unique=>1,@_);
}

# -----------------------------------------------------------------------------

=head3 dropIndex() - Droppe Index

=head4 Synopsis

    $cur = $db->dropIndex($table,\@colNames);

=cut

# -----------------------------------------------------------------------------

sub dropIndex {
    my $self = shift;
    my $tableName = shift;
    my $colNameA = shift;

    # Index droppen

    my $stmt = $self->stmt->dropIndex($tableName,$colNameA);
    return $self->sqlAtomic($stmt);
}

# -----------------------------------------------------------------------------

=head2 Sequences

=head3 createSequence() - Erzeuge Sequenz

=head4 Synopsis

    $db->createSequence($name,@opt);

=head4 Options

=over 4

=item -reCreate => $bool (Default: 0)

Droppe Sequenz, falls sie bereits existiert.

=item -startWith => $n (Default: 1)

Die Sequenz beginnt mit Startwert $n.

=back

=head4 Description

Erzeuge Sequenz $name auf Datenbank $db. Die Methode liefert
keinen Wert zurück.

Unter Oracle und PostgreSQL, die das Konzept der Sequenz haben,
wird eine normale Sequenz auf der Datenbank erzeugt.

Unter MySQL und SQLite, die das Konzept der Sequenz nicht haben,
wird eine Tabelle mit Autoinkrement-Kolumne zur Simulation einer
Sequenz erzeugt.

=cut

# -----------------------------------------------------------------------------

sub createSequence {
    my $self = shift;
    my $name = shift;

    # Optionen

    my $reCreate = 0;
    my $startWith = 1;

    if (@_) {
        Quiq::Option->extract(\@_,
            -reCreate => \$reCreate,
            -startWith => \$startWith,
        );
    }

    # Sequenz droppen (Fehler ignorieren, falls sie nicht existiert)

    if ($reCreate) {
        eval { $self->dropSequence($name) };
    }

    # Sequenz erzeugen

    my @stmt = $self->stmt->createSequence($name,-startWith=>$startWith);
    for my $stmt (@stmt) {
        $self->sqlAtomic($stmt);
    }

    return;
}

# -----------------------------------------------------------------------------

=head3 dropSequence() - Droppe Sequenz

=head4 Synopsis

    $cur = $db->dropSequence($name);

=head4 Description

Droppe Sequenz $name und liefere das Resultat der Statementausführung
zurück.

=cut

# -----------------------------------------------------------------------------

sub dropSequence {
    my $self = shift;
    my $name = shift;

    my ($oracle,$postgresql,$sqlite,$mysql) = $self->dbmsTestVector;

    # Sequenz droppen

    my $cur;
    if ($oracle || $postgresql) {
        my $stmt = $self->stmt->dropSequence($name);
        $cur = $self->sqlAtomic($stmt);
    }
    elsif ($mysql || $sqlite) {
        $cur = $self->dropTable($name);
    }

    return $cur;
}

# -----------------------------------------------------------------------------

=head3 setSequence() - Setze Sequenz auf neuen Startwert

=head4 Synopsis

    $db->setSequence($sequence,$n);

=head4 Description

Setze Sequenz $sequence auf Wert $n. Die Methode liefert keinen
Wert zurück.

=cut

# -----------------------------------------------------------------------------

sub setSequence {
    my ($self,$name,$n) = @_;

    # Sequenz setzen

    my @stmt = $self->stmt->setSequence($name,$n);
    for my $stmt (@stmt) {
        $self->sql($stmt);
    }

    return;
}

# -----------------------------------------------------------------------------

=head3 nextValue() - Liefere nächsten Sequenzwert

=head4 Synopsis

    $n = $db->nextValue($sequence);

=head4 Description

Ermittele den nächsten Sequenzwert der Sequenz $sequence
und liefere diesen zurück.

Unter Oracle und PostgreSQL wird die betreffende Sequenz befragt.

Unter MySQL und SQLite wird ein leerer Datensatz in die
Sequenz-Tabelle eingefügt und dessen automatisch generierter
Primärschlüsselwert ermittelt. Um die Sequenz-Tabelle nicht beliebig
anwachsen zu lassen, wird die Tabelle alle 100 Werte (d.h. wenn
$n % 100 == 0) bereinigt: alle Datensätze mit einem kleineren Wert als $n
werden gelöscht.

=cut

# -----------------------------------------------------------------------------

sub nextValue {
    my ($self,$name) = @_;

    my ($oracle,$postgresql,$sqlite,$mysql) = $self->dbmsTestVector;

    # Operation ausführen

    my $n;
    if ($oracle || $postgresql) {
        my $stmt;
        if ($oracle) {
            $stmt = "SELECT $name.nextval n FROM dual";
        }
        elsif ($postgresql) {
            $stmt = "SELECT nextval('$name') AS n";
        }
        # FIXME: auf lookupValue() umstellen
        $n = $self->sql($stmt)->fetch->n;
    }
    elsif ($mysql || $sqlite) {
        $n = $self->insert($name,n=>\'NULL')->id;
        if ($n % 100 == 0) {
            # Tabelle bereinigen
            $self->sql("DELETE FROM $name WHERE n < $n");
        }
    }
    else {
        # FIXME
        die;
    }

    return $n;
}

# -----------------------------------------------------------------------------

=head2 Views

=head3 createView() - Erzeuge View

=head4 Synopsis

    $cur = $db->createView($viewName,$selectStmt,@opt);

=head4 Options

=over 4

=item -reCreate => $bool (Default: 0)

Erzeuge View neu, falls sie bereits existiert.

=back

=cut

# -----------------------------------------------------------------------------

sub createView {
    my $self = shift;
    my $viewName = shift;
    my $selectStmt = shift;
    # @_: @opt

    # Optionen

    my $reCreate = 0;

    Quiq::Option->extract(-mode=>'sloppy',\@_,
        -reCreate => \$reCreate,
    );

    # View droppen

    if ($reCreate) {
        $self->dropView($viewName);
    }

    # View erzeugen

    my $stmt = $self->stmt->createView($viewName,$selectStmt);
    my $cur = $self->sqlAtomic($stmt,-fetchMode=>0); # kein Cursor bei PG

    return $cur;
}

# -----------------------------------------------------------------------------

=head3 dropView() - Lösche View

=head4 Synopsis

    $cur = $db->dropView($viewName);

=head4 Description

Lösche die View $viewName von der Datenbank $db und liefere das
Resultat-Objekt der Statementausführung zurück.

Es wird vorab geprüft, ob die View existiert. Ist dies nicht
der Fall, wird nicht zu löschen versucht und ein Null-Cursor
zurückgeliefert.

Wird die View erfolgreich gedroppt, führt die Methode ein COMMIT
durch. Schlägt dies fehl, führt sie ein ROLLBACK durch.
Dies ist für PostgreSQL und SQLite notwendig.

=cut

# -----------------------------------------------------------------------------

sub dropView {
    my ($self,$viewName) = @_;

    # Wenn zu droppende view nicht existiert, brauchen wir nichts
    # tun und liefern einen Null-Cursor.

    unless ($self->viewExists($viewName)) {
        return $self->sql;
    }

    my $stmt = $self->stmt->dropView($viewName);
    my $cur = $self->sqlAtomic($stmt);

    return $cur;
}

# -----------------------------------------------------------------------------

=head3 viewExists() - Prüfe, ob View existiert

=head4 Synopsis

    $bool = $db->viewExists($viewName);

=head4 Description

Prüfe, ob View existiert. Wenn ja, liefere "wahr", sonst "falsch".

=cut

# -----------------------------------------------------------------------------

sub viewExists {
    my ($self,$viewName) = @_;

    # Wir öffnen im Falle von PostgreSQL eine parallele Verbindung,
    # damit der Statement-Fehler im Falle einer nicht-exitierenden
    # View die aktuelle Transaction nicht stört

    if ($self->isPostgreSQL) {
        $self = $self->new;
    }

    local $@;
    my $stmt = $self->stmt->select(
        -select => 0,
        -from => $viewName,
        -limit => 0,
    );
    eval { $self->sql($stmt) };
    return $@? 0: 1;
}

# -----------------------------------------------------------------------------

=head2 Trigger

=head3 createTrigger() - Erzeuge Trigger

=head4 Synopsis

    $cur = $db->createTrigger($table,$name,$when,$event,$level,$body,@opt);
    $cur = $db->createTrigger($table,$name,$when,$event,$level,
        $dbms => $body,
        ...,
        @opt
    );

=head4 Options

=over 4

=item -replace => $bool (Default: 0)

Ersetze den Trigger, falls ein solcher existiert.

=back

=head4 Returns

Cursor

=head4 Description

Erzeuge einen Trigger mit Name $name für Tabelle $table und Zeitpunkt
$when (BEFORE oder AFTER), der bei Ereignis $event (INSERT, UPDATE
oder DELETE) auf Ebene $level (ROW oder STATEMENT) feuert und die
Rumpf/Anweisungsfolge $body ausführt.

Es kann ein einzelner Rumpf angegeben werden, wenn die Applikation
auf einem bestimmten RDBMS läuft. Oder es können, um portabel
programmieren zu können, unterschiedliche Prozedur-Rümpfe für
verschiedene RDBMSe definiert werden:

    ...
    Oracle => "
    <oracle_body>
    ",
    PostgreSQL => "
    <postgresql_body>
    ",
    ...

Die Methode wählt dann die zur Datenbank $db passende
Rumpf-Definition aus.

=head4 Example

Erzeuge unterschiedlichen Triggercode für Oracle und PostgreSQL:

    $db->createTrigger('mytab','mytrig','before','insert|update','row',
        Oracle => "
        BEGIN
            :new.c := 'a';
        END
        ",
        PostgreSQL => "
        BEGIN
            NEW.c = 'a';
            RETURN NEW;
        END;
        ",
    );

Für Oracle wird ein Trigger mit Rumpf erzeugt:

    CREATE TRIGGER mytrig
    BEFORE INSERT OR UPDATE ON mytab
    FOR EACH ROW
    BEGIN
        :new.c := 'a';
    END;

Für PostgreSQL wird zunächst eine Funktion C<set_c_proc> (Triggername
plus "_proc") erzeugt, welche die Triggerfunktionalität implementiert:

    CREATE FUNCTION mytrig_proc()
    RETURNS trigger
    AS $SQL$
    BEGIN
        NEW.c = 'a';
        RETURN NEW;
    END;
    $SQL$ LANGUAGE plpgsql

Dann wird der Trigger definiert, der diese Funktion aufruft:

    CREATE TRIGGER set_c
    BEFORE INSERT OR UPDATE ON mytab
    FOR EACH ROW
    EXECUTE PROCEDURE mytrig_proc()

=cut

# -----------------------------------------------------------------------------

sub createTrigger {
    my $self = shift;
    my $table = shift;
    my $name = shift;
    my $when = shift;
    my $event = shift;
    my $level = shift;
    # @_: $body,@opt -or- $dbms=>$body,...,@opt

    # Optionen

    my $replace = 0;

    Quiq::Option->extract(\@_,
        -replace => \$replace,
    );

    # Body ermitteln
    my $body = @_ == 1? shift: {@_}->{$self->dbms};

    # Trigger droppen

    if ($replace && $self->triggerExists($name)) {
        $self->dropTrigger($name);
    }

    # Trigger erzeugen

    my $sql = $self->stmt;
    if ($self->isOracle) {
        my $stmt = $sql->createTrigger($table,$name,$when,$event,$level,
            $body);
        return $self->sqlAtomic($stmt,-forceExec=>1);
    }
    elsif ($self->isPostgreSQL) { 
        my $procName = $name.'_proc';

        my $stmt = $sql->createFunction($procName,$body,
            -returns => 'trigger'
        );
        $self->sqlAtomic($stmt);

        $stmt = $sql->createTrigger($table,$name,$when,$event,$level,
            -execute => $procName,
        );
        return $self->sqlAtomic($stmt);
    }

    $self->throw('Not implemented');
}

# -----------------------------------------------------------------------------

=head3 dropTrigger() - Entferne Trigger

=head4 Synopsis

    $cur = $db->dropTrigger($name);

=cut

# -----------------------------------------------------------------------------

sub dropTrigger {
    my $self = shift;
    my $name = shift;

    my $sql = $self->stmt;

    if ($self->isOracle) {
        my $stmt = $sql->dropTrigger($name);
        return $self->sqlAtomic($stmt);
    }
    elsif ($self->isPostgreSQL) {
        my $stmt = $sql->dropFunction($name.'_proc',-cascade=>1);
        return $self->sqlAtomic($stmt);
    }

    $self->throw('Not implemented');
}

# -----------------------------------------------------------------------------

=head3 triggerExists() - Prüfe, ob Trigger existiert

=head4 Synopsis

    $bool = $db->triggerExists($name);

=cut

# -----------------------------------------------------------------------------

sub triggerExists {
    my $self = shift;
    my $name = shift;

    my $row;
    if ($self->isOracle) {
        ($row) = $self->lookup(
            -from => 'all_triggers',
            -where,trigger_name => $name,
            -raw => 1,
            -sloppy => 1,
        );
    }
    elsif ($self->isPostgreSQL) {
        ($row) = $self->lookup(
            -from => 'pg_proc',
            -where,proname => $name.'_proc',
            -raw => 1,
            -sloppy => 1,
        );
    }
    else {
        $self->throw('Not implemented');
    }

    return $row? 1: 0;
}

# -----------------------------------------------------------------------------

=head2 Spezielle Operationen

=head3 diff() - Ermittele Datendifferenzen

=head4 Synopsis

    $tab|@rows|$cur = $db->diff(@args);

=head4 Options

Wie $db->select()

=cut

# -----------------------------------------------------------------------------

sub diff {
    my $self = shift;
    # @_: @args

    my $stmt = $self->stmt->diff(@_);
    return $self->select($stmt);
}

# -----------------------------------------------------------------------------

=head1 DETAILS

=head2 Zeitmessung

Im Zuge der Ausführung eines SQL-Statement werden drei Zeiten ermittelt:

=over 4

=item 1.

Der Startzeitpunkt der Ausführung (Aufruf von sql)

=item 2.

Die Dauer der Statementausführung

=item 3.

Die Zeit, die seit Start des Statement vergangen ist

=back

Diese Zeiten können vom Cursor abgefragt werden mittels:

    $cur->startTime;
    $cur->execTime;
    $cur->time;

=head2 Parallele Datenbankverbindung

Eine parallele Verbindung zur gleichen Datenbank unter dem gleichen
User kann mittels

    $db2 = $db->new;

aufgebaut werden. Dies kann nützlich sein, um einen nebenläufigen
Transkationsrahmen zu eröffnen.

=head2 Null-Cursor

Wird ein Cursor benötigt, ohne dass ein Statement ausgeführt
werden soll, kann ein Null-Cursor erzeugt werden:

    $cur = $db->sql;

=head2 Statement-Generierung

Die Methode sql() liefert das SQL-Objekt der Datenbankverbindung.
Dies ist ein Objekt der Klasse Quiq::Sql, das beim
Verbindungsaufbau passend zum DBMS instantiiert wurde.

Alle SQL-Generierungsmethoden der Klasse Quiq::Sql können
über diese Methode aufgerufen werden, zum Beispiel:

    $stmt = $db->stmt->createTable('person',
        ['per_id',type=>'INTEGER',primaryKey=>1],
        ['per_vorname',type=>'STRING(20)'],
        ['per_nachname',type=>'STRING(20)'],
    );

=head2 Statement-Generierung plus -Ausführung

Die meisten Statements der Klasse Quiq::Sql können auch
direkt ausgeführt werden, ohne dass das Statement zuvor
generiert werden muss, zum Beispiel:

    $db->createTable('person',
        ['per_id',type=>'INTEGER',primaryKey=>1],
        ['per_vorname',type=>'STRING(20)'],
        ['per_nachname',type=>'STRING(20)'],
    );

Die direkte Ausführung ist einer getrennten Generierung
und Ausführung vorzuziehen, da die Quiq::Database::Connection-Methoden bei der
Ausführung teilweise DBMS-abhängige Sonderbehandlungen vornehmen.

=head2 Erweiterte Statement-Generierung

Anstelle der Default Sql-Klasse Quiq::Sql kann beim Verbindungsaufbau
eine anwendungspezifische Klasse vereinbart werden:

    package MyApp::Sql;
    use base qw/Quiq::Sql/;
    
    ...
    
    package main;
    
    $db = Quiq::Database::Connection->new(...,-sqlClass=>'MyApp::Sql');

=head2 Prepare/Bind

DML-Statements (SELECT, INSERT, UPDATE, DELETE) können mit Platzhaltern
versehen werden. Das Statement wird dann nicht ausgeführt, sondern
ein Bind-Cursor geliefert.

=head3 Beispiel mit INSERT

    my $bindCur = $db->insert('person',
        per_id => \'?',
        per_vorname => \'?',
        per_nachname => \'?',
    );
    
    $bindCur->bind(
        1,'Rudi','Ratlos',
        2,'Elli','Pirelli',
        3,'Erika','Mustermann',
    );

=head3 Beispiel mit SELECT

    my $bindCur = $db->select(
        -from => 'person',
        -where => 'per_nachname = ?',
    );
    
    my $cur = $bindCur->bind('Mustermann');
    while (my $row = $cur->fetch) {
        print $row->asString,"\n";
    }
    $cur->close;

=head2 Lookup von Datensätzen

=head3 Selektion eines eindeutigen Objekts

    $row = $db->lookup('person',-where,per_id=>4711);

Es ist ein Fehler, wenn

=over 2

=item *

kein Datensatz existiert

=item *

mehr als ein Datensatz existiert

=back

Soll die Methode undef liefern, wenn kein Datensatz existiert,
wird -sloppy=>1 angegeben:

    $row = $db->lookup('person',-sloppy=>1,-where,per_id=>4711);

Soll ein leerer Datensatz geliefert werden, der gesuchte Datensatz
nicht gefunden wird, wird -new=>1 angegeben:

    $row = $db->lookup('person',-new=>1,-where,per_id=>4711);

Der Aufruf liefert also immer einen Datensatz. Mit der Methode
rowStatus() kann geprüft werden, ob der Datensatz selektiert oder
neu erzeugt wurde:

    if ($row->rowStatus eq 'I') {
        # initialisieren
    
        $row->set(
            per_id => $db->nextValue('id');
            per_vorname => 'Erika',
            per_namchname => 'Mustermann',
        );
    
        # speichern
        $db->insert('person',$row);
    }

=head2 Einfügen von Datensätzen

=head3 Ad hoc

    my $per_id = $db->nextValue('id');
    $db->insert('person',
        per_id => $per_id,
        per_vorname => 'Rudi',
        per_nachname => 'Ratlos',
    );
    my $per = $db->lookup('person',-where,per_id=>$per_id);

Der Datensatz wird durch Aufzählung der Kolumnen/Wert-Paare zur
Tabelle hinzugefügt. Um das Objekt im Programm zu haben, muss
der Datensatz selektiert werden.

=head3 Mittels anonymem Row-Objekt

    my $per = $db->nullRow('person');
    $per->set(
        per_id => $db->nextValue('id'),
        per_vorname => 'Rudi',
        per_nachname => 'Ratlos',
    );
    $db->insert('person',$row);

=head3 Mittels Objekt (noch nicht implementiert)

    my $per = Person->new($db,
        per_id => $db->nextValue('id'),
        per_vorname => 'Rudi',
        per_nachname => 'Ratlos',
    );
    $per->insert($db);

=head2 Default-Schema

Per UDL kann ein Default-Schema definiert werden:

    dbi#DBMS:DB%USER:PASSW;schema=SCHEMA

Namen von Datenbank-Objekten, die ohne Schema-Präfix angegeben
werden, werden auf dieses Schema bezogen. Auf diese Weise
ist es leicht möglich, eine Anwendung auf verschiedenen Schemata
der gleichen Datenbank laufen zu lassen. Dies ist vor allem
bei Oracle nützlich, dessen Instanzen einen großen Overhead haben.

Bei SQLite ist die Semantik eine leicht andere: Hier ist es nicht
das Default-Schema, sondern es darf der Schema-Präfix
SCHEMA verwendet werden.

=head2 BLOB Datentyp

=over 2

=item *

Die maximale Größe eines BLOB/TEXT-Werts muss im Falle von Oracle
eingestellt werden. Dies geschieht durch Aufruf von maxBlobSize():

    $db->maxBlobSize(500*1024); # 0,5 MB

Der Defaultwert ist 1024*1024 Bytes (1MB).

=back

=head3 Tabelle erzeugen

    $db->createTable('person',
        ['per_id',type=>'INTEGER',primaryKey=>1],
        ['per_vorname',type=>'STRING(20)'],
        ['per_nachname',type=>'STRING(20)'],
        ['per_foto',type=>'BLOB'],
    );

=head3 Daten speichern

    $cur = $db->insert('person',
        per_id => \'?',
        per_vorname => \'?',
        per_nachname => \'?',
        per_foto => \'?',
    );
    
    # BLOB-Kolumne bekannt machen, damit die Schnittstelle
    # die notwendigen Sonderbehandlungen für diesen Datentyp
    # durchführen kann. Dies ist im Falle von Oracle und PostgreSQL
    # nötig, da diese die Daten speziell kodieren. Bei SQLite und MySQL
    # ist das nicht erforderlich. Der Aufruf von bindTypes() sollte aus
    # Portabilitätsgründen aber immer gemacht werden.
    
    $cur->bindTypes(undef,undef,undef,'BLOB');
    
    my $foto = Quiq::Path->read('/home/pirelli/Picture/elli.jpg');
    $cur->bind(1,'Elli','Pirelli',$foto);

=head3 Daten selektieren

    $per = $db->lookup('person',-where,per_id=>1);

=head2 TEXT-Datentyp

Wie BLOB-Datentyp, aber als Bind-Typ TXET angeben:

    $cur->bindTypes(undef,undef,undef,'TEXT');

Auch hier ist dies wegen Oracle erforderlich.

=head2 UTF-8

Beim Verbindungsaufbau kann angegeben werden, ob das Perl-Programm
UTF-8 Encoding verwendet:

    $db = Quiq::Database::Connection->new($udl,-utf8=>1);

Die Option sorgt dafür, dass Zeichenketten-Daten (STRING, TEXT)
als UTF-8 Zeichenketten auf der Datenbank gespeichert werden und
umgekehrt als UTF-8 Zeichenketten geliefert werden.

=head2 Existierende Handle nutzen

Existiert eine Lowlevel-Handle bereits, kann sie mit der Option
-handle in das Datenbankobjekt eingesetzt werden.

Beispiel: Eine DBI MySQL-Handle $dbh wird als Lowlevel-Handle verwendet,

    UDL braucht nur die
    
       $db = Quiq::Database::Connection->new('dbi#mysql',-handle=>$dbh);

=head2 Zugriff auf MS Access Datenbank

Unter Unix/Linux ist ein lesender Zugriff auf MS Access
Datenbanken mittels des freien Open Source Package B<mtools>
möglich. Es enthält neben verschiedenen Programme auch einen
ODBC-Treiber, der genutzt werden kann, um von Perl aus auf eine
Access-Datenbank zuzugreifen.

=head3 Installation (Redhat)

=head4 ODBC-Treiber für MS-Access

mtools: L<http://mdbtools.sourceforge.net/>

    # yum install mdbtools

=head4 ODBC Driver Manager

unixODBC: L<http://http://www.unixodbc.org/>

    # yum install unixODBC

=head4 Perl DBI-Treiber für ODBC

DBD::ODBC: L<https://metacpan.org/pod/DBD::ODBC>

    # cpanm DBD::ODBC

=head3 Konfiguration

ODBC-Treiber (aus den mtools) definieren:

    # vi /etc/odbcinst.ini
    [MDBTools]
    Description = MDB Tools ODBC
    Driver      = libmdbodbc.so
    FileUsage   = 1

Datenquelle definieren:

    # vi /etc/odbc.ini
    [test]
    Description = Access Test-Datenbank
    Driver      = MDB Tools ODBC
    Database    = /path/to/file.mdb

=head3 Perl-Programm

Von Perl aus auf die Access-Datenbank zugreifen:

    my $udl = 'dbi#access:test';
    my $db = Quiq::Database::Connection->new($udl,-utf8=>1);
    
    my $stmt = 'select * from tdruckdaten';
    my $tab = $db->select($stmt);
    print $tab->asTable;

=head1 VERSION

1.147

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
