use Test::Mojo::IRC -ua;

my $t      = Test::Mojo::IRC->new;
my $server = $t->start_server;
my $irc    = Mojo::IRC::UA->new(server => $server, user => "test$$");

$irc->connect(sub { Mojo::IOLoop->stop });
Mojo::IOLoop->start;

{
  my $err;
  $irc->whois("", sub { $err = $_[1]; Mojo::IOLoop->stop });
  Mojo::IOLoop->start;
  is $err, 'Cannot retrieve whois information without target.', 'target missing';
}

$t->run(
  [qr{WHOIS} => ['main', 'whois-jhthorsen.irc']],
  sub {
    my ($err, $info);
    $irc->whois("batman", sub { ($err, $info) = @_[1, 2]; Mojo::IOLoop->stop });
    Mojo::IOLoop->start;
    is $err, '', 'whois batman';
    is_deeply(
      $info,
      {
        channels    => {'#test123' => {mode => '@'}, '#convos' => {mode => '@'}},
        host        => 'i.love.debian.org',
        idle_for    => 17454,
        server_info => 'ircd-hybrid 8.1-debian',
        name        => 'Convos v0.99_08',
        nick        => 'batman',
        server      => 'hybrid8.debian.local',
        user        => 'jhthorsen',
      },
      'info'
    );
  },
);

done_testing;

__DATA__
@@ whois-jhthorsen.irc
:hybrid8.debian.local 311 test26217 batman jhthorsen i.love.debian.org * :Convos v0.99_08
:hybrid8.debian.local 319 test26217 batman :@#test123 @#convos
:hybrid8.debian.local 312 test26217 batman hybrid8.debian.local :ircd-hybrid 8.1-debian
:hybrid8.debian.local 338 test26217 batman 255.255.255.255 :actually using host
:hybrid8.debian.local 317 test26217 batman 17454 1432930742 :seconds idle, signon time
:hybrid8.debian.local 318 test26217 batman :End of /WHOIS list.
