#!/usr/bin/env perl
use Test2::V0;
use strictures 2;

{ package Test::en; use Moo }

{
    package MyApp::en;
    use Moo;
    with 'Object::Depot::Singleton';

    __PACKAGE__->init(
        class => 'Test::en',
        export_name => 'myapp_test',
    );
}

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

done_testing;
