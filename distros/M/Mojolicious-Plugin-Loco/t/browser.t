# -*-CPerl-*-
use Mojo::Base -strict;

use FindBin;
use lib "$FindBin::Bin";
use MyTest;

use Test::More;
use Test::Fatal;

sub make_t {
    MyTest->new(
        @_,
        sub {
            my $app = shift;
            my $r   = $app->routes;
            $r->get('/' => { text => "root page" });
            $r->get(
                '/s' => sub {
                    my $c = shift;
                    $c->render(json => $c->session);
                }
            );
        }
    );
}

my $t = make_t();

$t->status_is(200)->content_is('root page');
is($t->app->{_stats}->{cmd}, $t->default_browser, 'default browser');
is($t->app->{_stats}->{count}, 1, 'launched');
$t->get_ok('/s');
is($t->app->{_stats}->{count}, 1, 'launched once');
$t->json_is('/loco.id', 1, 'id set');

$t = make_t(plugin_args => [ browser => 0 ]);
$t->status_is(404);
is($t->app->{_stats}->{count}, undef, 'no launch');

$t = make_t(plugin_args => [ browser => 'waterferret' ]);
$t->status_is(200)->content_is('root page');
is($t->app->{_stats}->{cmd},   'waterferret', 'waterferret browser');
is($t->app->{_stats}->{count}, 1,             'launched');

$t->with_default_browser(
    undef,
    sub {
        like(
            exception { make_t() },
            qr/^Cannot find browser to execute/,
            'Browser::Open fail'
        );
    }
);

{
    my $called = 0;
    my $url;
    $t = make_t(plugin_args =>
          [ browser => sub { $url = shift; ++$called; }, initial_get => 0 ]);
    $t->get_ok('/')->status_is(200)->content_is('root page');
    ok($called, 'coderef browser');
    $t->get_ok('/s');
    is($called, 1, 'launch once');
    $t->json_is('/loco.id', undef, 'id not set');

    # since test is from UserAgent host:port will be bogus
    # let useragent rewrite it
    $url->host('')->port('')->scheme('');
    $t->get_ok($url)->status_is(200)->content_is('root page');
    $t->get_ok('/s');
    $t->json_is('/loco.id', 1, 'id set');
}
done_testing();

