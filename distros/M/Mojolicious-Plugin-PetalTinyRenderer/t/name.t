use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;

plugin PetalTinyRenderer => {name => "petal" };
app->renderer->default_handler( 'petal' );

get '/' => sub {
  my $self = shift;
  $self->render('index');
};

my $t = Test::Mojo->new;
$t->get_ok('/')->status_is(200)->content_is("foo\n");

done_testing();

__DATA__

@@ index.html.petal
foo
