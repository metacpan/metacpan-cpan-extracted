#!/usr/bin/perl -w
use strict;
use Pipeline;
use Pipeline::Segment;
use Pipeline::Production;
use Pipeline::Store::Simple;
use Pipeline::Store::ISA;

# A very simple test

use Test::Simple tests => 1;

ok(1, "loaded okay");
