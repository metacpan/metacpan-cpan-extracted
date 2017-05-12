use strict;
use warnings;

use Test::More tests => 1;

BEGIN { require_ok( 'Syntax::Feature::Loop' ); }

diag( "Testing Syntax::Feature::Loop $Syntax::Feature::Loop::VERSION" );
diag( "Using Perl $]" );

1;
