use strict;
use Test::More 0.98;
use Test::Mojo;
# use Data::Printer;

my $t = Test::Mojo->new('TestApp');


subtest 'routes' => sub {

    $t->get_ok('/')->content_is('default root');
    $t->get_ok('/backoffice')->content_is('backoffice root');
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
                path   => '/backoffice',
                setup  => \&_setup_backoffice
            }
        );

        $app->routes->get('/' => { text => 'default root' });
    }

    sub _setup_backoffice {
        my $app = shift;

        @{$app->routes->namespaces} = ('TestApp::Backoffice');
        $app->routes->get('/' => { text => 'backoffice root' });
    }

}
