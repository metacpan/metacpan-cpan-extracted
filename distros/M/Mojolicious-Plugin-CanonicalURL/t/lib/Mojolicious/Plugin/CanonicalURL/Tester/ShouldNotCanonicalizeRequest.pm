package Mojolicious::Plugin::CanonicalURL::Tester::ShouldNotCanonicalizeRequest;
use Mojo::Base -base;
use Test::More;
use Test::Mojo;
use Mojo::File 'path';

use lib path(__FILE__)->dirname->to_string;

sub test {
    my $self = shift;
    my $app = shift;
    my %options = %{+shift};

    _test_scalar($app, %options);
    _test_regexp($app, %options);
    _test_code($app, %options);
    _test_scalar_reference($app, %options);
    _test_hash($app, %options);
    _test_array($app, %options);

    return $self;
}

sub _test_scalar {
    my ($app, %options) = @_;

    my $t = Test::Mojo->new($app);
    $t->app->plugin(CanonicalURL => { should_not_canonicalize_request => '/foo', %options });

    $t->get_ok('/foo')->status_is(200)->content_is('foo');
    $t->get_ok('/foo/')->status_is(200)->content_is('foo');

    $t->get_ok('/bar')->status_is(200)->content_is('bar');
    $t->get_ok('/bar/')->status_is(301)->header_is(Location => '/bar');

    $t->get_ok('/baz')->status_is(200)->content_is('baz');
    $t->get_ok('/baz/')->status_is(301)->header_is(Location => '/baz');

    # test trailing slashes also work
    $t = Test::Mojo->new($app);
    $t->app->plugin(CanonicalURL => { should_not_canonicalize_request => '/foo/', %options });

    $t->get_ok('/foo')->status_is(200)->content_is('foo');
    $t->get_ok('/foo/')->status_is(200)->content_is('foo');

    $t->get_ok('/bar')->status_is(200)->content_is('bar');
    $t->get_ok('/bar/')->status_is(301)->header_is(Location => '/bar');

    $t->get_ok('/baz')->status_is(200)->content_is('baz');
    $t->get_ok('/baz/')->status_is(301)->header_is(Location => '/baz');
}

sub _test_regexp {
    my ($app, %options) = @_;

    my $t = Test::Mojo->new($app);
    $t->app->plugin(CanonicalURL => { should_not_canonicalize_request => qr/foo/, %options });

    $t->get_ok('/foo')->status_is(200)->content_is('foo');
    $t->get_ok('/foo/')->status_is(200)->content_is('foo');

    $t->get_ok('/bar')->status_is(200)->content_is('bar');
    $t->get_ok('/bar/')->status_is(301)->header_is(Location => '/bar');

    $t->get_ok('/baz')->status_is(200)->content_is('baz');
    $t->get_ok('/baz/')->status_is(301)->header_is(Location => '/baz');
}

sub _test_code {
    my ($app, %options) = @_;

    # test that all requests should be canonicalized
    my $t = Test::Mojo->new($app);
    $t->app->plugin(CanonicalURL => { should_not_canonicalize_request => sub { undef }, %options });

    $t->get_ok('/foo')->status_is(200)->content_is('foo');
    $t->get_ok('/foo/')->status_is(301)->header_is(Location => '/foo');

    $t->get_ok('/bar')->status_is(200)->content_is('bar');
    $t->get_ok('/bar/')->status_is(301)->header_is(Location => '/bar');

    $t->get_ok('/baz')->status_is(200)->content_is('baz');
    $t->get_ok('/baz/')->status_is(301)->header_is(Location => '/baz');

    # test that all requests should not be canonicalized
    $t = Test::Mojo->new($app);
    $t->app->plugin(CanonicalURL => { should_not_canonicalize_request => sub { 1 }, %options });

    $t->get_ok('/foo')->status_is(200)->content_is('foo');
    $t->get_ok('/foo/')->status_is(200)->content_is('foo');

    $t->get_ok('/bar')->status_is(200)->content_is('bar');
    $t->get_ok('/bar/')->status_is(200)->content_is('bar');

    $t->get_ok('/baz')->status_is(200)->content_is('baz');
    $t->get_ok('/baz/')->status_is(200)->content_is('baz');

    # test that a specific path is not canonicalized
    $t = Test::Mojo->new($app);
    $t->app->plugin(CanonicalURL => { should_not_canonicalize_request => sub { $_->req->url->path eq '/foo/' }, %options });

    $t->get_ok('/foo')->status_is(200)->content_is('foo');
    $t->get_ok('/foo/')->status_is(200)->content_is('foo');

    $t->get_ok('/bar')->status_is(200)->content_is('bar');
    $t->get_ok('/bar/')->status_is(301)->header_is(Location => '/bar');

    $t->get_ok('/baz')->status_is(200)->content_is('baz');
    $t->get_ok('/baz/')->status_is(301)->header_is(Location => '/baz');
}

sub _test_scalar_reference {
    my ($app, %options) = @_;

    # test that a specific path is canonicalized and use explicit and return and ;
    my $t = Test::Mojo->new($app);
    $t->app->plugin(CanonicalURL => { should_not_canonicalize_request => \q{return $next->() if $c->req->url->path eq '/foo/';}, %options });

    $t->get_ok('/foo')->status_is(200)->content_is('foo');
    $t->get_ok('/foo/')->status_is(200)->content_is('foo');

    $t->get_ok('/bar')->status_is(200)->content_is('bar');
    $t->get_ok('/bar/')->status_is(301)->header_is(Location => '/bar');

    $t->get_ok('/baz')->status_is(200)->content_is('baz');
    $t->get_ok('/baz/')->status_is(301)->header_is(Location => '/baz');

    # implicit "return $next->() unless " and ";" are added
    $t = Test::Mojo->new($app);
    $t->app->plugin(CanonicalURL => { should_not_canonicalize_request => \q{$c->req->url->path eq '/foo/'}, %options });

    $t->get_ok('/foo')->status_is(200)->content_is('foo');
    $t->get_ok('/foo/')->status_is(200)->content_is('foo');

    $t->get_ok('/bar')->status_is(200)->content_is('bar');
    $t->get_ok('/bar/')->status_is(301)->header_is(Location => '/bar');

    $t->get_ok('/baz')->status_is(200)->content_is('baz');
    $t->get_ok('/baz/')->status_is(301)->header_is(Location => '/baz');
}

sub _test_hash {
    my ($app, %options) = @_;

    # test starts with /foo
    my $t = Test::Mojo->new($app);
    $t->app->plugin(CanonicalURL => { should_not_canonicalize_request => {starts_with => '/foo'}, %options });

    $t->get_ok('/foo')->status_is(200)->content_is('foo');
    $t->get_ok('/foo/')->status_is(200)->content_is('foo');

    $t->get_ok('/bar')->status_is(200)->content_is('bar');
    $t->get_ok('/bar/')->status_is(301)->header_is(Location => '/bar');

    $t->get_ok('/baz')->status_is(200)->content_is('baz');
    $t->get_ok('/baz/')->status_is(301)->header_is(Location => '/baz');

    # test starts with /bar
    $t = Test::Mojo->new($app);
    $t->app->plugin(CanonicalURL => { should_not_canonicalize_request => {starts_with => '/bar'}, %options });

    $t->get_ok('/foo')->status_is(200)->content_is('foo');
    $t->get_ok('/foo/')->status_is(301)->header_is(Location => '/foo');

    $t->get_ok('/bar')->status_is(200)->content_is('bar');
    $t->get_ok('/bar/')->status_is(200)->content_is('bar');

    $t->get_ok('/baz')->status_is(200)->content_is('baz');
    $t->get_ok('/baz/')->status_is(301)->header_is(Location => '/baz');

    # test starts with /b
    $t = Test::Mojo->new($app);
    $t->app->plugin(CanonicalURL => { should_not_canonicalize_request => {starts_with => '/b'}, %options });

    $t->get_ok('/foo')->status_is(200)->content_is('foo');
    $t->get_ok('/foo/')->status_is(301)->header_is(Location => '/foo');

    $t->get_ok('/bar')->status_is(200)->content_is('bar');
    $t->get_ok('/bar/')->status_is(200)->content_is('bar');

    $t->get_ok('/baz')->status_is(200)->content_is('baz');
    $t->get_ok('/baz/')->status_is(200)->content_is('baz');

    $t->get_ok('/qux')->status_is(200)->content_is('qux');
    $t->get_ok('/qux/')->status_is(301)->header_is(Location => '/qux');
}

sub _test_array {
    my ($app, %options) = @_;

    my $t = Test::Mojo->new($app);
    $t->app->plugin(CanonicalURL => {
        should_not_canonicalize_request => [
            '/foo',
            qr/baz/,
        ],
        %options,
    });

    $t->get_ok('/foo')->status_is(200)->content_is('foo');
    $t->get_ok('/foo/')->status_is(200)->content_is('foo');

    $t->get_ok('/bar')->status_is(200)->content_is('bar');
    $t->get_ok('/bar/')->status_is(301)->header_is(Location => '/bar');

    $t->get_ok('/baz')->status_is(200)->content_is('baz');
    $t->get_ok('/baz/')->status_is(200)->content_is('baz');

    $t->get_ok('/qux')->status_is(200)->content_is('qux');
    $t->get_ok('/qux/')->status_is(301)->header_is(Location => '/qux');

    # test sub and scalar reference
    $t = Test::Mojo->new($app);
    $t->app->plugin(CanonicalURL => {
        should_not_canonicalize_request => [
            sub { $_->req->url->path eq '/foo/' },
            \q{$c->req->url->path eq '/qux/'},
        ],
        %options,
    });

    $t->get_ok('/foo')->status_is(200)->content_is('foo');
    $t->get_ok('/foo/')->status_is(200)->content_is('foo');

    $t->get_ok('/bar')->status_is(200)->content_is('bar');
    $t->get_ok('/bar/')->status_is(301)->header_is(Location => '/bar');

    $t->get_ok('/baz')->status_is(200)->content_is('baz');
    $t->get_ok('/baz/')->status_is(301)->header_is(Location => '/baz');

    $t->get_ok('/qux')->status_is(200)->content_is('qux');
    $t->get_ok('/qux/')->status_is(200)->content_is('qux');


    $t = Test::Mojo->new($app);
    $t->app->plugin(CanonicalURL => {
        should_not_canonicalize_request => [
            '/foo',
            qr/baz/,
            {starts_with => '/qux'},
        ],
        %options,
    });

    $t->get_ok('/foo')->status_is(200)->content_is('foo');
    $t->get_ok('/foo/')->status_is(200)->content_is('foo');

    $t->get_ok('/bar')->status_is(200)->content_is('bar');
    $t->get_ok('/bar/')->status_is(301)->header_is(Location => '/bar');

    $t->get_ok('/baz')->status_is(200)->content_is('baz');
    $t->get_ok('/baz/')->status_is(200)->content_is('baz');

    $t->get_ok('/qux')->status_is(200)->content_is('qux');
    $t->get_ok('/qux/')->status_is(200)->content_is('qux');


    $t = Test::Mojo->new($app);
    $t->app->plugin(CanonicalURL => {
        should_not_canonicalize_request => [
            '/foo',
            qr/ba/,
            {starts_with => '/qux'},
        ],
        %options,
    });

    $t->get_ok('/foo')->status_is(200)->content_is('foo');
    $t->get_ok('/foo/')->status_is(200)->content_is('foo');

    $t->get_ok('/bar')->status_is(200)->content_is('bar');
    $t->get_ok('/bar/')->status_is(200)->content_is('bar');

    $t->get_ok('/baz')->status_is(200)->content_is('baz');
    $t->get_ok('/baz/')->status_is(200)->content_is('baz');

    $t->get_ok('/qux')->status_is(200)->content_is('qux');
    $t->get_ok('/qux/')->status_is(200)->content_is('qux');
}

1;
