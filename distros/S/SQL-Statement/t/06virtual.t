#!/usr/bin/perl -w
use strict;
use warnings;
use lib qw(t);

use Test::More;
use TestLib qw(connect prove_reqs show_reqs test_dir default_recommended);

use Params::Util qw(_CODE _ARRAY);
use Scalar::Util qw(looks_like_number);

my ( $required, $recommended ) = prove_reqs(
    {
        default_recommended(),
        (
            MLDBM                 => 0,
            "Math::Base::Convert" => 0
        )
    }
);
show_reqs( $required, $recommended );
my @test_dbds              = ( 'SQL::Statement', grep { /^dbd:/i } keys %{$recommended} );
my $have_math_base_convert = exists $recommended->{"Math::Base::Convert"};
my $testdir                = test_dir();

my @massValues = map { [ $_, ( "a" .. "f" )[ int rand 6 ], int rand 10 ] } ( 1 .. 3999 );

# (this code shamelessly stolen from Math::Complex's t/Trig.t, with some mods to near)
use Math::Trig;
my $eps = 1e-11;

my $have_soundex = 0;
eval qq{
    require Text::Soundex;
    \$have_soundex = 1;
};

if ( $^O eq 'unicos' )
{    # See lib/Math/Complex.pm and t/lib/complex.t.
    $eps = 1e-10;
}

sub near ($$$)
{
    my $d = $_[1] ? abs( $_[0] / $_[1] - 1 ) : abs( $_[0] );
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    looks_like_number( $_[0] ) or return cmp_ok( $_[0], "eq", $_[1], "near? $_[0] ~= $_[1]" );
    $_[0] =~ m/nan/i and return cmp_ok( $_[0], "eq", $_[1], "near? $_[0] ~= $_[1]" );
    $_[0] =~ m/inf/i and return cmp_ok( $_[0], "eq", $_[1], "near? $_[0] ~= $_[1]" );
    cmp_ok( $d, '<', $eps, "$_[2] => near? $_[0] ~= $_[1]" ) or diag("near? $_[0] ~= $_[1]");
}
#

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
        split /\n/,
        sprintf( <<"", ($now) x 7, @timelist )
	CREATE $temp TABLE biz (sales INTEGER, class CHAR, color CHAR, BUGNULL CHAR)
	INSERT INTO biz VALUES (1000, 'Car',   'White', NULL)
	INSERT INTO biz VALUES ( 500, 'Car',   'Blue',  NULL )
	INSERT INTO biz VALUES ( 400, 'Truck', 'White', NULL )
	INSERT INTO biz VALUES ( 700, 'Car',   'Red',   NULL )
	INSERT INTO biz VALUES ( 300, 'Truck', 'White', NULL )
	CREATE $temp TABLE baz (ordered INTEGER, class CHAR, color CHAR)
	INSERT INTO baz VALUES ( 250, 'Car',   'White' ), ( 100, 'Car',   'Blue' ), ( 150, 'Car',   'Red' )
	INSERT INTO baz VALUES (  80, 'Truck', 'White' ), (  60, 'Truck', 'Green' ) -- Yes, we introduce new cars :)
	INSERT INTO baz VALUES ( 666, 'Truck', 'Yellow -- no, blue' ) -- Double dash inside quotes does not introduce comment
	CREATE $temp TABLE numbers (c_foo INTEGER, foo CHAR, bar INTEGER)
	CREATE $temp TABLE trick   (id INTEGER, foo CHAR)
	INSERT INTO trick VALUES (1, '1foo')
	INSERT INTO trick VALUES (11, 'foo')
	CREATE TYPE TIMESTAMP
	CREATE $temp TABLE log (id INT, host CHAR, signature CHAR, message CHAR, time_stamp TIMESTAMP)
	INSERT INTO log VALUES (1, 'bert', '/netbsd', 'Copyright (c) 1996, 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,', %d)
	INSERT INTO log VALUES (2, 'bert', '/netbsd', '2006, 2007, 2008, 2009, 2010', %d)
	INSERT INTO log VALUES (3, 'bert', '/netbsd', 'The NetBSD Foundation, Inc.  All rights reserved.', %d)
	INSERT INTO log VALUES (4, 'bert', '/netbsd', 'Copyright (c) 1982, 1986, 1989, 1991, 1993', %d)
	INSERT INTO log VALUES (5, 'bert', '/netbsd', 'The Regents of the University of California.  All rights reserved.', %d)
	INSERT INTO log VALUES (6, 'bert', '/netbsd', '', %d)
	INSERT INTO log VALUES (7, 'bert', '/netbsd', 'NetBSD 5.99.39 (BERT) #0: Fri Oct  8 06:23:03 CEST 2010', %d)
	INSERT INTO log VALUES (8, 'ernie', 'rpc.statd', 'starting', %d)
	INSERT INTO log VALUES (9, 'ernie', 'savecore', 'no core dump', %d)
	INSERT INTO log VALUES (10, 'ernie', 'postfix/postfix-script', 'starting the Postfix mail system', %d)
	INSERT INTO log VALUES (11, 'ernie', 'rpcbind', 'connect from 127.0.0.1 to dump()', %d)
	INSERT INTO log VALUES (12, 'ernie', 'sshd', 'last message repeated 2 times', %d)
	INSERT INTO log VALUES (13, 'ernie', 'shutdown', 'poweroff by root:', %d)
	INSERT INTO log VALUES (14, 'ernie', 'shutdown', 'rebooted by root', %d)
	INSERT INTO log VALUES (15, 'ernie', 'sshd', 'Server listening on :: port 22.', %d)
	INSERT INTO log VALUES (16, 'ernie', 'sshd', 'Server listening on 0.0.0.0 port 22.', %d)
	INSERT INTO log VALUES (17, 'ernie', 'sshd', 'Received SIGHUP; restarting.', %d)

      )
    {
        ok( $sth = $dbh->prepare($sql), "prepare $sql on $test_dbd" ) or diag( $dbh->errstr() );
        ok( $sth->execute(), "execute $sql on $test_dbd" ) or diag( $sth->errstr() );
    }

    my @tests = (
        ### GROUP BY Tests ###
        {
            test     => 'GROUP BY one column',
            sql      => "SELECT class,SUM(sales) as foo, MAX(sales) FROM biz GROUP BY class",
            fetch_by => 'class',
            result   => {
                Car => {
                    MAX   => '1000',
                    foo   => 2200,
                    class => 'Car'
                },
                Truck => {
                    MAX   => '400',
                    foo   => 700,
                    class => 'Truck'
                }
            },
        },
        {
            test     => "GROUP BY several columns",
            sql      => "SELECT color,class,SUM(sales), MAX(sales) FROM biz GROUP BY color,class",
            fetch_by => [ 'color', 'class' ],
            result   => {
                Blue => {
                    Car => {
                        color => 'Blue',
                        class => 'Car',
                        SUM   => 500,
                        MAX   => 500,
                    },
                },
                Red => {
                    Car => {
                        color => 'Red',
                        class => 'Car',
                        SUM   => 700,
                        MAX   => 700,
                    },
                },
                White => {
                    Car => {
                        color => 'White',
                        class => 'Car',
                        SUM   => 1000,
                        MAX   => 1000,
                    },
                    Truck => {
                        color => 'White',
                        class => 'Truck',
                        SUM   => 700,
                        MAX   => 400,
                    },
                }
            },
        },
        {
            test   => 'AGGREGATE FUNCTIONS WITHOUT GROUP BY',
            sql    => "SELECT SUM(sales), MAX(sales) FROM biz",
            result => [ [ 2900, 1000 ], ]
        },
        {
            test   => 'COUNT(distinct column) WITHOUT GROUP BY',
            sql    => "SELECT COUNT(DISTINCT class) FROM biz",
            result => [ [2], ]
        },
        {
            test     => 'COUNT(distinct column) WITH GROUP BY',
            sql      => "SELECT distinct class, COUNT(distinct color) FROM biz GROUP BY class",
            fetch_by => 'class',
            result   => {
                Car => {
                    class => 'Car',
                    COUNT => 3,
                },
                Truck => {
                    class => 'Truck',
                    COUNT => 1,
                },
            },
        },
        {
            test     => 'COUNT(*) with GROUP BY',
            sql      => "SELECT class, COUNT(*) FROM biz GROUP BY class",
            fetch_by => 'class',
            result   => {
                Car => {
                    class => 'Car',
                    COUNT => 3,
                },
                Truck => {
                    class => 'Truck',
                    COUNT => 2,
                },
            },
        },
        {
            test   => 'ORDER BY on aliased column',
            sql    => "SELECT DISTINCT biz.class, baz.color AS foo FROM biz, baz WHERE biz.class = baz.class ORDER BY foo",
            result => [
                [qw(Car Blue)], [qw(Truck Green)], [qw(Car Red)], [qw(Car White)],
                [qw(Truck White)], [ Truck => 'Yellow -- no, blue' ],
            ],
        },
        {
            test        => 'COUNT(DISTINCT *) fails',
            sql         => "SELECT class, COUNT(distinct *) FROM biz GROUP BY class",
            prepare_err => qr/Keyword DISTINCT is not allowed for COUNT/m,
        },
        {
            test        => 'GROUP BY required',
            sql         => "SELECT class, COUNT(color) FROM biz",
            execute_err => qr/Column 'biz\.class' must appear in the GROUP BY clause or be used in an aggregate function/,
        },
        ### Aggregate Functions ###
        {
            test   => 'SUM(bar) of empty table',
            sql    => "SELECT SUM(bar) FROM numbers",
            result => [ [undef] ],
        },
        {
            test   => 'COUNT(bar) of empty table with GROUP BY',
            sql    => "SELECT COUNT(bar),c_foo FROM numbers GROUP BY c_foo",
            result => [ [ 0, undef ] ],
        },
        {
            test   => 'COUNT(*) of empty table',
            sql    => "SELECT COUNT(*) FROM numbers",
            result => [ [0] ],
        },
        {
            test   => 'Mass insert of random numbers',
            sql    => "INSERT INTO numbers VALUES (?, ?, ?)",
            params => \@massValues,
        },
        {
            test        => 'Number of rows in aggregated Table',
            sql         => "SELECT foo AS boo, COUNT (*) AS counted FROM numbers GROUP BY boo",
            result_cols => [qw(boo counted)],
            result_code => sub {
                my $sth = $_[0];
                my $res = $sth->fetch_rows();
                cmp_ok( scalar( @{$res} ), '==', '6', 'Number of rows in aggregated Table' );
                my $all_counted = 0;
                foreach my $row ( @{$res} )
                {
                    $all_counted += $row->[1];
                }
                cmp_ok( $all_counted, '==', 3999, 'SUM(COUNTED)' );
            },
        },
        {
            test   => 'Aggregate functions MIN, MAX, AVG',
            sql    => "SELECT MIN(c_foo), MAX(c_foo), AVG(c_foo) FROM numbers",
            result => [ [ 1, 3999, 2000 ], ],
        },
        {
            test   => 'COUNT(*) internal for nasty table',
            sql    => "SELECT COUNT(*) FROM trick",
            result => [ [2] ],
        },
        ### Date/Time Functions ###
        {
            test        => 'current_date int',
            sql         => "SELECT CURRENT_DATE()",
            result_like => qr/^\d{4}-\d{2}-\d{2}$/,
        },
        {
            test        => 'current_time int',
            sql         => "SELECT CURRENT_TIME",
            result_like => qr/^\d{2}:\d{2}:\d{2}$/,
        },
        {
            test        => 'current_timestamp int',
            sql         => "SELECT CURRENT_TIMESTAMP()",
            result_like => qr/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$/,
        },
        {
            test        => 'curdate int',
            sql         => "SELECT CURDATE",
            result_like => qr/^\d{4}-\d{2}-\d{2}$/,
        },
        {
            test        => 'curtime int',
            sql         => "SELECT CURTIME()",
            result_like => qr/^\d{2}:\d{2}:\d{2}$/,
        },
        {
            test        => 'now int',
            sql         => "SELECT NOW",
            result_like => qr/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$/,
        },
        {
            test        => 'unix_timestamp int',
            sql         => "SELECT UNIX_TIMESTAMP()",
            result_like => qr/^\d{10,}$/,
        },
        {
            test        => 'current_time precision',
            sql         => "SELECT CURRENT_TIME (1)",
            result_like => qr/^\d{2}:\d{2}:\d{2}\.\d{1}$/,
        },
        {
            test        => 'current_timestamp precision',
            sql         => "SELECT CURRENT_TIMESTAMP  (2)",
            result_like => qr/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{2}$/,
        },
        {
            test        => 'curtime precision',
            sql         => "SELECT CURTIME   (3)",
            result_like => qr/^\d{2}:\d{2}:\d{2}\.\d{3}$/,
        },
        {
            test        => 'now precision',
            sql         => "SELECT NOW(4)",
            result_like => qr/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{4}$/,
        },
        {
            test        => 'unix_timestamp precision',
            sql         => "SELECT UNIX_TIMESTAMP(5)",
            result_like => qr/^\d{10,}\.\d{5}$/,
        },
        ### String Functions ###
        {
            test   => 'ascii char',
            sql    => "SELECT ASCII('A')",
            result => [ [65] ],
        },
        {
            test   => 'ascii str',
            sql    => "SELECT ASCII('ABC')",
            result => [ [65] ],
        },
        {
            test   => 'char blank',
            sql    => "SELECT CHAR()",
            result => [ [''] ],
        },
        {
            test   => 'char char',
            sql    => "SELECT CHAR(65)",
            result => [ ['A'] ],
        },
        $have_math_base_convert
        ? (
            {
                test   => 'char char unicode',
                sql    => "SELECT CHAR(CONV('263A', 16))",
                result => [ [ chr(0x263a) ] ]
            },
            {
                test   => 'char str unicode',
                sql    => "SELECT CHAR(CONV('263A', 16), 9787, CONV('10011000111100', 2))",
                result => [ [ chr(9786) . chr(9787) . chr(9788) ] ],
            },
          )
        : (),
        {
            test   => 'char str',
            sql    => "SELECT CHAR(65,66,67)",
            result => [ ['ABC'] ],
        },
        {
            test   => 'bit_length 6bit',
            sql    => "SELECT BIT_LENGTH(' oo')",
            result => [ [22] ],
        },
        {
            test   => 'bit_length 7bit',
            sql    => "SELECT BIT_LENGTH('foo')",
            result => [ [23] ],
        },
        {
            test    => 'bit_length unicode',
            sql     => "SELECT BIT_LENGTH(CHAR(9786, 9787, 9788))",
            result  => [ [62] ],
            comment => '14+24+24',
        },
        {
            test   => 'character_length',
            sql    => "SELECT CHARACTER_LENGTH('foo')",
            result => [ [3] ],
        },
        {
            test   => 'char_length',
            sql    => "SELECT CHAR_LENGTH('foo')",
            result => [ [3] ],
        },
        {
            test   => 'character_length unicode',
            sql    => "SELECT CHARACTER_LENGTH(CHAR(9786, 9787, 9788))",
            result => [ [3] ],
        },
        {
            test   => 'char_length unicode',
            sql    => "SELECT CHAR_LENGTH(CHAR(9786, 9787, 9788))",
            result => [ [3] ],
        },
        {
            test   => 'coalesce',
            sql    => "SELECT COALESCE(NULL,'z')",
            result => [ ['z'] ],
        },
        {
            test   => 'nvl',
            sql    => "SELECT NVL(NULL,'z')",
            result => [ ['z'] ],
        },
        {
            test   => 'ifnull',
            sql    => "SELECT IFNULL(NULL,'z')",
            result => [ ['z'] ],
        },
        {
            test   => 'concat good',
            sql    => "SELECT CONCAT('A','B')",
            result => [ ['AB'] ],
        },
        {
            test   => 'concat bad',
            sql    => "SELECT CONCAT('A',NULL)",
            result => [ [undef] ],
        },
        $have_math_base_convert
        ? (
            {
                test   => 'conv 2->64',
                sql    => "SELECT CONV('10101001111011101101011',  2, 64)",
                result => [ ['VPdr'] ],
            },
            {
                test   => 'conv 2->16',
                sql    => "SELECT CONV('10101001111011101101011',  2, 16)",
                result => [ ['54f76b'] ],
            },
            {
                test   => 'conv 2->10',
                sql    => "SELECT CONV('10101001111011101101011',  2, 10)",
                result => [ [5568363] ],
            },
            {
                test   => 'conv 2->8',
                sql    => "SELECT CONV('10101001111011101101011',  2,  8)",
                result => [ [25173553] ],
            },
            {
                test   => 'conv 2->2',
                sql    => "SELECT CONV('10101001111011101101011',  2,  2)",
                result => [ ['10101001111011101101011'] ],
            },
            {
                test   => 'conv 10->16 integer with trailing 0',
                sql    => "select conv('16', 10, 16)",
                result => [ ['10'] ],
            },
            {
                test   => 'conv 10->16 integer 0',
                sql    => "select conv('0', 10, 16)",
                result => [ ['0'] ],
            },
          )
        : (),
        {
            test   => 'decode',
            sql    => q{SELECT DISTINCT DECODE(color,'White','W','Red','R','B') AS cfc FROM biz ORDER BY cfc},
            result => [ ['B'], ['R'], ['W'] ],
        },
        {
            test   => 'insert good 1:1',
            sql    => "SELECT INSERT('foodieland', 4, 3, 'bar')",
            result => [ ['foobarland'] ],
        },
        {
            test   => 'insert good non-1:1',
            sql    => "SELECT INSERT('foodland', 4, 1, 'bar')",
            result => [ ['foobarland'] ],
        },
        {
            test   => 'insert bad 1',
            sql    => "SELECT INSERT(NULL, 4, 1, 'bar')",
            result => [ [undef] ],
        },
        {
            test   => 'insert bad 2',
            sql    => "SELECT INSERT('foodland', 4, 1, NULL)",
            result => [ [undef] ],
        },
        {
            test   => 'left good',
            sql    => "SELECT LEFT('foodland', 4)",
            result => [ ['food'] ],
        },
        {
            test   => 'left bad 1',
            sql    => "SELECT LEFT(NULL, 4)",
            result => [ [undef] ],
        },
        {
            test   => 'left bad 2',
            sql    => "SELECT LEFT('foodland', NULL)",
            result => [ [undef] ],
        },
        {
            test   => 'right good',
            sql    => "SELECT RIGHT('foodland', 4)",
            result => [ ['land'] ],
        },
        {
            test   => 'right bad 1',
            sql    => "SELECT RIGHT(NULL, 4)",
            result => [ [undef] ],
        },
        {
            test   => 'right bad 2',
            sql    => "SELECT RIGHT('foodland', NULL)",
            result => [ [undef] ],
        },
        {
            test   => 'locate 2param',
            sql    => "SELECT LOCATE('a','bar')",
            result => [ [2] ],
        },
        {
            test   => 'locate 3param',
            sql    => "SELECT LOCATE('a','barafa',3)",
            result => [ [4] ],
        },
        {
            test   => 'position 2param',
            sql    => "SELECT POSITION('a','bar')",
            result => [ [2] ],
        },
        {
            test   => 'position 3param',
            sql    => "SELECT POSITION('a','barafa',3)",
            result => [ [4] ],
        },
        {
            test   => 'lower',
            sql    => "SELECT LOWER('A')",
            result => [ ['a'] ],
        },
        {
            test   => 'upper',
            sql    => "SELECT UPPER('a')",
            result => [ ['A'] ],
        },
        {
            test   => 'lcase',
            sql    => "SELECT LCASE('A')",
            result => [ ['a'] ],
        },
        {
            test   => 'ucase',
            sql    => "SELECT UCASE('a')",
            result => [ ['A'] ],
        },
        {
            test   => 'ltrim',
            sql    => q{SELECT LTRIM(' fun ')},
            result => [ ['fun '] ],
        },
        {
            test   => 'rtrim',
            sql    => q{SELECT RTRIM(' fun ')},
            result => [ [' fun'] ],
        },
        {
            test   => 'octet_length',
            sql    => "SELECT OCTET_LENGTH('foo')",
            result => [ [3] ],
        },
        {
            test    => 'octet_length unicode',
            sql     => "SELECT OCTET_LENGTH(CHAR(64, 169, 9786, 65572))",
            result  => [ [10] ],
            comment => '1+2+3+4',
        },
        {
            test   => 'regex match',
            sql    => "SELECT REGEX('jeff','/EF/i')",
            result => [ [1] ],
        },
        {
            test   => 'regex no match',
            sql    => "SELECT REGEX('jeff','/zzz/')",
            result => [ [0] ],
        },
        {
            test   => 'repeat',
            sql    => q{SELECT REPEAT('zfunkY', 3)},
            result => [ ['zfunkYzfunkYzfunkY'] ],
        },
        {
            test   => 'replace',
            sql    => q{SELECT REPLACE('zfunkY','s/z(.+)ky/$1/i')},
            result => [ ['fun'] ],
        },
        {
            test   => 'substitute',
            sql    => q{SELECT SUBSTITUTE('zfunkY','s/z(.+)ky/$1/i')},
            result => [ ['fun'] ],
        },
        (
            $have_soundex
            ? (
                {
                    test   => 'soundex match',
                    sql    => "SELECT SOUNDEX('jeff','jeph')",
                    result => [ [1] ],
                },
                {
                    test   => 'soundex no match',
                    sql    => "SELECT SOUNDEX('jeff','quartz')",
                    result => [ [0] ],
                },
              )
            : ()
        ),
        {
            test   => 'space',
            sql    => q{SELECT SPACE(10)},
            result => [ [ ' ' x 10 ] ],
        },
        {
            test   => 'substr',
            sql    => q{SELECT SUBSTR('zfunkY',2,3)},
            result => [ ['fun'] ],
        },
        {
            test   => 'substring',
            sql    => "SELECT DISTINCT color FROM biz WHERE SUBSTRING(class FROM 1 FOR 1)='T'",
            result => [ ['White'] ],
        },
        {
            test   => 'translate',
            sql    => q{SELECT TRANSLATE('foobar forever', 'oae', '0@3')},
            result => [ ['f00b@r f0r3v3r'] ],
        },
        {
            test   => 'trim simple',
            sql    => q{SELECT TRIM(' fun ')},
            result => [ ['fun'] ],
        },
        {
            test   => 'trim leading',
            todo   => "Analyze why this fails; may be thinking FROM keyword is for table specs",
            sql    => q{SELECT TRIM(LEADING FROM ' fun ')},
            result => [ ['fun '] ],
        },
        {
            test   => 'trim trailing',
            todo   => "Analyze why this fails; may be thinking FROM keyword is for table specs",
            sql    => q{SELECT TRIM(TRAILING FROM ' fun ')},
            result => [ [' fun'] ],
        },
        {
            test   => 'trim leading ;',
            todo   => "Analyze why this fails; may be thinking FROM keyword is for table specs",
            sql    => q{SELECT TRIM(LEADING ';' FROM ';;; fun ')},
            result => [ [' fun '] ],
        },
        $have_math_base_convert
        ? (
            {
                test   => 'unhex str',
                sql    => "SELECT UNHEX('414243')",
                result => [ ['ABC'] ],
            },
            {
                test   => 'unhex str unicode',
                sql    => "SELECT UNHEX('263A' || HEX(9787) || CONV('10011000111100', 2, 16), 'UCS-2')",
                result => [ [ chr(9786) . chr(9787) . chr(9788) ] ],
            },
            {
                test   => 'bin from dec',
                sql    => "SELECT BIN('9788')",
                result => [ ['10011000111100'] ],
            },
            {
                test   => 'oct from dec',
                sql    => "SELECT OCT('420')",
                result => [ ['644'] ],
            },
          )
        : (),
        ### Numeric Functions ###
        {
            test   => 'abs',
            sql    => "SELECT ABS(-4)",
            result => [ [4] ],
        },
        {
            test   => 'ceiling int',
            sql    => "SELECT CEILING(5)",
            result => [ [5] ],
        },
        {
            test   => 'ceiling positive',
            sql    => "SELECT CEILING(4.1)",
            result => [ [5] ],
        },
        {
            test   => 'ceil negative',
            sql    => "SELECT CEIL(-4.5)",
            result => [ [-4] ],
        },
        {
            test   => 'floor int',
            sql    => "SELECT FLOOR(-5)",
            result => [ [-5] ],
        },
        {
            test   => 'floor positive',
            sql    => "SELECT FLOOR(4.999999999999)",
            result => [ [4] ],
        },
        {
            test   => 'floor negative',
            sql    => "SELECT FLOOR(-4.1)",
            result => [ [-5] ],
        },
        {
            test   => 'exp',
            sql    => "SELECT EXP(1)",
            result => [ [ ( sinh(1) + cosh(1) )**1 ] ],
        },
        {
            test   => 'log as log10',
            sql    => "SELECT LOG(6)",
            result => [ [ log(6) / log(10) ] ],
        },
        {
            test   => 'log as log2',
            sql    => "SELECT LOG(2, 32)",
            result => [ [ log(32) / log(2) ] ],
        },
        {
            test   => 'ln',
            sql    => "SELECT LN(3)",
            result => [ [ log(3) ] ],
        },
        {
            test   => 'mod',
            sql    => "SELECT MOD(8, 5)",
            result => [ [3] ],
        },
        {
            test   => 'power',
            sql    => "SELECT POWER(2, 4)",
            result => [ [16] ],
        },
        {
            test   => 'pow',
            sql    => "SELECT POW(2, 4)",
            result => [ [16] ],
        },
        {
            test        => 'rand',
            sql         => "SELECT FLOOR(RAND(4))",
            result_like => qr/^[0123]$|^-0$/,
        },
        {
            test        => 'rand with seed',
            sql         => "SELECT FLOOR(RAND(4), UNIX_TIMESTAMP())",
            result_like => qr/^-?[0123]$|^-0$/,
        },
        {
            test   => 'round int',
            sql    => "SELECT ROUND(4.999999999999)",
            result => [ [5] ],
        },
        {
            test   => 'round tenth',
            sql    => "SELECT ROUND(4.542222222222, 1)",
            result => [ [4.5] ],
        },
        {
            test   => 'sign -1',
            sql    => "SELECT SIGN(-25.5)",
            result => [ [-1] ],
        },
        {
            test   => 'sign 1',
            sql    => "SELECT SIGN(53645)",
            result => [ [1] ],
        },
        {
            test   => 'sign 0',
            sql    => "SELECT SIGN(0)",
            result => [ [0] ],
        },
        {
            test   => 'sign null',
            sql    => "SELECT SIGN(NULL)",
            result => [ [undef] ],
        },
        {
            test   => 'sqrt',
            sql    => "SELECT SQRT(64)",
            result => [ [8] ],
        },
        {
            test   => 'truncate int',
            sql    => "SELECT TRUNCATE(4.999999999999)",
            result => [ [4] ],
        },
        {
            test   => 'trunc int',
            sql    => "SELECT TRUNC(-4.9)",
            result => [ [-4] ],
        },
        {
            test   => 'truncate tenth',
            sql    => "SELECT TRUNCATE(4.934, 1)",
            result => [ [4.9] ],
        },
        {
            test   => 'trunc int',
            sql    => "SELECT TRUNC(-4.99999, 1)",
            result => [ [-4.9] ],
        },
        ### Trigonometric Functions ###
        # (this code shamelessly stolen from Math::Complex's t/Trig.t and converted to this test format)
        {
            test        => 'sin(1)',
            sql         => "SELECT SIN(1)",
            result_near => sin(1),
        },
        {
            test        => 'cos(1)',
            sql         => "SELECT COS(1)",
            result_near => cos(1),
        },
        {
            test        => 'tan(1)',
            sql         => "SELECT TAN(1)",
            result_near => tan(1),
        },
        {
            test        => 'sec(1)',
            sql         => "SELECT SEC(1)",
            result_near => sec(1),
        },
        {
            test        => 'csc(1)',
            sql         => "SELECT CSC(1)",
            result_near => csc(1),
        },
        {
            test        => 'cosec(1)',
            sql         => "SELECT COSEC(1)",
            result_near => cosec(1),
        },
        {
            test        => 'cot(1)',
            sql         => "SELECT COT(1)",
            result_near => cot(1),
        },
        {
            test        => 'cotan(1)',
            sql         => "SELECT COTAN(1)",
            result_near => cotan(1),
        },
        {
            test        => 'asin(1)',
            sql         => "SELECT ASIN(1)",
            result_near => asin(1),
        },
        {
            test        => 'acos(1)',
            sql         => "SELECT ACOS(1)",
            result_near => acos(1),
        },
        {
            test        => 'atan(1)',
            sql         => "SELECT ATAN(1)",
            result_near => atan(1),
        },
        {
            test        => 'asec(1)',
            sql         => "SELECT ASEC(1)",
            result_near => asec(1),
        },
        {
            test        => 'acsc(1)',
            sql         => "SELECT ACSC(1)",
            result_near => acsc(1),
        },
        {
            test        => 'acosec(1)',
            sql         => "SELECT ACOSEC(1)",
            result_near => acosec(1),
        },
        {
            test        => 'acot(1)',
            sql         => "SELECT ACOT(1)",
            result_near => acot(1),
        },
        {
            test        => 'acotan(1)',
            sql         => "SELECT ACOTAN(1)",
            result_near => acotan(1),
        },
        {
            test        => 'sinh(1)',
            sql         => "SELECT SINH(1)",
            result_near => sinh(1),
        },
        {
            test        => 'cosh(1)',
            sql         => "SELECT COSH(1)",
            result_near => cosh(1),
        },
        {
            test        => 'tanh(1)',
            sql         => "SELECT TANH(1)",
            result_near => tanh(1),
        },
        {
            test        => 'sech(1)',
            sql         => "SELECT SECH(1)",
            result_near => sech(1),
        },
        {
            test        => 'csch(1)',
            sql         => "SELECT CSCH(1)",
            result_near => csch(1),
        },
        {
            test        => 'cosech(1)',
            sql         => "SELECT COSECH(1)",
            result_near => cosech(1),
        },
        {
            test        => 'coth(1)',
            sql         => "SELECT COTH(1)",
            result_near => coth(1),
        },
        {
            test        => 'cotanh(1)',
            sql         => "SELECT COTANH(1)",
            result_near => cotanh(1),
        },
        {
            test        => 'asinh(1)',
            sql         => "SELECT ASINH(1)",
            result_near => asinh(1),
        },
        {
            test        => 'acosh(1)',
            sql         => "SELECT ACOSH(1)",
            result_near => acosh(1),
        },
        {
            test        => 'atanh(0.9)',
            sql         => "SELECT ATANH(0.9)",
            result_near => atanh(0.9),
        },
        {
            test        => 'asech(0.9)',
            sql         => "SELECT ASECH(0.9)",    # atanh(1.0) would be an error.
            result_near => asech(0.9),
        },
        {
            test        => 'acsch(2)',
            sql         => "SELECT ACSCH(2)",
            result_near => acsch(2),
        },
        {
            test        => 'acosech(2)',
            sql         => "SELECT ACOSECH(2)",
            result_near => acosech(2),
        },
        {
            test        => 'acoth(2)',
            sql         => "SELECT ACOTH(2)",
            result_near => acoth(2),
        },
        {
            test        => 'acotanh(2)',
            sql         => "SELECT ACOTANH(2)",
            result_near => acotanh(2),
        },
        {
            test        => 'pi',
            sql         => "SELECT PI",
            result_near => pi,
        },
        {
            test        => 'atan2(1, 0)',
            sql         => "SELECT ATAN2(1, 0)",
            result_near => atan2( 1, 0 ),
        },
        {
            test        => 'atan2(1, 1)',
            sql         => "SELECT ATAN2(1, 1)",
            result_near => atan( 1, 1 ),
        },
        {
            test        => 'atan2(-1, -1) to -3pi/4',
            sql         => "SELECT ATAN2(-1, -1)",
            result_near => atan2( -1, -1 ),
        },
        {
            test        => 'tan(0.9) as property sin/cos',
            sql         => "SELECT TAN(0.9)",
            result_near => tan(0.9),
        },
        {
            test        => 'sinh(2)',
            sql         => "SELECT SINH(2)",
            result_near => sinh(2),
        },
        {
            test        => 'acsch 0.1',
            sql         => "SELECT ACSCH(0.1)",
            result_near => acsch(0.1),
        },
        {
            test        => 'deg2rad(90)',
            sql         => "SELECT DEG2RAD(90)",
            result_near => deg2rad(90),
        },
        {
            test        => 'radians(90)',
            sql         => "SELECT RADIANS(90)",
            result_near => deg2rad(90),
        },
        {
            test        => 'rad2deg(PI)',
            sql         => "SELECT RAD2DEG(PI)",
            result_near => rad2deg(pi),
        },
        {
            test        => 'degrees(PI)',
            sql         => "SELECT DEGREES(PI())",
            result_near => rad2deg(pi),
        },
        {
            test        => 'deg2grad(0.9)',
            sql         => "SELECT DEG2GRAD(0.9)",
            result_near => deg2grad(0.9),
        },
        {
            test        => 'grad2deg(50)',
            sql         => "SELECT GRAD2DEG(50)",
            result_near => grad2deg(50),
        },
        {
            # XXX calculus within function parameters with functions as operands do not work
            test        => 'rad2grad(pi/2)',
            sql         => "SELECT RAD2GRAD(PI/2)",
            result_near => rad2grad( pi / 2 ),
            todo        => "Known limitation. Parser/Engine can not handle properly",
        },
        {
            test        => 'rad2grad(pi)',
            sql         => "SELECT RAD2GRAD(PI)",
            result_near => rad2grad(pi),
        },
        {
            test        => 'grad2rad(200)',
            sql         => "SELECT GRAD2RAD(200)",
            result_near => grad2rad(200),
        },
        {
            test        => 'lotta radians - deg2rad(10000000000)',
            sql         => "SELECT DEG2RAD(10000000000)",
            result_near => deg2rad(10000000000),
        },
        {
            test        => 'negative degrees - rad2deg(-10000000000)',
            sql         => "SELECT RAD2DEG(-10000000000)",
            result_near => rad2deg(-10000000000),
        },
        {
            test        => 'positive degrees - rad2deg(10000)',
            sql         => "SELECT RAD2DEG(10000)",
            result_near => rad2deg(10000),
        },
        {
            test        => 'tanh 100',
            sql         => "SELECT TANH(100)",
            result_near => tanh(100),
        },
        {
            test        => 'coth 100',
            sql         => "SELECT COTH(100)",
            result_near => coth(100),
        },
        {
            test        => 'tanh -100',
            sql         => "SELECT TANH(-100)",
            result_near => tanh(-100),
        },
        {
            test        => 'coth -100',
            sql         => "SELECT COTH(-100)",
            result_near => coth(-100),
        },
        {
            test        => 'sech 1e5',
            sql         => "SELECT SECH(100000)",
            result_near => sech(100000),
        },
        {
            test        => 'csch 1e5',
            sql         => "SELECT CSCH(100000)",
            result_near => csch(100000),
        },
        {
            test        => 'tanh 1e5',
            sql         => "SELECT TANH(100000)",
            result_near => tanh(100000),
        },
        {
            test        => 'coth 1e5',
            sql         => "SELECT COTH(100000)",
            result_near => coth(100000),
        },
        {
            test        => 'sech -1e5',
            sql         => "SELECT SECH(-100000)",
            result_near => sech(-100000),
        },
        {
            test        => 'csch -1e5',
            sql         => "SELECT CSCH(-100000)",
            result_near => csch(-100000),
            comment     => 'Is meant to return a "negative zero"'
        },
        {
            test        => 'tanh -1e5',
            sql         => "SELECT TANH(-100000)",
            result_near => tanh(-100000),
        },
        {
            test        => 'coth -1e5',
            sql         => "SELECT COTH(-100000)",
            result_near => Math::Trig::coth(-100000),
        },
        ### System Functions
        {
            test   => 'dbname',
            sql    => "SELECT DBNAME()",
            result => [ [ $dbh->{Name} ] ],
        },
        {
            test   => 'username',
            sql    => "SELECT USERNAME()",
            result => [ [ $dbh->{CURRENT_USER} ] ],
        },
        {
            test   => 'user',
            sql    => "SELECT USER()",
            result => [ [ $dbh->{CURRENT_USER} ] ],
        },
        {
            test     => 'SELECT with calculation in WHERE CLAUSE',
            sql      => sprintf( "SELECT id,host,signature,message FROM log WHERE time_stamp < (%d - ( 4 * 60 ))", $now ),
            fetch_by => "id",
            result   => {
                8 => {
                    id        => 8,
                    host      => "ernie",
                    signature => "rpc.statd",
                    message   => "starting",
                },
                9 => {
                    id        => 9,
                    host      => "ernie",
                    signature => "savecore",
                    message   => "no core dump",
                },
                10 => {
                    id        => 10,
                    host      => "ernie",
                    signature => "postfix/postfix-script",
                    message   => "starting the Postfix mail system",
                },
                11 => {
                    id        => 11,
                    host      => "ernie",
                    signature => "rpcbind",
                    message   => "connect from 127.0.0.1 to dump()",
                },
                12 => {
                    id        => 12,
                    host      => "ernie",
                    signature => "sshd",
                    message   => "last message repeated 2 times",
                },
                13 => {
                    id        => 13,
                    host      => "ernie",
                    signature => "shutdown",
                    message   => "poweroff by root:",
                },
                14 => {
                    id        => 14,
                    host      => "ernie",
                    signature => "shutdown",
                    message   => "rebooted by root",
                },
                15 => {
                    id        => 15,
                    host      => "ernie",
                    signature => "sshd",
                    message   => "Server listening on :: port 22.",
                },
                16 => {
                    id        => 16,
                    host      => "ernie",
                    signature => "sshd",
                    message   => "Server listening on 0.0.0.0 port 22.",
                },
                17 => {
                    id        => 17,
                    host      => "ernie",
                    signature => "sshd",
                    message   => "Received SIGHUP; restarting.",
                },

            },
        },
        {
            test => 'SELECT with calculation and logical expression in WHERE CLAUSE',
            sql  => sprintf(
                "SELECT id,host,signature,message FROM log WHERE (time_stamp > (%d - 5)) AND (time_stamp < (%d + 5))",
                $now, $now
            ),
            fetch_by => "id",
            result   => {
                1 => {
                    id        => 1,
                    host      => "bert",
                    signature => "/netbsd",
                    message   => "Copyright (c) 1996, 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,",
                },
                2 => {
                    id        => 2,
                    host      => "bert",
                    signature => "/netbsd",
                    message   => "2006, 2007, 2008, 2009, 2010",
                },
                3 => {
                    id        => 3,
                    host      => "bert",
                    signature => "/netbsd",
                    message   => "The NetBSD Foundation, Inc.  All rights reserved.",
                },
                4 => {
                    id        => 4,
                    host      => "bert",
                    signature => "/netbsd",
                    message   => "Copyright (c) 1982, 1986, 1989, 1991, 1993",
                },
                5 => {
                    id        => 5,
                    host      => "bert",
                    signature => "/netbsd",
                    message   => "The Regents of the University of California.  All rights reserved.",
                },
                6 => {
                    id        => 6,
                    host      => "bert",
                    signature => "/netbsd",
                    message   => '',
                },
                7 => {
                    id        => 7,
                    host      => "bert",
                    signature => "/netbsd",
                    message   => "NetBSD 5.99.39 (BERT) #0: Fri Oct  8 06:23:03 CEST 2010",
                },
            },
        },
        {
            test => 'SELECT with calculated items in BETWEEN in WHERE CLAUSE',
            sql  => sprintf( "SELECT id,host,signature,message FROM log WHERE time_stamp BETWEEN ( %d - 5, %d + 5)", $now, $now ),
            fetch_by => "id",
            result   => {
                1 => {
                    id        => 1,
                    host      => "bert",
                    signature => "/netbsd",
                    message   => "Copyright (c) 1996, 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,",
                },
                2 => {
                    id        => 2,
                    host      => "bert",
                    signature => "/netbsd",
                    message   => "2006, 2007, 2008, 2009, 2010",
                },
                3 => {
                    id        => 3,
                    host      => "bert",
                    signature => "/netbsd",
                    message   => "The NetBSD Foundation, Inc.  All rights reserved.",
                },
                4 => {
                    id        => 4,
                    host      => "bert",
                    signature => "/netbsd",
                    message   => "Copyright (c) 1982, 1986, 1989, 1991, 1993",
                },
                5 => {
                    id        => 5,
                    host      => "bert",
                    signature => "/netbsd",
                    message   => "The Regents of the University of California.  All rights reserved.",
                },
                6 => {
                    id        => 6,
                    host      => "bert",
                    signature => "/netbsd",
                    message   => '',
                },
                7 => {
                    id        => 7,
                    host      => "bert",
                    signature => "/netbsd",
                    message   => "NetBSD 5.99.39 (BERT) #0: Fri Oct  8 06:23:03 CEST 2010",
                },
            },
        },
        {
            test   => 'MAX() with calculated WHERE clause',
            sql    => sprintf( "SELECT MAX(time_stamp) FROM log WHERE time_stamp IN (%d - (2*3600), %d - (4*3600))", $now, $now ),
            result => [ [ $now - ( 2 * 3600 ) ] ],
        },
        {
            test   => 'calculation in MAX()',
            sql    => "SELECT MAX(time_stamp - 3*3600) FROM log",
            result => [ [ $now - ( 3 * 3600 ) ] ],
        },
        {
            test   => 'Caclulation outside aggregation',
            todo   => "Known limitation. Parser/Engine can not handle properly",
            passes => 'parse-DBD::CSV parse-DBD::File parse-DBD::DBM',
            sql    => "SELECT MAX(time_stamp) - 3*3600 FROM log",
            result => [ [ $now - ( 3 * 3600 ) ] ],
        },
        {
            test   => 'function in MAX()',
            sql    => "SELECT MAX( CHAR_LENGTH(message) ) FROM log",
            result => [ [73] ],
        },
        {
            test   => 'select simple calculated constant from table',
            sql    => "SELECT 1+0 from log",
            result => [ ( [1] ) x 17 ],
        },
        {
            test   => 'select calculated constant with preceedence rules',
            sql    => "SELECT 1+1*2",
            result => [ [3] ],
        },
        {
            test   => 'SELECT not calculated constant',
            sql    => "SELECT 1",
            result => [ [1] ],
        },
    );

    foreach my $test (@tests)
    {
        local $TODO;
        defined( $test->{todo} )
          and not( defined( $test->{passes} ) and $test->{passes} =~ /(?:parse|execute|result)(?:(?!-)|-\Q$test_dbd\E)/ )
          and $TODO = $test->{todo};
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

        defined( $test->{todo} )
          and not( defined( $test->{passes} ) and $test->{passes} =~ /(?:execute|result)(?:(?!-)|-\Q$test_dbd\E)/ )
          and $TODO = $test->{todo};
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
                  or ok( $n, "$i: execute $test->{sql} using $test_dbd (" . DBI::neat_list($bp) . ")" )
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

            defined( $test->{todo} )
              and not( defined( $test->{passes} ) and $test->{passes} =~ /result(?:(?!-)|-\Q$test_dbd\E)/ )
              and $TODO = $test->{todo};
            if ( $test->{result_cols} )
            {
                is_deeply( $sth->col_names(), $test->{result_cols}, "Columns in $test->{test}" );
            }

            if ( $test->{fetch_by} )
            {
                is_deeply( $sth->fetchall_hashref( $test->{fetch_by} ), $test->{result}, $test->{test} );
            }
            elsif ( defined( $test->{result_code} ) )
            {
                &{ $test->{result_code} }($sth);
            }
            elsif ( defined( $test->{result_like} ) )
            {
                my $row = $sth->fetch_rows();
                like( $row && $row->[0] && $row->[0][0], $test->{result_like}, $test->{test} );
            }
            elsif ( defined( $test->{result_near} ) )
            {
                my $row = $sth->fetch_rows();
                near( $row && $row->[0] && $row->[0][0], $test->{result_near}, $test->{test} );
            }
            else
            {
                is_deeply( $sth->fetch_rows(), $test->{result}, $test->{test} );
            }
        }
    }
}

done_testing();
