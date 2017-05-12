use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;

plugin 'Mojolicious::Plugin::ChromeLogger';

get '/' => sub {
    my $self = shift;

    my $log = $self->app->log;

    $log->debug('Some debug here(С кириллицей)');
    $log->info('Some info here');
    $log->warn('Some warn here');
    $log->error('Some error here');
    $log->fatal('Some fatal here');

    $self->render( text => 'Open Chrome console' );
};

my $t = Test::Mojo->new;
$t
->get_ok('/')
->status_is(200)
->content_is('Open Chrome console')
->header_like( 'X-ChromeLogger-Data' => qr/[a-z0-9\.\/=]+/i );

done_testing();
