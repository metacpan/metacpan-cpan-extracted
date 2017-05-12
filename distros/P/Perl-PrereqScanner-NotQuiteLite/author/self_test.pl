#!perl

use strict;
use warnings;
use author::Util;
use Perl::PrereqScanner::NotQuiteLite;

my $c = scan("lib/Perl/PrereqScanner/NotQuiteLite.pm");
for (qw/requires recommends suggests/) {
  next unless $c->{$_};
  say $_, dump($c->{$_}->as_string_hash);
}
