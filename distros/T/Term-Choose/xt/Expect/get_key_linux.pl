#!/usr/bin/env perl
use warnings;
use strict;
use 5.010000;
use Term::Choose::Linux;

my $linux = Term::Choose::Linux->new();

my $key = $linux->__get_key_OS( 0 );

say "<$key>";
