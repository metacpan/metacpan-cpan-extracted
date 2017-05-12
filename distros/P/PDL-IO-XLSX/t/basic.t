use strict;
use warnings;

use Test::More;
use PDL;
use PDL::IO::XLSX ':all';
use Test::Number::Delta relative => 0.00001;
use Config;

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

### TAB1
my $t1  = rxlsx2D('t/_sample1.xlsx');
my @p1  = rxlsx1D('t/_sample1.xlsx');
  
is($p1[0]->info,  "PDL: Double D [5]",   '$p1[0]->info');
is($p1[1]->info,  "PDL: Double D [5]",   '$p1[1]->info');
is($p1[2]->info,  "PDL: Double D [5]",   '$p1[2]->info');
is($p1[3]->info,  "PDL: Double D [5]",   '$p1[3]->info');
is($p1[4]->info,  "PDL: Double D [5]",   '$p1[4]->info');
is($p1[5]->info,  "PDL: Double D [5]",   '$p1[5]->info');
is($p1[6]->info,  "PDL: Double D [5]",   '$p1[6]->info');
is($t1->info,     "PDL: Double D [5,7]", '$t1->info');
  
delta_ok($t1->transpose->unpdl,  $tab1, '$t1->unpdl');

### TAB2
my $t2  = rxlsx2D('t/_sample2.xlsx');
my @p2  = rxlsx1D('t/_sample2.xlsx');
my @p2d = rxlsx1D('t/_sample2.xlsx', {type=>double, empty2bad=>1});
my @p2f = rxlsx1D('t/_sample2.xlsx', {type=>float, empty2bad=>1});

is($t2->info,     "PDL: Double D [24,5]", '$t2->info');

is($p2[0]->info,  "PDL: Double D [24]",   '$p2[0]->info');
is($p2[1]->info,  "PDL: Double D [24]",   '$p2[1]->info');
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

my @p2x = rxlsx1D('t/_sample2.xlsx', {type=>[short, long, longlong, float], empty2bad=>1});
is($p2x[0]->info, "PDL: Short D [24]",    '$p2x[0]->info');
is($p2x[1]->info, "PDL: Long D [24]",     '$p2x[1]->info');
is($p2x[2]->info, "PDL: LongLong D [24]", '$p2x[2]->info');
is($p2x[3]->info, "PDL: Float D [24]",    '$p2x[3]->info');

delta_ok($t2->transpose->unpdl,  $tab2, '$t2->unpdl');
delta_ok($t2->slice(':', "(0)")->sum, 40123167);
delta_ok($t2->slice(':', "(1)")->sum, -68083968);
delta_ok($t2->slice(':', "(2)")->sum, 561059287524926230000.0);
delta_ok($t2->slice(':', "(3)")->sum, -5789801080043.0);
delta_ok($t2->slice(':', "(4)")->sum, -0.76818887);
delta_ok($t2->sum, $p2d[0]->sum + $p2d[1]->sum + $p2d[2]->sum + $p2d[3]->sum, "sum double");
delta_ok($t2->sum, $p2f[0]->sum + $p2f[1]->sum + $p2f[2]->sum + $p2f[3]->sum, "sum float");

### TAB3
my $t3  = rxlsx2D('t/_sample3.xlsx', {type=>long});
my $t3b = rxlsx2D('t/_sample3.xlsx', {type=>long, empty2bad=>1});
my $t3x = rxlsx2D('t/_sample3.xlsx', {type=>long, empty2bad=>1, text2bad=>1});
is($t3->sum,  32, '$t3->sum');
is($t3b->sum, 32, '$t3b->sum');
is($t3->info,  "PDL: Long D [5,3]", '$t3->info');
is($t3b->info, "PDL: Long D [5,3]", '$t3b->info');
delta_ok($t3b->sum, $t3->sum, '$t3b->sum == $t3->sum');
is($t3->at(0,2), 0, '$t3->at(0,2)');
is($t3->at(2,0), 0, '$t3->at(2,0)');
is($t3->at(3,1), 0, '$t3->at(3,1)');
is($t3->at(4,2), 0, '$t3->at(4,2)');
is($t3b->at(0,2), 0,     '$t3b->at(0,2)');
is($t3b->at(2,0), 'BAD', '$t3b->at(2,0)');
is($t3b->at(3,1), 'BAD', '$t3b->at(3,1)');
is($t3b->at(4,2), 'BAD', '$t3b->at(4,2)');
is($t3x->at(0,2), 'BAD', '$t3x->at(0,2)');
is($t3x->at(2,0), 'BAD', '$t3x->at(2,0)');
is($t3x->at(3,1), 'BAD', '$t3x->at(3,1)');
is($t3x->at(4,2), 'BAD', '$t3x->at(4,2)');

done_testing;