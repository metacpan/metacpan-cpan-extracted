BEGIN {
    $ENV{PERL_STRICT} = 1;
}

use Test::Most;

use lib 't/lib';
use TestClass;

lives_ok {
    TestClass->new( a => 1 );
} 'isa';

dies_ok {
    TestClass->new( a => -1 );
} 'should';

lives_ok {
    TestClass->new( b => 1 );
} 'isa';

dies_ok {
    TestClass->new( b => 'x' );
} 'should';

done_testing;
