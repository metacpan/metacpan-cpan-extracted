BEGIN {
  *Mojo::IRC::localtime = sub {'Fri Feb 21 19:35:24 2014'}
}
use lib '.';
use t::Helper;

my $port        = generate_port();
my $irc         = Mojo::IRC->new(nick => "mojo_irc", user => "u1", server => "127.0.0.1:$port");
my $server_read = '';

plan skip_all => 'http://www.cpantesters.org/cpan/report/a7e2d979-6c10-1014-9411-15f7e1165d23' if $^O eq 'MSWin32';

Mojo::IOLoop->server(
  {port => $port},
  sub {
    my ($self, $stream) = @_;

    $stream->on(
      read => sub {
        my ($stream, $data) = @_;
        $server_read .= $data;
        Mojo::IOLoop->stop if $server_read =~ /VERSION/;
      }
    );

    $stream->write(":other_client!u2\@other.example.com PRIVMSG #channel :\x{1}ACTION msg1\x{1}\r\n");
    $stream->write(":other_client!u2\@other.example.com PRIVMSG mojo_irc :\x{1}PING 1393007660\x{1}\r\n");
    $stream->write(":other_client!u2\@other.example.com PRIVMSG mojo_irc :\x{1}TIME\x{1}\r\n");
    $stream->write(":other_client!u2\@other.example.com PRIVMSG mojo_irc :\x{1}VERSION\x{1}\r\n");
  },
);

$irc->parser(Parse::IRC->new(ctcp => 1));

my ($err, $ctcp_action_message);
$irc->on(ctcp_action => sub { $ctcp_action_message = $_[1]; });
$irc->connect(sub { $err = $_[1] });
start_ioloop();
is $err, '', 'no error on connect';

delete $ctcp_action_message->{raw_line};
is_deeply(
  $ctcp_action_message,
  {
    command => 'CTCP_ACTION',
    event   => 'ctcp_action',
    params  => ['#channel', 'msg1'],
    prefix  => 'other_client!u2@other.example.com'
  },
  'CTCP ACTION'
);

is $server_read, <<"HERE", "got correct response from mojo_irc";
NICK mojo_irc\r
USER u1 8 * :Mojo IRC\r
NOTICE other_client :\001PING 1393007660\001\r
NOTICE other_client :\001TIME Fri Feb 21 19:35:24 2014\001\r
NOTICE other_client :\001VERSION Mojo-IRC $Mojo::IRC::VERSION\001\r
HERE

done_testing;

sub start_ioloop {
  my $tid = Mojo::IOLoop->timer(1 => sub { Mojo::IOLoop->stop });
  Mojo::IOLoop->start;
  Mojo::IOLoop->remove($tid);
}
