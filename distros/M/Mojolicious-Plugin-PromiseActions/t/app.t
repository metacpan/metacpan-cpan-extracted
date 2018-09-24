BEGIN { $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll' }
use Test::More;
use Test::Mojo;

use Mojolicious::Lite;
use Mojo::Promise;

plugin 'PromiseActions';
my @values;

app->hook(around_action => sub {
    my ($next, $c) = @_;
    my ($res, $text) = $next->();
    push @values, $res,$text;
    return ($res, $text);

});

get '/' => sub {
  my $c=shift;

  my $p=Mojo::Promise->new;
  Mojo::IOLoop->timer(0.1,sub { $p->resolve('HI'); });
  $p->then(sub {
    $c->render(text=>'Hello');
  });
  return ($p, 'hello');
};
get '/normal' => sub {
  my $c=shift;
  $c->render(text=>'NO');
  return 1;
};

my $t=Test::Mojo->new;
$t->get_ok('/')->status_is('200')->content_is('Hello');
is(ref $values[0],'Mojo::Promise', 'Promise is passed through');
is($values[1],'hello', 'Second argument passed through ok');
$t->get_ok('/normal')->status_is('200')->content_is('NO');
is($values[2],'1', 'Got return');
is($values[3],undef, 'No second argument');


done_testing;
