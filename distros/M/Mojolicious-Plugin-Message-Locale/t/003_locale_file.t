use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;

use utf8;

plugin 'Message::Locale', file => 'other_locale.conf';

get '/message_from_common' => sub {
  my $self = shift;
  $self->render_text( $self->locale('message', 'common') );
};
get '/message_from_original' => sub {
  my $self = shift;
  $self->render_text( $self->locale('message', 'original') );
};

my $t = Test::Mojo->new;
$t->get_ok('/message_from_common')->status_is(200)->content_is('OTHER MESSAGE');
$t->get_ok('/message_from_original')->status_is(200)->content_is('OTHER ORIGINAL MESSAGE');

done_testing();
