use strict;
use Test::More 0.98;
use Test::Mojo;

my $t = Test::Mojo->new('TestApp');


subtest 'routes' => sub {
    $t->get_ok('/')->content_is('default root');

    $t->get_ok('/' => {'Host' => 'backoffice' })
      ->content_is('backoffice root');

    $t->get_ok('/')->content_is('default root');
};

subtest 'controller namespaces' => sub {

    $t->get_ok('/controller')
      ->status_is(200)->content_like(qr/default controller/);

    $t->get_ok('/controller' => {'Host' => 'backoffice' })
      ->status_is(200)->content_like(qr/backoffice controller/);
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

        $app->routes->get('/' => { text => 'default root' });
        $app->routes->get('/controller')->to('foo#process');
    }

    sub _setup_backoffice {
        my $app = shift;

        @{$app->routes->namespaces} = ('TestApp::Backoffice');
        $app->routes->get('/' => { text => 'backoffice root' });
        $app->routes->get('/controller')->to('foo#process');
    }


    package TestApp::Foo;
    use Mojo::Base 'Mojolicious::Controller';

    sub process {
        shift->render(text => 'default controller')
    }


    package TestApp::Backoffice::Foo;
    use Mojo::Base 'Mojolicious::Controller';

    sub process {
        shift->render(text => 'backoffice controller')
    }

}
