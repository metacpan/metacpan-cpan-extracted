#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;

use ok "Module::Compile::TT";

BEGIN { eval "require tt"; ok(!$@, "require tt") };



