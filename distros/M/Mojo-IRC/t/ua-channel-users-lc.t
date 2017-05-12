use Test::Mojo::IRC -ua;

# https://github.com/Nordaaker/convos/issues/277

my $t      = Test::Mojo::IRC->new;
my $server = $t->start_server;
my $irc    = Mojo::IRC::UA->new(server => $server, user => "test$$");

$irc->connect(sub { Mojo::IOLoop->stop });
Mojo::IOLoop->start;

$t->run(
  [qr{NAMES} => ['main', 'names.irc']],
  sub {
    my ($err, $users);
    $irc->channel_users("#KNAQU", sub { ($err, $users) = @_[1, 2]; Mojo::IOLoop->stop });
    Mojo::IOLoop->start;
    is $err, '', 'no error';
    ok $users->{r1},         'got user r1';
    ok $users->{superwoman}, 'got user superwoman';
    ok $users->{z},          'got user z';
  },
);

done_testing;

__DATA__
@@ names.irc
:irc.local 353 superwoman = #KnaQu :x superwoman y z
:irc.local 353 superwoman = #KnaQu :r1 r2 r3
:irc.local 366 superwoman #knaqu :End of /NAMES list.
