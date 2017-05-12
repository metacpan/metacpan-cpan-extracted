use Mojo::Base -strict;

use Test::More;
use Test::Warn;
use Mojolicious::Lite;
use Test::Mojo;

plugin 'Message::Locale', default_message => '-----';

get '/message_from_empty' => sub {
  my $self = shift;
  $self->render_text( $self->locale() );
};
get '/message_from_sasakure' => sub {
  my $self = shift;
  $self->render_text( $self->locale('sasakure', 'common') );
};

my $t = Test::Mojo->new;
warning_like {
$t->get_ok('/message_from_empty')->status_is(200)->content_is('-----');
} qr/^key is undefined or incorrenct. at /;
$t->get_ok('/message_from_sasakure')->status_is(200)->content_is('-----');

done_testing();
