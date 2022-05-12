#!/usr/bin/env perl

use strict;
use warnings;

our $VERSION = '0.1';

use Module::ScanDeps::Static;

__PACKAGE__->main();

sub main {

  Module::ScanDeps::Static->main;

  exit 0;
} ## end sub main

1;
