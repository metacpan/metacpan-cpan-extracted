use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Mojolicious::Lite;

plugin 'MoreUtilHelpers';

get '/trim_param' => sub {
  my $self = shift;
  $self->trim_param('a');

  my $a = $self->param('a');
  my $b = $self->param('b');

  $self->render(text => "$a|$b");
};

get '/trim_param_array' => sub {
  my $self = shift;
  $self->trim_param('a');

  my @a = @{ $self->every_param('a') };
  $self->render(text => "$a[0]|$a[1]");
};

get '/trim_param_no_param' => sub {
  my $self = shift;
  $self->trim_param('a');
  $self->render(text => defined $self->param('a'));
};

get '/trim_param_multi' => sub {
  my $self = shift;

  $self->trim_param('a','b');

  my $a = $self->param('a');
  my $b = $self->param('b');

  $self->render(text => "$a|$b");
};

get '/trim_param_regex' => sub {
  my $self = shift;

  $self->trim_param(qr/a/);

  my $a = $self->param('a');
  my $b = $self->param('b');

  $self->render(text => "$a|$b");
};

get '/trim_param_regex_mixed' => sub {
  my $self = shift;

  $self->trim_param(qr/a/,'b');

  my $a = $self->param('a');
  my $b = $self->param('b');

  $self->render(text => "$a|$b");
};

get '/trim_param_regex_multi' => sub {
  my $self = shift;

  $self->trim_param(qr/a/,qr/b/);

  my $a = $self->param('a');
  my $b = $self->param('b');

  $self->render(text => "$a|$b");
};


my $params = { a => ' foo ', b => ' moo '};
my $t = Test::Mojo->new;
$t->get_ok('/trim_param', form => $params)->content_is('foo| moo ');
$t->get_ok('/trim_param_no_param')->content_is('');
$t->get_ok('/trim_param_array', form => {a => [' foo ', ' moo ']})->content_is('foo|moo');
$t->get_ok('/trim_param_multi', form => $params)->content_is('foo|moo');
$t->get_ok('/trim_param_regex', form => $params)->content_is('foo| moo ');
$t->get_ok('/trim_param_regex_mixed', form => $params)->content_is('foo|moo');
$t->get_ok('/trim_param_regex_multi', form => $params)->content_is('foo|moo');

done_testing();
