use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use File::Path 'rmtree';
use Mojolicious::Commands;

my $cmd = Mojolicious::Commands->new;
$cmd->run('am', 'n');

ok( -d 'test_app', 'App folder exist' );
ok( -r 'test_app/lib/TestApp/Controllers/App.pm', 'Controller exist' );
ok( -r 'test_app/lib/TestApp/Models/App.pm', 'Model exist' );
ok( -r 'test_app/lib/TestApp/Helpers/App.pm', 'Helper exist' );

use lib 'test_app/lib';

my $t = Test::Mojo->new('TestApp');

$t->get_ok('/')->status_is(200)->content_like(qr/action #index/);

rmtree( 'test_app' );

done_testing();
