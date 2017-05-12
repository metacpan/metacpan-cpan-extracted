use Mojo::Base -base;
use Test::Mojo;
use Test::More;

BEGIN { $ENV{MOJO_MODE} = 'production'; }
use Mojolicious::Lite;
plugin 'PayPal';

my $t = Test::Mojo->new;
is $t->app->paypal->base_url, 'https://api.paypal.com', 'production mode base_url';

done_testing;
