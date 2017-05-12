#!perl -T

use strict;
use warnings;
use Sub::Called qw(already_called);
use Test::More tests => 2;

sub test {
    already_called();
}

ok( ! test() );
ok( test() );