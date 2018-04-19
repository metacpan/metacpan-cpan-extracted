use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;

#plugin 'NamedHelpers' => { namespace => 'wee' };
plugin 'NamedHelpers';
app->named_helper( my_little_helper => sub { my ($c) = @_; return (caller(0))[3]; });

get '/' => sub {
  my $c = shift;
  $c->render(text => $c->my_little_helper);
};

my $t = Test::Mojo->new;
$t->get_ok('/')->status_is(200)->content_is('Mojolicious::Lite::my_little_helper');


done_testing();
