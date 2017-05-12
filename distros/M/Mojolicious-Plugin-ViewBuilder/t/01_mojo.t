use lib './t/lib';
use WebApp;
use Test::More;
use Test::Mojo;
my $t = Test::Mojo->new("WebApp");
$t->get_ok('/')->status_is(200)
    ->content_like(  qr/double it/ );
$t->get_ok('/')->status_is(200)
    ->content_like(  qr/42/ );
done_testing();
1;

