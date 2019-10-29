package Mojolicious::Plugin::CanonicalURL::Tester::EndWithSlash;
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
    $t->app->plugin(CanonicalURL => { %options });

    # default is no trailing slash
    $t->get_ok('/foo/')->status_is(301)->header_is(Location => '/foo');
    $t->get_ok('/foo')->status_is(200)->content_is('foo');

    # / doesn't redirect
    $t->get_ok('/')->status_is(200)->content_is('index');


    # set end_with_slash to undef manually
    $t = Test::Mojo->new($app);
    $t->app->plugin(CanonicalURL => { end_with_slash => undef, %options });

    $t->get_ok('/foo/')->status_is(301)->header_is(Location => '/foo');
    $t->get_ok('/foo')->status_is(200)->content_is('foo');

    # / doesn't redirect
    $t->get_ok('/')->status_is(200)->content_is('index');


    # set end_with_slash to 0 manually
    $t = Test::Mojo->new($app);
    $t->app->plugin(CanonicalURL => { end_with_slash => 0, %options });

    $t->get_ok('/foo/')->status_is(301)->header_is(Location => '/foo');
    $t->get_ok('/foo')->status_is(200)->content_is('foo');

    # / doesn't redirect
    $t->get_ok('/')->status_is(200)->content_is('index');


    # end_with_slash true
    $t = Test::Mojo->new($app);
    $t->app->plugin(CanonicalURL => { end_with_slash => 1 , %options });

    $t->get_ok('/foo/')->status_is(200)->content_is('foo');
    $t->get_ok('/foo')->status_is(301)->header_is(Location => '/foo/');

    # / doesn't redirect
    $t->get_ok('/')->status_is(200)->content_is('index');

    return $self;
}

1;
