## no critic (Modules::ProhibitMultiplePackages, Moose::RequireCleanNamespace, Moose::RequireMakeImmutable)
use strict;
use warnings;

use Test::More 0.88;
use Test::Needs 'Moo';
use Test::Fatal;
use Test::Moose qw( with_immutable );

{
    package Parent;
    use Moose;
    use MooseX::StrictConstructor;
}

{
    package Child;
    use Moo;
    extends 'Parent';
}

with_immutable {
    my $obj;
    is(
        exception { $obj = Child->new },
        undef,
        'no errors when instantiating a Moo child of a strict superclass',
    );

}
'Parent';

done_testing;
