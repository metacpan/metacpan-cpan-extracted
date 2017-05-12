#!/usr/bin/perl -w
use strict;
my ($nt, $nt1,);

BEGIN { $nt = 6; 
$nt1 = 8;
}
use Test::More tests=> $nt+$nt1;

# test grammar.dot graphic description of .output files
SKIP: {
  skip "t/AmbiguousCalc.eyp not found", $nt unless ($ENV{DEVELOPER} 
                                                        && -r "t/AmbiguousCalc.eyp" 
                                                        && -r "t/AmbiguousCalc.wexpected" 
                                                        && -r "t/AmbiguousCalc.Wexpected" 
                                                        && -x "./eyapp");
  { # test -w
    unlink 't/AmbiguousCalc.pm';
    unlink 't/AmbiguousCalc.output';
    unlink 't/AmbiguousCalc.dot';
    unlink 't/AmbiguousCalc.png';

    my $r = qx{perl -I./lib/ eyapp -w t/AmbiguousCalc.eyp 2>&1};
    like($r, qr{35 shift.reduce conflicts}, "compilation with -w of ambiguous Calc grammar");

    ok(-s "t/AmbiguousCalc.dot", "AmbiguousCalc.dot generated");

    $r = qx{diff t/AmbiguousCalc.dot t/AmbiguousCalc.wexpected};

    is($r, '', '.dot file as expected with w');

    unlink 't/AmbiguousCalc.pm';
    unlink 't/AmbiguousCalc.output';
    unlink 't/AmbiguousCalc.dot';
    unlink 't/AmbiguousCalc.png';
  }

  { # test -W

    my $r = qx{perl -I./lib/ eyapp -W t/AmbiguousCalc.eyp 2>&1};
    like($r, qr{35 shift.reduce conflicts}, "compilation with -w of ambiguous Calc grammar");

    ok(-s "t/AmbiguousCalc.dot", "AmbiguousCalc.dot generated");

    $r = qx{diff t/AmbiguousCalc.dot t/AmbiguousCalc.WWexpected};

    is($r, '', '.dot file as expected with W');

    unlink 't/AmbiguousCalc.pm';
    unlink 't/AmbiguousCalc.output';
    unlink 't/AmbiguousCalc.dot';
    unlink 't/AmbiguousCalc.png';
  }
}

# test grammar.dot graphic description of AST .dot files
SKIP: {
  skip "t/Precedencia.eyp not found", $nt1 unless ($ENV{DEVELOPER} 
                                                        && -r "t/Precedencia.eyp" 
                                                        && -x "./eyapp");
  { # test -w
    unlink 't/Precedencia.pm';
    unlink 'tree.png';
    unlink 'tree.dot';
    unlink 't.gif';

    my $r = qx{perl -I./lib/ eyapp -C t/Precedencia.eyp 2>&1};
    is($r, '', "compilation with -C of Precedencia.eyp grammar");

    $r = qx{perl -Ilib/ t/Precedencia.pm -dot t.gif -i -t -c '1\@2\@3'};

    my $expected = q{
    AT(AT(NUM[1],NUM[2]),NUM[3])
    AT(AT(NUM[1],NUM[2]),NUM[3])
    };

    $expected =~ s/\s+//g;
    $expected = quotemeta($expected);
    $expected = qr{$expected};

    $r =~ s/\s+//g;

    like($r, $expected, 'tree->str for 1@2@3');

    ok(-r 'tree.png', 'tree.png generated');

    ok(-r 't.gif', 't.gif generated');

    ok(-r 'tree.dot', 'tree.dot generated');
   
    ok(-r 't.dot', 't.dot generated');

    $r = qx{diff tree.dot t/tree.dot.expected 2>&1};

    is($r, '', 'tree.dot as expected');

    $r = qx{diff t.dot t/tree.dot.expected 2>&1};

    is($r, '', 't.dot as expected');

    unlink 'tree.png';
    unlink 't.gif';
    unlink 't.dot';
    unlink 'tree.dot';
    unlink 't/Precedencia.pm';
  }

}

