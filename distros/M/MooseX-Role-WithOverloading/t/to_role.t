use strict;
use warnings;

use Test::More 0.96;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use overload ();

use lib 't/lib';

BEGIN { use_ok('OtherClass') }

ok(OtherClass->meta->does_role('Role'));
ok(OtherClass->meta->does_role('OtherRole'));

ok(overload::Overloaded('Role'));
ok(overload::Overloaded('OtherRole'));
ok(overload::Overloaded('OtherClass'));
ok(overload::Method('Role', q{""}));
ok(overload::Method('OtherRole', q{""}));
ok(overload::Method('OtherClass', q{""}));

my $foo = OtherClass->new({ message => 'foo' });
isa_ok($foo, 'OtherClass');
is($foo->message, 'foo');

my $str = "${foo}";
is($str, 'foo');

# These tests failed on 5.18+ without some fixes to the MXRWO internals
{
    package MyRole1;
    use MooseX::Role::WithOverloading;
    use overload q{""} => '_stringify';
    sub _stringify { __PACKAGE__ };
}

{
    package MyRole2;
    use Moose::Role;
    with 'MyRole1';
}

{
    package Class1;
    use Moose;
    with 'MyRole2';
}

is(
    Class1->new . q{},
    'MyRole1',
    'stringification overloading is passed through all roles'
);

done_testing();
