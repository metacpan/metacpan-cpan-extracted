use Test::Mojo::IRC -ua;

my $t      = Test::Mojo::IRC->new;
my $server = $t->start_server;
my $irc    = Mojo::IRC::UA->new(server => $server, user => "test$$");

$irc->connect(sub { Mojo::IOLoop->stop });
Mojo::IOLoop->start;

$t->run(
  [qr{JOIN} => ['join-convos.irc']],
  sub {
    my ($err, $info);
    $irc->join_channel("#convos", sub { ($err, $info) = @_[1, 2]; Mojo::IOLoop->stop });
    Mojo::IOLoop->start;
    is $err, '', 'channel joined';
    is_deeply(
      $info,
      {
        name     => '##convos',
        topic    => 'some cool topic',
        topic_by => 'jhthorsen!jhthorsen@i.love.debian.org',
        users    => {batman => {mode => 'o'}, Test21362 => {mode => ''}},
      },
      'got channel info'
    );
  },
);

done_testing;

__DATA__
@@ join-convos.irc
:hybrid8.debian.local 470 test_____ #convos ##convos :Forwarding to another channel
:test_____!~test12120@somehost JOIN ##convos
:hybrid8.debian.local 332 test21362 ##convos :some cool topic
:hybrid8.debian.local 333 test21362 ##convos jhthorsen!jhthorsen@i.love.debian.org 1432932059
:hybrid8.debian.local 353 test21362 @ ##convos :Test21362 @batman
:hybrid8.debian.local 366 test21362 ##convos :End of /NAMES list.
