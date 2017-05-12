#!/usr/bin/perl

use feature qw(say);
use Foo;

say "Can $_? ", (Foo->can($_) ? "Yes, " . Foo->$_() : "No") for qw(foo bar baz);
