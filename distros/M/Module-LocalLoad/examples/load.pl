#!/usr/bin/perl
use strict;
use warnings;

use Module::LocalLoad;


# Some random core modules
my @mod = qw(
  Term::ANSIColor
  File::Compare
  Pod::Text::Termcap
  Memoize::Storable
  IO::Zlib
  Pod::InputObjects
  Module::Build::YAML
  Text::Wrap
  Pod::LaTeX
);

for my $m(@mod) {
  (my $file = $m) =~ s{::}{/}g;
  $file .= '.pm';
  load($m)and printf("%20s %9s loaded - %s\n", $m, $m->VERSION, $INC{$file});
}
