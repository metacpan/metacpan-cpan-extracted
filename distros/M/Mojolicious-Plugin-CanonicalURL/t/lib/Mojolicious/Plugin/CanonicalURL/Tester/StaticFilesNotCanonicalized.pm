package Mojolicious::Plugin::CanonicalURL::Tester::StaticFilesNotCanonicalized;
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
    $t->app->plugin(CanonicalURL => {end_with_slash => 1, %options});

    # make sure that a slash is required
    $t->get_ok('/foo/')->status_is(200)->content_is('foo');
    $t->get_ok('/foo')->status_is(301)->header_is(Location => '/foo/');

    $t->get_ok('/static.txt')->status_is(200)->content_is("hi\n");

    return $self;
}

1;
