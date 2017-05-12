use strict;
use warnings;
use Test::More;

use_ok( 'MojoX::AlmostJSON', 'encode_json' ) || print "Bail out!\n";

my $obj = [
        { a => 1 },
        {b => [10..12] },
        {c => 'test'},
        {f => \q[ function(t){ return t+42; } ]},
    ];
my $got = encode_json( $obj );

is $got, '[{"a":1},{"b":[10,11,12]},{"c":"test"},{"f": function(t){ return t+42; } }]',
    'serialize javascript function';

done_testing;