#!/usr/bin/env perl
use Test2::V0;
use strictures 2;

{ package Test::ae; use Moo }

{
    package MyApp::ae;
    use Moo;
    with 'Object::Depot::Role';

    __PACKAGE__->init_depot(
        class => 'Test::ae',
        export_name => 'myapp_test',
        always_export => 1,
    );
}

MyApp::ae->import();

like(
    dies { myapp_test() },
    qr{No key was passed},
    'export requires key',
);

isa_ok(
    myapp_test('foo'),
    ['Test::ae'],
    'got export',
);

done_testing;
