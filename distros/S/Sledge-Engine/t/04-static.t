#!perl

use Test::More tests => 5;
use lib "./t/lib";

local $ENV{SLEDGE_CONFIG_NAME} = '_common';

use MyApp;
use IO::Scalar;
{
    tie *STDOUT, 'IO::Scalar', \my $s;
    local $ENV{PATH_INFO} = '/foo/static.html';
    local $ENV{REQUEST_URI} = '/foo/static.html';
    local $ENV{HTTP_HOST} = 'localhost';
    MyApp->run;
    like $s, qr/this is a static template/;
    is_deeply({
        class => 'MyApp::Pages::Foo', 
        page => 'static',
    }, MyApp->ActionMap->{'/foo/static.html'});
    isa_ok(MyApp::Pages::Foo->can('dispatch_static'), 'CODE');
}

{
    tie *STDOUT, 'IO::Scalar', \my $s;
    local $ENV{PATH_INFO} = '/hoge.html';
    local $ENV{REQUEST_URI} = '/hoge.html';
    local $ENV{HTTP_HOST} = 'localhost';
    MyApp->run;
    like $s, qr/Hoge/;
    isa_ok(MyApp::Pages::Root->can('dispatch_hoge'), 'CODE');
}




