#!perl -T

use strict;
use warnings;
use Sub::Called qw(not_called);
use Test::More tests => 2;

sub test {
    not_called();
}

ok( test() );
ok( ! test() );