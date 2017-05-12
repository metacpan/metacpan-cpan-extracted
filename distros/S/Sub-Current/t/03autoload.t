#!perl

use strict;
use warnings;
use Test::More tests => 3;
use Sub::Current;

sub AUTOLOAD {
    is(ROUTINE(), \&AUTOLOAD, "AUTOLOAD $::AUTOLOAD");
}
sarah_jane();
leela();
sarah_jane(); # again
