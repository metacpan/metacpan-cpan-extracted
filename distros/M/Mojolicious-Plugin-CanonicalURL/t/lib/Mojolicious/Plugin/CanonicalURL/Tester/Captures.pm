package Mojolicious::Plugin::CanonicalURL::Tester::Captures;
use Mojo::Base -base;
use Test::More;
use Test::Mojo;
use Mojo::File 'path';

use lib path(__FILE__)->dirname->to_string;

sub test {
    my $self = shift;
    my $app = shift;
    my %options = %{+shift};

    _test_should_canonicalize_request($app, %options);
    _test_should_not_canonicalize_request($app, %options);
    _test_should_canonicalize_request_array($app, %options);
    _test_should_not_canonicalize_request_array($app, %options);
    _test_inline_code($app, %options);

    return $self;
}

sub _test_should_canonicalize_request {
    my ($app, %options) = @_;

    my $t = Test::Mojo->new($app);
    my $foo = '/foo/';
    $t->app->plugin(CanonicalURL => {
        captures => { '$foo' => \$foo },
        should_canonicalize_request => \'$c->req->url->path eq $foo',
        %options,
    });

    $t->get_ok('/foo')->status_is(200)->content_is('foo');
    $t->get_ok('/foo/')->status_is(301)->header_is(Location => '/foo');

    $t->get_ok('/bar')->status_is(200)->content_is('bar');
    $t->get_ok('/bar/')->status_is(200)->content_is('bar');

    $t->get_ok('/baz')->status_is(200)->content_is('baz');
    $t->get_ok('/baz/')->status_is(200)->content_is('baz');

    $t->get_ok('/qux')->status_is(200)->content_is('qux');
    $t->get_ok('/qux/')->status_is(200)->content_is('qux');
}

sub _test_should_not_canonicalize_request {
    my ($app, %options) = @_;

    my $t = Test::Mojo->new($app);
    my $foo = '/foo/';
    $t->app->plugin(CanonicalURL => {
        captures => { '$foo' => \$foo },
        should_not_canonicalize_request => \'$c->req->url->path eq $foo',
        %options,
    });

    $t->get_ok('/foo')->status_is(200)->content_is('foo');
    $t->get_ok('/foo/')->status_is(200)->content_is('foo');

    $t->get_ok('/bar')->status_is(200)->content_is('bar');
    $t->get_ok('/bar/')->status_is(301)->header_is(Location => '/bar');

    $t->get_ok('/baz')->status_is(200)->content_is('baz');
    $t->get_ok('/baz/')->status_is(301)->header_is(Location => '/baz');

    $t->get_ok('/qux')->status_is(200)->content_is('qux');
    $t->get_ok('/qux/')->status_is(301)->header_is(Location => '/qux');
}

sub _test_should_canonicalize_request_array {
    my ($app, %options) = @_;

    my $t = Test::Mojo->new($app);
    my $foo = '/foo/';
    $t->app->plugin(CanonicalURL => {
        captures => { '$foo' => \$foo },
        should_canonicalize_request => [\'$c->req->url->path eq $foo'],
        %options,
    });

    $t->get_ok('/foo')->status_is(200)->content_is('foo');
    $t->get_ok('/foo/')->status_is(301)->header_is(Location => '/foo');

    $t->get_ok('/bar')->status_is(200)->content_is('bar');
    $t->get_ok('/bar/')->status_is(200)->content_is('bar');

    $t->get_ok('/baz')->status_is(200)->content_is('baz');
    $t->get_ok('/baz/')->status_is(200)->content_is('baz');

    $t->get_ok('/qux')->status_is(200)->content_is('qux');
    $t->get_ok('/qux/')->status_is(200)->content_is('qux');
}

sub _test_should_not_canonicalize_request_array {
    my ($app, %options) = @_;

    my $t = Test::Mojo->new($app);
    my $foo = '/foo/';
    $t->app->plugin(CanonicalURL => {
        captures => { '$foo' => \$foo },
        should_not_canonicalize_request => [\'$c->req->url->path eq $foo'],
        %options,
    });

    $t->get_ok('/foo')->status_is(200)->content_is('foo');
    $t->get_ok('/foo/')->status_is(200)->content_is('foo');

    $t->get_ok('/bar')->status_is(200)->content_is('bar');
    $t->get_ok('/bar/')->status_is(301)->header_is(Location => '/bar');

    $t->get_ok('/baz')->status_is(200)->content_is('baz');
    $t->get_ok('/baz/')->status_is(301)->header_is(Location => '/baz');

    $t->get_ok('/qux')->status_is(200)->content_is('qux');
    $t->get_ok('/qux/')->status_is(301)->header_is(Location => '/qux');
}

sub _test_inline_code {
    my ($app, %options) = @_;

    my $t = Test::Mojo->new($app);
    my $bar = '/bar/';
    my $ba_regex = qr/ba/;
    $t->app->plugin(CanonicalURL => {
        captures => { '$bar' => \$bar , '$ba_regex' => \$ba_regex },
        inline_code => q{
            return $next->() unless $c->req->url->path =~ $ba_regex;
            return $next->() if $c->req->url->path eq $bar;
        },
        %options,
    });

    $t->get_ok('/foo')->status_is(200)->content_is('foo');
    $t->get_ok('/foo/')->status_is(200)->content_is('foo');

    $t->get_ok('/bar')->status_is(200)->content_is('bar');
    $t->get_ok('/bar/')->status_is(200)->content_is('bar');

    $t->get_ok('/baz')->status_is(200)->content_is('baz');
    $t->get_ok('/baz/')->status_is(301)->header_is(Location => '/baz');

    $t->get_ok('/qux')->status_is(200)->content_is('qux');
    $t->get_ok('/qux/')->status_is(200)->content_is('qux');
}

1;
