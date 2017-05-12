use Mojolicious::Lite;

use Test::More;
use Test::Mojo;

plugin 'SimpleSlides';

my $t = Test::Mojo->new;

# App::git::ship creates this test,
# so needed to test something...
$t->get_ok('/')
  ->status_is(404);

done_testing;
