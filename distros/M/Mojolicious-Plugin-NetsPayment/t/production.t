use Mojo::Base -base;
use Test::Mojo;
use Test::More;

BEGIN { $ENV{MOJO_MODE} = 'production'; }
use Mojolicious::Lite;
plugin 'NetsPayment';

my $t = Test::Mojo->new;
is $t->app->nets->base_url, 'https://epayment.nets.eu', 'production mode base_url';

done_testing;
