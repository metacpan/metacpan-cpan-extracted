use lib '.';
use t::Helper;

# guard
Mojo::IOLoop->recurring(2 => sub { Mojo::IOLoop->stop });

my $port            = generate_port();
my $irc             = Mojo::IRC->new(nick => 'test123', name => 'testman', server => "127.0.0.1:$port");
my $first_stream_id = '';
my $server_stream;
my %events;

Mojo::IOLoop->server(
  {port => $port},
  sub {
    $events{connect}++;
    $server_stream = $_[1];
    Mojo::IOLoop->stop;
  },
);

$irc->on(
  close => sub {
    $events{close}++;
    $irc->connect(sub { });
  }
);

$irc->connect(sub { });
ok + ($first_stream_id = $irc->{stream_id}), 'got stream_id';
ok !$irc->{stream}, 'no stream';

Mojo::IOLoop->start;
ok $irc->{stream}, 'got stream';

$server_stream->close;
Mojo::IOLoop->start;

is_deeply(\%events, {close => 1, connect => 2}, 'got correct events');
is length($irc->{stream_id} || ''), length($first_stream_id), 'got stream_id on reconnect';
isnt $irc->{stream_id}, $first_stream_id, 'got new stream_id';
ok $irc->{stream}, 'and new stream';

done_testing;

sub irc_data {
  my $file = shift;
  diag "read $file";
  open my $FH, '<', "t/data/$file" or die $!;
  join '', map { s/\r?\n$/\r\n/; $_ } <$FH>;
}

sub start_ioloop {
  my $tid = Mojo::IOLoop->timer(1 => sub { Mojo::IOLoop->stop });
  Mojo::IOLoop->start;
  Mojo::IOLoop->remove($tid);
}
