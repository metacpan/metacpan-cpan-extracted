use Mojo::Base qw{ -strict };
use Mojolicious::Lite;

plugin 'AutoIndex' => { index => [qw/XF/] };

my $after_static_called = 0;
app->hook(
        after_static => sub {
                     $after_static_called =1;
        }
);

get '/' =>  sub {
    shift->render( text => 'XFbyRoute')
};

use Test::More tests => 4;
use Test::Mojo;

my $t = Test::Mojo->new();

$t->get_ok('/')->status_is(200)->content_is('XFbyRoute');

ok !$after_static_called, "after static should not be called";