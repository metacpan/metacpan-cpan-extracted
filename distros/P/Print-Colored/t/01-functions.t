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
}

note 'Functions and exports';

for my $context (qw|error info input ok warn|) {
  for my $command (qw|color password print prompt say|) {
    my $fn = "${command}_$context";
    my $tag = $command =~ s/password/prompt/r;
    can_ok $package, $fn;
    ok grep(/$fn/, @Print::Colored::EXPORT_OK), "$fn is exported";
    ok grep(/$fn/, $Print::Colored::EXPORT_TAGS{all}->@*), "$fn is exported in :all";
    ok grep(/$fn/, $Print::Colored::EXPORT_TAGS{$tag}->@*), "$fn is exported in :$tag";
  }
}

note 'Colors';

my $esc    = chr(27);
my %colors = (
  error => "${esc}[91m",
  info  => "${esc}[94m",
  input => "${esc}[96m",
  ok    => "${esc}[92m",
  warn  => "${esc}[95m",
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
