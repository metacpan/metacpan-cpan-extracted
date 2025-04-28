use 5.16.0;
use strict;
use warnings;
use Test::More tests => 1;


BEGIN {
    use_ok('Term::Choose::LineFold::XS') or BAIL_OUT("Can't load Term::Choose::LineFold::XS");;
}

diag( "Testing Term::Choose::LineFold::XS $Term::Choose::LineFold::XS::VERSION, Perl $], $^X" );
