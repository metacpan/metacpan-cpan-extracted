use strict;
use Test::More 0.98;
use Test::Mojo;

my $t = Test::Mojo->new('TestApp');


subtest 'sessions' => sub {
    $t->ua->max_redirects(1);

    $t->get_ok('/session')
      ->status_is(200);

    $t->get_ok('/backoffice/session')->status_is(200);

    $t->get_ok('/dump-session')
      ->status_is(200)
      ->json_is('/default/facet', 'none')
      ->json_is('/default/cookie', 'mojolicious')
      ->json_is('/backoffice/facet', 'backoffice')
      ->json_is('/backoffice/cookie', 'backoffice');
};


done_testing;


{
    package TestApp;
    use Mojo::Base 'Mojolicious';

    sub startup {
        my $app = shift;

        $app->routes->get('/session' => sub {
            my $c = shift;
            $c->session->{facet} = 'none';
            $c->session->{cookie} = $c->app->sessions->cookie_name;
            $c->rendered(200);
        });

        $app->routes->get('/dump-session' => sub {
            my $c = shift;

            $c->render(json => {
                default => $c->session,
                backoffice => $c->facet_do('backoffice', sub { shift->session })
            });
        });

        $app->plugin('Facets',
            backoffice => {
                path   => '/backoffice',
                setup  => \&_setup_backoffice
            }
        );

    }

    sub _setup_backoffice {
        my $app = shift;

        $app->sessions->cookie_name('backoffice');

        $app->routes->get('/session' => sub {
            my $c = shift;
            $c->session->{facet} = 'backoffice';
            $c->session->{cookie} = $c->app->sessions->cookie_name;
            $c->rendered(200);
        });
    }

}
