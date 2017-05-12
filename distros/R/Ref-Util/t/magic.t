use strict;
use warnings;
use Ref::Util qw<is_arrayref>;
use Test::More 'tests' => 1;

my ( $x, $y );

{
    package Foo;
    sub TIESCALAR { bless {}, shift }
    sub FETCH { $x }
}

tie $y, 'Foo';
$x = [];

ok( is_arrayref($y), 'Will not accept tied hashref as arrayref' );
