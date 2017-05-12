#!perl

use Test::More tests => 3;
use lib "./t/lib";

BEGIN {
    use_ok( 'MyApp' );
}
is scalar @{MyApp->components}, 2;
is_deeply({
    '/' => {
        class => 'MyApp::Pages::Root',
        page => 'index',
    },
    '/foo/bar' => {
        class => 'MyApp::Pages::Foo',
        page => 'bar',
    },
}, MyApp->ActionMap);


