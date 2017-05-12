use Test::Mojo::IRC -ua;

my $t      = Test::Mojo::IRC->new;
my $server = $t->start_server;
my $irc    = Mojo::IRC::UA->new(server => $server, user => "test$$");

$irc->connect(sub { Mojo::IOLoop->stop });
Mojo::IOLoop->start;

#$t->run(
#  [qr{JOIN} => ['join-convos.irc']],
#  sub {
#    my ($err, $info);
#    $irc->join_channel('#foo', sub { ($err, $info) = @_[1, 2]; Mojo::IOLoop->stop });
#    Mojo::IOLoop->start;
#    is $err, '', 'join convos';
#  },
#);

$t->run(
  [qr{KICK} => ['no-such-channel.irc']],
  sub {
    my ($err, $res);
    $irc->kick('#foo superman', sub { ($err, $res) = @_[1, 2]; Mojo::IOLoop->stop });
    Mojo::IOLoop->start;
    is $err, 'No such channel', 'kick error';
  },
);

$t->run(
  [qr{KICK} => ['kick.irc']],
  sub {
    my ($err, $res);
    $irc->kick('#foo superman', sub { ($err, $res) = @_[1, 2]; Mojo::IOLoop->stop });
    Mojo::IOLoop->start;
    is $err, '', 'kick success';
    is $res->{reason}, '', 'kick reason';
  },
);


done_testing;

__DATA__
@@ no-such-channel.irc
:hades.arpa 403 test_____ #foo :No such channel
@@ kick.irc
:test_____!~test86048@localhost KICK #foo superman :test_____
