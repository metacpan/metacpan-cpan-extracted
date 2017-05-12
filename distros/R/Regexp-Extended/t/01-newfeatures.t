#!/usr/bin/perl 

use Test;
use re 'eval';

BEGIN { plan tests => 11}

use Regexp::Extended qw(:all);

sub foo {
  my ($arg1, $arg2) = @_;

  if ($arg1 and $arg2) {
    return "$arg1$arg2";
  }

  return "foo";
}

$bu = "bur";

my $pat1 = qr/((?&foo("a", "b")))/;
my $pat2 = qr/((?*<i>|<b>))/;
my $pat3 = qr/(?*<i>|($bu)|<b>)/;
my $pat4 = qr/(?*<i>|$bu($bu(()$bu)))|(<b>)/;
my $pat5 = qr/this is(?<test>.*)/;
my $pat6 = qr/(?<test>$bu($bu(()$bu).*))|(<b>)/;
my $pat7 = qr/(?<day>\d{1,2})-(?<month>\d{1,2})-(?<year>\d{4})/;
my $pat8 = qr/(\d{1,2})-(\d{1,2})-(\d{4})/;

ok($pat1, '(?-xism:((??{foo("a", "b")})))');
ok($pat2, '(?-xism:((??{Regexp::Extended::upto(\'<i>|<b>\')})))');
ok($pat3, '(?-xism:(??{Regexp::Extended::upto(\'<i>|(bur)|<b>\')}))');
ok($pat4, '(?-xism:(??{Regexp::Extended::upto(\'<i>|bur(bur(()bur))\')})|(<b>))');
ok($pat5, '(?-xism:this is(?:(.*)(?{ local $n = $n + 1; $Regexp::Extended::MATCH_ARRAY[$n - 1] = new Regexp::Extended::Match("test", $^N, pos()) })))');
ok($pat6, '(?-xism:(?:(bur(bur(()bur).*))(?{ local $n = $n + 1; $Regexp::Extended::MATCH_ARRAY[$n - 1] = new Regexp::Extended::Match("test", $^N, pos()) }))|(<b>))');

if ('ab' =~ /$pat1/) {
  ok($1, 'ab');
}
else {
  ok(0);
}

if ('fdasf</b>dasfdasfda<i>' =~ /$pat2/) {
  ok($1, 'fdasf</b>dasfdasfda');
}
else {
  ok(0);
}

if ('this is some text' =~ /\A$pat5\Z/) {
  ok($1, ' some text');
}
else {
  ok(0);
}

my $str = "here is a date: 1-2-2004";

if ($str =~ s/\A^.*$pat7.*\Z/$day->[0]-$month->[0]-$year->[0]/g) {
  ok($str, '1-2-2004');
}

$str = "here is a date: 1-2-2004";

if ($str =~ s/\A^.*$pat7.*\Z/$day->[0]-$month->[0]-$year->[0]/g) {
  ok($str, '1-2-2004');
}

