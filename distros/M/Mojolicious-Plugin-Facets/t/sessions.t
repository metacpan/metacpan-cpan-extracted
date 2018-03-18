use strict;
use Test::More 0.98;
use Test::Mojo;

my $t = Test::Mojo->new('TestApp');


subtest 'sessions' => sub {
    $t->ua->max_redirects(1);

    $t->get_ok('/session')
      ->status_is(200)->json_is('/facet', 'none')->json_is('/cookie', 'mojolicious');

    $t->get_ok('/session' => {'Host' => 'backoffice' })->status_is(200);
    $t->get_ok('/dump-session' => {'Host' => 'backoffice' })
      ->status_is(200)->json_is('/facet', 'backoffice')->json_is('/cookie', 'backoffice');
};


done_testing;


{
    package TestApp;

    use Mojo::Base 'Mojolicious';
    use FindBin;

    sub startup {
        my $app = shift;

        $app->plugin('Facets',
            backoffice => {
                host   => 'backoffice',
                setup  => \&_setup_backoffice
            }
        );

        $app->routes->get('/session' => sub {
            my $c = shift;
            $c->session->{facet} = 'none';
            $c->session->{cookie} = $c->app->sessions->cookie_name;
            $c->redirect_to('/dump-session');
        });

        $app->routes->get('/dump-session' => sub {
            my $c = shift;
            $c->render(json => $c->session);
        });

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

        $app->routes->get('/dump-session' => sub {
            my $c = shift;
            $c->render(json => $c->session);
        });
    }

}
