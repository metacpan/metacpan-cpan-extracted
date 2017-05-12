use Test::Mojo::IRC -ua;

my $t      = Test::Mojo::IRC->new;
my $server = $t->start_server;
my $irc    = Mojo::IRC::UA->new(server => $server, user => "test$$");

$irc->connect(sub { Mojo::IOLoop->stop });
Mojo::IOLoop->start;

$t->run(
  [qr{LIST} => ['main', 'channel-list.irc']],
  sub {
    my ($err, $channels);
    $irc->channels(sub { ($err, $channels) = @_[1, 2]; Mojo::IOLoop->stop });
    Mojo::IOLoop->start;
    is $err, '', 'err';
    is_deeply($channels,
      {'#test123' => {n_users => 1, topic => ''}, '#convos' => {n_users => 4, topic => 'some cool topic'}}, 'channels');
  },
);

done_testing;

__DATA__
@@ channel-list.irc
:hybrid8.debian.local 321 test10409 Channel :Users  Name
:hybrid8.debian.local 322 test10409 #test123 1 :[+nt]
:hybrid8.debian.local 322 test10409 #convos 4 :[+nt] some cool topic
:hybrid8.debian.local 323 test10409 :End of /LIST
