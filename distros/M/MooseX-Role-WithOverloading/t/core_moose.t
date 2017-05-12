use strict;
use warnings;

use Test::More;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

plan skip_all => 'Moose 2.1300 required for these tests'
    unless eval "require Moose; Moose->VERSION('2.1300'); 1";

use lib 't/lib';

use_ok('SomeClass');

ok(SomeClass->meta->does_role('Role'), 'class does the role');
ok(overload::Method('Role', q{""}), 'the overload is on the role');
ok(overload::Method('SomeClass', q{""}), 'the overload is on the class');

ok(
    !Role->meta->meta->isa('Moose::Meta::Class'),
    "the role's metaclass has not been upgraded from a Class::MOP::Class::Immutable::Class::MOP::Class to a full Moose metaclass",
);

done_testing;
