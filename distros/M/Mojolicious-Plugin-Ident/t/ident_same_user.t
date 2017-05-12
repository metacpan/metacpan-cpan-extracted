use strict;
use warnings;
use Test::More tests => 15;
use Test::Mojo;
use Mojolicious::Lite;
use AnyEvent::Ident qw( ident_server );

my $execute_count = 0;

my $error = '';

plugin 'ident' => { 
  port => do {
    use AnyEvent;
    my $bind = AnyEvent->condvar;
    my $server = ident_server '127.0.0.1', 0, sub {
      my $tx = shift;
      if($error)
      {
        $tx->reply_with_error($error);
      }
      else
      {
        $tx->reply_with_user('AwesomeOS', 'foo');
      }
      $execute_count++;
    }, { on_bind => sub { $bind->send(shift) } };
    $bind->recv->bindport;
  }
};

under sub {
  my $self = shift;
  $self->ident_same_user ? 1 : $self->reply->not_found && 0;
};

get '/ident' => sub { shift->render(text => 'okay') };

my $same_user;

eval q{
  no warnings qw( redefine );
  sub Mojolicious::Plugin::Ident::Response::same_user
  {
    $same_user;
  }
};
die $@ if $@;

my $t = Test::Mojo->new;

is $execute_count, 0, 'execute_count = 0';

$same_user = 1;
$t->get_ok("/ident")
  ->status_is(200);
is $execute_count, 1, 'execute_count = 1';
$t->get_ok("/ident")
  ->status_is(200);
is $execute_count, 1, 'execute_count = 1';

$t->reset_session;

$same_user = 0;
$t->get_ok('/ident')
  ->status_is(404);
is $execute_count, 2, 'execute_count = 2';
$t->get_ok('/ident')
  ->status_is(404);
is $execute_count, 2, 'execute_count = 2';

$t->reset_session;
$error = 'ident error';
$t->get_ok('/ident')
  ->status_is(404);
