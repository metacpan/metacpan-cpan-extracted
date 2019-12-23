package App::Foo::interface;


use strict;
use warnings;

use OpenTracing::ReadableInterface;
# use App::Interface;
use App::Foo::types qw/:all/;

use Types::Standard qw/:all/;


around test_me => method_parameters ( Int $x, Int $y ) {
    
    returns( AppFooInterface,
         $original->( $invocant => ( $x, $y ) )
    )
};

1;


