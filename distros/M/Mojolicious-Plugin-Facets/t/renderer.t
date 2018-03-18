use strict;
use Test::More 0.98;
use Test::Mojo;

my $t = Test::Mojo->new('TestApp');


subtest 'renderer paths' => sub {

    $t->get_ok('/page')->content_like(qr/default page/);

    $t->get_ok('/backoffice-page' => {'Host' => 'backoffice' })
      ->status_is(200)
      ->content_like(qr/backoffice page/);


    $t->get_ok('/backoffice-page')->status_is(404);
    $t->get_ok('/page' => {'Host' => 'backoffice' })->status_is(404);

    $t->get_ok('/page')->content_like(qr/default page/);
};


done_testing;


{
    package TestApp;

    use Mojo::Base 'Mojolicious';
    use FindBin;

    sub startup {
        my $app = shift;

        $app->home(Mojo::Home->new("$FindBin::Bin/app_home"));
        @{$app->renderer->paths} = ($app->home->child('template')->to_string);

        $app->plugin('Facets',
            backoffice => {
                host   => 'backoffice',
                setup  => \&_setup_backoffice
            }
        );

        $app->routes->get('/page' => { template => 'page' });
    }

    sub _setup_backoffice {
        my $app = shift;
        @{$app->renderer->paths} = ($app->home->child('backoffice/template')->to_string);
        $app->routes->get('/backoffice-page' => { template => 'page' });
    }

}
