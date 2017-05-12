
use strict;
use Test::More 0.98;
use FindBin;
use lib "$FindBin::Bin/pliftapp/lib";
use Test::Mojo;

# Load application class
my $t = Test::Mojo->new('PliftApp');
$t->ua->max_redirects(1);

# my $app = $t->app;
# $app->defaults( username => 'Cafe' );

# my $c = $app->build_controller;
# $c->render('index');
# diag $c->res->body;

# index tempate
$t->get_ok('/custom_response')
  ->status_is(402)
  ->content_is('CustomResponse');


done_testing();
