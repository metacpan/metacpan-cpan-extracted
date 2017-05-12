#!/usr/bin/env perl -w
use strict;
use lib 'lib';
use File::Find;
use Test::More;

my @modules;

find(\&wanted, 'lib/PatchReader');
plan tests => (2 * scalar(@modules));

use_ok('PatchReader');

foreach my $module (sort @modules) {
  use_ok($module);
  next if $module eq 'PatchReader::CVSClient';

  my $opt = "";
  $opt = ':pserver:anonymous@localhost:/cvsroot'
    if $module eq 'PatchReader::FixPatchRoot';
  my $obj = new $module($opt);

  isa_ok($obj, $module, $module);
}

sub wanted {
  return if $_ !~ /\.pm$/;
  my $module = $File::Find::name;
  $module =~ s/^lib\/(.*)\.pm$/$1/;
  $module =~ s/\//::/g;
  push(@modules, $module);
}
