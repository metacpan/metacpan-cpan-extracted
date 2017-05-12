use strict;
use warnings;

use Test::More 0.88;
use Test::Fatal;

use Test::Requires {
    'MooseX::StrictConstructor' => 0.16,
};

{
    package MySingleton;
    use Moose;
    use MooseX::Singleton;
    use MooseX::StrictConstructor;

    has 'attrib' => ( is => 'rw' );
}

like( exception {
    MySingleton->new( bad_name => 42 );
},
qr/Found unknown attribute/, 'singleton class also has a strict constructor');

done_testing;
