use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Mojolicious::Lite;

plugin 'MoreUtilHelpers', collection => { patch => 1 };

get '/list' => sub {
  my $self = shift;
  $self->render(text => $self->collection(1,2,3)->join(','));
};

get '/ref' => sub {
  my $self = shift;
  $self->render(text => $self->collection([1,2,3])->join(','));
};

get '/undef' => sub {
  my $self = shift;
  $self->render(text => $self->collection(undef)->join(','));
};

my $t = Test::Mojo->new;
$t->get_ok('/list')->content_is('1,2,3');
$t->get_ok('/ref')->content_is('1,2,3');
$t->get_ok('/undef')->content_is('');

done_testing();
