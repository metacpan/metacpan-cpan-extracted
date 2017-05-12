#!perl -T
use strict;
use Test::More tests => 1;

use_ok( 'PerlIO::via::escape_ansi' );

diag( "Testing PerlIO::via::escape_ansi $PerlIO::via::escape_ansi::VERSION, Perl $], $^X" );
