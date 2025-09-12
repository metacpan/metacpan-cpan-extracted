#!/usr/bin/env perl
# Check modifier HTML

use warnings;
use strict;
use utf8;

use Test::More;

use String::Print;

my $g = String::Print->new;
isa_ok($g, 'String::Print');

is $g->sprinti("Hello &amp; greetz {name HTML}", name => "André"),
   'Hello &amp; greetz Andr&eacute;', 'html modifier';

done_testing;
