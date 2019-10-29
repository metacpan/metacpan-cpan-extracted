package Mojolicious::Plugin::CanonicalURL::Tester::InlineCode;
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
        inline_code => q{
            return $next->() unless $c->req->url->path =~ /ba/;
            return $next->() if $c->req->url->path eq '/bar/';
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

    return $self;
}

1;
