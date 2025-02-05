use Test2::V0;
use Test2::MojoX;
use Mojolicious::Lite;

my $t = Test2::MojoX->new;

$t->app->log->level('error');
ok( lives { $t->app->plugin( CaptchaPNG => { value => sub { 42 } } ) }, 'plugin registration' ) or note $@;

$t
    ->get_ok('/captcha')
    ->status_is(200)
    ->header_is( 'Content-Type' => 'image/png' )
    ->content_like( qr/^\x89PNG\r\n\x1a\n/ );

$t->tx->req->cookies( @{ $t->tx->res->cookies } );
my $c = $t->app->build_controller( $t->tx );

is( $c->get_captcha_value, 42, 'get_captcha_value' );
ok( ! $c->check_captcha_value(1138), 'check_captcha_value bad' );
is( $c->get_captcha_value, 42, 'get_captcha_value still exists' );
ok( $c->check_captcha_value(42), 'check_captcha_value good' );
is( $c->get_captcha_value, undef, 'get_captcha_value no longer exists' );

done_testing;
