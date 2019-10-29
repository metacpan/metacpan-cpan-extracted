package Mojolicious::Plugin::CanonicalURL::Tester::Text;
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

    if (exists $options{canonicalize_before_render} and $options{canonicalize_before_render}) {
        $t->get_ok('/text')->status_is(200)->content_is('text');
        $t->get_ok('/text/')->status_is(301)->header_is(Location => '/text');
    } else {
        $t->get_ok('/text')->status_is(200)->content_is('text');
        $t->get_ok('/text/')->status_is(200)->content_is('text');
    }

    return $self;
}

1;
