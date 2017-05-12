use strict;

use Test::More;
use RDF::Dumper;

eval { rdfdump( undef ); };
like( $@, qr{got undef}, 'got undef' );

eval { rdfdump( 'foo' ); };
like( $@, qr{got foo}, 'got scalar' );

eval { rdfdump( { } ); };
like( $@, qr{got HASH}, 'got ref' );

done_testing;
