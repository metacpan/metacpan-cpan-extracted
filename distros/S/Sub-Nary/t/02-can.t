#!perl -T

use strict;
use warnings;

use Test::More tests => 3;

require Sub::Nary;

for (qw/new nary flush/) {
 ok(Sub::Nary->can($_), 'SN can ' . $_);
}
