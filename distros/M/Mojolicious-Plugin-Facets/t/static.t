use strict;
use Test::More 0.98;
use Test::Mojo;

my $t = Test::Mojo->new('TestApp');


subtest 'static paths' => sub {

    $t->get_ok('/file.txt')->content_like(qr/default/);
    $t->get_ok('/file.txt' => {'Host' => 'backoffice' })->content_like(qr/backoffice/);
    $t->get_ok('/file.txt')->content_like(qr/default/);
};


done_testing;


{
    package TestApp;

    use Mojo::Base 'Mojolicious';
    use FindBin;

    sub startup {
        my $app = shift;

        $app->home(Mojo::Home->new("$FindBin::Bin/app_home"));
        @{$app->static->paths} = ($app->home->child('public')->to_string);

        $app->plugin('Facets',
            backoffice => {
                host   => 'backoffice',
                setup  => \&_setup_backoffice
            }
        );
    }

    sub _setup_backoffice {
        my $app = shift;
        @{$app->static->paths} = ($app->home->child('backoffice/static')->to_string);
    }

}
