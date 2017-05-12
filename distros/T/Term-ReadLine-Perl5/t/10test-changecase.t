#!/usr/bin/env perl
use strict; use warnings;
use lib '../lib' ;

use Test::More;

BEGIN {
  use_ok( 'Term::ReadLine::Perl5' );
  use_ok( 'Term::ReadLine::Perl5::readline' );
}

$ENV{'COLUMNS'} = '80';
$ENV{'LINES'}    = '25';
# stop reading ~/.inputrc
$ENV{'INPUTRC'} = '/dev/null';

$Term::ReadLine::Perl5::readline::_rl_japanese_mb = 0;
$Term::ReadLine::Perl5::readline::line = 'xyz123 XYZ 012z MiXedCase ABCt !@#$%{}';
$Term::ReadLine::Perl5::readline::D    = 0;
note("F_Upcase");
Term::ReadLine::Perl5::readline::F_UpcaseWord(1);
is($Term::ReadLine::Perl5::readline::line, 'XYZ123 XYZ 012z MiXedCase ABCt !@#$%{}');
Term::ReadLine::Perl5::readline::F_UpcaseWord(2);
is($Term::ReadLine::Perl5::readline::line, 'XYZ123 XYZ 012Z MiXedCase ABCt !@#$%{}');

note("F_Downcase");
$Term::ReadLine::Perl5::readline::D    = 0;
Term::ReadLine::Perl5::readline::F_DownCaseWord(1);
is($Term::ReadLine::Perl5::readline::line, 'xyz123 XYZ 012Z MiXedCase ABCt !@#$%{}');
Term::ReadLine::Perl5::readline::F_DownCaseWord(2);
is($Term::ReadLine::Perl5::readline::line, 'xyz123 xyz 012z MiXedCase ABCt !@#$%{}');

note("F_CapitalizeWord");
$Term::ReadLine::Perl5::readline::D    = 0;
Term::ReadLine::Perl5::readline::F_CapitalizeWord(1);
is($Term::ReadLine::Perl5::readline::line, 'Xyz123 xyz 012z MiXedCase ABCt !@#$%{}');
Term::ReadLine::Perl5::readline::F_CapitalizeWord(2);
is($Term::ReadLine::Perl5::readline::line, 'Xyz123 Xyz 012Z MiXedCase ABCt !@#$%{}');

done_testing();
