use Mojolicious::Lite;

plugin 'Mojolicious::Plugin::ForkCall';

get '/slow' => sub {
  my $c = shift;
  my $num = $c->param('num');
  $c->fork_call(
    sub {
      my $num = shift;
      die "$num is not even" if $num % 2;
      return $num / 2;
    }, 
    [$num], 
    sub {
      my ($c, $res) = @_;
      die "$res is too small!" unless $res >= 5;
      $c->render(json => {res => $res});
    },
  );
};

get '/bad' => sub { shift->fork_call(sub{}) }; my $line = __LINE__;

use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new;
$t->get_ok('/slow?num=12')
  ->status_is(200)
  ->json_is('/res' => 6);
$t->get_ok('/slow?num=1')
  ->status_is(500);
$t->get_ok('/slow?num=4')
  ->status_is(500);

$t->get_ok('/bad')
  ->status_is(500)
  ->text_like('#error' => qr/$line/);

{
  no warnings 'once';
  no warnings 'redefine';
  local *Mojo::IOLoop::ForkCall::deserializer = sub { sub { die 'argh' } };
  $t->get_ok('/slow?num=12')
    ->status_is(500)
    ->text_like('#error' => qr/argh/);
}

done_testing;

