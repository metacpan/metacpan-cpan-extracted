package main;

use 5.006001;

use strict;
use warnings;

use PPI::Document;
use Test::More 0.88;	# Because of done_testing();

note <<'EOD';

This test will start failing if PPI actually recognizes the variable
in a catch() as being a declaration. If it does, the special-case
code for this can go away. But I'm not holding my breath.

EOD

my $doc = PPI::Document->new( \<<'EOD' );
    try {
	foo();
    } catch ( $bar ) {
	baz( $bar );
    }
EOD

ok ! scalar @{ $doc->find( 'PPI::Statement::Variable' ) || [] },
'PPI does not parse catch( $foo ) as defining a variable';

done_testing;

1;

# ex: set textwidth=72 :
