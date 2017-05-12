#!perl -T
use strict;
use warnings;
use Test::More tests => 1;

use_ok( "POE::Devel::Top" );

diag( "Testing POE::Devel::Top $POE::Devel::Top::VERSION, Perl $], $^X" );
