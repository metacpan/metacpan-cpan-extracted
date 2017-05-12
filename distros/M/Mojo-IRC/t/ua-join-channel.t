use Test::Mojo::IRC -ua;

my $t      = Test::Mojo::IRC->new;
my $server = $t->start_server;
my $irc    = Mojo::IRC::UA->new(server => $server, user => "test$$");

{
  my $err;
  $irc->join_channel("", sub { $err = $_[1]; Mojo::IOLoop->stop });
  Mojo::IOLoop->start;
  is $err, 'Cannot join without channel name.', 'channel name missing';
}

$irc->connect(sub { Mojo::IOLoop->stop });
Mojo::IOLoop->start;

$t->run(
  [qr{JOIN} => ['cannot-join-convos.irc']],
  sub {
    my ($err, $info);
    $irc->join_channel("#convos", sub { ($err, $info) = @_[1, 2]; Mojo::IOLoop->stop });
    Mojo::IOLoop->start;
    is $err, 'Cannot join channel (+k)', 'cannot join +k';
  },
);

$t->run(
  [qr{JOIN} => ['join-convos.irc']],
  sub {
    my ($err, $info);
    $irc->join_channel("#convos key", sub { ($err, $info) = @_[1, 2]; Mojo::IOLoop->stop });
    Mojo::IOLoop->start;
    is $err, '', 'channel joined';
    is_deeply(
      $info,
      {
        name     => '#convos',
        topic    => 'some cool topic',
        topic_by => 'jhthorsen!jhthorsen@i.love.debian.org',
        users    => {batman => {mode => 'o'}, Test21362 => {mode => ''}},
      },
      'got channel info'
    );
  },
);

$t->run(
  [qr{USER} => ['join-convos.irc']],
  sub {
    my $err;
    $irc->op_timeout(0.3)->join_channel("#convos", sub { $err = $_[1]; Mojo::IOLoop->stop });
    Mojo::IOLoop->start;
    local $TODO = 'Maybe TOPIC can be added to see if already joined?';
    is $err, 'Response timeout after 0.3s.', 'response timeout';
  }
);

# TODO: Should the keys also get deleted?
is_deeply(
  $irc->{write_and_wait},
  {
    479                 => {},
    err_badchanmask     => {},
    err_badchannelkey   => {},
    err_bannedfromchan  => {},
    err_channelisfull   => {},
    err_inviteonlychan  => {},
    err_linkchannel     => {},
    err_nosuchchannel   => {},
    err_toomanychannels => {},
    err_toomanytargets  => {},
    err_unavailresource => {},
    rpl_endofnames      => {},
    rpl_namreply        => {},
    rpl_topic           => {},
    rpl_topicwhotime    => {},
  },
  'events are cleaned up'
);

done_testing;

__DATA__
@@ cannot-join-convos.irc
:hybrid8.debian.local 475 Superman20001 #convos :Cannot join channel (+k)
@@ join-convos.irc
:test21362!test21362@i.love.debian.org JOIN :#convos
:hybrid8.debian.local 475 Superman20001 #foo :Cannot join channel (+k)
:hybrid8.debian.local 332 test21362 #convos :some cool topic
:hybrid8.debian.local 333 test21362 #convos jhthorsen!jhthorsen@i.love.debian.org 1432932059
:hybrid8.debian.local 353 test21362 = #convos :Test21362 @batman
:hybrid8.debian.local 366 test21362 #convos :End of /NAMES list.
