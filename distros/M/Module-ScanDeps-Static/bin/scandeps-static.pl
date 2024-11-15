#!/usr/bin/env perl

use strict;
use warnings;

our $VERSION = '1.005';

use Module::ScanDeps::Static;

__PACKAGE__->main();

sub main {
  return Module::ScanDeps::Static->main;
}

1;
