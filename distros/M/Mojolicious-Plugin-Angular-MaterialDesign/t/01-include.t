use Mojo::Base -base;
use Mojolicious;
use Test::Mojo;
use Test::More;

$ENV{PATH} = '/dev/null';    # make sure sass is not found

my $app = Mojolicious->new( mode => 'development' );
my $t = Test::Mojo->new($app);

$app->plugin('Angular::MaterialDesign');
$app->routes->get( '/test1' => 'test1' );
$t->get_ok('/test1')->status_is(200)
    ->text_like( 'script', qr{Angular Material Design},
    'angular-material.js' )
    ->text_like( 'style', qr{md-bottom-sheet\.md-grid}, 'css' );

done_testing;

__DATA__
@@ test1.html.ep
%= asset 'materialdesign.css' => {inline=> 1};
%= asset 'materialdesign.js' => {inline=> 1};
