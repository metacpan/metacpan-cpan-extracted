#!perl -T

use strict;
use warnings;

use Test::More tests => 5;

require Regexp::Wildcards;

for (qw<new do capture type convert>) {
 ok(Regexp::Wildcards->can($_), 'RW can ' . $_);
}

