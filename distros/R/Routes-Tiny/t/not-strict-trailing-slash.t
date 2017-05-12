use strict;
use warnings;

use Test::More;

use Routes::Tiny;

subtest 'match simple route with trailing slash' => sub {
    my $r = Routes::Tiny->new(strict_trailing_slash => 0);
    $r->add_route('/admin/', name => 'route');

    ok $r->match('/admin');
    ok $r->match('/admin/');
};

subtest 'match simple route without trailing slash' => sub {
    my $r = Routes::Tiny->new(strict_trailing_slash => 0);
    $r->add_route('/admin', name => 'route');

    ok $r->match('/admin');
    ok $r->match('/admin/');
};

subtest 'match optional route' => sub {
    my $r = Routes::Tiny->new(strict_trailing_slash => 0);
    $r->add_route('/admin/(:foo)?', name => 'route');

    ok $r->match('/admin');
    ok $r->match('/admin/');
    ok $r->match('/admin/foo');
    ok $r->match('/admin/foo/');

    ok!$r->match('/admin//');
};

subtest 'match route with captures' => sub {
    my $r = Routes::Tiny->new(strict_trailing_slash => 0);
    $r->add_route('/admin/:foo', name => 'route');

    ok $r->match('/admin/foo');
    ok $r->match('/admin/foo/');
};

subtest 'build path as it was specified originally with slash' => sub {
    my $r = Routes::Tiny->new(strict_trailing_slash => 0);
    $r->add_route('/admin/', name => 'route');

    is $r->build_path('route'), '/admin/';
};

subtest 'build path as it was specified originally without slash' => sub {
    my $r = Routes::Tiny->new(strict_trailing_slash => 0);
    $r->add_route('/admin', name => 'route');

    is $r->build_path('route'), '/admin';
};

done_testing;
