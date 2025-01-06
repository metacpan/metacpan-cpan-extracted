# -*- perl -*-
use strict;
use warnings;
use Test::More tests => 2;

require String::ProperCase::Surname;

is(String::ProperCase::Surname::ProperCase("normal"), "Normal", "require");

*pc=\&String::ProperCase::Surname::ProperCase;

is(pc("normal"), "Normal", "require");
