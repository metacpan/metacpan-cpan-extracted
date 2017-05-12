#!/usr/bin/env perl
use strict; use warnings;

use Test::More;
use lib '../lib' ;

BEGIN {
  $ENV{PERL_RL} = 'Perl5';	# force to use Term::ReadLine::Perl5
  $ENV{LANG} = 'C';
  $ENV{'COLUMNS'} = 80;
  $ENV{'LINES'} = 25;
  # stop reading ~/.inputrc
  $ENV{'INPUTRC'} = '/dev/null';
  use_ok( 'Term::ReadLine::Perl5' );
}

require 'Term/ReadLine/Perl5/readline.pm';

# stop reading ~/.inputrc
$ENV{'INPUTRC'} = '/dev/null';

note('_unescape()');
my @tests = (
    ["foo", [qw(102 111 111)], 'No escape'],
    ["f\x74o\x723", [qw(102 116 111 114 51)], ''],
    ["f\x74o\x723\0777f\x23d\0555",
     [qw(102 116 111 114 51 63 55 102 35 100 45 53)], ''],
    ['f\\C-\\M-f', [qw(102 27 6)], 'Ctrl Meta f'],
    ['f\\C-\\M-d', [qw(102 27 4)], 'Ctrl Meta d'],
    ['f\\C-d', [qw(102 4)], 'Ctrl-d'],
    ['f\\C-x', [qw(102 24)], 'Ctrl-x'],
    ['f\\C-a', [qw(102 1)], 'Ctrl-a'],
    ['f\\C-r', [qw(102 18)], 'Ctrl-r'],
    ['f\\C-rq', [qw(102 18 113)], 'Ctrl-r q'],
    ['q\\x0fDr', [qw(113 15 68 114)], ''],
    ['\\e', [qw(27)], ''],
    ['\\M-f', [qw(27 102)], 'Meta-f'],
    ['f\\M-a', [qw(102 27 97)], 'Meta-a'],
    ['r\\xdd', [qw(114 221)], 'hex dd'],
    ['r\\xddd', [qw(114 221 100)], 'hex ddd'],
    ['rd\\0330\\dfe3', [qw(114 100 27 48 4 102 101 51)],
     'octal + EOT'],
    ['rd\\0330\\dfe3\\xfdd', [qw(114 100 27 48 4 102 101 51 253 100)],
     'octal + EOT + hex'],
    ['\\*', [qw(default)], 'default'],
    ['\\0333foo\\*', [qw(27 51 102 111 111 default)], 'octal + default'],
    ['\\d', [qw(4)], 'EOT (Ctrl-D)'],
    ['fo\\d', [qw(102 111 4)], 'EOT (Ctrl-D)'],
    ['fo\\d\\b', [qw(102 111 4 127)], 'escape_seq'],
    ['\\adf\\n\\r\\w\\w\\f\\a\\effffff',
     [qw(7 100 102 10 13 119 119 12 7 27 102 102 102 102 102 102),
     ], ''],
);

foreach my $tuple (@tests) {
    is_deeply([Term::ReadLine::Perl5::readline::_unescape($tuple->[0])],  $tuple->[1],
	"_unescape($tuple->[0]) -- $tuple->[2]");
}

done_testing();
