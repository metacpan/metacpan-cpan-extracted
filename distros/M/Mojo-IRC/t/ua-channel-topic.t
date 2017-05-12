use Test::Mojo::IRC -ua;

my $t      = Test::Mojo::IRC->new;
my $server = $t->start_server;
my $irc    = Mojo::IRC::UA->new(server => $server, user => "test$$");

$irc->connect(sub { Mojo::IOLoop->stop });
Mojo::IOLoop->start;

{
  my $err;
  $irc->channel_topic("", "0", sub { $err = $_[1]; Mojo::IOLoop->stop });
  Mojo::IOLoop->start;
  is $err, 'Cannot get/set topic without channel name.', 'channel name missing';
}

{
  my $err;
  $irc->channel_topic("channel with space", "", sub { $err = $_[1]; Mojo::IOLoop->stop });
  Mojo::IOLoop->start;
  is $err, 'Cannot get/set topic on channel with spaces in name.', 'channel name with whitespace';
}

$t->run(
  [qr{TOPIC} => ['main', 'topic.irc']],
  sub {
    my ($err, $topic);
    $irc->channel_topic("#convos", sub { ($err, $topic) = @_[1, 2]; Mojo::IOLoop->stop });
    Mojo::IOLoop->start;
    is $err, '', 'get no error';
    is_deeply($topic, {topic => 'some cool topic'}, 'got topic');
  },
);

$t->run(
  [qr{TOPIC} => ['main', 'cannot-set.irc']],
  sub {
    my $err;
    $irc->channel_topic("#convos", "cannot set topic?", sub { $err = $_[1]; Mojo::IOLoop->stop });
    Mojo::IOLoop->start;
    is $err, "You're not on that channel", 'cannot set topic';
  },
);

$t->run(
  [qr{TOPIC} => ['main', 'chan-op.irc']],
  sub {
    my $err;
    $irc->channel_topic("#convos", "not op?", sub { $err = $_[1]; Mojo::IOLoop->stop });
    Mojo::IOLoop->start;
    is $err, "You're not channel operator", 'chanoprivsneeded';
  },
);

$t->run(
  [qr{TOPIC} => ['main', 'no-topic.irc']],
  sub {
    my ($err, $topic);
    $irc->channel_topic("#test_channel_topic", sub { ($err, $topic) = @_[1, 2]; Mojo::IOLoop->stop });
    Mojo::IOLoop->start;
    is $err, '', 'get no topic error';
    is_deeply($topic, {topic => ''}, 'got no topic');
  },
);

$t->run(
  [qr{TOPIC} => ['main', 'set.irc']],
  sub {
    my $err;
    $irc->channel_topic("#test_channel_topic", "awesomeness", sub { $err = $_[1]; Mojo::IOLoop->stop });
    Mojo::IOLoop->start;
    is $err, "", 'set topic';
  },
);

done_testing;

__DATA__
@@ topic.irc
:hybrid8.debian.local 332 test18655 #convos :some cool topic
:hybrid8.debian.local 333 test18655 #convos jhthorsen!jhthorsen@i.love.debian.org 1432932059
@@ cannot-set.irc
:hybrid8.debian.local 442 test18655 #convos :You're not on that channel
@@ set.irc
:test20949!test20949@i.love.debian.org TOPIC #test_channel_topic :awesomeness
@@ no-topic.irc
:hybrid8.debian.local 331 test18655 #test_channel_topic :No topic is set.
@@ chan-op.irc
:hybrid8.debian.local 482 test18655 #convos :You're not channel operator
