use Mojo::Base qw{ -strict };
use Mojolicious::Lite;

plugin 'AutoIndex' => { index => [qw/XF/] };

my $after_static_called = 0;
app->hook(
        after_static => sub {
                     $after_static_called =1;
        }
);
use Test::More tests => 3;
use Test::Mojo;

my $t = Test::Mojo->new();

$t->get_ok('/')->status_is(404);

ok !$after_static_called, "after static should not be called";