#!/usr/bin/env perl

package Quiq::Sql::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;
use utf8;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Sql');
}

# -----------------------------------------------------------------------------

sub test_new : Test(7) {
    my $self = shift;

    my $sql = Quiq::Sql->new('Oracle');
    $self->is($sql->{'dbms'},'Oracle');

    $sql = Quiq::Sql->new('PostgreSQL');
    $self->is($sql->{'dbms'},'PostgreSQL');

    $sql = Quiq::Sql->new('SQLite');
    $self->is($sql->{'dbms'},'SQLite');

    $sql = Quiq::Sql->new('MySQL');
    $self->is($sql->{'dbms'},'MySQL');

    $sql = Quiq::Sql->new('Access');
    $self->is($sql->{'dbms'},'Access');

    $sql = Quiq::Sql->new('MSSQL');
    $self->is($sql->{'dbms'},'MSSQL');

    eval { Quiq::Sql->new('Unknown') };
    $self->like($@,qr/SQL-00001/);
}

# -----------------------------------------------------------------------------

sub test_dbms : Test(6) {
    my $self = shift;

    my $sql = Quiq::Sql->new('oracle');
    $self->is($sql->dbms,'Oracle');

    $sql = Quiq::Sql->new('postgresql');
    $self->is($sql->dbms,'PostgreSQL');

    $sql = Quiq::Sql->new('sqlite');
    $self->is($sql->dbms,'SQLite');

    $sql = Quiq::Sql->new('mysql');
    $self->is($sql->dbms,'MySQL');

    $sql = Quiq::Sql->new('access');
    $self->is($sql->dbms,'Access');

    $sql = Quiq::Sql->new('mssql');
    $self->is($sql->dbms,'MSSQL');
}

# -----------------------------------------------------------------------------

sub test_dbmsNames : Test(2) {
    my $self = shift;

    my $dbmsNames = [qw/Oracle PostgreSQL SQLite MySQL Access MSSQL/];

    my @arr = Quiq::Sql->dbmsNames;
    $self->isDeeply(\@arr,$dbmsNames);

    my $arr = Quiq::Sql->dbmsNames;
    $self->isDeeply($arr,$dbmsNames);
}

# -----------------------------------------------------------------------------

sub test_dbmsTestVector : Test(6) {
    my $self = shift;

    my @vec = Quiq::Sql->new('Oracle')->dbmsTestVector;
    $self->isDeeply(\@vec,[1,0,0,0,0,0]);

    @vec = Quiq::Sql->new('PostgreSQL')->dbmsTestVector;
    $self->isDeeply(\@vec,[0,1,0,0,0,0]);

    @vec = Quiq::Sql->new('SQLite')->dbmsTestVector;
    $self->isDeeply(\@vec,[0,0,1,0,0,0]);

    @vec = Quiq::Sql->new('MySQL')->dbmsTestVector;
    $self->isDeeply(\@vec,[0,0,0,1,0,0]);

    @vec = Quiq::Sql->new('Access')->dbmsTestVector;
    $self->isDeeply(\@vec,[0,0,0,0,1,0]);

    @vec = Quiq::Sql->new('MSSQL')->dbmsTestVector;
    $self->isDeeply(\@vec,[0,0,0,0,0,1]);
}

# -----------------------------------------------------------------------------

sub test_isOracle : Test(2) {
    my $self = shift;

    my $bool = Quiq::Sql->new('Oracle')->isOracle;
    $self->is($bool,1);

    $bool = Quiq::Sql->new('PostgreSQL')->isOracle;
    $self->is($bool,0);
}

# -----------------------------------------------------------------------------

sub test_isPostgreSQL : Test(2) {
    my $self = shift;

    my $bool = Quiq::Sql->new('PostgreSQL')->isPostgreSQL;
    $self->is($bool,1);

    $bool = Quiq::Sql->new('Oracle')->isPostgreSQL;
    $self->is($bool,0);
}

# -----------------------------------------------------------------------------

sub test_isSQLite : Test(2) {
    my $self = shift;

    my $bool = Quiq::Sql->new('SQLite')->isSQLite;
    $self->is($bool,1);

    $bool = Quiq::Sql->new('PostgreSQL')->isSQLite;
    $self->is($bool,0);
}

# -----------------------------------------------------------------------------

sub test_isMySQL : Test(2) {
    my $self = shift;

    my $bool = Quiq::Sql->new('MySQL')->isMySQL;
    $self->is($bool,1);

    $bool = Quiq::Sql->new('PostgreSQL')->isMySQL;
    $self->is($bool,0);
}

# -----------------------------------------------------------------------------

sub test_isAccess : Test(2) {
    my $self = shift;

    my $bool = Quiq::Sql->new('Access')->isAccess;
    $self->is($bool,1);

    $bool = Quiq::Sql->new('PostgreSQL')->isAccess;
    $self->is($bool,0);
}

# -----------------------------------------------------------------------------

sub test_isMSSQL : Test(2) {
    my $self = shift;

    my $bool = Quiq::Sql->new('MSSQL')->isMSSQL;
    $self->is($bool,1);

    $bool = Quiq::Sql->new('PostgreSQL')->isMSSQL;
    $self->is($bool,0);
}

# -----------------------------------------------------------------------------

sub test_split : Test(2) {
    my $self = shift;

    my $stmt1 = "SELECT 'abc', * FROM xyz WHERE a = 'aga' AND b = 'ga''ga'";
    my $stmt2 = "SELECT '%s', * FROM xyz WHERE a = '%s' AND b = '%s''%s'";

    my ($stmt,@arr) = Quiq::Sql->split($stmt1);
    $self->is($stmt,$stmt2);

    $stmt = sprintf($stmt,@arr);
    $self->is($stmt,$stmt1);
}

# -----------------------------------------------------------------------------

sub test_resolve : Test(1) {
    my $self = shift;

    my $sql = Quiq::Sql->new('PostgreSQL');

    my $stmt = 'SELECT * FROM t WHERE x = ? AND y > ?';
    my @vals = (47,11);
    $stmt = $sql->resolve($stmt,@vals);
    $self->is($stmt,"SELECT * FROM t WHERE x = '47' AND y > '11'");
}

# -----------------------------------------------------------------------------

sub test_removeSelectClause : Test(1) {
    my $self = shift;

    my $sql = Quiq::Sql->new('Oracle');
    my $stmt = 'SELECT a, b, c FROM t WHERE a = 4711';
    my $newStmt = $sql->removeSelectClause($stmt);
    $self->isTest($newStmt,'FROM t WHERE a = 4711');
}

# -----------------------------------------------------------------------------

sub test_removeOrderByClause : Test(1) {
    my $self = shift;

    my $sql = Quiq::Sql->new('Oracle');
    my $stmt = 'SELECT a, b, c FROM t WHERE a = 4711 ORDER BY a, b, c';
    my $newStmt = $sql->removeOrderByClause($stmt);
    $self->isTest($newStmt,'SELECT a, b, c FROM t WHERE a = 4711');
}

# -----------------------------------------------------------------------------

sub test_checkName : Test(1) {
    my $self = shift;

    my $sql = Quiq::Sql->new('Oracle');
    my $name = 'abcdefghijklmnopqrstuvwxyz1234567890';
    my $val = $sql->checkName($name);
    $self->is($val,'abcdefghijklmnopqrstuvwxyz123$');
}

# -----------------------------------------------------------------------------

sub test_dataType_scalarContext : Test(12) {
    my $self = shift;

    for my $dbms (Quiq::Sql->dbmsNames()) {
        my $sql = Quiq::Sql->new($dbms);

        my $val = $sql->dataType('STRING');
        $self->like($val,qr/^(VARCHAR2?|TEXT)$/);

        eval { $sql->dataType('X') };
        $self->like($@,qr/SQL-00003/);
    }
}

sub test_dataType_arryContext : Test(42) {
    my $self = shift;

    for my $dbms (Quiq::Sql->dbmsNames()) {
        my $sql = Quiq::Sql->new($dbms);

        my ($type,$args) = $sql->dataType('STRING(10)');
        $self->like($type,qr/^VARCHAR2?|(LONG)?TEXT$/);
        $self->is($args,'(10)');

        ($type,$args) = $sql->dataType('INTEGER');
        $self->like("$type$args",qr/^(NUMBER|NUMERIC|INTEGER|BIGINT|LONG)$/);

        ($type,$args) = $sql->dataType('INTEGER(4)');
        $self->like("$type$args",
            qr/^((NUMBER|NUMERIC|LONG)\(4\))|(INTEGER|SMALLINT)$/);

        ($type,$args) = $sql->dataType('REAL(12,4)');
        if ($dbms eq 'PostgreSQL') {
            $self->is("$type$args",'NUMERIC');
        }
        else {
            $self->like("$type$args",
                qr/^(NUMBER|DECIMAL|NUMERIC|REAL|DOUBLE)\(12,4\)$/);
        }

        ($type,$args) = $sql->dataType('BLOB');
        $self->like("$type$args",qr/^((LONG)?BLOB|BYTEA|LONGBINARY)$/);

        eval { $sql->dataType('INVALID(12,4)') };
        $self->like($@,qr/SQL-00003/);
    }
}

# -----------------------------------------------------------------------------

sub test_columnDef : Test(3) {
    my $self = shift;

    my $sql = Quiq::Sql->new('Oracle');

    my $val = $sql->columnDef(type=>'STRING(20)');
    $self->is($val,'VARCHAR2(20)');

    $val = $sql->columnDef(type=>'STRING(20)',oracleType=>'VARCHAR2(10)');
    $self->is($val,'VARCHAR2(10)');

    eval { $sql->columnDef(postgresqlType=>'VARCHAR(20)') };
    $self->like($@,qr/SQL-00007/);
}

# -----------------------------------------------------------------------------

sub test_comment : Test(3) {
    my $self = shift;

    my $sql = Quiq::Sql->new('PostgreSQL');

    my $str = $sql->comment;
    $self->is($str,'');

    $str = $sql->comment('ein Kommentar');
    $self->is($str,'-- ein Kommentar');

    $str = $sql->comment("mehrzeiliger\n\nKommentar\n\n");
    $self->is($str,"-- mehrzeiliger\n--\n-- Kommentar");

    return;
}

# -----------------------------------------------------------------------------

sub test_createUser : Test(4) {
    my $self = shift;

    # Oracle

    my $sql = Quiq::Sql->new('Oracle');
    my $stmt = $sql->createUser('user1','yyy',
        -defaultTableSpace => 'dflt',
        -tempTableSpace => 'tmp',
    );
    $self->like($stmt,qr/CREATE USER user1/);
    $self->like($stmt,qr/IDENTIFIED BY yyy/);
    $self->like($stmt,qr/DEFAULT TABLESPACE dflt/);
    $self->like($stmt,qr/TEMPORARY TABLESPACE tmp/);
}

# -----------------------------------------------------------------------------

sub test_createSchema : Test(1) {
    my $self = shift;

    # PostgreSQL

    my $sql = Quiq::Sql->new('PostgreSQL');
    my $stmt = $sql->createSchema('xxx');
    $self->is($stmt,'CREATE SCHEMA xxx');
}

# -----------------------------------------------------------------------------

sub test_dropSchema : Test(1) {
    my $self = shift;

    # PostgreSQL

    my $sql = Quiq::Sql->new('PostgreSQL');
    my $stmt = $sql->dropSchema('xxx');
    $self->is($stmt,'DROP SCHEMA xxx CASCADE');
}

# -----------------------------------------------------------------------------

sub test_splitTableName : Test(5) {
    my $self = shift;

    my ($schema,$table) = Quiq::Sql->splitTableName('aaa.bbb');
    $self->is($schema,'aaa');
    $self->is($table,'bbb');

    ($schema,$table) = eval {Quiq::Sql->splitTableName('bbb')};
    $self->ok($@);

    ($schema,$table) = Quiq::Sql->splitTableName('bbb',1);
    $self->is($schema,undef);
    $self->is($table,'bbb');
}

# -----------------------------------------------------------------------------

sub test_createTable : Test(20) {
    my $self = shift;

    # Oracle -----------------------------------------------------------------

    my $dbms = 'Oracle';
    my $sql = Quiq::Sql->new($dbms);

    my $stmt = $sql->createTable('test4711',
        ['xxx',type=>'STRING(10)',notNull=>1,primaryKey=>1,autoIncrement=>1],
    );

    $self->like($stmt,qr/^CREATE TABLE test4711/);
    $self->like($stmt,qr/xxx VARCHAR2\(10\)/);
    $self->like($stmt,qr/NOT NULL/);
    $self->like($stmt,qr/PRIMARY KEY/);
    $self->unlike($stmt,qr/AUTO/);

    # PostgeSQL --------------------------------------------------------------

    $dbms = 'PostgreSQL';
    $sql = Quiq::Sql->new($dbms);

    $stmt = $sql->createTable('test4711',
        ['xxx',type=>'STRING(10)',notNull=>1,primaryKey=>1,autoIncrement=>1],
    );

    $self->like($stmt,qr/^CREATE TABLE test4711/);
    $self->like($stmt,qr/xxx VARCHAR\(10\)/);
    $self->like($stmt,qr/NOT NULL/);
    $self->like($stmt,qr/PRIMARY KEY/);
    $self->unlike($stmt,qr/AUTO/);

    # SQLite -----------------------------------------------------------------

    $dbms = 'SQLite';
    $sql = Quiq::Sql->new($dbms);

    $stmt = $sql->createTable('test4711',
        ['xxx',type=>'STRING(10)',notNull=>1,primaryKey=>1,autoIncrement=>1],
    );

    $self->like($stmt,qr/^CREATE TABLE test4711/);
    $self->like($stmt,qr/xxx TEXT\(10\)/);
    $self->like($stmt,qr/NOT NULL/);
    $self->like($stmt,qr/PRIMARY KEY/);
    $self->like($stmt,qr/AUTOINCREMENT/);

    # MySQL ------------------------------------------------------------------

    $dbms = 'MySQL';
    $sql = Quiq::Sql->new($dbms);

    $stmt = $sql->createTable('test4711',
        ['xxx',type=>'STRING(10)',notNull=>1,primaryKey=>1,autoIncrement=>1],
    );

    $self->like($stmt,qr/^CREATE TABLE test4711/);
    $self->like($stmt,qr/xxx VARCHAR\(10\)/);
    $self->like($stmt,qr/NOT NULL/);
    $self->like($stmt,qr/PRIMARY KEY/);
    $self->like($stmt,qr/AUTO_INCREMENT/);
}

# -----------------------------------------------------------------------------

sub test_legalizeTablename : Test(4) {
    my $self = shift;

    # MySQL

    my $sql = Quiq::Sql->new('MySQL');

    my $table = $sql->legalizeTablename('tab47');
    $self->is($table,'tab47');

    $table = $sql->legalizeTablename('tab-47');
    $self->is($table,'`tab-47`');

    $table = $sql->legalizeTablename('sch5.tab47');
    $self->is($table,'sch5.tab47');

    $table = $sql->legalizeTablename('sch-5.tab-47');
    $self->is($table,'`sch-5`.`tab-47`');
}

# -----------------------------------------------------------------------------

sub test_addColumn : Test(4) {
    my $self = shift;

    # Oracle

    my $sql = Quiq::Sql->new('Oracle');

    my $stmt = $sql->addColumn('person','per_id',type=>'INTEGER(10)');
    $self->is($stmt,'ALTER TABLE person ADD (per_id NUMBER(10))');

    # PostgreSQL

    $sql = Quiq::Sql->new('PostgreSQL');

    $stmt = $sql->addColumn('person','per_id',type=>'INTEGER(10)');
    $self->is($stmt,'ALTER TABLE person ADD COLUMN per_id NUMERIC(10)');

    # SQLite

    $sql = Quiq::Sql->new('SQLite');

    $stmt = $sql->addColumn('person','per_id',type=>'INTEGER(10)');
    $self->is($stmt,'ALTER TABLE person ADD COLUMN per_id INTEGER');

    # MySQL

    $sql = Quiq::Sql->new('MySQL');

    $stmt = $sql->addColumn('person','per_id',type=>'INTEGER(10)');
    $self->is($stmt,'ALTER TABLE person ADD COLUMN per_id BIGINT');
}

# -----------------------------------------------------------------------------

sub test_dropColumn : Test(2) {
    my $self = shift;

    # Oracle

    my $sql = Quiq::Sql->new('Oracle');

    my $stmt = $sql->dropColumn('person','per_geburtstag');
    $self->is($stmt,'ALTER TABLE person DROP COLUMN per_geburtstag');

    # PostgreSQL

    $sql = Quiq::Sql->new('PostgreSQL');

    $stmt = $sql->dropColumn('person','per_geburtstag');
    $self->is($stmt,'ALTER TABLE person DROP COLUMN per_geburtstag');
}

# -----------------------------------------------------------------------------

sub test_modifyColumn : Test(2) {
    my $self = shift;

    # Oracle

    my $sql = Quiq::Sql->new('Oracle');

    my $stmt = $sql->modifyColumn('person','per_geburtstag',notNull=>1);
    $self->is($stmt,'ALTER TABLE person MODIFY per_geburtstag NOT NULL');

    # PostgreSQL

    $sql = Quiq::Sql->new('PostgreSQL');

    $stmt = $sql->modifyColumn('person','per_geburtstag',notNull=>1);
    $self->is($stmt,
        'ALTER TABLE person ALTER COLUMN per_geburtstag SET NOT NULL');
}

# -----------------------------------------------------------------------------

sub test_renameColumn : Test(2) {
    my $self = shift;

    # Oracle

    my $sql = Quiq::Sql->new('Oracle');

    my $stmt = $sql->renameColumn('person','per_name','per_nachname');
    # is $stmt,'ALTER TABLE person RENAME COLUMN per_name TO per_nachname';
    $self->isTest($stmt,
        'ALTER TABLE person RENAME COLUMN per_name TO per_nachname');

    # PostgreSQL

    $sql = Quiq::Sql->new('PostgreSQL');

    $stmt = $sql->renameColumn('person','per_name','per_nachname');
    $self->isTest($stmt,
        'ALTER TABLE person RENAME COLUMN per_name TO per_nachname');
}

# -----------------------------------------------------------------------------

sub test_addPrimaryKeyConstraint : Test(3) {
    my $self = shift;

    # PostgreSQL

    my $sql = Quiq::Sql->new('PostgreSQL');
    my $stmt = $sql->addPrimaryKeyConstraint('tab1',['col1','col2']);
    $self->like($stmt,qr/ALTER TABLE tab1/);
    $self->like($stmt,qr/CONSTRAINT tab1_PK/);
    $self->like($stmt,qr/PRIMARY KEY \(col1, col2\)/);
}

# -----------------------------------------------------------------------------

sub test_addForeignKeyConstraint : Test(6) {
    my $self = shift;

    # PostgreSQL

    my $sql = Quiq::Sql->new('PostgreSQL');
    my $stmt = $sql->addForeignKeyConstraint('tab1',['col1','col2'],'tab2',
        -constraintName => 'tab1_tab2_FK',
        -defer => 1,
        -onDelete => 'cascade',
    );
    $self->like($stmt,qr/ALTER TABLE tab1 ADD/);
    $self->like($stmt,qr/CONSTRAINT tab1_tab2_FK/);
    $self->like($stmt,qr/FOREIGN KEY \(col1, col2\)/);
    $self->like($stmt,qr/REFERENCES tab2/);
    $self->like($stmt,qr/ON DELETE CASCADE/);
    $self->like($stmt,qr/DEFERRABLE INITIALLY DEFERRED/);
}

# -----------------------------------------------------------------------------

sub test_addNotNullConstraint : Test(3) {
    my $self = shift;

    # PostgreSQL

    my $sql = Quiq::Sql->new('PostgreSQL');
    my $stmt = $sql->addNotNullConstraint('tab1','col1');
    $self->like($stmt,qr/ALTER TABLE tab1/);
    $self->like($stmt,qr/ALTER COLUMN col1/);
    $self->like($stmt,qr/SET NOT NULL/);
}

# -----------------------------------------------------------------------------

sub test_addCheckConstraint : Test(3) {
    my $self = shift;

    # PostgreSQL

    my $sql = Quiq::Sql->new('PostgreSQL');
    my $stmt = $sql->addCheckConstraint('tab1','col1 > col2');
    $self->like($stmt,qr/ALTER TABLE tab1/);
    $self->like($stmt,qr/CONSTRAINT tab1_CK/);
    $self->like($stmt,qr/CHECK \(col1 > col2\)/);
}

# -----------------------------------------------------------------------------

sub test_addUniqueConstraint : Test(3) {
    my $self = shift;

    # PostgreSQL

    my $sql = Quiq::Sql->new('PostgreSQL');
    my $stmt = $sql->addUniqueConstraint('tab1',['col1','col2']);
    $self->like($stmt,qr/ALTER TABLE tab1/);
    $self->like($stmt,qr/CONSTRAINT tab1_UQ_col1_col2/);
    $self->like($stmt,qr/UNIQUE \(col1, col2\)/);
}

# -----------------------------------------------------------------------------

sub test_createIndex : Test(3) {
    my $self = shift;

    # PostgreSQL

    my $sql = Quiq::Sql->new('PostgreSQL');
    my $stmt = $sql->createIndex('tab1',['col1','col2']);
    $self->like($stmt,qr/CREATE INDEX tab1_ix_col1_col2/);
    $self->like($stmt,qr/ON tab1/);
    $self->like($stmt,qr/\(col1, col2\)/);
}

# -----------------------------------------------------------------------------

sub test_createFunction_postgresql : Test(4) {
    my $self = shift;

    # PostgreSQL

    my $sql = Quiq::Sql->new('PostgreSQL');
    my $stmt = $sql->createFunction(
        '<name>',
        -replace => 1,
        -returns => '<returns>','
        <body>
        ',
    );
    # warn $stmt,"\n";
    $self->like($stmt,qr/<name>\(\)/);
    $self->like($stmt,qr/\bOR REPLACE\b/);
    $self->like($stmt,qr/\bRETURNS <returns>/);
    $self->like($stmt,qr/<body>/);
}

# -----------------------------------------------------------------------------

sub test_createTrigger_oracle : Test(6) {
    my $self = shift;

    # Oracle

    my $sql = Quiq::Sql->new('Oracle');
    my $stmt = $sql->createTrigger(
        '<table>',
        '<name>',
        'before',
        'insert|update',
        'row',
        -replace => 1,'
        <body>
        '
    );
    # warn $stmt,"\n";
    $self->like($stmt,qr/^CREATE OR REPLACE TRIGGER <name>/);
    $self->like($stmt,qr/\bBEFORE\b/);
    $self->like($stmt,qr/\bINSERT OR UPDATE\b/);
    $self->like($stmt,qr/\bON <table>/);
    $self->like($stmt,qr/\bFOR EACH ROW\b/);
    $self->like($stmt,qr/<body>/);
}

sub test_createTrigger_postgresql : Test(6) {
    my $self = shift;

    # PostgreSQL

    my $sql = Quiq::Sql->new('PostgreSQL');
    my $stmt = $sql->createTrigger(
        '<table>',
        '<name>',
        'before',
        'insert|update',
        'row',
        -replace => 1,
        -execute => '<proc>',
    );
    # warn $stmt,"\n";
    $self->like($stmt,qr/^CREATE TRIGGER <name>/);
    $self->like($stmt,qr/\bBEFORE\b/);
    $self->like($stmt,qr/\bINSERT OR UPDATE\b/);
    $self->like($stmt,qr/\bON <table>/);
    $self->like($stmt,qr/\bFOR EACH ROW\b/);
    $self->like($stmt,qr/\bEXECUTE PROCEDURE <proc>\(\)/);
}

# -----------------------------------------------------------------------------

sub test_grant : Test(3) {
    my $self = shift;

    # PostgreSQL

    my $sql = Quiq::Sql->new('PostgreSQL');
    my $stmt = $sql->grant('TABLE','tab1','ALL','PUBLIC');
    $self->like($stmt,qr/GRANT ALL/);
    $self->like($stmt,qr/ON TABLE tab1/);
    $self->like($stmt,qr/TO PUBLIC/);

    return;
}

# -----------------------------------------------------------------------------

sub test_grantUser : Test(2) {
    my $self = shift;

    # PostgreSQL

    my $sql = Quiq::Sql->new('Oracle');
    my $stmt = $sql->grantUser('user1','connect, resource, dba');
    $self->like($stmt,qr/GRANT connect, resource, dba/);
    $self->like($stmt,qr/TO user1/);

    return;
}

# -----------------------------------------------------------------------------

sub test_select : Test(7) {
    my $self = shift;

    # keine Klauseln

    my $sql = Quiq::Sql->new('PostgreSQL');

    my $stmt1 = Quiq::String->removeIndentation(<< '    __SQL__');
    SELECT
        *
    __SQL__

    my $stmt = $sql->select;
    $self->is($stmt,$stmt1);

    # Nur Tabellenname

    $stmt1 = Quiq::String->removeIndentation(<< '    __SQL__');
    SELECT
        *
    FROM
        tab
    __SQL__

    $stmt = $sql->select('tab');
    $self->is($stmt,$stmt1);

    # Tabellenname und Suchkriterien

    $stmt1 = Quiq::String->removeIndentation(<< '    __SQL__');
    SELECT
        *
    FROM
        person
    WHERE
        vorname = 'Elli'
        AND nachname = 'Pirelli'
    __SQL__

    $stmt = $sql->select('person',vorname=>'Elli',nachname=>'Pirelli');
    $self->is($stmt,$stmt1);

    # SELECT, FROM, WHERE, ORDER BY

    $stmt = $sql->select(
        -select => 'col1','col2','col3',
        -from => 'tab',
        -where => 'col1 > col2','col2 > col3',
        -orderBy => 1,
    );

    my $stmt2 = Quiq::String->removeIndentation(<< '    __SQL__');
    SELECT
        col1,
        col2,
        col3
    FROM
        tab
    WHERE
        col1 > col2
        AND col2 > col3
    ORDER BY
        1
    __SQL__

    $self->is($stmt,$stmt2);

    # Mit Statement-Muster und Platzhaltern

    $stmt = $sql->select(
        -stmt => '
        SELECT
            %SELECT%
        FROM
            %FROM%
        WHERE
            %WHERE%
        ORDER BY
            %ORDERBY%
        ',
        -select => 'col1','col2','col3',
        -from => 'tab',
        -where => 'col1 > col2','col2 > col3',
        -orderBy => 1,
    );

    $self->is($stmt,$stmt2);

    # Mit Statement-Muster und Klausel-Ergänzungen

    $stmt = $sql->select(
        -stmt => '
        SELECT
            %SELECT%
        ',
        -select => 'col1','col2','col3',
        -from => 'tab',
        -where => 'col1 > col2','col2 > col3',
        -orderBy => 1,
    );

    $self->is($stmt,$stmt2);

    my $select = <<'    __SQL__';
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
    
    $stmt2 = Quiq::String->removeIndentation(<< '    __SQL__');
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
    __SQL__

    $self->is($stmt,$stmt2);
}

# -----------------------------------------------------------------------------

sub test_insert_1 : Test(1) {
    my $self = shift;

    my $sql = Quiq::Sql->new('PostgreSQL');

    my $stmt1 = Quiq::String->removeIndentation(<<'    __SQL__');
    INSERT INTO person (
        per_id,
        per_vorname,
        per_nachname
    )
    VALUES (
        '10',
        'Hanno',
        'Seitz'
    )
    __SQL__

    my $stmt = $sql->insert('person',
        per_id => 10,
        per_vorname => 'Hanno',
        per_nachname => 'Seitz',
        per_geburtstag => undef,
    );
    $self->is($stmt,$stmt1);
}

#------------------------------------------------------------------------------

sub test_insert_1b : Test(1) {
    my $self = shift;

    my $sql = Quiq::Sql->new('PostgreSQL');

    my $stmt1 = Quiq::String->removeIndentation(<<'    __SQL__');
    INSERT INTO person (
        per_id,
        per_vorname,
        per_nachname
    )
    VALUES (
        '10',
        'Hanno',
        'Seitz'
    )
    __SQL__

    my @keys = qw/per_id per_vorname per_nachname per_geburtstag/;
    my @vals = (10,'Hanno','Seitz',undef);
    my $stmt = $sql->insert('person',\@keys,\@vals);

    $self->is($stmt,$stmt1);
}

#------------------------------------------------------------------------------

sub test_insert_2 : Test(1) {
    my $self = shift;

    my $sql = Quiq::Sql->new('PostgreSQL');

    my $stmt1 = Quiq::String->removeIndentation(<<'    __SQL__');
    INSERT INTO objekt (
        obj_id,
        obj_letzteaenderung
    )
    VALUES (
        '4711',
        SYSDATE
    )
    __SQL__

    my $stmt = $sql->insert('objekt',
        obj_id => 4711,
        obj_letzteaenderung => \'SYSDATE',
    );
    $self->is($stmt,$stmt1);
}

#------------------------------------------------------------------------------

sub test_insert_3 : Test(3) {
    my $self = shift;

    my $sql = Quiq::Sql->new('PostgreSQL');

    my $stmt = $sql->insert('person');
    $self->is($stmt,'');

    $stmt = $sql->insert('person',
        per_id => undef,
        per_vorname => undef,
        per_nachname => undef,
        per_geburtstag => undef,
    );
    $self->is($stmt,'');

    $stmt = $sql->insert('person',
        per_id => '',
        per_vorname => '',
        per_nachname => '',
        per_geburtstag => '',
    );
    $self->is($stmt,'');
}

#------------------------------------------------------------------------------

sub test_insert_4 : Test(1) {
    my $self = shift;

    my $sql = Quiq::Sql->new('PostgreSQL');

    my $stmt1 = Quiq::String->removeIndentation(<<'    __SQL__');
    INSERT INTO person (
        per_id,
        per_vorname,
        per_nachname,
        per_geburtstag
    )
    VALUES (
        ?,
        ?,
        ?,
        ?
    )
    __SQL__

    my $stmt = $sql->insert('person',
        per_id => \'?',
        per_vorname => \'?',
        per_nachname => \'?',
        per_geburtstag => \'?',
    );
    $self->is($stmt,$stmt1);
}

# -----------------------------------------------------------------------------

sub test_insertMulti_1 : Test(2) {
    my $self = shift;

    my $expected = sprintf Quiq::Unindent->string(q~
        INSERT INTO person
            (per_id, per_vorname, per_nachname, per_geburtstag)
        VALUES
            ('1', 'Linus', 'Seitz', '2002-11-11'),
            ('2', 'Hanno', 'Seitz', '2000-04-07')
    ~);

    my $sql = Quiq::Sql->new('PostgreSQL');

    my $stmt = $sql->insertMulti('person',
        [qw/per_id per_vorname per_nachname per_geburtstag/],
        [], # keine Daten
    );
    $self->is($stmt,'');

    $stmt = $sql->insertMulti('person',
        [qw/per_id per_vorname per_nachname per_geburtstag/],[
            [qw/1 Linus Seitz 2002-11-11/],
            [qw/2 Hanno Seitz 2000-04-07/],
        ]
    );
    $self->is($stmt,$expected);
}

# -----------------------------------------------------------------------------

sub test_update : Test(3) {
    my $self = shift;

    my $sql = Quiq::Sql->new('PostgreSQL');

    # -

    my $stmt = $sql->update('person');
    $self->is($stmt,'');

    # -

    my $stmt0 = Quiq::String->removeIndentation(<<'    __SQL__');
    UPDATE person SET
        per_vorname = 'Hanno'
    __SQL__

    $stmt = $sql->update('person',
        per_vorname => 'Hanno',
    );
    $self->is($stmt,$stmt0);

    # -

    $stmt0 = Quiq::String->removeIndentation(<<'    __SQL__');
    UPDATE person SET
        per_vorname = 'Hanno',
        per_nachname = 'Seitz'
    WHERE
        per_id = '4711'
    __SQL__

    $stmt = $sql->update('person',
        per_vorname => 'Hanno',
        per_nachname => 'Seitz',
        -where,per_id => 4711,
    );
    $self->is($stmt,$stmt0);
}

# -----------------------------------------------------------------------------

sub test_delete : Test(2) {
    my $self = shift;

    # kein WHERE

    my $sql = Quiq::Sql->new('PostgreSQL') ;

    my $stmt = $sql->delete('person');
    $self->is($stmt,'DELETE FROM person');

    # mit WHERE

    $stmt = $sql->delete('person',
        'col1 > col2','col2 > col3',
    );

    my $stmt2 = Quiq::String->removeIndentation(<< '    __SQL__');
    DELETE FROM person
    WHERE
        col1 > col2
        AND col2 > col3
    __SQL__

    $self->is($stmt,$stmt2);
}

# -----------------------------------------------------------------------------

sub test_keyExpr_key : Test(4) {
    my $self = shift;

    my $sql = Quiq::Sql->new('PostgreSQL');

    eval { $sql->keyExpr(undef) };
    $self->like($@,qr/SQL-00005/);

    my $str = $sql->keyExpr('per_id');
    $self->is($str,'per_id');

    $str = $sql->keyExpr('UPPER(per_nachname)');
    $self->is($str,'UPPER(per_nachname)');

    $str = $sql->keyExpr(['UPPER','per_nachname']);
    $self->is($str,'UPPER(per_nachname)');

    # FIXME: weitere Tests
}

# -----------------------------------------------------------------------------

sub test_valExpr_key : Test(3) {
    my $self = shift;

    my $sql = Quiq::Sql->new('PostgreSQL');

    my $str = $sql->valExpr('Kai Nelust');
    $self->is($str,"'Kai Nelust'");

    $str = $sql->valExpr(\'USERNAME');
    $self->is($str,"USERNAME");

    $str = $sql->valExpr(['LOWER','Elli Pirelli']);
    $self->is($str,"LOWER('Elli Pirelli')");
}

# -----------------------------------------------------------------------------

sub test_whereExpr_key : Test(3) {
    my $self = shift;

    my $sql = Quiq::Sql->new('PostgreSQL');

    my $str = $sql->whereExpr('Kai Nelust');
    $self->is($str,"= 'Kai Nelust'");

    $str = $sql->whereExpr(\'USERNAME');
    $self->is($str,"= USERNAME");

    $str = $sql->whereExpr(['!=',['LOWER','Elli Pirelli']]);
    $self->is($str,"!= LOWER('Elli Pirelli')");
}

# -----------------------------------------------------------------------------

sub test_stringLiteral : Test(1) {
    my $self = shift;

    my $sql = Quiq::Sql->new('PostgreSQL');

    my $val = $sql->stringLiteral('');
    $self->is($val,'');

    return;
}

# -----------------------------------------------------------------------------

sub test_selectClause : Test(0) {
    my $self = shift;

    my $sql = Quiq::Sql->new('PostgreSQL');

    return;
}

# -----------------------------------------------------------------------------

sub test_fromClause_oracle : Test(2) {
    my $self = shift;

    my $sql = Quiq::Sql->new('Oracle');
    my $fromClause = $sql->fromClause('x');
    $self->is($fromClause,'x');

    $fromClause = $sql->fromClause(['AS','x','y']);
    $self->is($fromClause,'x y');
}

sub test_fromClause_postgresql : Test(2) {
    my $self = shift;

    my $sql = Quiq::Sql->new('PostgreSQL');
    my $fromClause = $sql->fromClause('x');
    $self->is($fromClause,'x');

    $fromClause = $sql->fromClause(['AS','x','y']);
    $self->is($fromClause,'x AS y');
}

# -----------------------------------------------------------------------------

sub test_whereClause : Test(7) {
    my $self = shift;

    my $sql = Quiq::Sql->new('PostgreSQL');

    my $where = $sql->whereClause;
    $self->is($where,'');

    $where = $sql->whereClause('a = b');
    $self->is($where,'a = b');

    $where = $sql->whereClause(a=>'b');
    $self->is($where,"a = 'b'");

    $where = $sql->whereClause(a=>undef);
    $self->is($where,'');

    $where = $sql->whereClause(a=>'');
    $self->is($where,'');

    $where = $sql->whereClause(a=>['>=',7]);
    $self->is($where,"a >= '7'");

    $where = $sql->whereClause(['UPPER','a']=>['=',['UPPER','b']]);
    $self->is($where,"UPPER(a) = UPPER('b')");

    return;
}

# -----------------------------------------------------------------------------

sub test_setClause : Test(6) {
    my $self = shift;

    my $sql = Quiq::Sql->new('PostgreSQL');

    my $set = $sql->setClause;
    $self->is($set,'');

    $set = $sql->setClause(per_geburtsdatum=>undef);
    $self->is($set,"per_geburtsdatum = NULL");

    $set = $sql->setClause(per_geburtsdatum=>'');
    $self->is($set,"per_geburtsdatum = NULL");

    $set = $sql->setClause(anzahl=>0);
    $self->is($set,"anzahl = '0'");

    $set = $sql->setClause(per_vorname=>'Hanno');
    $self->is($set,"per_vorname = 'Hanno'");

    $set = $sql->setClause(per_vorname=>'Hanno',per_nachname=>'Seitz');
    $self->is($set,"per_vorname = 'Hanno',\n    per_nachname = 'Seitz'");
}

# -----------------------------------------------------------------------------

sub test_exists : Test(2) {
    my $self = shift;

    my $sql = Quiq::Sql->new('PostgreSQL');

    my $str = $sql->exists('person');
    $self->like($str,qr/^EXISTS \(/);
    $self->like($str,qr/\bperson\b/);
}

# -----------------------------------------------------------------------------

sub test_notExists : Test(2) {
    my $self = shift;

    my $sql = Quiq::Sql->new('PostgreSQL');

    my $str = $sql->notExists('person');
    $self->like($str,qr/^NOT EXISTS \(/);
    $self->like($str,qr/\bperson\b/);
}

# -----------------------------------------------------------------------------

package main;
Quiq::Sql::Test->runTests;

# eof
