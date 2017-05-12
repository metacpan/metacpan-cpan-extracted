use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;
use utf8;

plugin 'Message::Locale';

get '/message_from_common' => sub {
  my $self = shift;
  $self->render_text( $self->locale('message', 'common') );
};
get '/message_from_original' => sub {
  my $self = shift;
  $self->render_text( $self->locale('message', 'original') );
};
get '/set_locale_method' => sub {
  my $self = shift;
  $self->set_locale('ja');
  $self->render_text( $self->locale('message', 'common') );
};

my $t = Test::Mojo->new;
$t->get_ok('/message_from_common')->status_is(200)->content_is('MESSAGE');
$t->get_ok('/message_from_original')->status_is(200)->content_is('ORIGINAL MESSAGE');
$t->get_ok('/set_locale_method')->status_is(200)->content_is('メッセージ');

done_testing();
