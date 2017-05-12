package TAEB::Meta::Trait::GoodStatus;
use Moose::Role;

no Moose::Role;

package Moose::Meta::Attribute::Custom::Trait::TAEB::GoodStatus;
sub register_implementation { 'TAEB::Meta::Trait::GoodStatus' }

1;

