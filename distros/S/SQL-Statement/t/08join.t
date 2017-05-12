#!/usr/bin/perl -w
use strict;
use warnings;
use lib qw(t);

use Test::More;
use TestLib qw(connect prove_reqs show_reqs test_dir default_recommended);

use Params::Util qw(_CODE _ARRAY);

my ( $required, $recommended ) = prove_reqs( { default_recommended(), ( MLDBM => 0 ) } );
show_reqs( $required, $recommended );
my @test_dbds = ( 'SQL::Statement', grep { /^dbd:/i } keys %{$recommended} );
my $testdir = test_dir();

my @massValues = map { [ $_, ( "a" .. "f" )[ int rand 6 ], int rand 10 ] } ( 1 .. 3999 );

SKIP:
foreach my $test_dbd (@test_dbds)
{
    my $dbh;
    note("Running tests for $test_dbd");
    my $temp = "";
    # XXX
    # my $test_dbd_tbl = "${test_dbd}::Table";
    # $test_dbd_tbl->can("fetch") or $temp = "$temp";
    $test_dbd eq "DBD::File"      and $temp = "TEMP";
    $test_dbd eq "SQL::Statement" and $temp = "TEMP";

    my %extra_args;
    if ( $test_dbd eq "DBD::DBM" )
    {
        if ( $recommended->{MLDBM} )
        {
            $extra_args{dbm_mldbm} = "Storable";
        }
        else
        {
            skip( 'DBD::DBM test runs without MLDBM', 1 );
        }
    }
    $dbh = connect(
                    $test_dbd,
                    {
                       PrintError => 0,
                       RaiseError => 0,
                       f_dir      => $testdir,
                       %extra_args,
                    }
                  );

    my ( $sth, $str );
    my $now = time();
    my @timelist;
    for my $hour ( 1 .. 10 )
    {
        push( @timelist, $now - ( $hour * 3600 ) );
    }

    for my $sql (
        split /\n/, <<""
	CREATE $temp TABLE Prof (pname CHAR, pid INT)
	INSERT INTO Prof VALUES ('Sue', 1)
	INSERT INTO Prof VALUES ('Bob', 2)
	INSERT INTO Prof VALUES ('Tom', 3)
	CREATE $temp TABLE Subject (sname CHAR, pid INT)
	INSERT INTO Subject VALUES ('Chem', 1)
	INSERT INTO Subject VALUES ('Bio', 2)
	INSERT INTO Subject VALUES ('Math', 2)
	INSERT INTO Subject VALUES ('English', 4)
	CREATE $temp TABLE Room (rname CHAR, pid INT)
	INSERT INTO Room VALUES ('1C', 1)
	INSERT INTO Room VALUES ('2B', 2)
	CREATE $temp TABLE author (author_name CHAR, author_id INT)
	INSERT INTO author VALUES ('Neal Stephenson',1)
	INSERT INTO author VALUES ('Vernor Vinge',2)
	CREATE $temp TABLE book (book_title CHAR, author_id INT)
	INSERT INTO book VALUES ('Cryptonomicon',1)
	INSERT INTO book VALUES ('Dahlgren',3)
	CREATE $temp TABLE t1 (num INT, name CHAR)
	INSERT INTO t1 VALUES (1,'a')
	INSERT INTO t1 VALUES (2,'b')
	INSERT INTO t1 VALUES (3,'c')
	CREATE $temp TABLE t2 (num INT, wert CHAR)
	INSERT INTO t2 VALUES (1,'xxx')
	INSERT INTO t2 VALUES (3,'yyy')
	INSERT INTO t2 VALUES (5,'zzz')
	CREATE $temp TABLE APPL (id INT, applname CHAR, appluniq CHAR, version CHAR, appl_type CHAR)
	INSERT INTO APPL VALUES ( 1, 'ZQF', 'ZFQLIN', '10.2.0.4', 'Oracle DB')
	INSERT INTO APPL VALUES ( 2, 'YRA', 'YRA-UX', '10.2.0.2', 'Oracle DB')
	INSERT INTO APPL VALUES ( 3, 'PRN1', 'PRN1-4.B2', '1.1.22', 'CUPS' )
	INSERT INTO APPL VALUES ( 4, 'PRN2', 'PRN2-4.B2', '1.1.22', 'CUPS' )
	INSERT INTO APPL VALUES ( 5, 'PRN1', 'PRN1-4.B1', '1.1.22', 'CUPS' )
	INSERT INTO APPL VALUES ( 7, 'PRN2', 'PRN2-4.B1', '1.1.22', 'CUPS' )
	INSERT INTO APPL VALUES ( 8, 'sql-stmt', 'SQL::Statement', '1.21', 'Project Web-Site')
	INSERT INTO APPL VALUES ( 9, 'cpan.org', 'http://www.cpan.org/', '1.0', 'Web-Site')
	INSERT INTO APPL VALUES (10, 'httpd', 'cpan-apache', '2.2.13', 'Web-Server')
	INSERT INTO APPL VALUES (11, 'cpan-mods', 'cpan-mods', '8.4.1', 'PostgreSQL DB')
	INSERT INTO APPL VALUES (12, 'cpan-authors', 'cpan-authors', '8.4.1', 'PostgreSQL DB')
	CREATE $temp TABLE NODE (id INT, nodename CHAR, os CHAR, version CHAR)
	INSERT INTO NODE VALUES ( 1, 'ernie', 'RHEL', '5.2')
	INSERT INTO NODE VALUES ( 2, 'bert', 'RHEL', '5.2')
	INSERT INTO NODE VALUES ( 3, 'statler', 'FreeBSD', '7.2')
	INSERT INTO NODE VALUES ( 4, 'waldorf', 'FreeBSD', '7.2')
	INSERT INTO NODE VALUES ( 5, 'piggy', 'NetBSD', '5.0.2')
	INSERT INTO NODE VALUES ( 6, 'kermit', 'NetBSD', '5.0.2')
	INSERT INTO NODE VALUES ( 7, 'samson', 'NetBSD', '5.0.2')
	INSERT INTO NODE VALUES ( 8, 'tiffy', 'NetBSD', '5.0.2')
	INSERT INTO NODE VALUES ( 9, 'rowlf', 'Debian Lenny', '5.0')
	INSERT INTO NODE VALUES (10, 'fozzy', 'Debian Lenny', '5.0')
	CREATE $temp TABLE PREC (id INT, appl_id INT, node_id INT, precedence INT)
	INSERT INTO PREC VALUES ( 1,  1,  1, 1)
	INSERT INTO PREC VALUES ( 2,  1,  2, 2)
	INSERT INTO PREC VALUES ( 3,  2,  2, 1)
	INSERT INTO PREC VALUES ( 4,  2,  1, 2)
	INSERT INTO PREC VALUES ( 5,  3,  5, 1)
	INSERT INTO PREC VALUES ( 6,  3,  7, 2)
	INSERT INTO PREC VALUES ( 7,  4,  6, 1)
	INSERT INTO PREC VALUES ( 8,  4,  8, 2)
	INSERT INTO PREC VALUES ( 9,  5,  7, 1)
	INSERT INTO PREC VALUES (10,  5,  5, 2)
	INSERT INTO PREC VALUES (11,  6,  8, 1)
	INSERT INTO PREC VALUES (12,  7,  6, 2)
	INSERT INTO PREC VALUES (13, 10,  9, 1)
	INSERT INTO PREC VALUES (14, 10, 10, 1)
	INSERT INTO PREC VALUES (15,  8,  9, 1)
	INSERT INTO PREC VALUES (16,  8, 10, 1)
	INSERT INTO PREC VALUES (17,  9,  9, 1)
	INSERT INTO PREC VALUES (18,  9, 10, 1)
	INSERT INTO PREC VALUES (19, 11,  3, 1)
	INSERT INTO PREC VALUES (20, 11,  4, 2)
	INSERT INTO PREC VALUES (21, 12,  4, 1)
	INSERT INTO PREC VALUES (22, 12,  3, 2)
	CREATE $temp TABLE LANDSCAPE (id INT, landscapename CHAR)
	INSERT INTO LANDSCAPE VALUES (1, 'Logistic')
	INSERT INTO LANDSCAPE VALUES (2, 'Infrastructure')
	INSERT INTO LANDSCAPE VALUES (3, 'CPAN')
	CREATE $temp TABLE CONTACT (id INT, surname CHAR, familyname CHAR, phone CHAR, userid CHAR, mailaddr CHAR)
	INSERT INTO CONTACT VALUES ( 1, 'Hans Peter', 'Mueller', '12345', 'HPMUE', 'hp-mueller\@here.com')
	INSERT INTO CONTACT VALUES ( 2, 'Knut', 'Inge', '54321', 'KINGE', 'k-inge\@here.com')
	INSERT INTO CONTACT VALUES ( 3, 'Lola', 'Nguyen', '+1-123-45678-90', 'LNYUG', 'lola.ngyuen\@customer.com')
	INSERT INTO CONTACT VALUES ( 4, 'Helge', 'Brunft', '+41-123-45678-09', 'HBRUN', 'helge.brunft\@external-dc.at')
	-- TYPE: 1: APPL 2: NODE 3: CONTACT
	CREATE $temp TABLE NM_LANDSCAPE (id INT, ls_id INT, obj_id INT, obj_type INT)
	INSERT INTO NM_LANDSCAPE VALUES ( 1, 1, 1, 2)
	INSERT INTO NM_LANDSCAPE VALUES ( 2, 1, 2, 2)
	INSERT INTO NM_LANDSCAPE VALUES ( 3, 3, 3, 2)
	INSERT INTO NM_LANDSCAPE VALUES ( 4, 3, 4, 2)
	INSERT INTO NM_LANDSCAPE VALUES ( 5, 2, 5, 2)
	INSERT INTO NM_LANDSCAPE VALUES ( 6, 2, 6, 2)
	INSERT INTO NM_LANDSCAPE VALUES ( 7, 2, 7, 2)
	INSERT INTO NM_LANDSCAPE VALUES ( 8, 2, 8, 2)
	INSERT INTO NM_LANDSCAPE VALUES ( 9, 3, 9, 2)
	INSERT INTO NM_LANDSCAPE VALUES (10, 3,10, 2)
	INSERT INTO NM_LANDSCAPE VALUES (11, 1, 1, 1)
	INSERT INTO NM_LANDSCAPE VALUES (12, 2, 2, 1)
	INSERT INTO NM_LANDSCAPE VALUES (13, 2, 2, 3)
	INSERT INTO NM_LANDSCAPE VALUES (14, 3, 1, 3)
	CREATE $temp TABLE APPL_CONTACT (id INT, contact_id INT, appl_id INT, contact_type CHAR)
	INSERT INTO APPL_CONTACT VALUES (1, 3, 1, 'OWNER')
	INSERT INTO APPL_CONTACT VALUES (2, 3, 2, 'OWNER')
	INSERT INTO APPL_CONTACT VALUES (3, 4, 3, 'ADMIN')
	INSERT INTO APPL_CONTACT VALUES (4, 4, 4, 'ADMIN')
	INSERT INTO APPL_CONTACT VALUES (5, 4, 5, 'ADMIN')
	INSERT INTO APPL_CONTACT VALUES (6, 4, 6, 'ADMIN')

                )
    {
        $sql =~ m/^\s*--/ and next;
        ok( $sth = $dbh->prepare($sql), "prepare $sql on $test_dbd" ) or diag( $dbh->errstr() );
        ok( $sth->execute(), "execute $sql on $test_dbd" ) or diag( $sth->errstr() );
    }

    my @tests = (
        {
           test   => 'NATURAL JOIN - with named columns in select list',
           sql    => "SELECT pname,sname FROM Prof NATURAL JOIN Subject",
           result => [ [qw(Sue Chem)], [qw(Bob Bio)], [qw(Bob Math)], ],
        },
        {
           test   => 'NATURAL JOIN - with select list = *',
           sql    => "SELECT * FROM Prof NATURAL JOIN Subject",
           result => [ [qw(Sue 1 Chem)], [qw(Bob 2 Bio)], [qw(Bob 2 Math)], ],
        },
        {
           test   => 'NATURAL JOIN - with computed columns',
           sql    => "SELECT UPPER(pname) AS P,Prof.pid,pname,sname FROM Prof NATURAL JOIN Subject",
           result => [ [qw(SUE 1 Sue Chem)], [qw(BOB 2 Bob Bio)], [qw(BOB 2 Bob Math)], ],
        },
        {
           test   => 'NATURAL JOIN - with no specifier on join column',
           sql    => "SELECT UPPER(pname) AS P,pid,pname,sname FROM Prof NATURAL JOIN Subject",
           result => [ [qw(SUE 1 Sue Chem)], [qw(BOB 2 Bob Bio)], [qw(BOB 2 Bob Math)], ],
        },
        {
           test   => 'INNER JOIN - with no specifier on join column',
           sql    => "SELECT UPPER(pname) AS P,pid,pname,sname FROM Prof JOIN Subject using (pid)",
           result => [ [qw(SUE 1 Sue Chem)], [qw(BOB 2 Bob Bio)], [qw(BOB 2 Bob Math)], ],
        },
        {
           test   => 'LEFT JOIN',
           sql    => "SELECT * FROM Prof LEFT JOIN Subject USING(pid)",
           result => [ [qw(Sue 1 Chem)], [qw(Bob 2 Bio)], [qw(Bob 2 Math)], [ 'Tom', 3, undef ], ],
        },
        {
           test   => 'LEFT JOIN - enumerated columns',
           sql    => "SELECT pid,pname,sname FROM Prof LEFT JOIN Subject USING(pid)",
           result => [ [qw(1 Sue Chem)], [qw(2 Bob Bio)], [qw(2 Bob Math)], [ 3, 'Tom', undef ], ],
        },
        {
           test => 'LEFT JOIN - perversely intentionally mis-enumerated columns',
           sql  => "SELECT subject.pid,pname,sname FROM Prof LEFT JOIN Subject USING(pid)",
           result =>
             [ [qw(1 Sue Chem)], [qw(2 Bob Bio)], [qw(2 Bob Math)], [ undef, 'Tom', undef ], ],
        },
        {
           test => 'LEFT JOIN - lower case keywords',
           sql  => "SELECT subject.pid, pname, sname FROM prof LEFT JOIN subject USING(pid)",
           result =>
             [ [qw(1 Sue Chem)], [qw(2 Bob Bio)], [qw(2 Bob Math)], [ undef, 'Tom', undef ], ],
        },
        {
           test => 'RIGHT JOIN',
           sql  => "SELECT * FROM Prof RIGHT JOIN Subject USING(pid)",
           result =>
             [ [qw(Sue 1 Chem)], [qw(Bob 2 Bio)], [qw(Bob 2 Math)], [ undef, undef, 'English' ], ],
        },
        {
           test => 'RIGHT JOIN - enumerated columns',
           sql  => "SELECT pid,sname,pname FROM Prof RIGHT JOIN Subject USING(pid)",
           result =>
             [ [qw(1 Chem Sue)], [qw(2 Bio Bob)], [qw(2 Math Bob)], [ undef, 'English', undef ], ],
        },
        {
           test   => 'FULL JOIN',
           sql    => "SELECT * FROM Prof FULL JOIN Subject USING(pid)",
           result => [
                      [qw(Sue 1 Chem)], [qw(Bob 2 Bio)],
                      [qw(Bob 2 Math)], [ 'Tom', 3, undef ],
                      [ undef, 4, 'English' ],
                     ],
        },
        {
           test   => 'IMPLICIT JOIN - two tables',
           sql    => "SELECT * FROM Prof AS P,Subject AS S WHERE P.pid=S.pid",
           result => [ [qw(Sue 1 Chem 1)], [qw(Bob 2 Bio 2)], [qw(Bob 2 Math 2)], ],
        },
        {
           test => 'IMPLICIT JOIN - three tables',
           sql  => "SELECT *
		    FROM Prof AS P,Subject AS S,Room AS R
		   WHERE P.pid=S.pid
		     AND P.pid=R.pid",
           result => [ [qw(Sue 1 Chem 1 1C 1)], [qw(Bob 2 Bio 2 2B 2)], [qw(Bob 2 Math 2 2B 2)], ],
        },
        {
           test        => 'NATURAL JOIN - on unique id\'s with select list = *',
           sql         => "SELECT * FROM author NATURAL JOIN book",
           result_cols => [qw(author_name author_id book_title)],
           result      => [ [ 'Neal Stephenson', '1', 'Cryptonomicon' ], ],
        },
        {
           test        => 'CROSS JOIN with select list = *',
           sql         => "SELECT * FROM t1 CROSS JOIN t2",
           result_cols => [qw(num name num wert)],
           result      => [
                       [ 1, 'a', 1, 'xxx' ],
                       [ 1, 'a', 3, 'yyy' ],
                       [ 1, 'a', 5, 'zzz' ],
                       [ 2, 'b', 1, 'xxx' ],
                       [ 2, 'b', 3, 'yyy' ],
                       [ 2, 'b', 5, 'zzz' ],
                       [ 3, 'c', 1, 'xxx' ],
                       [ 3, 'c', 3, 'yyy' ],
                       [ 3, 'c', 5, 'zzz' ],
                     ],
           comment => q{
 num | name | num | wert
-----+------+-----+------
   1 | a    |   1 | xxx
   1 | a    |   3 | yyy
   1 | a    |   5 | zzz
   2 | b    |   1 | xxx
   2 | b    |   3 | yyy
   2 | b    |   5 | zzz
   3 | c    |   1 | xxx
   3 | c    |   3 | yyy
   3 | c    |   5 | zzz
	   }
        },
        {
           test        => 'INNER JOIN with select list = *',
           sql         => "SELECT * FROM t1 INNER JOIN t2 ON t1.num = t2.num",
           result_cols => [qw(num name num wert)],
           result      => [ [ 1, 'a', 1, 'xxx' ], [ 3, 'c', 3, 'yyy' ], ],
           comment     => q{
 num | name | num | wert
-----+------+-----+------
   1 | a    |   1 | xxx
   1 | a    |   3 | yyy
	   }
        },
        {
           test        => 'INNER JOINS (USING) with select list = *',
           sql         => "SELECT * FROM t1 INNER JOIN t2 USING (num)",
           result_cols => [qw(num name wert)],
           result      => [ [ 1, 'a', 'xxx' ], [ 3, 'c', 'yyy' ], ],
           comment     => q{
 num | name | wert
-----+------+------
   1 | a    | xxx
   3 | c    | yyy
	   },
        },
        {
           test        => 'INNER JOINS (NATURAL) with select list = *',
           sql         => "SELECT * FROM t1 NATURAL INNER JOIN t2",
           result_cols => [qw(num name wert)],
           result      => [ [ 1, 'a', 'xxx' ], [ 3, 'c', 'yyy' ], ],
           comment     => q{
 num | name | wert
-----+------+------
   1 | a    | xxx
   3 | c    | yyy
	   },
        },
        {
           test        => 'LEFT JOINS (using ON condition) with select list = *',
           sql         => "SELECT * FROM t1 LEFT JOIN t2 ON t1.num = t2.num",
           result_cols => [qw(num name num wert)],
           result      => [ [ 1, 'a', 1, 'xxx' ], [ 2, 'b', undef, undef ], [ 3, 'c', 3, 'yyy' ], ],
           comment     => q{
 num | name | num | wert
-----+------+-----+------
   1 | a    | 1   | xxx
   2 | b    |     |
   3 | c    | 3   | yyy
	   },
        },
        {
           test        => 'LEFT JOINS (USING (num) condition) with select list = *',
           sql         => "SELECT * FROM t1 LEFT JOIN t2 USING (num)",
           result_cols => [qw(num name wert)],
           result      => [ [ 1, 'a', 'xxx' ], [ 2, 'b', undef ], [ 3, 'c', 'yyy' ], ],
           comment     => q{
 num | name | wert
-----+------+------
   1 | a    | xxx
   2 | b    |
   3 | c    | yyy
	   },
        },
        {
           test        => 'Right Joins (using ON condition) with select list = *',
           sql         => "SELECT * FROM t1 RIGHT JOIN t2 ON t1.num = t2.num",
           result_cols => [qw(num name num wert)],
           result  => [ [ 1, 'a', 1, 'xxx' ], [ 3, 'c', 3, 'yyy' ], [ undef, undef, 5, 'zzz' ], ],
           comment => q{
 num | name | num | wert
-----+------+-----+------
   1 | a    | 1   | xxx
   3 | c    | 3   | yyy
     |      | 5   | zzz
	   },
        },
        {
           test        => 'Left Joins (reverse former Right Join) with select list = *',
           sql         => "SELECT * FROM t2 LEFT JOIN t1 ON t1.num = t2.num",
           result_cols => [qw(num wert num name)],
           result  => [ [ 1, 'xxx', 1, 'a' ], [ 3, 'yyy', 3, 'c' ], [ 5, 'zzz', undef, undef ], ],
           comment => q{
 num | name | num | wert
-----+------+-----+------
   1 | a    | 1   | xxx
   3 | c    | 3   | yyy
     |      | 5   | zzz
	   },
        },
        {
           test        => 'Full Joins (using ON condition) with select list = *',
           sql         => "SELECT * FROM t1 FULL JOIN t2 ON t1.num = t2.num",
           result_cols => [qw(num name num wert)],
           result      => [
                       [ 1,     'a',   1,     'xxx' ],
                       [ 2,     'b',   undef, undef ],
                       [ 3,     'c',   3,     'yyy' ],
                       [ undef, undef, 5,     'zzz' ],
                     ],
           comment => q{
 num | name | num | wert
-----+------+-----+------
   1 | a    | 1   | xxx
   2 | b    |     |
   3 | c    | 3   | yyy
     |      | 5   | zzz
	   },
        },
        {
           test => 'Left Joins (using ON t1.num = t2.num AND t2.wert = "xxx") with select list = *',
           sql  => "SELECT * FROM t1 LEFT JOIN t2 ON t1.num = t2.num AND t2.wert = 'xxx'",
           result_cols => [qw(num name num wert)],
           result  => [ [ 1, 'a', 1, 'xxx' ], [ 2, 'b', undef, undef ], [ 3, 'c', undef, undef ], ],
           comment => q{
 num | name | num | wert
-----+------+-----+------
   1 | a    | 1   | xxx
   2 | b    |     |
   3 | c    |     |
	   },
           todo => 'Analyze',
        },
        {
           test =>
             'Left Joins (using ON t1.num = t2.num WHERE (t2.wert = "xxx" OR t2.wert IS NULL)) with select list = *',
           sql =>
             "SELECT * FROM t1 LEFT JOIN t2 ON t1.num = t2.num WHERE (t2.wert = 'xxx' OR t2.wert IS NULL)",
           result_cols => [qw(num name num wert)],
           result  => [ [ 1, 'a', 1, 'xxx' ], [ 2, 'b', undef, undef ], [ 3, 'c', undef, undef ], ],
           comment => q{
 num | name | num | wert
-----+------+-----+------
   1 | a    | 1   | xxx
   2 | b    |     |
   3 | c    |     |
	   },
           todo => 'Analyze',
        },
        {
           test => "DEFAULT INNER (1) with named columns",
           sql  => q{SELECT applname, appluniq, version, nodename
			    FROM APPL, PREC, NODE
			    WHERE appl_type LIKE '%DB'
			      AND APPL.id=PREC.appl_id
			      AND PREC.node_id=NODE.id},
           result      => [
                       [ 'ZQF',          'ZFQLIN',       '10.2.0.4', 'ernie', ],
                       [ 'ZQF',          'ZFQLIN',       '10.2.0.4', 'bert', ],
                       [ 'YRA',          'YRA-UX',       '10.2.0.2', 'bert', ],
                       [ 'YRA',          'YRA-UX',       '10.2.0.2', 'ernie', ],
                       [ 'cpan-mods',    'cpan-mods',    '8.4.1',    'statler', ],
                       [ 'cpan-mods',    'cpan-mods',    '8.4.1',    'waldorf', ],
                       [ 'cpan-authors', 'cpan-authors', '8.4.1',    'waldorf', ],
                       [ 'cpan-authors', 'cpan-authors', '8.4.1',    'statler', ],
                     ],
        },
        {
           test => "DEFAULT INNER (2) with named columns",
           sql  => q{SELECT applname, appluniq, version, landscapename, nodename
			    FROM APPL, PREC, NODE, LANDSCAPE, NM_LANDSCAPE
			    WHERE appl_type LIKE '%DB'
			      AND APPL.id=PREC.appl_id
			      AND PREC.node_id=NODE.id
			      AND NM_LANDSCAPE.obj_id=APPL.id
			      AND NM_LANDSCAPE.obj_type=1
			      AND NM_LANDSCAPE.ls_id=LANDSCAPE.id},
           result => [
                       [ 'ZQF', 'ZFQLIN', '10.2.0.4', 'Logistic',       'ernie', ],
                       [ 'ZQF', 'ZFQLIN', '10.2.0.4', 'Logistic',       'bert', ],
                       [ 'YRA', 'YRA-UX', '10.2.0.2', 'Infrastructure', 'bert', ],
                       [ 'YRA', 'YRA-UX', '10.2.0.2', 'Infrastructure', 'ernie', ],
                     ],
        },
        {
           test => "DEFAULT INNER (3) with named columns",
           sql  => q{SELECT applname, appluniq, version, surname, familyname, phone, nodename
			    FROM APPL, PREC, NODE, CONTACT, APPL_CONTACT
			    WHERE appl_type='CUPS'
			      AND APPL.id=PREC.appl_id
			      AND PREC.node_id=NODE.id
			      AND APPL_CONTACT.appl_id=APPL.id
			      AND APPL_CONTACT.contact_id=CONTACT.id
			      AND PREC.PRECEDENCE=1
			    ORDER BY appluniq DESC, applname ASC},
           result => [
                       [
                          'PRN2',   'PRN2-4.B2',        '1.1.22', 'Helge',
                          'Brunft', '+41-123-45678-09', 'kermit',
                       ],
                       [
                          'PRN1',   'PRN1-4.B2',        '1.1.22', 'Helge',
                          'Brunft', '+41-123-45678-09', 'piggy',
                       ],
                       [
                          'PRN1',   'PRN1-4.B1',        '1.1.22', 'Helge',
                          'Brunft', '+41-123-45678-09', 'samson',
                       ],
                     ],
        },
        {
           test => "DEFAULT INNER (4) with named columns",
           sql => q{SELECT DISTINCT applname, appluniq, version, surname, familyname, phone, nodename
			    FROM APPL, PREC, NODE, CONTACT, APPL_CONTACT
			    WHERE appl_type='CUPS'
			      AND APPL.id=PREC.appl_id
			      AND PREC.node_id=NODE.id
			      AND APPL_CONTACT.appl_id=APPL.id
			      AND APPL_CONTACT.contact_id=CONTACT.id
			    ORDER BY applname, appluniq, nodename},
           result => [
                       [
                          'PRN1',   'PRN1-4.B1',        '1.1.22', 'Helge',
                          'Brunft', '+41-123-45678-09', 'piggy',
                       ],
                       [
                          'PRN1',   'PRN1-4.B1',        '1.1.22', 'Helge',
                          'Brunft', '+41-123-45678-09', 'samson',
                       ],
                       [
                          'PRN1',   'PRN1-4.B2',        '1.1.22', 'Helge',
                          'Brunft', '+41-123-45678-09', 'piggy',
                       ],
                       [
                          'PRN1',   'PRN1-4.B2',        '1.1.22', 'Helge',
                          'Brunft', '+41-123-45678-09', 'samson',
                       ],
                       [
                          'PRN2',   'PRN2-4.B2',        '1.1.22', 'Helge',
                          'Brunft', '+41-123-45678-09', 'kermit',
                       ],
                       [
                          'PRN2',   'PRN2-4.B2',        '1.1.22', 'Helge',
                          'Brunft', '+41-123-45678-09', 'tiffy',
                       ],
                     ],
        },
        {
           test => "DEFAULT INNER (5) with named columns",
           sql => q{SELECT CONCAT('[% NOW %]') AS "timestamp", applname, appluniq, version, nodename
			    FROM APPL, PREC, NODE
			    WHERE appl_type LIKE '%DB'
			      AND APPL.id=PREC.appl_id
			      AND PREC.node_id=NODE.id},
           result => [
                       [ '[% NOW %]', 'ZQF',          'ZFQLIN',       '10.2.0.4', 'ernie', ],
                       [ '[% NOW %]', 'ZQF',          'ZFQLIN',       '10.2.0.4', 'bert', ],
                       [ '[% NOW %]', 'YRA',          'YRA-UX',       '10.2.0.2', 'bert', ],
                       [ '[% NOW %]', 'YRA',          'YRA-UX',       '10.2.0.2', 'ernie', ],
                       [ '[% NOW %]', 'cpan-mods',    'cpan-mods',    '8.4.1',    'statler', ],
                       [ '[% NOW %]', 'cpan-mods',    'cpan-mods',    '8.4.1',    'waldorf', ],
                       [ '[% NOW %]', 'cpan-authors', 'cpan-authors', '8.4.1',    'waldorf', ],
                       [ '[% NOW %]', 'cpan-authors', 'cpan-authors', '8.4.1',    'statler', ],
                     ],
        },
        {
           test => "Complex INNER JOIN",
           sql => q{SELECT pname, sname, rname
             FROM Prof p
             JOIN Subject s
               ON p.pid = s.pid
             JOIN Room r
               ON p.pid = r.pid
           },
           result => [ [qw(Sue Chem 1C)], [qw(Bob Bio 2B)], [qw(Bob Math 2B)] ],
           todo => 'Not supported yet!',
	   execute_err => qr/No such column 'rname'/,
        },
        {
           test => "Complex INNER JOIN (using)",
           sql => q{SELECT pname, sname, rname
             FROM Prof p
             JOIN Subject s USING (pid)
             JOIN Room r USING (pid)
           },
           result => [ [qw(Sue Chem 1C)], [qw(Bob Bio 2B)], [qw(Bob Math 2B)] ],
           todo => 'Not supported yet!',
	   prepare_err => qr/Can't find table names in FROM clause/,
        },
        {
           test => "Complex NATURAL JOIN",
           sql => q{SELECT pname, sname, rname
             FROM Prof NATURAL JOIN Subject NATURAL JOIN Room
           },
           result => [ [qw(Sue Chem 1C)], [qw(Bob Bio 2B)], [qw(Bob Math 2B)] ],
           todo => 'Not supported yet!',
	   prepare_err => qr/Can't find table names in FROM clause/,
        },
        {
           test => "Complex LEFT JOIN",
           sql => q{SELECT pname, sname, rname
             FROM Prof p
             LEFT JOIN Subject s
               ON p.pid = s.pid
             LEFT JOIN Room r
               ON p.pid = r.pid
           },
           result => [ [qw(Sue Chem 1C)], [qw(Bob Bio 2B)], [qw(Bob Math 2B)], ['Tom', undef, undef] ],
           todo => 'Not supported yet!',
	   execute_err => qr/No such column 'rname'/,
        },
    );

    foreach my $test (@tests)
    {
        $test->{test} or next;
        local $TODO;
        if ( $test->{todo} )
        {
            note("break here");
        }
        defined( $test->{todo} ) and $TODO = $test->{todo};
        if ( defined( $test->{prepare_err} ) )
        {
            $sth = $dbh->prepare( $test->{sql} );
            ok( !$sth, "prepare $test->{sql} using $test_dbd fails" );
            like( $dbh->errstr(), $test->{prepare_err}, $test->{test} );
            next;
        }
        $sth = $dbh->prepare( $test->{sql} );
        ok( $sth, "prepare $test->{sql} using $test_dbd" ) or diag( $dbh->errstr() );
        $sth or next;
        if ( defined( $test->{params} ) )
        {
            my $params;
            if ( defined( _CODE( $test->{params} ) ) )
            {
                $params = [ &{ $test->{params} } ];
            }
            elsif ( !defined( _ARRAY( $test->{params}->[0] ) ) )
            {
                $params = [ $test->{params} ];
            }
            else
            {
                $params = $test->{params};
            }

            my $i = 0;
            my @failed;
            foreach my $bp ( @{ $test->{params} } )
            {
                ++$i;
                my $n = $sth->execute(@$bp);
                $n
                  or
                  ok( $n, "$i: execute $test->{sql} using $test_dbd (" . DBI::neat_list($bp) . ")" )
                  or diag( $dbh->errstr() )
                  or push( @failed, $bp );

                # 'SELECT' eq $sth->command() or next;
                # could become funny ...
            }

            @failed or ok( 1, "1 .. $i: execute $test->{sql} using $test_dbd" );
        }
        else
        {
            my $n = $sth->execute();
            if ( defined( $test->{execute_err} ) )
            {
                ok( !$n, "execute $test->{sql} using $test_dbd fails" );
                like( $dbh->errstr(), $test->{execute_err}, $test->{test} );
                next;
            }

            ok( $n, "execute $test->{sql} using $test_dbd" ) or diag( $dbh->errstr() );
            'SELECT' eq $sth->command() or next;

            if ( $test->{result_cols} )
            {
                is_deeply( $sth->col_names(), $test->{result_cols}, "Columns in $test->{test}" );
            }

            if ( $test->{fetch_by} )
            {
                my $got_result = $sth->fetchall_hashref( $test->{fetch_by} );
                is_deeply( $got_result, $test->{result}, $test->{test} );
            }
            elsif ( $test->{result_code} )
            {
                &{ $test->{result_code} }($sth);
            }
            else
            {
                my $got_result = $sth->fetch_rows();
                is_deeply( $got_result, $test->{result}, $test->{test} );
            }
        }
    }
}

done_testing();
