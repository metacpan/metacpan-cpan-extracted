#!perl -w

use strict;
use Test::More;

use MouseX::YAML qw(:all);

my $demolished = 0;
{
    package MyValue;
    use Mouse;

    has value => (
        init_arg => -value,
        is => 'rw',
    );

    sub BUILDARGS {
        my($self, $value) = @_;
        return { -value => $value };
    }

    package MyClass;
    use Mouse;

    has foo => (
        init_arg => 'bar',
        is       => 'rw',
    );

    has xyz => (
        is        => 'rw',
        predicate => 'has_xyz',

        lazy      => 1,
        default   => sub{ 99 },
    );

    has initialized_ok => (
        init_arg => undef,
        is       => 'rw',
    );

    sub BUILD {
        my($self) = @_;
        $self->initialized_ok(1);
    }

    sub DEMOLISH {
        $demolished++;
    }

    __PACKAGE__->meta->make_immutable();
}

my $obj = Load(<<'YAML');
--- !!perl/hash:MyClass
bar: 42
YAML

ok defined($obj), 'MouseX::YAML::Load';
isa_ok $obj, 'MyClass';
is $obj->foo, 42;
is $obj->initialized_ok, 1;
ok!$obj->has_xyz;
is $demolished, 0, 'no more DEMOLISH';

undef $obj;

is $demolished, 1;

$obj = Load(<<'YAML');
--- !!perl/hash:MyClass
bar: !!perl/hash:MyValue
  -value: 100
YAML

isa_ok $obj, 'MyClass';
isa_ok $obj->foo, 'MyValue';
is $obj->foo->value, 100;

$obj = LoadFile('t/yaml/myclass.yml');
isa_ok $obj, 'MyClass';
isa_ok $obj->foo, 'MyValue';
is $obj->foo->value, 200;

done_testing;
