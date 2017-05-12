use strict;
use warnings;
use Test::More tests => 2;
use Test::Mojo;
use AnyEvent::Ident qw( ident_server );
use Mojolicious::Lite;

plugin 'ident' => { 
  port => do {
    use AnyEvent;
    my $bind = AnyEvent->condvar;
    my $server = ident_server '127.0.0.1', 0, sub {
      my $tx = shift;
      $tx->reply_with_error('some ident error');
    }, { on_bind => sub { $bind->send(shift) } };
    $bind->recv->bindport;
  }
};

get '/' => sub { shift->render(text => 'index') };

get '/ident' => sub {
  my($self) = @_;
  my $ident = $self->ident;
  $self->render(text => 'okay!');
};

my $t = Test::Mojo->new;

$t->get_ok("/ident")
  ->status_is(500);
