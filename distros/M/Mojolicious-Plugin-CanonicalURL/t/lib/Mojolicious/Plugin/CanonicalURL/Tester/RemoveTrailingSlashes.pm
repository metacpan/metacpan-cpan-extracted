package Mojolicious::Plugin::CanonicalURL::Tester::RemoveTrailingSlashes;
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
    $t->app->plugin(CanonicalURL => {should_canonicalize_request => \q{remove_trailing_slashes($c->req->url->path) eq '/foo'}, %options});

    $t->get_ok('/foo/')->status_is(301)->header_is(Location => '/foo');
    $t->get_ok('/foo')->status_is(200)->content_is('foo');

    return $self;
}

1;
