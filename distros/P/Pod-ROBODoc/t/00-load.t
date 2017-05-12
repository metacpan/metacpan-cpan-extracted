use strict;
use warnings;

use Test::More tests => 1;

BEGIN {
    use_ok( 'Pod::ROBODoc' ) || print "Bail out!
";
}

diag( "Testing Pod::ROBODoc $Pod::ROBODoc::VERSION, Perl $], $^X" );
