#!/usr/bin/env perl -w
use strict;
use warnings;
## no critic (Variables::RequireLocalizedPunctuationVars)
BEGIN { $^O = 'SomeFakeValue' }
use Test::Sys::Info;

driver_ok('Unknown');
