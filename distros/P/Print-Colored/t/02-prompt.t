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

local *ARGV;
open *ARGV, '<', \<<'...' or die $!;
input error
password error
input info
password info
input input
password input
input ok
password ok
input warn
password warn
...

for my $context (qw|error info input ok warn|) {
  no strict 'refs';    ## no critic
  my $text = 'abc';
  my ($fn, $input);
  my $colored_text = qq|$colors{$context}$text$off|;

  $fn = "${package}::prompt_$context";
  ok $input = &$fn($text), "prompt_$context";
  is $input, "input $context", "input for $context";

  $fn = "${package}::password_$context";
  ok $input = &$fn($text), "password_$context";
  is $input, "password $context", "password for $context";
}

done_testing();
