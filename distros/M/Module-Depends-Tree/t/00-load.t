#!perl -T

use warnings;
use strict;
use Test::More tests => 1;

BEGIN {
    use_ok( 'Module::Depends::Tree' );
}

diag( "Testing Module::Depends::Tree $Module::Depends::Tree::VERSION, Perl $], $^X" );
