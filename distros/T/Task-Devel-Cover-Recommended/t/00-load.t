#!perl -T

use strict;
use warnings;

use Test::More tests => 1;

BEGIN {
 use_ok( 'Task::Devel::Cover::Recommended' );
}

diag( "Testing Task::Devel::Cover::Recommended $Task::Devel::Cover::Recommended::VERSION, Perl $], $^X" );
