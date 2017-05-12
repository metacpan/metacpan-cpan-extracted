BEGIN {
    package Foo;
    sub foo {'foo'};
}


use Test::Class::Sugar defaults => {prefix => 'MySuite'};

testclass exercises Foo {
    test classname {
        isa_ok $test, 'MySuite::Foo';
    }
}

Test::Class->runtests unless caller();
