package Mojolicious::Plugin::CanonicalURL::Tester::OnlyPathChanges;
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

    $t->get_ok('/foo')->status_is(200)->content_is('foo');
    $t->get_ok('/foo/?param=yes&other_param=wow')->status_is(301)->header_is(Location => '/foo?param=yes&other_param=wow');

    return $self;
}

1;
