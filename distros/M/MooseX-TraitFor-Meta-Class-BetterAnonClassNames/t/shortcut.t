use strict;
use warnings;

use Test::More;
use Test::Moose::More;

{
    package TestClass;
    use Moose;
    use MooseX::TraitFor::Meta::Class::BetterAnonClassNames;
}

# Simple check to ensure our shortcut is exported

can_ok TestClass => 'BetterAnonClassNames';
is TestClass::BetterAnonClassNames() =>
    'MooseX::TraitFor::Meta::Class::BetterAnonClassNames',
    'BetterAnonClassNames() correct',
    ;

done_testing;
