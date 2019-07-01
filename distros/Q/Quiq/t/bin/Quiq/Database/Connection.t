#!/usr/bin/env perl

package Quiq::Database::Connection::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;
use utf8;

use Quiq::Database::Connection;
use Quiq::Path;

# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------

sub initMethod : Init(1) {
    my $self = shift;

    # FIXME: Test sollte anders aussehen: Je UDL, einen Foreach-Zweig abbrechen

    eval {require DBI};
    if ($@) {
        $self->skipAllTests('DBI nicht installiert');
        return;
    }
    $self->ok(1);
}

# Tests der Klasse über verschiedenen DBMSen laufen lassen

sub udls : Foreach {
    my $self = shift;

    my $file = $self->testPath('t/data/db/test-databases.conf');
    my @arr = split /\n/,Quiq::Path->read($file);
    @arr = grep { !/^#/ } @arr; # Kommentarzeichen überlesen

    return @arr;
}

# -----------------------------------------------------------------------------

# Testkonzept:
# o Konstruktor new() hat Startup-Testmethode, baut Db-Verbindung auf
#   und erstellt Test-Tabellen und Test-Daten.
# o Destruktor destroy() hat Shutdown-Testmethode, entfernt Test-Tabellen
#   und baut Verbindung ab
# o Die anderen Methoden haben normale Test-Methoden, operieren
#   auf den Testdaten und nehmen nur lokale Änderungen vor,
#   sie verändern die Testdaten nicht dauerhaft, d.h. führen
#   ggf. rollback() am Ende aus

our $PersonTable = 'person4713';
our $PersonClass = 'Test::Person4713';
our @PersonTitles = qw/per_id per_vorname per_nachname/;

sub test_new_startup : Startup(8) {
    my ($self,$udl) = @_;

    # $self->diag("### $udl ###");

    my $udlObj = Quiq::Udl->new($udl);
    # Um Permission-Probleme bei CPAN-Tests zu vermeiden
    # (hilft leider nichts)
    # if ($udlObj->dbms eq 'sqlite') {
    #     my $file = $udlObj->db;
    #     Quiq::Path->chmod($file,0600);
    # }

    # Datenbankverbindung aufbauen

    $ENV{'NLS_LANG'} = 'GERMAN_AMERICA.AL32UTF8';
    my $db = Quiq::Database::Connection->new($udl,-utf8=>1,-log=>1);
    $self->is(ref($db),'Quiq::Database::Connection');
    $self->set(db=>$db);

    # Testtabelle anlegen

    $db->createTable($PersonTable,-reCreate=>1,
        ['per_id',type=>'INTEGER',primaryKey=>1],
        ['per_vorname',type=>'STRING(20)'],
        ['per_nachname',type=>'STRING(20)'],
    );
    $db->commit;

    $db->insertRows($PersonTable,
        [qw/per_id per_vorname per_nachname/],
        [qw/1 Rudi Ratlos/],
        [qw/2 Elli Pirelli/],
    );

    # INSERT mit Bind-Variablen

    my $cur = $db->insert($PersonTable,
        per_id => \'?',
        per_vorname => \'?',
        per_nachname => \'?',
    );
    my $bindVars = $cur->bindVars;
    $self->is($bindVars,3);

    $cur->bind(3,'Erika','Mustermann');
    $cur->close;

    # SELECT mit Bind-Variablen

    $cur = $db->select(
        -from => $PersonTable,
        -where => 'per_id = ?',
    );
    $bindVars = $cur->bindVars;
    $self->is($bindVars,1);

    my $cur2 = $cur->bind(3);
    my $row = $cur2->fetch;
    $self->is(ref($row),$cur->rowClass);
    $self->is($row->per_nachname,'Mustermann');

    $row = $cur2->fetch;
    $self->is($row,undef);

    $cur2->close;

    # Wiederholtes SELECT über Bind-Cursor

    $cur2 = $cur->bind(1);
    $row = $cur2->fetch;
    $self->is($row->per_nachname,'Ratlos');

    $cur2->close;
    $cur->close;

    $db->commit;

    # Arbeiten mit Row-Klasse

    use Quiq::Database::Row::Object::Table;
    Quiq::Perl->createClass($PersonClass,
        'Quiq::Database::Row::Object::Table');

    my $titles = $PersonClass->titles($db);
    $self->isDeeply($titles,\@PersonTitles);
}

sub test_new_doublette : Test(1) {
    my $self = shift;

    my $db = $self->get('db');

    $db->createTable('test67',-reCreate=>1,
        ['id',type=>'INTEGER',primaryKey=>1]
    );

    $db->insert('test67',id=>1);
    eval { $db->insert('test67',id=>1) };
    $self->like($@,qr/DB-00004/);
    $db->commit; # für PostgreSQL

    $db->dropTable('test67');    
}

# Test des BLOB-Typs

sub test_new_oracleLimit : Test(1) {
    my $self = shift;

    my $table = 'test69';
    my $db = $self->get('db');

    $db->createTable($table,-reCreate=>1,
        ['xxx',type=>'STRING(4000)'],
    );
    $self->ok(1);

    $db->dropTable($table);    
}

# Test des BLOB-Typs

sub test_new_blob : Test(4) {
    my $self = shift;

    my $table = 'test68';
    my $db = $self->get('db');

    # Tabelle mit BLOB-Typ erzeugen

    $db->createTable($table,-reCreate=>1,
        ['id',type=>'INTEGER',primaryKey=>1],
        ['bin',type=>'BLOB'],
    );
    $self->ok(1);

    # Bind-Cursor erzeugen

    my $cur = $db->insert($table,
        id => \'?',
        bin => \'?',
    );
    $cur->bindTypes(undef,'BLOB');

    # 128K einfügen

    my $blobData;
    for (0..255) {
        $blobData .= pack 'C',$_;
    }
    $blobData = $blobData x 512;

    $cur->bind(1,$blobData);
    $cur->close;
    $self->ok(2);

    # SELECT der Daten

    my $row = $db->lookup($table,-where,id=>1);
    $self->is($row->id,1);
    $self->is($row->bin,$blobData);

    $db->dropTable($table);    
}

# Test des TEXT-Typs

sub test_new_text : Test(5) {
    my $self = shift;

    my $table = 'test69';
    my $db = $self->get('db');
    my $dbms = $db->udl->dbms;

    # Tabelle mit TEXT-Typ erzeugen

    $db->createTable($table,-reCreate=>1,
        ['id',type=>'INTEGER',primaryKey=>1],
        ['txt',type=>'TEXT'],
        ['txt2',type=>'STRING(20)'],
    );
    $self->ok(1);

    # Bind-Cursor erzeugen

    my $cur = $db->insert($table,
        id => \'?',
        txt => \'?',
        txt2 => \'?',
    );
    $cur->bindTypes(undef,'TEXT',undef);

    # 140000 Zeichen einfügen
    # MEMO: auf vostro muss das Oracle-Environment aufgesetzt sein, damit
    # das funktioniert:
    # . /usr/lib/oracle/xe/app/oracle/product/10.2.0/client/bin/oracle_env.sh
    # Was genau ist dafür verantwortlich?

    my $textData = 'äöüÄÖÜß'x20000;
    my $textData2 = 'äöüÄÖÜß';
    $cur->bind(1,$textData,$textData2);
    $cur->close;
    $self->ok(2);

    # SELECT der Daten

    my $row = $db->lookup($table,-where,id=>1);
    $self->is($row->id,1);
    $self->is($row->txt,$textData);
    $self->is($row->txt2,$textData2);

    $db->dropTable($table);
}

# Kompatibilitätstests

sub test_new_columnAlias : Test(1) {
    my $self = shift;

    my $db = $self->get('db');

    my @rows = $db->select(
        -select => 'per_id AS id',
        -from => $PersonTable,
        -orderBy => 'id',
    );

    my @arr;
    for my $row (@rows) {
        push @arr,$row->id;
    }

    $self->isDeeply(\@arr,[1,2,3]);
}

sub test_new_tableAlias : Test(1) {
    my $self = shift;

    my $db = $self->get('db');

    # Tabellenalias mit AS ist bei Oracle nicht zulässig

    my @rows = $db->select(
        -select => 'per_id',
        -from => "$PersonTable per",
        -orderBy => 'per.per_id',
    );

    my @arr;
    for my $row (@rows) {
        push @arr,$row->per_id;
    }

    $self->isDeeply(\@arr,[1,2,3]);
}

# Erzeuge eine Tabelle "trigger_test" mit zwei Kolumnen n1 und n2.
# Setze einen Trigger auf, der beim Schreiben auf n1 (INSERT oder
# UPDATE) den Wert der Kolumne n2 setzt.

sub test_new_trigger : Test(2) {
    my $self = shift;

    my $db = $self->get('db');

    my $table = 'trigger_test';
    $db->createTable($table,-reCreate=>1,
        ['n',type=>'INTEGER(1)'],
        ['c',type=>'STRING(1)'],
    );

    my $table2 = 'trigger_lookup';
    $db->createTable($table2,-reCreate=>1,
        ['n',type=>'INTEGER(1)'],
        ['c',type=>'STRING(1)'],
    );
    $db->insertRows($table2,
        ['n','c'],
        0,'a',
        1,'b',
        2,'c',
    );

    if ($db->isPostgreSQL) {
        # Test für PostgreSQL

        # $db->sqlAtomic('DROP FUNCTION set_n2() CASCADE');

        my $stmt = <<'        __SQL__';
        CREATE FUNCTION set_n2() RETURNS trigger AS $$
            BEGIN
                SELECT
                    c
                INTO STRICT
                    NEW.c
                FROM
                    trigger_lookup
                WHERE
                    n = NEW.n;

                RETURN NEW;
            END;
        $$ LANGUAGE plpgsql;
        __SQL__
        $db->sql($stmt);

        $stmt = 'CREATE TRIGGER n2 BEFORE INSERT OR UPDATE'.
            " ON $table FOR EACH ROW EXECUTE PROCEDURE set_n2()";
        $db->sql($stmt);

        # Wirkungsweise des Trigger testen
        $self->test_new_trigger_test($db,$table);

        $db->sqlAtomic('DROP FUNCTION set_n2() CASCADE');
    }
    elsif ($db->isOracle) {
        # Test für Oracle

        my $stmt = <<'        __SQL__';
        CREATE OR REPLACE TRIGGER set_n2 BEFORE INSERT OR UPDATE
            ON trigger_test FOR EACH ROW
        BEGIN
            SELECT
                c
            INTO
                :new.c
            FROM
                trigger_lookup
            WHERE
                n = :new.n;
        END;
        __SQL__
        $db->sql($stmt,-forceExec=>1);

        # Wirkungsweise des Trigger testen
        $self->test_new_trigger_test($db,$table);

        $db->sqlAtomic('DROP TRIGGER set_n2');
    }
    else {    
        $self->skipTest(sprintf 'Test für %s uebergehen',$db->dbms);
    }

    $db->dropTable($table);  
    $db->dropTable($table2);  

    return;
}

# Hilfsmethode für Trigger-Test

sub test_new_trigger_test {
    my ($self,$db,$table) = @_;

    # Datensätze erzeugen

    $db->insert($table,n=>0);
    $db->insert($table,n=>1);
    my @rows = $db->select($table,-orderBy=>'n',-raw=>1);
    $self->isDeeply(\@rows,[[0,'a'],[1,'b']]);

    # Datensätze aktualisieren

    $db->update($table,n=>0,-where,n=>1);
    @rows = $db->select($table,-orderBy=>'n',-raw=>1);
    $self->isDeeply(\@rows,[[0,'a'],[0,'a']]);

    return;
}

# -----------------------------------------------------------------------------

sub test_disconnect : Shutdown(2) {
    my ($self,$udl) = @_;

    my $db = $self->get('db');

    my $cur = $db->dropTable($PersonTable);
    $self->is(ref($cur),'Quiq::Database::Cursor');

    $db->disconnect;
    $self->is($db,undef);

    return;
}

# -----------------------------------------------------------------------------

sub test_dbExists : Shutdown(1) {
    my ($self,$udl) = @_;

    my $bool = Quiq::Database::Connection->dbExists($udl);
    $self->ok($bool);

    return;
}

# -----------------------------------------------------------------------------

sub test_maxBlobSize : Test(3) {
    my $self = shift;

    my $db = $self->get('db');
    my $dbms = $db->udl->dbms;

    my $defaultVal = $db->isOracle? 1024*1024: 0;

    my $n = $db->maxBlobSize;
    $self->is($n,$defaultVal);

    my $val = $db->isOracle? 10*1024: 0;

    $n = $db->maxBlobSize($val);
    $self->is($n,$val);

    # Exception prüfen

    # Tabelle mit TEXT-Typ erzeugen

    my $table = 'test70';
    $db->createTable($table,-reCreate=>1,
        ['dat',type=>'BLOB'],
    );

    # Bind-Cursor erzeugen

    my $cur = $db->insert($table,
        dat => \'?',
    );
    $cur->bindTypes('BLOB');

    eval {
        my $data = 'x'x($n+1); # für Oracle zu großen Wert einfügen
        $cur->bind($data);
        $cur->close;

        # SELECT der Daten

        my $row = $db->lookup($table);
        $self->is($row->dat,$data);
    };
    if ($db->isOracle) {
        $self->like($@,qr/truncated/);
    }

    $db->dropTable($table);
}

# -----------------------------------------------------------------------------

sub test_stmt : Test(1) {
    my $self = shift;

    my $db = $self->get('db');

    my $stmt = $db->stmt->dropTable($PersonTable);
    $self->like($stmt,qr/DROP TABLE $PersonTable/);
}

# -----------------------------------------------------------------------------

sub test_udl : Test(1) {
    my $self = shift;

    my $db = $self->get('db');

    # Das DBMS ist eine Pflichtangabe

    my $dbms = $db->udl->dbms;
    $self->ok($dbms);

    # Der Username ist optional
    my $user = $db->udl->user;
}

# -----------------------------------------------------------------------------

sub test_dbms : Test(1) {
    my $self = shift;

    my $db = $self->get('db');

    my $dbms = $db->dbms;
    if ($db->isOracle) {
        $self->is($dbms,'Oracle');
    }
    elsif ($db->isPostgreSQL) {
        $self->is($dbms,'PostgreSQL');
    }
    elsif ($db->isSQLite) {
        $self->is($dbms,'SQLite');
    }
    elsif ($db->isMySQL) {
        $self->is($dbms,'MySQL');
    }
    elsif ($db->isAccess) {
        $self->is($dbms,'Access');
    }
    elsif ($db->isMSSQL) {
        $self->is($dbms,'MSSQL');
    }
    else {
        $self->ok(0);
    }
}

# -----------------------------------------------------------------------------

sub test_dbmsTestVector : Test(4) {
    my ($self,$udl) = @_;

    my $dbms = Quiq::Udl->new($udl)->dbms;
    my $db = $self->get('db');

    my ($oracle,$postgresql,$sqlite,$mysql) = $db->dbmsTestVector;

    $self->ok($dbms eq 'oracle'? $oracle: !$oracle);
    $self->ok($dbms eq 'postgresql'? $postgresql: !$postgresql);
    $self->ok($dbms eq 'sqlite'? $sqlite: !$sqlite);
    $self->ok($dbms eq 'mysql'? $mysql: !$mysql);
}

# -----------------------------------------------------------------------------

sub test_isOracle : Test(1) {
    my ($self,$udl) = @_;

    my $dbms = Quiq::Udl->new($udl)->dbms;
    my $db = $self->get('db');

    my $bool = $db->isOracle;
    $self->ok($dbms eq 'oracle'? $bool: !$bool);
}

# -----------------------------------------------------------------------------

sub test_isPostgreSQL : Test(1) {
    my ($self,$udl) = @_;

    my $dbms = Quiq::Udl->new($udl)->dbms;
    my $db = $self->get('db');

    my $bool = $db->isPostgreSQL;
    $self->ok($dbms eq 'postgresql'? $bool: !$bool);
}

# -----------------------------------------------------------------------------

sub test_isSQLite : Test(1) {
    my ($self,$udl) = @_;

    my $dbms = Quiq::Udl->new($udl)->dbms;
    my $db = $self->get('db');

    my $bool = $db->isSQLite;
    $self->ok($dbms eq 'sqlite'? $bool: !$bool);
}

# -----------------------------------------------------------------------------

sub test_isMySQL : Test(1) {
    my ($self,$udl) = @_;

    my $dbms = Quiq::Udl->new($udl)->dbms;
    my $db = $self->get('db');

    my $bool = $db->isMySQL;
    $self->ok($dbms eq 'mysql'? $bool: !$bool);
}

# -----------------------------------------------------------------------------

sub test_isAccess : Test(1) {
    my ($self,$udl) = @_;

    my $dbms = Quiq::Udl->new($udl)->dbms;
    my $db = $self->get('db');

    my $bool = $db->isAccess;
    $self->ok($dbms eq 'access'? $bool: !$bool);
}

# -----------------------------------------------------------------------------

sub test_isMSSQL : Test(1) {
    my ($self,$udl) = @_;

    my $dbms = Quiq::Udl->new($udl)->dbms;
    my $db = $self->get('db');

    my $bool = $db->isMSSQL;
    $self->ok($dbms eq 'mssql'? $bool: !$bool);
}

# -----------------------------------------------------------------------------

sub test_sql_select : Test(3) {
    my $self = shift;

    my $db = $self->get('db');

    my $cur = $db->sql("SELECT * FROM $PersonTable");
    $self->is(ref($cur),'Quiq::Database::Cursor');

    my @rows = $cur->fetchAll;
    $self->ok(@rows >= 2);

    $cur->close;
    $self->is($cur,undef);
}

sub test_sql_oracleTrigger : Test(2) {
    my $self = shift;

    my $db = $self->get('db');
    if (!$db->isOracle) {
        $self->skipTest('Test nur fuer Oracle');
        return;
    }

    $db->createTable('x',
        ['id','INTEGER',primaryKey=>1],
        ['create_date','DATETIME',notNull=>1],
        ['id2','INTEGER',notNull=>1],
        -reCreate => 1,
    );

    my $cur = $db->sql(-forceExec=>1,"
    CREATE OR REPLACE TRIGGER x_before_insert
    BEFORE INSERT
        ON x
        FOR EACH ROW
    BEGIN
        :new.create_date := sysdate;
        :new.id2 := :new.id*2;
    END;
    ");

    $db->insert('x',id=>1);
    my ($row) = $db->select('x');
    $self->ok($row->create_date);
    $self->is($row->id2,2);

    $db->dropTable('x');
}

# -----------------------------------------------------------------------------

sub test_begin : Test(1) {
    my $self = shift;

    my $db = $self->get('db');
    my $cur = $db->begin;
    $self->is(ref($cur),'Quiq::Database::Cursor');
}

# -----------------------------------------------------------------------------

sub test_commit : Test(1) {
    my $self = shift;

    # FIXME: Code hinzufügen, der Commit mit Daten testet

    my $db = $self->get('db');
    my $cur = $db->commit;
    $self->is(ref($cur),'Quiq::Database::Cursor');
}

# -----------------------------------------------------------------------------

sub test_rollback : Test(1) {
    my $self = shift;

    # FIXME: Code hinzufügen, der Rollback mit Daten testet

    my $db = $self->get('db');
    $db->begin;
    my $cur = $db->rollback;
    $self->is(ref($cur),'Quiq::Database::Cursor');
}

# -----------------------------------------------------------------------------

sub test_titles : Test(3) {
    my $self = shift;

    my $db = $self->get('db');

    my $arr = $db->titles(-from=>$PersonTable);
    $self->isDeeply($arr,\@PersonTitles);

    my $arr2 = $db->titles(-from=>$PersonTable);
    $self->is($arr,$arr2);

    my @arr = $db->titles(-from=>$PersonTable);
    $self->isDeeply(\@arr,\@PersonTitles);
}

# -----------------------------------------------------------------------------

sub test_select_cursor : Test(4) {
    my $self = shift;

    my $db = $self->get('db');

    my $cur = $db->select($PersonTable,-limit=>0,-cursor=>1);
    $self->is(ref($cur),'Quiq::Database::Cursor');

    my @titles = $cur->titles;
    $self->isDeeply(\@titles,\@PersonTitles);

    my $row = $cur->fetch;
    $self->is($row,undef);

    $cur->close;
    $self->is($cur,undef);
}

sub test_select_rows : Test(1) {
    my $self = shift;

    my $db = $self->get('db');

    my @rows = $db->select($PersonTable);
    $self->ok(@rows >= 2);
}

sub test_select_table : Test(1) {
    my $self = shift;

    my $db = $self->get('db');

    my $tab = $db->select($PersonTable);
    $self->is(ref($tab),'Quiq::Database::ResultSet::Object');
}

sub test_select_tableClass : Test(3) {
    my $self = shift;

    my $db = $self->get('db');

    my $personClassTable = "$PersonClass\::Table";
    Quiq::Perl->createClass($personClassTable,
        'Quiq::Database::ResultSet::Object');
    my $tab = $PersonClass->select($db,-tableClass=>$personClassTable);
    $self->is(ref($tab),$personClassTable);

    my $per = $tab->lookup(per_id=>1);
    $self->is(ref($per),$PersonClass);
    $self->is($per->per_vorname,'Rudi');
}

sub test_select_rows_raw : Ignore(1) {
    my $self = shift;

    my $db = $self->get('db');

    my @rows = $db->select($PersonTable,-raw=>1);
    $self->ok(@rows >= 2);
}

# -----------------------------------------------------------------------------

sub test_lookup_object : Test(4) {
    my $self = shift;

    my $db = $self->get('db');
    my $rowClass = $db->defaultRowClass;

    my $row = $db->lookup(-from=>$PersonTable,-where=>'per_id = 1');
    $self->is(ref($row),$rowClass);
    $self->is($row->per_nachname,'Ratlos');

    my @row = $db->lookup(-from=>$PersonTable,-where=>'per_id = 1');
    $self->isDeeply(\@row,[1,'Rudi','Ratlos']);

    eval { $db->lookup(-from=>$PersonTable,-where=>'per_id = 4711') };
    $self->like($@,qr/DB-00001/);
}

sub test_lookup_array : Test(4) {
    my $self = shift;

    my $db = $self->get('db');
    my $rowClass = $db->defaultRowClass(1);

    my $row = $db->lookup(-from=>$PersonTable,-where=>'per_id = 1',-raw=>1);
    $self->is(ref($row),$rowClass);
    $self->is($row->[2],'Ratlos');

    my @row = $db->lookup(-from=>$PersonTable,-where=>'per_id = 1',-raw=>1);
    $self->isDeeply(\@row,[1,'Rudi','Ratlos']);

    eval {$db->lookup(-from=>$PersonTable,-where=>'per_id = 4711',-raw=>1)};
    $self->like($@,qr/DB-00001/);
}

# -----------------------------------------------------------------------------

sub test_values_array : Test(5) {
    my $self = shift;

    my $db = $self->get('db');

    my @arr = $db->values(
        -select => 'per_id',
        -from => $PersonTable,
        -orderBy => 'per_id',
    );
    $self->is($arr[0],1);
    $self->is($arr[-1],3);

    my $arr = $db->values(
        -select => 'per_id',
        -from => $PersonTable,
        -orderBy => 'per_id',
    );
    $self->is(ref($arr),'Quiq::Array');
    $self->is($arr->[0],1);
    $self->is($arr->[-1],3);
}

sub test_values_hash : Test(5) {
    my $self = shift;

    my $db = $self->get('db');

    my %hash = $db->values(
        -select => 'per_nachname',2,
        -from => $PersonTable,
        -hash => 1,
    );
    $self->is($hash{'Pirelli'},2);
    $self->is($hash{'Ratlos'},2);

    my $hash = $db->values(
        -select => 'per_nachname',3,
        -from => $PersonTable,
        -hash => 1,
    );
    $self->is(ref($hash),'Quiq::Hash');
    $self->is($hash->{'Pirelli'},3);
    $self->is($hash->{'Ratlos'},3);
}

sub test_values_array2 : Test(3) {
    my $self = shift;

    my $db = $self->get('db');

    my %hash = $db->values(
        -select => 'per_id','per_nachname',
        -from => $PersonTable,
    );
    $self->is($hash{1},'Ratlos');
    $self->is($hash{2},'Pirelli');
    $self->is($hash{3},'Mustermann');
}

sub test_values_hashref : Test(3) {
    my $self = shift;

    my $db = $self->get('db');

    my $hash = $db->values(
        -select => 'per_id','per_nachname',
        -from => $PersonTable,
        -hash => 1,
    );
    $self->is($hash->{1},'Ratlos');
    $self->is($hash->{2},'Pirelli');
    $self->is($hash->{3},'Mustermann');
}

# -----------------------------------------------------------------------------

sub test_value_cursor : Test(1) {
    my $self = shift;

    my $db = $self->get('db');

    my $val = $db->value(
        -select => 'per_nachname',
        -from => $PersonTable,
        -where => 'per_id = 2',
    );
    $self->is($val,'Pirelli');
}

# -----------------------------------------------------------------------------

sub test_insert : Test(2) {
    my $self = shift;

    my $db = $self->get('db');

    $db->begin;

    # FIXME: Anzahl Datensätze vorher und hinterher zählen

    #--------------------------------------------------------------------------

    my $cur = $db->insert($PersonTable,
        per_id => 4711,
        per_vorname => 'Hans',
        per_nachname => 'Mustermann',
    );
    $self->is(ref($cur),'Quiq::Database::Cursor');

    my $hits = $cur->hits;
    $self->is($hits,1);

    #--------------------------------------------------------------------------

    $db->rollback;
}

# -----------------------------------------------------------------------------

sub test_insertRows_arrays : Test(1) {
    my $self = shift;

    my $db = $self->get('db');

    $db->begin;

    $db->insertRows($PersonTable,
        [qw/per_id per_vorname per_nachname/],
        [qw/100 Frank Seitz/],
        [qw/101 Hanno Seitz/],
        [qw/102 Linus Seitz/],
    );

    my @rows = $db->select(
        -from => $PersonTable,
        -where => 'per_id >= 100',
        -raw => 1,
    );
    $self->is(scalar(@rows),3);

    $db->rollback;
}

sub test_insertRows_values : Test(1) {
    my $self = shift;

    my $db = $self->get('db');

    $db->begin;

    $db->insertRows($PersonTable,
        [qw/per_id per_vorname per_nachname/],
        qw/100 Frank Seitz/,
        qw/101 Hanno Seitz/,
        qw/102 Linus Seitz/,
    );

    my @rows = $db->select(
        -from => $PersonTable,
        -where => 'per_id >= 100',
        -raw => 1,
    );
    $self->is(scalar(@rows),3);

    $db->rollback;
}

# -----------------------------------------------------------------------------

sub test_insertMulti : Test(1) {
    my $self = shift;

    my $db = $self->get('db');

    $db->begin;

    $db->insertMulti($PersonTable,
        [qw/per_id per_vorname per_nachname/],[
            [qw/100 Frank Seitz/],
            [qw/101 Hanno Seitz/],
            [qw/102 Linus Seitz/],
        ]
    );

    my @rows = $db->select(
        -from => $PersonTable,
        -where => 'per_id >= 100',
        -raw => 1,
    );
    $self->is(scalar(@rows),3);

    $db->rollback;
}

# -----------------------------------------------------------------------------

sub test_update : Ignore(2) {
    my $self = shift;

    my $db = $self->get('db');

    $db->begin;

    # FIXME: Anzahl Datensätze vorher und hinterher zählen

    #--------------------------------------------------------------------------

    my $cur = $db->update($PersonTable,
        per_id => 4711,
        per_vorname => 'Hans',
        per_nachname => 'Mustermann',
    );
    $self->is(ref($cur),'Quiq::Database::Cursor');

    my $hits = $cur->hits;
    $self->is($hits,1);

    #--------------------------------------------------------------------------

    $db->rollback;
}

# -----------------------------------------------------------------------------

sub test_delete : Test(2) {
    my $self = shift;

    my $db = $self->get('db');

    $db->begin;

    #--------------------------------------------------------------------------

    my $cur = $db->insert($PersonTable,
        per_id => 4712,
        per_vorname => 'Heinz',
        per_nachname => 'Mustermann',
    );

    #--------------------------------------------------------------------------

    $cur = $db->delete($PersonTable,'per_id = 4712');
    $self->is(ref($cur),'Quiq::Database::Cursor');

    my $hits = $cur->hits;
    $self->is($hits,1);

    #--------------------------------------------------------------------------

    $db->rollback;
}

# -----------------------------------------------------------------------------

sub test_createTable : Test(3) {
    my $self = shift;

    my $db = $self->get('db');

    my $table = 'test_createTable_4711';
    $db->dropTable($table);

    #--------------------------------------------------------------------------

    my $cur = $db->createTable($table,
        ['id',type=>'INTEGER'],
    );
    $self->is(ref($cur),'Quiq::Database::Cursor');

    #--------------------------------------------------------------------------

    $cur = eval { $db->createTable($table,['id',type=>'INTEGER']) };
    $self->ok($@); # Exception - Tabelle $table existiert bereits

    #--------------------------------------------------------------------------

    $cur = $db->createTable($table,-reCreate=>1,
        ['id',type=>'INTEGER'],
    );
    $self->is(ref($cur),'Quiq::Database::Cursor');

    #--------------------------------------------------------------------------

    $db->dropTable($table);
}

# -----------------------------------------------------------------------------

sub test_dropTable : Test(3) {
    my $self = shift;

    my $db = $self->get('db');
    my $table = 'test_dropTable_4711';

    #--------------------------------------------------------------------------

    my $cur = $db->dropTable($table);
    $self->is(ref($cur),'Quiq::Database::Cursor');

    #--------------------------------------------------------------------------

    $cur = $db->dropTable($table,
        [id=>'INTEGER'],
    );
    $self->is(ref($cur),'Quiq::Database::Cursor');

    #--------------------------------------------------------------------------

    $cur = $db->dropTable($table);
    $self->is(ref($cur),'Quiq::Database::Cursor');
}

# -----------------------------------------------------------------------------

sub test_tableExists : Test(2) {
    my $self = shift;

    my $db = $self->get('db');
    my $table = 'tableExists_4713';

    $db->dropTable($table);

    my $bool = $db->tableExists($table);
    $self->ok(!$bool);

    $db->createTable($table,
        ['id',type=>'INTEGER'],
    );

    $bool = $db->tableExists($table);
    $self->ok($bool);

    $db->dropTable($table);
}

# -----------------------------------------------------------------------------

sub test_addColumn : Test(3) {
    my $self = shift;

    my $db = $self->get('db');

    my $cur = $db->addColumn($PersonTable,'mag_eis',
        type => 'STRING(1)',
        default => '1',
        notNull => 1,
    );
    $self->is(ref($cur),'Quiq::Database::Cursor');

    eval { $db->addColumn($PersonTable,'mag_eis','STRING(1)') };
    $self->ok($@);

    $cur = $db->addColumn($PersonTable,'mag_eis','STRING(1)',-sloppy=>1);
    $self->is($cur,undef);
}

# -----------------------------------------------------------------------------

sub test_dropColumn : Test(2) {
    my $self = shift;

    my $db = $self->get('db');

    if ($db->isSQLite) {
        $self->skipTest('SQLite: DROP COLUMN nicht vorhanden');
        return;
    }

    my $cur = $db->dropColumn($PersonTable,'mag_eis');
    $self->is(ref($cur),'Quiq::Database::Cursor');

    $cur = $db->dropColumn($PersonTable,'mag_eis');
    $self->is($cur,undef);
}

# -----------------------------------------------------------------------------

sub test_modifyColumn : Test(2) {
    my $self = shift;

    my $db = $self->get('db');

    if ($db->isSQLite || $db->isMySQL) {
        $self->skipTest('SQLite: Kolumnen koennen nicht modifiziert werden');
        return;
    }

    my $cur = $db->modifyColumn($PersonTable,'per_vorname',notNull=>1);
    $self->is(ref($cur),'Quiq::Database::Cursor');

    $cur = $db->modifyColumn($PersonTable,'per_vorname',notNull=>0);
    $self->is(ref($cur),'Quiq::Database::Cursor');
}

# -----------------------------------------------------------------------------

sub test_renameColumn : Test(2) {
    my $self = shift;

    my $db = $self->get('db');

    if ($db->isSQLite || $db->isMySQL) {
        $self->skipTest('nicht implementiert');
        return;
    }

    my $cur = $db->renameColumn($PersonTable,'per_nachname','per_name');
    $self->isTest(ref($cur),'Quiq::Database::Cursor');

    $cur = $db->renameColumn($PersonTable,'per_name','per_nachname');
    $self->isTest(ref($cur),'Quiq::Database::Cursor');
}

# -----------------------------------------------------------------------------

sub test_countDistinctMinMax : Test(8) {
    my $self = shift;

    my $db = $self->get('db');

    my $table = 'test_countDistinctMinMax';
    my $column = 'col';

    $db->createTable($table,
        [$column=>'INTEGER(2)'],
        -replace => 1,
    );

    my ($count,$countDistinct,$min,$max) = $db->countDistinctMinMax($table,$column);
    $self->is($count,0);
    $self->is($countDistinct,0);
    $self->is($min,''); 
    $self->is($max,''); 

    $db->insertRows($table,[$column],
        34,34,92,7,'',
    );

    ($count,$countDistinct,$min,$max) = $db->countDistinctMinMax($table,$column);
    $self->is($count,4);
    $self->is($countDistinct,3);
    $self->is($min,7);
    $self->is($max,92); 

    $db->dropTable($table);
}

# -----------------------------------------------------------------------------

sub test_ : Test(7) {
    my $self = shift;

    my $db = $self->get('db');
    my $testSequence = 'testseq';

    $db->createSequence($testSequence,-reCreate=>1);

    my $val = $db->nextValue($testSequence);
    $self->is($val,1);
    $val = $db->nextValue($testSequence);
    $self->is($val,2);
    $val = $db->nextValue($testSequence);
    $self->is($val,3);

    $db->dropSequence($testSequence);

    $db->createSequence($testSequence,-startWith=>10);

    $val = $db->nextValue($testSequence);
    $self->is($val,10);
    $val = $db->nextValue($testSequence);
    $self->is($val,11);
    $val = $db->nextValue($testSequence);
    $self->is($val,12);

    $db->setSequence($testSequence,20);
    $val = $db->nextValue($testSequence);
    $self->is($val,20);

    $db->dropSequence($testSequence);
}

# -----------------------------------------------------------------------------

sub test_createView : Test(1) {
    my $self = shift;

    my $db = $self->get('db');

    my $viewName = 'view_4711';
    $db->dropView($viewName);

    #--------------------------------------------------------------------------

    my $cur = $db->createView($viewName,"SELECT * FROM $PersonTable");
    $self->ok(ref $cur);

    #--------------------------------------------------------------------------

    $db->dropView($viewName);
}

# -----------------------------------------------------------------------------

sub test_createTrigger : Test(1) {
    my $self = shift;

    my $db = $self->get('db');

    if (!$db->isOracle && !$db->isPostgreSQL) {
        $self->skipTest(sprintf 'Test fuer %s uebergehen',$db->dbms);
        return;
    }

    my $table = 'test_createTrigger_table';
    my $name = 'set_c';

    $db->createTable($table,-replace=>1,
        ['n',type=>'INTEGER(1)'],
        ['c',type=>'STRING(1)'],
    );

    $db->createTrigger($table,$name,'before','insert|update','row',-replace=>1,
        Oracle => "
        BEGIN
            :new.c := 'a';
        END;
        ",
        PostgreSQL => "
        BEGIN
            NEW.c = 'a';
            RETURN NEW;
        END;
        ",
    );

    $db->insert($table,n=>1);
    my $val = $db->value(
        -select => 'c',
        -from => $table,
        -where,n => 1,
    );
    $self->is($val,'a');

    $db->dropTable($table);
}

# -----------------------------------------------------------------------------

package main;
Quiq::Database::Connection::Test->runTests;

# eof
