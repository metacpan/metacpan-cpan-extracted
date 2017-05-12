use strict;
use warnings;
use Test::More tests => 4;
use Test::Mojo;
use AnyEvent::Ident qw( ident_server );
use Mojolicious::Lite;

plugin 'ident' => { 
  port => do {
    use AnyEvent;
    my $bind = AnyEvent->condvar;
    my $server = ident_server '127.0.0.1', 0, sub {
      eval {
        my $tx = shift;
        $tx->reply_with_user('AwesomeOS', 'foo');
      };
      diag "died in server callback: $@" if $@;
    }, { on_bind => sub { $bind->send(shift) } };
    $bind->recv->bindport;
  }
};

get '/' => sub { shift->render(text => 'index') };

get '/ident' => sub {
  my($self) = @_;
  eval {
    $self->ident(sub {
      eval {
        my $res = shift;
        $self->render(json => { username => $res->username, os => $res->os });
      };
      diag "died in ident client callback: $@" if $@;
    });
  };
  diag "died in mojo callback: $@" if $@;
};

my $t = Test::Mojo->new;

$t->get_ok("/ident")
  ->status_is(200)
  ->json_is('/username',       'foo')
  ->json_is('/os',             'AwesomeOS');

#diag "AE::detect = " . AnyEvent::detect();
