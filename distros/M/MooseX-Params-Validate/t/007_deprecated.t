## no critic (Moose::RequireCleanNamespace, Modules::ProhibitMultiplePackages, Moose::RequireMakeImmutable)
use strict;
use warnings;

use Test::More;

{
    package Foo;

    use Moose;
    use MooseX::Params::Validate qw( :deprecated );
}

ok( Foo->can('validate'),  ':deprecated tag exports validate' );
ok( Foo->can('validatep'), ':deprecated tag exports validatep' );

done_testing();
