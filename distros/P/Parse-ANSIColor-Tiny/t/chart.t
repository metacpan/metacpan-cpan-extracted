use strict;
use warnings;
use Test::More tests => 4;
use Test::Differences;

# shortcuts
BEGIN {
  use Parse::ANSIColor::Tiny;
  sub o ($) { 'on_'     . $_[0] }
  sub b ($) { 'bright_' . $_[0] }
  sub bo () { 'bold' }
  eval join '', map { "sub $_ () { '$_' }" } keys %Parse::ANSIColor::Tiny::ATTRIBUTES;
}

is underline, 'underline', 'shortcut works';
is o b cyan, 'on_bright_cyan', 'shortcuts work together';

my $p = new_ok('Parse::ANSIColor::Tiny');

my $chart = do { local $/; <DATA>; };
note $chart;

eq_or_diff $p->parse($chart), [
[[],   " 0\t"], [[         ], '  0 '],  [[             ], '  0 '],  [[], "\t\t 1\t"], [[bo         ], '  1 '],  [[bo             ], '  1 '],
[[], "\n 2\t"], [[dark     ], '  2 '],  [[bo, dark     ], '  2 '],  [[], "\t\t 3\t"], [[           ], '  3 '],  [[bo,            ], '  3 '],
[[], "\n 4\t"], [[underline], '  4 '],  [[bo, underline], '  4 '],  [[], "\t\t 5\t"], [[blink      ], '  5 '],  [[bo, blink      ], '  5 '],
[[], "\n 6\t"], [[         ], '  6 '],  [[bo,          ], '  6 '],  [[], "\t\t 7\t"], [[&reverse   ], '  7 '],  [[bo, &reverse   ], '  7 '],
[[], "\n30\t"], [[black    ], ' 30 '],  [[bo, black    ], ' 30 '],  [[], "\t\t31\t"], [[red        ], ' 31 '],  [[bo, red        ], ' 31 '],
[[], "\n32\t"], [[green    ], ' 32 '],  [[bo, green    ], ' 32 '],  [[], "\t\t33\t"], [[yellow     ], ' 33 '],  [[bo, yellow     ], ' 33 '],
[[], "\n34\t"], [[blue     ], ' 34 '],  [[bo, blue     ], ' 34 '],  [[], "\t\t35\t"], [[magenta    ], ' 35 '],  [[bo, magenta    ], ' 35 '],
[[], "\n36\t"], [[cyan     ], ' 36 '],  [[bo, cyan     ], ' 36 '],  [[], "\t\t37\t"], [[white      ], ' 37 '],  [[bo, white      ], ' 37 '],
[[], "\n40\t"], [[o black  ], ' 40 '],  [[bo, o black  ], ' 40 '],  [[], "\t\t41\t"], [[o red      ], ' 41 '],  [[bo, o red      ], ' 41 '],
[[], "\n42\t"], [[o green  ], ' 42 '],  [[bo, o green  ], ' 42 '],  [[], "\t\t43\t"], [[o yellow   ], ' 43 '],  [[bo, o yellow   ], ' 43 '],
[[], "\n44\t"], [[o blue   ], ' 44 '],  [[bo, o blue   ], ' 44 '],  [[], "\t\t45\t"], [[o magenta  ], ' 45 '],  [[bo, o magenta  ], ' 45 '],
[[], "\n46\t"], [[o cyan   ], ' 46 '],  [[bo, o cyan   ], ' 46 '],  [[], "\t\t47\t"], [[o white    ], ' 47 '],  [[bo, o white    ], ' 47 '],
[[], "\n90\t"], [[b black  ], ' 90 '],  [[bo, b black  ], ' 90 '],  [[], "\t\t91\t"], [[b red      ], ' 91 '],  [[bo, b red      ], ' 91 '],
[[], "\n92\t"], [[b green  ], ' 92 '],  [[bo, b green  ], ' 92 '],  [[], "\t\t93\t"], [[b yellow   ], ' 93 '],  [[bo, b yellow   ], ' 93 '],
[[], "\n94\t"], [[b blue   ], ' 94 '],  [[bo, b blue   ], ' 94 '],  [[], "\t\t95\t"], [[b magenta  ], ' 95 '],  [[bo, b magenta  ], ' 95 '],
[[], "\n96\t"], [[b cyan   ], ' 96 '],  [[bo, b cyan   ], ' 96 '],  [[], "\t\t97\t"], [[b white    ], ' 97 '],  [[bo, b white    ], ' 97 '],
[[], "\n100\t"], [[o b black], ' 100 '], [[bo, o b black], ' 100 '], [[], "\t\t101\t"], [[o b red    ], ' 101 '], [[bo, o b red    ], ' 101 '],
[[], "\n102\t"], [[o b green], ' 102 '], [[bo, o b green], ' 102 '], [[], "\t\t103\t"], [[o b yellow ], ' 103 '], [[bo, o b yellow ], ' 103 '],
[[], "\n104\t"], [[o b blue ], ' 104 '], [[bo, o b blue ], ' 104 '], [[], "\t\t105\t"], [[o b magenta], ' 105 '], [[bo, o b magenta], ' 105 '],
[[], "\n106\t"], [[o b cyan ], ' 106 '], [[bo, o b cyan ], ' 106 '], [[], "\t\t107\t"], [[o b white  ], ' 107 '], [[bo, o b white  ], ' 107 '],
[[], "\n"],
  ],
  'parsed simple color chart';

# cat this file to see the color chart

__DATA__
 0	[00m  0 [01;00m  0 [0m		 1	[01m  1 [01;01m  1 [0m
 2	[02m  2 [01;02m  2 [0m		 3	[03m  3 [01;03m  3 [0m
 4	[04m  4 [01;04m  4 [0m		 5	[05m  5 [01;05m  5 [0m
 6	[06m  6 [01;06m  6 [0m		 7	[07m  7 [01;07m  7 [0m
30	[30m 30 [01;30m 30 [0m		31	[31m 31 [01;31m 31 [0m
32	[32m 32 [01;32m 32 [0m		33	[33m 33 [01;33m 33 [0m
34	[34m 34 [01;34m 34 [0m		35	[35m 35 [01;35m 35 [0m
36	[36m 36 [01;36m 36 [0m		37	[37m 37 [01;37m 37 [0m
40	[40m 40 [01;40m 40 [0m		41	[41m 41 [01;41m 41 [0m
42	[42m 42 [01;42m 42 [0m		43	[43m 43 [01;43m 43 [0m
44	[44m 44 [01;44m 44 [0m		45	[45m 45 [01;45m 45 [0m
46	[46m 46 [01;46m 46 [0m		47	[47m 47 [01;47m 47 [0m
90	[90m 90 [01;90m 90 [0m		91	[91m 91 [01;91m 91 [0m
92	[92m 92 [01;92m 92 [0m		93	[93m 93 [01;93m 93 [0m
94	[94m 94 [01;94m 94 [0m		95	[95m 95 [01;95m 95 [0m
96	[96m 96 [01;96m 96 [0m		97	[97m 97 [01;97m 97 [0m
100	[100m 100 [01;100m 100 [0m		101	[101m 101 [01;101m 101 [0m
102	[102m 102 [01;102m 102 [0m		103	[103m 103 [01;103m 103 [0m
104	[104m 104 [01;104m 104 [0m		105	[105m 105 [01;105m 105 [0m
106	[106m 106 [01;106m 106 [0m		107	[107m 107 [01;107m 107 [0m
