use strict;
use warnings;

use Params::Validate qw( validate SCALAR );

use Test::More;

{
    $@ = 'foo';
    v( bar => 42 );

    is(
        $@,
        'foo',
        'calling validate() does not clobber'
    );
}

done_testing();

sub v {
    validate( @_, { bar => { type => SCALAR } } );
}
