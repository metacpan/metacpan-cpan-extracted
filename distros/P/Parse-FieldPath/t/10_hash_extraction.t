use strict;
use warnings;

use Test::More tests => 7;
use Test::Deep;
use Test::MockObject;

use Parse::FieldPath qw/extract_fields/;

my $h = {
    a => 1,
    b => 2,
    c => {
        d => 3,
    },
    d => [ qw/ 1 2 3 / ],
};

cmp_deeply( extract_fields( $h, '' ), $h );
cmp_deeply( extract_fields( $h, '*' ), $h );
cmp_deeply( extract_fields( $h, 'a' ), { a => 1 } );
cmp_deeply( extract_fields( $h, 'a,b' ), { a => 1, b => 2 } );
cmp_deeply( extract_fields( $h, 'c/d' ), { c => { d => 3 } } );
cmp_deeply( extract_fields( $h, 'c/*' ), { c => { d => 3 } } );
cmp_deeply( extract_fields( $h, 'd' ), { d => $h->{d} } );
