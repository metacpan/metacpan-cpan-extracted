#!/usr/bin/env perl
use strict; use warnings;
use lib '../lib' ;

use Test::More;

BEGIN {
  # stop reading ~/.inputrc
    $ENV{LANG} = 'C';
    $ENV{'INPUTRC'} = '/dev/null';
    $ENV{'COLUMNS'} = '80';
    $ENV{'LINES'}    = '25';
    use_ok( 'Term::ReadLine::Perl5' );
    use_ok( 'Term::ReadLine::Perl5::readline' );
}

note("CharSize()");
$Term::ReadLine::Perl5::readline::_rl_japanese_mb = 1;
$Term::ReadLine::Perl5::readline::line = '"ABCt !@#$%{}';
for (my $i=0; $i<length($Term::ReadLine::Perl5::readline::line); $i++)
{
    is(Term::ReadLine::Perl5::readline::CharSize($i), 1,
       "should be single character at position $i: " .
       substr($Term::ReadLine::Perl5::readline::line, $i, 1));
}

my $double_chars = '';
for (my $i=0; $i<4; $i++) {
    $double_chars .= chr(0x81 + $i)
}
$Term::ReadLine::Perl5::readline::line = $double_chars;

for (my $i=0; $i<length($Term::ReadLine::Perl5::readline::line); $i += 2)
{
    is(Term::ReadLine::Perl5::readline::CharSize($i), 2,
       "double character at position $i: " .
       substr($Term::ReadLine::Perl5::readline::line, $i, 2));
}

note("end_of_line() only");
$Term::ReadLine::Perl5::readline::line = 'Moving along this line';
$Term::ReadLine::Perl5::readline::D    = 0;
ok(!Term::ReadLine::Perl5::readline::at_end_of_line(),
   "position $Term::ReadLine::Perl5::readline::D is not at the end of line '$Term::ReadLine::Perl5::readline::line'");

$Term::ReadLine::Perl5::readline::D = length($Term::ReadLine::Perl5::readline::line);
ok(Term::ReadLine::Perl5::readline::at_end_of_line(),
   "position $Term::ReadLine::Perl5::readline::D is at the end of line '$Term::ReadLine::Perl5::readline::line'");

note("F_ForwardChar only");
$Term::ReadLine::Perl5::readline::D = 0;
Term::ReadLine::Perl5::readline::F_ForwardChar(1);
is($Term::ReadLine::Perl5::readline::D, 1, "Moving a single character from position 0");
Term::ReadLine::Perl5::readline::F_ForwardChar(3);
is($Term::ReadLine::Perl5::readline::D, 4, "Moving a 3 characters from position 1");
Term::ReadLine::Perl5::readline::F_ForwardChar(100);
is($Term::ReadLine::Perl5::readline::D, length($Term::ReadLine::Perl5::readline::line),
   "Moving past the end of the line");

$Term::ReadLine::Perl5::readline::line = 'a' . $double_chars . 'b';
$Term::ReadLine::Perl5::readline::D = 0;
Term::ReadLine::Perl5::readline::F_ForwardChar(1);
is($Term::ReadLine::Perl5::readline::D, 1, "Moving again a single character from position 0");
Term::ReadLine::Perl5::readline::F_ForwardChar(1);
is($Term::ReadLine::Perl5::readline::D, 3, "Moving one double from position 1");
Term::ReadLine::Perl5::readline::F_ForwardChar(1);
is($Term::ReadLine::Perl5::readline::D, 5, "Moving another double from position 1");
Term::ReadLine::Perl5::readline::F_ForwardChar(1);
is($Term::ReadLine::Perl5::readline::D, 6, "Moving a single after a double from position 5");

note("F_BackwardChar only");
Term::ReadLine::Perl5::readline::F_BackwardChar(1);
is($Term::ReadLine::Perl5::readline::D, 5, "Moving back single from 6");
Term::ReadLine::Perl5::readline::F_BackwardChar(2);
is($Term::ReadLine::Perl5::readline::D, 1, "Moving back two doubles from position 5");
Term::ReadLine::Perl5::readline::F_BackwardChar(2);
is($Term::ReadLine::Perl5::readline::D, 0, "Moving back beyond beginning");

note("F_ForwardWord only");
$Term::ReadLine::Perl5::readline::line = 'Moving along this line ' . $double_chars . ' again.';
$Term::ReadLine::Perl5::readline::D    = 0;

note("F_ForwardChar only");
Term::ReadLine::Perl5::readline::F_ForwardWord(1);
is($Term::ReadLine::Perl5::readline::D, 6, "Moving forward word from 0");
Term::ReadLine::Perl5::readline::F_ForwardWord(2);
is($Term::ReadLine::Perl5::readline::D, 17, "Moving forward to 3rd word");
Term::ReadLine::Perl5::readline::F_ForwardWord(2);
is($Term::ReadLine::Perl5::readline::D, 27, "Moving forward to 3rd word");

note("F_BackwardWord only");
Term::ReadLine::Perl5::readline::F_BackwardWord(2);
is($Term::ReadLine::Perl5::readline::D, 18,
   "Moving back over two words, one doublechar");
Term::ReadLine::Perl5::readline::F_BackwardWord(10);
is($Term::ReadLine::Perl5::readline::D, 0,
   "Moving back past the beginning");

note("Mixed Forward/Back test");
Term::ReadLine::Perl5::readline::F_BackwardWord(-1);
is($Term::ReadLine::Perl5::readline::D, 6, "back word -1");
Term::ReadLine::Perl5::readline::F_ForwardWord(-1);
is($Term::ReadLine::Perl5::readline::D, 0, "back word -1");
Term::ReadLine::Perl5::readline::F_BackwardChar(-2);
is($Term::ReadLine::Perl5::readline::D, 2, "back char -2");
Term::ReadLine::Perl5::readline::F_ForwardChar(-1);
is($Term::ReadLine::Perl5::readline::D, 1, "forward char -1");

done_testing();
