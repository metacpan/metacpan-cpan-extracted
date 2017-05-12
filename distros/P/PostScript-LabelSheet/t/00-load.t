#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'PostScript::LabelSheet' );
}

diag( "Testing PostScript::LabelSheet $PostScript::LabelSheet::VERSION, Perl $], $^X" );
