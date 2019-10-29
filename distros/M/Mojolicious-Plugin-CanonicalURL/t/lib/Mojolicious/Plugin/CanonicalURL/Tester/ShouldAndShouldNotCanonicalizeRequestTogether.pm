package Mojolicious::Plugin::CanonicalURL::Tester::ShouldAndShouldNotCanonicalizeRequestTogether;
use Mojo::Base -base;
use Test::More;
use Test::Mojo;
use Mojo::File 'path';

use lib path(__FILE__)->dirname->to_string;

sub test {
    my $self = shift;
    my $app = shift;
    my %options = %{+shift};

    my $t = Test::Mojo->new($app);
    $t->app->plugin(CanonicalURL => {
        should_canonicalize_request => [
            qr/ba/,
            {starts_with => '/q'},
        ],
        should_not_canonicalize_request => qr/bar/,
        %options,
    });

    $t->get_ok('/foo')->status_is(200)->content_is('foo');
    $t->get_ok('/foo/')->status_is(200)->content_is('foo');

    $t->get_ok('/bar')->status_is(200)->content_is('bar');
    $t->get_ok('/bar/')->status_is(200)->content_is('bar');

    $t->get_ok('/baz')->status_is(200)->content_is('baz');
    $t->get_ok('/baz/')->status_is(301)->header_is(Location => '/baz');

    $t->get_ok('/qux')->status_is(200)->content_is('qux');
    $t->get_ok('/qux/')->status_is(301)->header_is(Location => '/qux');

    return $self;
}

1;
