use strict;
use warnings;

use Test::More tests => 1;
use Moose::Util qw/ with_traits /;

{ 
    package Bar;

    use Moose::Role;

    use Template::Caribou;

    template bar => sub { 'bar' };
}
{ 
    
    package Foo;

    use Template::Caribou;

    with 'Bar';

    template foo => sub { print 'x'; $_[0]->bar };

}

is( Foo->new->foo => 'xbar', 'template inherited' );



