use Mojo::Base -strict;

use lib 'lib';
use Test::More;
use Test::Mojo;
use Mojolicious;
use Mojo::Hakkefuin::Sessions;
use Mojo::File;
use IO::Socket::UNIX;
use Socket qw(SOCK_STREAM);
use Config;

# Windows (and some builds) lack pack_sockaddr_un; skip to avoid runtime errors.
plan skip_all => 'Unix sockets not available on this platform'
  if $^O =~ /MSWin32/i || !$Config{d_sockaddr_un};

# Prefer unix socket to avoid network restrictions
my $sock = Mojo::File->new('t/tmp/sessions.sock');
$sock->dirname->make_path;
my $check = IO::Socket::UNIX->new(
  Type   => SOCK_STREAM(),
  Local  => $sock->to_string,
  Listen => 1
);
plan skip_all => 'listen not permitted in this environment' unless $check;
$check->close;
unlink $sock->to_string if -S $sock->to_string;
local $ENV{MOJO_LISTEN} = 'http+unix:' . $sock->to_string;

{

  package TestAppWithMaxAge;
  use Mojo::Base 'Mojolicious';

  sub startup {
    my $self = shift;
    $self->secrets(['secret-max']);
    my $sessions = Mojo::Hakkefuin::Sessions->new(
      cookie_name        => 'mhf',
      default_expiration => 3600,
      cookie_path        => '/',
      secure             => 0,
      max_age            => 1
    );
    $self->sessions($sessions);
    my $r = $self->routes;
    $r->get(
      '/set' => sub {
        my $c = shift;
        $c->session(foo => 'bar');
        $c->render(text => 'ok');
      }
    );
  }
}

{

  package TestAppNoMaxAge;
  use Mojo::Base 'Mojolicious';

  sub startup {
    my $self = shift;
    $self->secrets(['secret-nomax']);
    my $sessions = Mojo::Hakkefuin::Sessions->new(
      cookie_name        => 'mhf2',
      default_expiration => 3600,
      cookie_path        => '/',
      secure             => 0,
      max_age            => 0
    );
    $self->sessions($sessions);
    my $r = $self->routes;
    $r->get(
      '/set' => sub {
        my $c = shift;
        $c->session(foo => 'bar');
        $c->render(text => 'ok');
      }
    );
  }
}

package main;

my $t_max = Test::Mojo->new('TestAppWithMaxAge');
$t_max->get_ok('/set')
  ->status_is(200)
  ->header_like('Set-Cookie', qr/Max-Age=/i, 'max-age set when enabled');

my $t_nomax = Test::Mojo->new('TestAppNoMaxAge');
$t_nomax->get_ok('/set')
  ->status_is(200)
  ->header_unlike('Set-Cookie', qr/Max-Age=/i, 'max-age not set when disabled');

done_testing();

# Clean up socket dir
unlink $sock->to_string if -S $sock->to_string;
my $tmpdir = $sock->dirname;
$tmpdir->remove_tree if -d $tmpdir && !$tmpdir->list->size;
