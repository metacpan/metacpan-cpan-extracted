#!/usr/bin/perl

use Test::More tests => 17;

use Perl6::Classes;

class Test1 { }
like(ref Test1->new, qr/^Test1/, "Empty class");


class Test2 {
    method test { "ok" }
}

my $test2 = new Test2;
like(ref $test2, qr/^Test2/, "Simple method parse");
is($test2->test, 'ok', "Simple method");


my $flag;
class Test4 {
    submethod BUILD { $flag++ }
}

my $test4 = new Test4;
like(ref $test4, qr/^Test4/, "Constructor parse");
is($flag, 1, "Constructor");


class Test6 {
    submethod BUILD { $.test = shift; $flag++ }
    method test { $.test }
    has $.test;
}

my $test6 = Test6->new(42);
ok($flag == 2, "Constructor w/ args");
is($test6->test, 42, "Attribute");


class Base {
    method test { "ok" }
}

class Derived is Base { }

my $test8 = Derived->new;
is($test8->test, 'ok', "Simple inheritance");
ok($test8->isa(Base), "isa()");

my $test10 = Base->new;
ok(!$test10->isa(Derived), "isa()");


class Base2 {
    method test { "o" . $self->retk }
    method retk { "h no" }
}

class Derived2 is Base2 {
    method retk { "k" }
}

my $test11 = new Derived2;
is($test11->test, "ok", "Template method");
my $test12 = new Base2;
is($test12->test, "oh no", "Template method");


class Base3 {
    method setb { $.attr = shift; }
    method getb { $.attr }
    has $.attr;
}

class Derived3 is Base3 {
    method setd { $.attr = shift; }
    method getd { $.attr }
    has $.attr;
}

my $test13 = Derived3->new;
$test13->setb(10);
$test13->setd(20);
is($test13->getb, 10, "Inheritance & Attributes");
is($test13->getd, 20, "Inheritance & Attributes");


sub makereturner {
    my $val = shift;
    class {
        method test { $val }
    }
}

my $test15a = makereturner(30);
my $test15b = makereturner(40);
my $test15 = new $test15b;
is($test15->test, 40, "Anonymous class");

my $test16 = new $test15a;
is($test16->test, 30, "Anonymous class");


sub makeconcat {
    my $left = shift;
    class {
        method makereturn {
            my $right = shift;
            class {
                method test {
                    "$left$right"
                }
            }
        }
    }
}

my $test17a = makeconcat("Hello, ");
my $test17b = new $test17a;
my $test17c = $test17b->makereturn("World!");
my $test17d = $test17c->new;

is($test17d->test, "Hello, World!", "Nested anonymous class");
