use strict;
use warnings;
use utf8;
use v5.24;

use FindBin;
use Test::More;
use Test::Output;

my $package;

BEGIN {
  $package = 'Print::Colored';
  use_ok $package or exit;
  use_ok 'Term::ANSIColor', 'coloralias';
}

note 'Define new colors';

ok coloralias('error', 'yellow'),       'New color for error';
ok coloralias('info',  'white'),        'New color for info';
ok coloralias('input', 'bright_white'), 'New color for input';
ok coloralias('ok',    'black'),        'New color for ok';
ok coloralias('warn',  'red'),          'New color for warn';

note 'Colors';

my $esc    = chr(27);
my %colors = (
  error => "${esc}[33m",
  info  => "${esc}[37m",
  input => "${esc}[97m",
  ok    => "${esc}[30m",
  warn  => "${esc}[31m",
);
my $off = "${esc}[0m";

for my $context (qw|error info input ok warn|) {
  no strict 'refs';    ## no critic
  my $text = 'abc';
  my $fn;
  my $colored_text = qq|$colors{$context}$text$off|;

  $fn = "${package}::color_$context";
  is &$fn($text), $colored_text, "color_$context";

  $fn = "${package}::print_$context";
  stdout_is { &$fn($text) } $colored_text, "print_$context";

  $fn = "${package}::say_$context";
  stdout_is { &$fn($text) } "$colored_text\n", "say_$context";
}

done_testing();
