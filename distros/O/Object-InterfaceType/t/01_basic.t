use strict;
use warnings;
use Test::More;

{
    package ClassBase;
    sub new {
        bless {}, $_[0];
    }
}
{
    package ClassA;
    our @ISA = 'ClassBase';
    sub as_string {}
}
{
    package ClassB;
    our @ISA = 'ClassBase';
    sub as_string {}
    sub dump {}
}
{
    package ClassC;
    sub dump {}
}

use Object::InterfaceType;

interface_type Object       => [];
interface_type Stringify    => ['as_string'];
interface_type ObjectDumper => ['new', 'dump'];

ok(is_Object(ClassA->new), 'ClassA is Object');
ok(is_Object(ClassB->new), 'ClassB is Object');
ok(is_Object(bless {}, 'ClassC'), 'ClassC is Object');

ok(is_Stringify(ClassA->new), 'ClassA is Stringify');
ok(is_Stringify(ClassB->new), 'ClassB is Stringify');
ok(!is_Stringify(bless {}, 'ClassC'), 'ClassC is not Stringify');

ok(!is_ObjectDumper(ClassA->new), 'ClassA is not ObjectDumper');
ok(is_ObjectDumper(ClassB->new), 'ClassB is ObjectDumper');
ok(!is_ObjectDumper(bless {}, 'ClassC'), 'ClassC is not ObjectDumper');

ok(!is_Object('ClassA'), 'class name is not object');
ok(!is_Object({}), 'hash ref is not object');


my $is_Object       = interface_type [];
my $is_Stringify    = interface_type ['as_string'];
my $is_ObjectDumper = interface_type ['new', 'dump'];

ok($is_Object->(ClassA->new), 'ClassA is Object');
ok($is_Object->(ClassB->new), 'ClassB is Object');
ok($is_Object->(bless {}, 'ClassC'), 'ClassC is Object');

ok($is_Stringify->(ClassA->new), 'ClassA is Stringify');
ok($is_Stringify->(ClassB->new), 'ClassB is Stringify');
ok(!$is_Stringify->(bless {}, 'ClassC'), 'ClassC is not Stringify');

ok(!$is_ObjectDumper->(ClassA->new), 'ClassA is not ObjectDumper');
ok($is_ObjectDumper->(ClassB->new), 'ClassB is ObjectDumper');
ok(!$is_ObjectDumper->(bless {}, 'ClassC'), 'ClassC is not ObjectDumper');

ok(!$is_Object->('ClassA'), 'class name is not object');
ok(!$is_Object->({}), 'hash ref is not object');

done_testing;
