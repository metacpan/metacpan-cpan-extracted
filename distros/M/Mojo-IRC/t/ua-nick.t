use Test::Mojo::IRC -ua;

my $t      = Test::Mojo::IRC->new;
my $server = $t->start_server;
my $irc    = Mojo::IRC::UA->new(server => $server, user => "test$$");

$irc->connect(sub { Mojo::IOLoop->stop });
Mojo::IOLoop->start;

$t->run(
  [qr{NICK testX} => ['main', 'nick-testx.irc']],
  sub {
    my ($err, $nick);

    $irc->nick("testX15044", sub { ($err) = @_[1, 2]; Mojo::IOLoop->stop });
    Mojo::IOLoop->start;
    is $err, '', 'set nick';

    $irc->nick(sub { ($err, $nick) = @_[1, 2] });
    is $nick, "testX15044", 'get test';
  }
);

$t->run(
  [qr{NICK jhthorsen} => ['main', 'nick-in-use.irc']],
  sub {
    my ($err, $nick);
    $irc->nick('jhthorsen', sub { ($err) = @_[1, 2]; Mojo::IOLoop->stop });
    Mojo::IOLoop->start;
    is $err, 'Nickname is already in use.', 'nick in use';
  },
);

done_testing;

__DATA__
@@ nick-testx.irc
:test15044!test15044@i.love.debian.org NICK :testX15044
@@ nick-in-use.irc
:hybrid8.debian.local 433 testX15044 jhthorsen :Nickname is already in use.
