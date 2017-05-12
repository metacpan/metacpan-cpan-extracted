use strict;
use warnings;

use Test::Needs 'namespace::autoclean';

use Test::More 0.96;

{
    package Foo;
    use namespace::autoclean;
    use Specio::Library::Builtins;
}

ok( !Foo->can('t'), 't sub is cleaned by namespace::autoclean' );

done_testing();
