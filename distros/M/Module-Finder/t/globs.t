#!/usr/bin/perl

use warnings;
use strict;

use Test::More 'no_plan';

BEGIN {
  use_ok('Module::Finder');
}

my @checks = (
 [qw(/      )],
 [qw(+      *)],
 [qw(-/+    */*)],
 [qw(-/-/+  */*/*)],
 [qw(-/+/+  */* */*/*)],
 [qw(+/+/+  * */* */*/*)],
 # and with implicit +
 [qw(-/     */*)],
 [qw(-/-/   */*/*)],
 [qw(-/+/   */* */*/*)],
 [qw(+/+/   * */* */*/*)],
);
foreach my $check (@checks) {
  my ($glob, @want) = @$check;
  my @ans = Module::Finder->_glob_parse($glob);
  is(scalar(@ans), scalar(@want), "count for '$glob'");
  $_ .= '.pm' for(@want);
  is_deeply(\@ans, \@want, "expect for '$glob'");
}
# vi:ts=2:sw=2:et:sta
