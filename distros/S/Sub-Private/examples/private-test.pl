#!/usr/bin/env perl

use strict;
use feature qw(say);
use lib '.';
use Foo;

say "Can $_? ", (Foo->can($_) ? "Yes, " . Foo->$_() : "No") for qw(foo bar baz);
