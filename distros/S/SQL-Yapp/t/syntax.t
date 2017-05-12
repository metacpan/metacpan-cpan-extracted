#! /usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
use Test::Simple tests => 1;

my $dbh;

use SQL::Yapp
    marker => 'sql'
  , dbh    => sub { $dbh },
  , table_prefix => 'noten_'
  #, debug  => 1
  , write_dialect => 'mysql'
  , quote_identifier => sub {
        join('.', map { "`$_`" } grep { defined($_) } @_)
    }
  , quote => sub {
        $_[0] && qq{'$_[0]'}
    }
;

sub DEBUG($)
{
    my ($s) = @_;
    #print STDERR "DEBUG: $s\n";
}

sub test()
{
    my $o1= SQL::Yapp::Asterisk->obj();
    DEBUG "'$o1': ".Dumper($o1);
    my $b= "'end";
    DEBUG "X";
    my %tab= ('x' => 1, 'y' => sqlExpr{NOT 5});
    DEBUG "Y";
    my $tab= 'z';
    my @col= ('a', 'b');
    my %col= ('a' => 1, 'b' => 1);
    my %b=   (1 => 2);
    my %sql= ();
    DEBUG "Z";
    my $d=   $sql{5};
    my $tabspec= sqlTable{ blah.blup };
    DEBUG "A";
    my @join2= sqlJoin{
        NATURAL JOIN %tab
        INNER JOIN b ON 9
        LEFT OUTER JOIN b USING ( @col )
    };
    DEBUG "B";
    my @cc= sqlColumn{ @col };
    DEBUG "C";
    my @order=  sqlOrder{ Table @col DESC, c, @cc ASC };
    DEBUG "D";
    my @order2= sqlOrder{ @order DESC };
    DEBUG "order:\n".join(', ', map { Dumper($_) } @order);
    DEBUG "order2:\n".join(', ', map { Dumper($_) } @order2);
    DEBUG "$tabspec\n";
    my $s2= sql {
        DELETE FROM test10;
    };
    my $c1= sqlColumn{ a };
    my $e1= sqlExpr{ a };
    my $e2= sqlExpr{ a = (1 - NOT 5) };
    my $e3= sqlExpr{ $e2 };
    my @arr= ([1,2],[2,3]);
    my $f= sub($) {
        my ($x)= @_;
        return $x * 6;
    };
    DEBUG "".Dumper($c1);
    DEBUG "".Dumper($e1);
    DEBUG "".Dumper($e2);
    DEBUG "".Dumper($e3);
    DEBUG sqlOrder{ {'a'} };
    DEBUG sqlExpr{ {'a'} };
    my $cs= sqlCharSet{ main.utf8 };
    my $t1= sqlType{ VARCHAR(50) };
    my $t2= sqlType{ $t1 (100) };
    my $t3= sqlType{ ENUM('eins', 'zwei', 'drei') CHARSET $cs };
    my $t4= sqlType{ $t3 DROP CHARACTER SET };
    DEBUG "$t1: ".Dumper($t1);
    DEBUG "$t2: ".Dumper($t2);
    DEBUG "$t3: ".Dumper($t3);
    DEBUG "$t4: ".Dumper($t4);
    my $k1= sqlColumnSpec{ VARCHAR(50) CONSTRAINT len10 UNIQUE NOT NULL };
    my $k2= sqlColumnSpec{ $k1 INT };
    my $k3= sqlColumnSpec{ $k2 BLOB (50 K OCTETS)};
    my $k4= sqlColumnSpec{ $t3 DROP CHARACTER SET };
    DEBUG "$k1: ".Dumper($k1);
    DEBUG "$k2: ".Dumper($k2);
    DEBUG "$k3: ".Dumper($k3);
    DEBUG "$k4: ".Dumper($k4);
    my @to= sqlTableOption{
        ENGINE = innodb
        CHARSET = utf8
    };
    my @a= sql {
        SELECT b IN (SELECT 2);
        SELECT $e1, 5, 'te
            st', a, (8), NOT TRUE, 1 AND NOT %tab, {} + %tab, @col + a,
            {} AND NOT (@col IS NULL), a != b,
            a + NOT b, a BETWEEN (x + 5) AND y * 6, COUNT(*),
            a == ANY (SELECT b FROM test10),
            CONCATENATE(1,2,34,@col, @cc),
            a IS NOT NULL,
            {} + .@col,
            a IN (.@col),
            {} AND (.@col IS NOT NULL),
            b IN (SELECT x FROM test10), (SELECT a FROM test10 LIMIT 1),
            #a IN ($s2),
            strato1.Table 'test10'.Column 'a'
        FROM test10
        GROUP BY %col ORDER BY @col FOR UPDATE;

        SELECT 6, { 7, $b } , { undef }, $tabspec.z, foo.bar
            FROM %tab, $tab AS hurz
            INNER JOIN t ON 5
            @join2
            WHERE a
            GROUP BY @order DESC, 'test16', {'test17'}, Expr 'test18' WITH ROLLUP
            HAVING b
            ORDER BY @order, a, "a", {"a"}, blah."foo"
            LIMIT {undef} OFFSET 5
            ;

        SELECT DISTINCT %tab.*, *, ?, NULL FROM %tab;
        SELECT ${ \$b }, %b, %{{ a => 5, b => 9 }};
        SELECT 6, { $b, $b };
        SELECT 6, $b AS blah;
        SELECT test.test2, .@col, %tab.next, blup.@col, %tab.@col,
               .{ map sql{s.c.t.$_}, @col };
        SELECT "hallo \'Welt $b", $b, { $b eq 'tesT' ? 5 : sql{ 'hallo' } } ;
        DELETE FROM test10 USING test1 @join2 WHERE a = 5 ;
        SELECT a FROM b ORDER BY NULL;
        SELECT $e1;             # no parens
        SELECT 5 + .$c1;        # no parens
        SELECT 5 + $c1;         # no parens
        SELECT 5 + $e1;         # no parens
        SELECT NOT $e1;         # parens
        SELECT %tab;            # no parens
        SELECT NOT %tab;        # parens
        SELECT {} AND %tab;     # parens
        SELECT a || b;          # normalisation
        SELECT a % b;           # normalisation
        SELECT POSITION('a' IN 'b');                         # strange functions
        SELECT OVERLAY('a' PLACING 'c' FROM 2);
        SELECT OVERLAY('a' PLACING 'c' FROM 2 FOR 'd');
        SELECT UNNEST('a');
        SELECT UNNEST('a') WITH ORDINALITY;
        SELECT 1 < 5;
        SELECT CASE a WHEN IS NOT NULL THEN 5 WHEN b < 5 THEN 7 ELSE 0 END;
        SELECT CASE a WHEN IS NOT NULL THEN 5 WHEN < 5 THEN 7 ELSE 0 END;
        SELECT CASE a WHEN IS NOT NULL THEN 5 ELSE 0 END;
        SELECT CASE a WHEN 1 THEN 5 ELSE 5 + a END;
        SELECT CASE a WHEN 1 THEN 5 END;
        SELECT CASE a ELSE 5 END;
        SELECT CASE a END;
        SELECT CASE WHEN a IS NOT NULL THEN 5 WHEN b < 6 THEN 8 ELSE 0 END;
        SELECT CASE WHEN a IS NOT NULL THEN 5 ELSE 0 END;
        SELECT CASE WHEN 1 THEN 5 ELSE 0 END;
        SELECT CASE WHEN 1 THEN 5 END;
        SELECT CASE ELSE 5 END;
        SELECT CASE END;
        SELECT 1 + CASE a WHEN IS NOT NULL THEN 5 WHEN b < 5 THEN 7 ELSE 0 END;
        SELECT 1 * CASE a WHEN IS NOT NULL THEN 5 WHEN < 5 THEN 7 ELSE 0 END;
        SELECT 1 - CASE a WHEN IS NOT NULL THEN 5 ELSE 0 END;
        SELECT 1 / CASE a WHEN 1 THEN 5 ELSE 5 + a END;
        SELECT 1 % CASE a WHEN 1 THEN 5 END;
        SELECT 1 AND CASE a ELSE 5 END;
        SELECT 1 OR  CASE a END;
        SELECT 1 XOR CASE WHEN a IS NOT NULL THEN 5 WHEN b < 6 THEN 8 ELSE 0 END;
        SELECT NOT CASE WHEN a IS NOT NULL THEN 5 ELSE 0 END;
        SELECT -CASE WHEN 1 THEN 5 ELSE 0 END;
        SELECT +CASE WHEN 1 THEN 5 END;
        SELECT a || CASE ELSE 5 END;
        SELECT (5 IS OF (VARCHAR CHARACTER SET utf8 COLLATE german2 (17) INT ZEROFILL SIGNED)) AND (a ^ CASE END);
        DELETE FROM test10 WHERE a IS NULL ;
        UPDATE ONLY test10 AS t10 SET %tab FROM test10 WHERE a == 5 ORDER BY b LIMIT 2;
        INSERT IGNORE
            INTO test10
            SET %tab, a= DEFAULT, b=DEFAULT(a), y = $f->(5), x = 0x60
            ON DUPLICATE KEY UPDATE a = 6, b = VALUES(x);
        INSERT IGNORE
            INTO test10
            ('x', 'y')
            VALUES @arr, (5 IS NOT NORMALISED, 6);

        CREATE TABLE IF NOT EXISTS test20 (
            a $k1,
            b VARCHAR(50) NOT NULL DEFAULT 'nix'
                  CONSTRAINT "a_a"
                      REFERENCES test10 (a)
                      MATCH FULL
                      ON DELETE CASCADE,
            x $t3,
            CONSTRAINT test UNIQUE USING BTREE (a(1),b DESC),
            CONSTRAINT test2 FOREIGN KEY (x,y) REFERENCES test10 (x,y, a),
        ) @to, COMMENT='blah', ON COMMIT PRESERVE ROWS
        AS SELECT a,b FROM test10;

        ALTER TABLE test10 RENAME TO test20;

        ALTER IGNORE TABLE main.test10
            ADD CONSTRAINT blah
                FOREIGN KEY (test) REFERENCES main2.test20 (test2);

        ALTER ONLINE TABLE test10
            ADD COLUMN
                (
                    a VARCHAR(50) NOT NULL DEFAULT 'hallo',
                    b BIGINT      NOT NULL
                );

        ALTER ONLINE TABLE test10
            ADD COLUMN
                a VARCHAR(50) NOT NULL DEFAULT 'hallo' AFTER 'blup';

        ALTER ONLINE TABLE test10
            MODIFY COLUMN
                a VARCHAR(50) NOT NULL DEFAULT 'hallo' FIRST;

        ALTER ONLINE TABLE test10
            CHANGE COLUMN
                a a2 VARCHAR(50) NOT NULL DEFAULT 'hallo';

        ALTER ONLINE TABLE test10
            ALTER COLUMN
                foo SET DEFAULT 15+6;

        ALTER ONLINE TABLE test10
            ALTER COLUMN
                foo DROP DEFAULT;

        ALTER ONLINE TABLE test10
            ALTER COLUMN
                foo TYPE INT(50);

        ALTER ONLINE TABLE test10
            ALTER COLUMN
                foo TYPE INT(50) USING foo + 2;

        ALTER ONLINE TABLE test10
            ALTER COLUMN
                foo SET NOT NULL;

        ALTER ONLINE TABLE test10
            ALTER COLUMN
                foo DROP NOT NULL;

        ALTER ONLINE TABLE test10
            DROP COLUMN foo;

        ALTER ONLINE TABLE test10
            DROP COLUMN foo CASCADE;

        ALTER ONLINE TABLE test10
            DROP COLUMN foo RESTRICT;

        ALTER ONLINE TABLE test10
            RENAME COLUMN foo TO bar;

        ALTER ONLINE TABLE test10
            DROP CONSTRAINT blah;

        ALTER ONLINE TABLE test10
            DROP PRIMARY KEY;

        ALTER ONLINE TABLE test10
            DROP FOREIGN KEY blah;

        ALTER ONLINE TABLE test10
            DROP INDEX blah;

        DROP TABLE IF EXISTS test20 RESTRICT;

        SELECT 5 AND ({(1,2)} IS A SET);

        SELECT {} OR {map {sql{test = $_}} 1, 2};

        SELECT blah FROM blub WHERE {} AND {
            (0 ? sql { 1 } : ()),
            (0 ? sql { 1 } : ()),
        };
    };
    my @a2= sql{
        @a[1..2]
    };
    my @c= sqlExpr { 'hallo' , 7};
    return "SQL:\n\t".join("\n\t", map { "$_;" } $tabspec, @join2, @a2, @a, @c)."\n";
}

#use DBI;
#$dbh= DBI->connect(
#    "dbi:mysql:$DB;hostname=127.0.0.1;port=3306",
#    "$USER",
#    "$PW",
#    {
#        RaiseError => 1,
#        AutoCommit => 0,
#    }
#);
#
#DEBUG "***** Data base driver: ".$dbh->get_info( $GetInfoType{SQL_DBMS_NAME} );
#DEBUG "".test();
#
my $type1= SQL::Yapp::parse('Type', 'VARCHAR(60) CHARACTER SET utf8');
#my $obj1=  eval($type1);
#DEBUG "Manually parsed: $type1\n => $obj1";
#DEBUG "".($obj1 ne '' ? 'non-empty' : 'empty');

ok(1);

0;
