#!/usr/bin/env perl

use strict;
use warnings;

require Module::ScanDeps::VERSION;

use Module::ScanDeps::Static;

__PACKAGE__->main();

sub main {
  return Module::ScanDeps::Static->main;
}

1;
