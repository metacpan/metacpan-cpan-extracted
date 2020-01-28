#!/usr/bin/env perl
use Test2::V0;
use strictures 2;

package Test::en;
    use Moo;

package MyApp::en;
    use Moo;
    with 'Object::Depot::Role';

    __PACKAGE__->init_depot(
        class => 'Test::en',
        export_name => 'myapp_test',
    );

package main;

MyApp::en->import();

like(
    dies { myapp_test() },
    qr{Undefined subroutine},
    'does not export by default',
);

MyApp::en->import('myapp_test');

like(
    dies { myapp_test() },
    qr{No key was passed},
    'export requires key',
);

isa_ok(
    myapp_test('foo'),
    ['Test::en'],
    'got export',
);

package Test::en2;
    use Moo;

package MyApp::en2;
    use Moo;
    with 'Object::Depot::Role';

    __PACKAGE__->init_depot(
        class => 'Test::en2',
        export_name => 'myapp_test2',
    );

    our $CALLED = 0;

    sub myapp_test2 {
        $CALLED++;
        __PACKAGE__->depot->fetch( @_ );
    }

package main;

MyApp::en2->import('myapp_test2');

myapp_test2('foo');
myapp_test2('foo');

is(
    $MyApp::en2::CALLED,
    2,
    'custom export sub was used',
);

done_testing;
