#!/usr/bin/perl

# Test cases from Open Formula Specification 1.2 p73
# OpenFormula-v1.2-draft7.odtOpenFormula-v1.2-draft7.odt
# Copyright (C) OASIS Open 2006. All Rights Reserved

use strict;
use warnings;
use lib ('lib', 't/lib');

use SheetTest;
use Test::More tests => 4;

run_tests(against => 't/data/openformula-testsuite.txt');

__DATA__

# Simple named expression 
set A101 formula FOUR 
test A101 4

# Named expression, marker saying so 
# set A102 formula $$FOUR 
TODO test A102 4

# Named expression, marker saying so 
# set A103 formula $$'FOUR' 
TODO test A103 4

# International characters are permitted in names, not just ASCII or Latin-1 
# set A104 formula ¿¿ 
TODO test A104 4

