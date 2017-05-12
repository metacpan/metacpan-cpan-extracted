use strict;
use warnings;
use Test::More 0.96;
use Test::Differences;
use Test::Requires 'Encode';
BEGIN { Encode->import(qw( encode decode is_utf8 )); }

my $mod = 'Parse::ANSIColor::Tiny';
eval "require $mod" or die $@;

my $p = new_ok($mod);

sub is_utf8_ok {
  my ($string, $exp, $desc) = @_;
  my $is = is_utf8($string);
  $is = !$is if !$exp;
  ok($is, $desc);
}

sub parse_ok {
  my ($input, $exp, $exp_utf8) = @_;
  my $type = ($exp_utf8 ? 'character' : 'byte') . ' string';

  is_utf8_ok($input, $exp_utf8, "input is $type");

  my $parsed = $p->parse($input);
  eq_or_diff
    $parsed,
    [
      [ ['green'], $exp ],
    ],
    "parse and return $type";

  is_utf8_ok($parsed->[0][1], $exp_utf8, "output is $type");
}

my $text = " \xc3\x97 ";
my $ansi = "\033[32m${text}\033[0m";

parse_ok $ansi, $text, 0;

parse_ok decode(utf8 => $ansi), decode(utf8 => $text), 1;

done_testing;
