use Test::Mojo::IRC -ua;

my $t      = Test::Mojo::IRC->new;
my $server = $t->start_server;
my $irc    = Mojo::IRC::UA->new(server => $server, user => "test$$");

plan skip_all => 'https://github.com/jhthorsen/mojo-irc/issues/28' unless $ENV{TEST_ALL};

$irc->connect(sub { Mojo::IOLoop->stop });
Mojo::IOLoop->start;

#$t->run(
#  [qr{JOIN} => ['join-convos.irc']],
#  sub {
#    my ($err, $info);
#    $irc->join_channel('#random', sub { ($err, $info) = @_[1, 2]; Mojo::IOLoop->stop });
#    Mojo::IOLoop->start;
#    is $err, '', 'join convos';
#  },
#);

$t->run(
  [qr{MODE} => ['mode-i.irc']],
  sub {
    my ($err, $mode);
    $irc->mode('-i', sub { ($err, $mode) = @_[1, 2]; Mojo::IOLoop->stop });
    Mojo::IOLoop->start;
    is $err,  '',   'mode mode set error';
    is $mode, '-i', 'user mode set';
  },
);

$t->run(
  [qr{MODE} => ['mode-get.irc']],
  sub {
    my ($err, $mode);
    $irc->mode(sub { ($err, $mode) = @_[1, 2]; Mojo::IOLoop->stop });
    Mojo::IOLoop->start;
    is $err,  '',  'user mode get err';
    is $mode, '+', 'user mode get';
  },
);

$t->run(
  [qr{MODE} => ['channel-mode-set.irc']],
  sub {
    my ($err, $mode);
    $irc->mode('#random +k secret', sub { ($err, $mode) = @_[1, 2]; Mojo::IOLoop->stop });
    Mojo::IOLoop->start;
    is $err, '', 'channel mode err';
    is $mode->{mode}, '+k secret', 'channel mode set';
  },
);

done_testing;

__DATA__
@@ mode-i.irc
:test_____!~test70243@localhost MODE other :+i
:test_____!~test70243@localhost MODE test_____ -i
@@ mode-get.irc
:hades.arpa 221 other x
:hades.arpa 221 test_____ +
@@ channel-mode-set.irc
:test_____!~test72489@localhost MODE #foo -k
:test_____!~test72489@localhost MODE #random +k secret
