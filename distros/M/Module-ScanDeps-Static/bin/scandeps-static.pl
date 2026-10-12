#!/usr/bin/env perl

use strict;
use warnings;

use Module::ScanDeps::Static;

exit __PACKAGE__->main();

sub main {
  print {*STDERR} "Deprecated...use scandeps-static\n";

  return Module::ScanDeps::Static->main;
}

1;
