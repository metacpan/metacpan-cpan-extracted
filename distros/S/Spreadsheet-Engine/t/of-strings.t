#!/usr/bin/perl

# Test cases from Open Formula Specification 1.2 p61
# OpenFormula-v1.2-draft7.odtOpenFormula-v1.2-draft7.odt
# Copyright (C) OASIS Open 2006. All Rights Reserved

use strict;
use warnings;
use lib ('lib', 't/lib');

use SheetTest;
use Test::More tests => 3;

run_tests();

__DATA__
# Simple string.
set A100 formula LEN("Hi")
test A100 2

# Repeat double-quote to embed a double-quote character.
set A101 formula LEN("Hi""t")
test A101 4

# C-format strings have no effect inside character strings. This is two
# characters, "\" and "n".
set A102 formula LEN("\n")
test A102 2

