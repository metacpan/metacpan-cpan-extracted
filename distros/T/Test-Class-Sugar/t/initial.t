use Test::Class::Sugar;

testclass Some::Class::Name {
    test simple_test {
        ok 1;
    }
}

testclass OldStyleTestMethods {
    sub test_this_still_works : Test {
        ok 1;
    }
}

testclass ChildClass extends Some::Class::Name {
    test extra_test {
        ok 2, 'Child class test';
    }
}

testclass Child2 extends Some::Class::Name, OldStyleTestMethods {
    test child_test {
        ok 3;
    }
}

testclass MultipleHelpers uses Test::More, Test::Exception {
    test multi_test >> 2 {
        ok 4;
        lives_ok { 5 };
    }
}

testclass ShortcutHelper uses -Exception {
    test exception_test {
        lives_ok { 1 }
    }
}

testclass TestClass exercises Test::Class::Sugar {
    test test_requirement {
        ok $test->subject->isa( 'UNIVERSAL' );
    }
}

BEGIN {
    package Foo;
    sub foo {'foo'}
}

testclass exercises Foo {
    test test_class_name {
        is ref($test) => 'Test::Foo';
    }

    test test_subject {
        is $test->subject => 'Foo';
    }
}

testclass WithInnerKeywords {
    test simpletest {
        is $test->current_method, 'test_simpletest';
    }

    test 'named with a string' {
        is $test->current_method, 'named_with_a_string';
    }

    test named with multiple symbols {
        is $test->current_method, 'test_named_with_multiple_symbols';
    }

    test with multiple assertions >> 3 {
        ok 1;
        ok 2;
        ok 3;
    }
}

testclass LifeCycle {
    my $log = '';

    startup       { $log .= 'startup ' }
    setup         { $log .= 'setup '}
    test one >> 0 { $log .= 'test ' }
    test two >> 0 { $log .= 'test ' }
    teardown      { $log .= 'teardown '}
    shutdown >> 1 {
        is $log, 'startup setup test teardown setup test teardown ',
    }
}

testclass LifeCycleWithNamedMethods {
    my $log = '';
    
    startup with name { $log .= 'startup ' }
    setup with name   { $log .= 'setup '}
    test one >> 0 { $log .= 'test ' }
    test two >> 0 { $log .= 'test ' }
    teardown with name { $log .= 'teardown '}
    shutdown with name >> 1 {
        is $log, 'startup setup test teardown setup test teardown ',
    }
}

testclass MultipleLifeCycleMethods {
    my $log = '';

    setup a { $log .= 'A' }
    setup b { $log .= 'B' }
    test expectations {
        is $log, 'AB';
    }
}

Test::Class->runtests;
