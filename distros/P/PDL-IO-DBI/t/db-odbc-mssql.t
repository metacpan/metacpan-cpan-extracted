use strict;
use warnings;

use Test::More;
use DBI;
use PDL;
use PDL::IO::DBI ':all';
use Test::Number::Delta relative => 0.000_000_1;
use Config;

plan skip_all => "DBD::ODBC not installed" unless eval { require DBD::ODBC };
plan skip_all => "PDL_IO_DBI_ODBC_MSSQL_TEST_DSN not set" unless $ENV{PDL_IO_DBI_ODBC_MSSQL_TEST_DSN};

use constant NO64BITINT => $Config{ivsize} < 8 ? 1 : 0;
use constant NODATETIME => eval { require PDL::DateTime; require Time::Moment; 1 } ? 0 : 1;
diag "No support for 64bitint - some tests will be skipped" if NO64BITINT;

my $dsn = $ENV{PDL_IO_DBI_ODBC_MSSQL_TEST_DSN}; # e.g. PDL_IO_DBI_ODBC_MSSQL_TEST_DSN=dbi:ODBC:dsn=d1

my $tab1 = [
        [    1,    1  ,    -32768,    -2147483648,    -9223372036854775808,    -3.40282347e+37 ,    -1.79769313486231571e+307    ],
        [    2,    127,    -10   ,    -10        ,    -10                 ,    -1.175494351e-37,    -2.22507385850720138e-307    ],
        [    3,    128,      1   ,     1         ,     1                  ,     0.12345        ,     0.12345                     ],
        [    4,    192,     10   ,     10        ,     10                 ,     1.175494351e-37,     2.22507385850720138e-307    ],
        [    5,    255,     32767,     2147483647,     9223372036854775807,     3.40282347e+37 ,     1.79769313486231571e+307    ],
];

my $tab2 = [
        [    123    ,    -123    ,    1          ,    -3          ,    -0.123          ],
        [    456    ,    -456    ,    2          ,    -4          ,    -0.456          ],
        [    271308 ,    -381825 ,    861        ,    -369        ,     0.058402734    ],
        [    419160 ,    -640194 ,    6027       ,    -1107       ,     0.65683974     ],
        [    567012 ,    -898563 ,    42189      ,    -3321       ,    -0.996871604    ],
        [    714864 ,    -1156932,    295323     ,    -9963       ,     0.767454364    ],
        [    862716 ,    -1415301,    2067261    ,    -29889      ,    -0.099639442    ],
        [    1010568,    -1673670,    14470827   ,    -89667      ,    -0.625093132    ],
        [    1158420,    -1932039,    101295789  ,    -269001     ,     0.992749907    ],
        [    1306272,    -2190408,    709070523  ,    -807003     ,    -0.79331204     ],
        [    1454124,    -2448777,    4963493661 ,    -2421009    ,     0.140705652    ],
        [    1601976,    -2707146,    34744455627,    -7263027    ,     0.592276893    ],
        [    1749828,    -2965515,    2.43211E+11,    -21789081   ,    -0.986929461    ],
        [    1897680,    -3223884,    1.70248E+12,    -65367243   ,     0.817812236    ],
        [    2045532,    -3482253,    1.19173E+13,    -196101729  ,    -0.181531092    ],
        [    2193384,    -3740622,    8.34214E+13,    -588305187  ,    -0.558447175    ],
        [    2341236,    -3998991,    5.8395E+14 ,    -1764915561 ,     0.979420224    ],
        [    2489088,    -4257360,    4.08765E+15,    -5294746683 ,    -0.840913028    ],
        [    2636940,    -4515729,    2.86136E+16,    -15884240049,     0.222045905    ],
        [    2784792,    -4774098,    2.00295E+17,    -47652720147,     0.523661868    ],
        [    2932644,    -5032467,    1.40206E+18,    -1.42958E+11,    -0.970235047    ],
        [    3080496,    -5290836,    9.81445E+18,    -4.28874E+11,     0.862574886    ],
        [    3228348,    -5549205,    6.87011E+19,    -1.28662E+12,    -0.262180762    ],
        [    3376200,    -5807574,    4.80908E+20,    -3.85987E+12,    -0.487980493    ],
];

my $tab3 = [
        [    1    ,    1    ,    1        ],
        [    2    ,    2    ,    2        ],
        [    undef,    3    ,    3        ],
        [    4    ,    undef,    4        ],
        [    5    ,    5    ,    undef    ],
];

{
  my $dbh = DBI->connect($dsn);
  $dbh->do('DROP TABLE tab1');
  $dbh->do('DROP TABLE tab2');
  $dbh->do('DROP TABLE tab3');
  $dbh->do('DROP TABLE tab4');
  $dbh->do('CREATE TABLE tab1 (
                c1 INT,
                c2 TINYINT,
                c3 SMALLINT,
                c4 INT,
                c5 BIGINT,
                c6 REAL,
                c7 FLOAT
            )');
  $dbh->do('INSERT INTO tab1 VALUES (?, ?, ?, ?, ?, ?, ?)', undef, @$_) for (@$tab1);
  $dbh->do('CREATE TABLE tab2 ( c1 INT,  c2 INT, c3 FLOAT, c4 FLOAT, c5 FLOAT )');
  $dbh->do('INSERT INTO tab2 VALUES (?, ?, ?, ?, ?)', undef, @$_) for (@$tab2);
  $dbh->do('CREATE TABLE tab3 ( c1 INT,  c2 INT, c3 INT )');
  $dbh->do('INSERT INTO tab3 VALUES (?, ?, ?)', undef, @$_) for (@$tab3);
  $dbh->do('CREATE TABLE tab4 ( dt DATE,  ts1 DATETIME2, ts2 DATETIME, ts3 SMALLDATETIME)');
  $dbh->do('INSERT INTO tab4 VALUES (?, ?, ?, ?)', undef, "1969-12-31", "2015-12-31 23:23:23.999999", "2001-11-11 12:23:00", "2001-11-11 00:00:00");
  $dbh->disconnect;
}

### TAB1
if (!NO64BITINT) {
  my $t1  = rdbi2D($dsn, "select * from tab1");
  my $t1h = rdbi2D(DBI->connect($dsn), "select * from tab1");
  my @p1  = rdbi1D($dsn, "select * from tab1");

  is($p1[0]->info,  "PDL: Long D [5]",     '$p1[0]->info');
  is($p1[1]->info,  "PDL: Byte D [5]",     '$p1[1]->info');
  is($p1[2]->info,  "PDL: Short D [5]",    '$p1[2]->info');
  is($p1[3]->info,  "PDL: Long D [5]",     '$p1[3]->info');
  is($p1[4]->info,  "PDL: LongLong D [5]", '$p1[4]->info');
  is($p1[5]->info,  "PDL: Float D [5]",    '$p1[5]->info');
  is($p1[6]->info,  "PDL: Double D [5]",   '$p1[6]->info');
  is($t1->info,     "PDL: Double D [5,7]", '$t1->info');
  is($t1h->info,    "PDL: Double D [5,7]", '$t1h->info');

  delta_ok($t1->transpose->unpdl,  $tab1, '$t1->unpdl');
  delta_ok($t1h->transpose->unpdl, $tab1, '$t1h->unpdl');
}

### TAB2
my $t2  = rdbi2D($dsn, "select * from tab2");
my @p2  = rdbi1D($dsn, "select * from tab2");
my @p2d = rdbi1D($dsn, "select * from tab2", {type=>double, null2bad=>1});
my @p2f = rdbi1D($dsn, "select * from tab2", {type=>float, null2bad=>1});

is($t2->info,     "PDL: Double D [24,5]", '$t2->info');

is($p2[0]->info,  "PDL: Long D [24]",     '$p2[0]->info');
is($p2[1]->info,  "PDL: Long D [24]",     '$p2[1]->info');
is($p2[2]->info,  "PDL: Double D [24]",   '$p2[2]->info');
is($p2[3]->info,  "PDL: Double D [24]",   '$p2[3]->info');

is($p2d[0]->info, "PDL: Double D [24]",   '$p2d[0]->info');
is($p2d[1]->info, "PDL: Double D [24]",   '$p2d[1]->info');
is($p2d[2]->info, "PDL: Double D [24]",   '$p2d[2]->info');
is($p2d[3]->info, "PDL: Double D [24]",   '$p2d[3]->info');

is($p2f[0]->info, "PDL: Float D [24]",    '$p2f[0]->info');
is($p2f[1]->info, "PDL: Float D [24]",    '$p2f[1]->info');
is($p2f[2]->info, "PDL: Float D [24]",    '$p2f[2]->info');
is($p2f[3]->info, "PDL: Float D [24]",    '$p2f[3]->info');

if (!NO64BITINT) {
  my @p2x = rdbi1D($dsn, "select * from tab2", {type=>[short, long, longlong, float], null2bad=>1});
  is($p2x[0]->info, "PDL: Short D [24]",    '$p2x[0]->info');
  is($p2x[1]->info, "PDL: Long D [24]",     '$p2x[1]->info');
  is($p2x[2]->info, "PDL: LongLong D [24]", '$p2x[2]->info');
  is($p2x[3]->info, "PDL: Float D [24]",    '$p2x[3]->info');
}

delta_ok($t2->transpose->unpdl,  $tab2, '$t2->unpdl');
delta_ok($t2->slice(':', "(0)")->sum, 40123167);
delta_ok($t2->slice(':', "(1)")->sum, -68083968);
delta_ok($t2->slice(':', "(2)")->sum, 561059287524926160896.0);
delta_ok($t2->slice(':', "(3)")->sum, -5789801080043.0);
delta_ok($t2->slice(':', "(4)")->sum, -0.768188867000000108);

delta_within($t2->sum, $p2d[0]->sum + $p2d[1]->sum + $p2d[2]->sum + $p2d[3]->sum, 1000000, "sum double");
delta_within($t2->sum, $p2f[0]->sum + $p2f[1]->sum + $p2f[2]->sum + $p2f[3]->sum, 10000000000000, "sum float");

### TAB3
my $t3  = rdbi2D($dsn, "select * from tab3");
my $t3b = rdbi2D($dsn, "select * from tab3", {null2bad=>1});
is($t3->sum,  33, '$t3->sum');
is($t3b->sum, 33, '$t3b->sum');
is($t3->info,  "PDL: Long D [5,3]", '$t3->info');
is($t3b->info, "PDL: Long D [5,3]", '$t3b->info');
delta_ok($t3b->sum, $t3->sum, '$t3b->sum == $t3->sum');
is($t3->at(2,0), 0, '$t3->at(2,0)');
is($t3->at(3,1), 0, '$t3->at(3,1)');
is($t3->at(4,2), 0, '$t3->at(4,2)');
is($t3b->at(2,0), 'BAD', '$t3b->at(2,0)');
is($t3b->at(3,1), 'BAD', '$t3b->at(3,1)');
is($t3b->at(4,2), 'BAD', '$t3b->at(4,2)');

### TAB4
if (!NO64BITINT) {
  my $t4a = rdbi2D($dsn, "select * from tab4", {type => longlong});
  is_deeply([$t4a->list], [-86400000000, 1451604203999999,1005481380000000,1005436800000000]);
  my ($t4i, $t4j, $t4k, $t4l) = rdbi1D($dsn, "select * from tab4", {type => longlong});
  is($t4i->at(0,0), -86400000000);
  is($t4j->at(0,0), 1451604203999999);
  is($t4k->at(0,0), 1005481380000000);
  is($t4l->at(0,0), 1005436800000000);
  is($t4i->hdr->{col_name}, "dt");
  is($t4j->hdr->{col_name}, "ts1");
  is($t4k->hdr->{col_name}, "ts2");
  is($t4l->hdr->{col_name}, "ts3");

  if (!NODATETIME) {
    my ($dt4i, $dt4j, $dt4k, $dt4l) = rdbi1D($dsn, "select * from tab4");
    is($dt4i->hdr->{col_name}, "dt");
    is($dt4j->hdr->{col_name}, "ts1");
    is($dt4k->hdr->{col_name}, "ts2");
    is($dt4l->hdr->{col_name}, "ts3");
    is($dt4i->info, "PDL::DateTime: LongLong D [1]");
    is($dt4j->info, "PDL::DateTime: LongLong D [1]");
    is($dt4k->info, "PDL::DateTime: LongLong D [1]");
    is($dt4l->info, "PDL::DateTime: LongLong D [1]");
  }
  else {
    diag "no PDL::DateTime";
    my ($dt4i, $dt4j, $dt4k, $dt4l) = rdbi1D($dsn, "select * from tab4");
    is($dt4i->hdr->{col_name}, "dt");
    is($dt4j->hdr->{col_name}, "ts1");
    is($dt4k->hdr->{col_name}, "ts2");
    is($dt4l->hdr->{col_name}, "ts3");
    is($dt4i->info, "PDL: Double D [1]");
    is($dt4j->info, "PDL: Double D [1]");
    is($dt4k->info, "PDL: Double D [1]");
    is($dt4l->info, "PDL: Double D [1]");
  }
}
else {
  diag "perl without 64bit int";
}
my $t4b = rdbi2D($dsn, "select * from tab4");
delta_ok([$t4b->list], [-86400.0, 1451604203.999, 1005481380.0, 1005436800.0]);
my ($t4m, $t4n, $t4o, $t4p) = rdbi1D($dsn, "select * from tab4", {type => double});
is($t4m->hdr->{col_name}, "dt");
is($t4n->hdr->{col_name}, "ts1");
is($t4o->hdr->{col_name}, "ts2");
is($t4p->hdr->{col_name}, "ts3");
delta_within($t4m->at(0,0), -86400.0, 0.000_001);
delta_within($t4n->at(0,0), 1451604203.999, 0.000_000_1);
delta_within($t4o->at(0,0), 1005481380.0, 0.000_001);
delta_within($t4p->at(0,0), 1005436800.0, 0.000_001);

done_testing;