use Test::Mojo::IRC -ua;

my $t      = Test::Mojo::IRC->new;
my $server = $t->start_server;
my $irc    = Mojo::IRC::UA->new(server => $server, user => "test$$");

$irc->register_default_event_handlers;
$irc->connect(sub { Mojo::IOLoop->stop });
Mojo::IOLoop->start;

{
  my $err;
  $irc->channel_users("", sub { $err = $_[1]; Mojo::IOLoop->stop });
  Mojo::IOLoop->start;
  is $err, 'Cannot get users without channel name.', 'channel name missing';
}

$t->run(
  [qr{NAMES} => ['main', 'convos-names.irc']],
  sub {
    my ($err, $users);

    #for testing with live server:
    #$irc->join_channel("#convos", sub { Mojo::IOLoop->stop });
    #Mojo::IOLoop->start;
    $irc->channel_users("#convos", sub { ($err, $users) = @_[1, 2]; Mojo::IOLoop->stop });
    Mojo::IOLoop->start;
    is $err, '', 'no error';
    is_deeply(
      $irc->server_settings,
      {
        callerid    => 'g',
        casemapping => 'rfc1459',
        chanlimit   => '#:50',
        chanmodes   => 'eIbq,k,flj,CDEFGJKLMOPQTcdgimnpstuz',
        channellen  => '50',
        chantypes   => '#',
        clientver   => '3.0',
        cnotice     => 1,
        cprivmsg    => 1,
        deaf        => 'D',
        elist       => 'CTU',
        etrace      => 1,
        excepts     => 1,
        fnc         => 1,
        invex       => 1,
        knock       => 1,
        maxlist     => 'bqeI:100',
        modes       => '5',
        monitor     => '100',
        network     => 'Channel0',
        nicklen     => '31',
        prefix      => '(aohv)!@%+',
        safelist    => 1,
        statusmsg   => '@+',
        targmax     => 'NAMES:1,LIST:1,KICK:1,WHOIS:1,PRIVMSG:8,NOTICE:8,ACCEPT:,MONITOR:',
        topiclen    => '390',
        whox        => 1,
      },
      'server_settings'
    );
    is_deeply(
      $users,
      {
        bar      => {mode => 'o'},
        foo      => {mode => 'v'},
        super    => {mode => 'h'},
        batman   => {mode => 'o'},
        test6851 => {mode => ''},
      },
      'users'
    );
  },
);

done_testing;

__DATA__
@@ convos-names.irc
:hybrid8.debian.local 005 test6851 CHANTYPES=# EXCEPTS INVEX CHANMODES=eIbq,k,flj,CDEFGJKLMOPQTcdgimnpstuz CHANLIMIT=#:50 PREFIX=(aohv)!@%+ MAXLIST=bqeI:100 MODES=5 NETWORK=Channel0 KNOCK STATUSMSG=@+ CALLERID=g :are supported by this server
:hybrid8.debian.local 005 test6851 CASEMAPPING=rfc1459 NICKLEN=31 CHANNELLEN=50 TOPICLEN=390 ETRACE CPRIVMSG CNOTICE DEAF=D MONITOR=100 FNC TARGMAX=NAMES:1,LIST:1,KICK:1,WHOIS:1,PRIVMSG:8,NOTICE:8,ACCEPT:,MONITOR: WHOX :are supported by this server
:hybrid8.debian.local 005 test6851 CLIENTVER=3.0 SAFELIST ELIST=CTU :are supported by this server
:hybrid8.debian.local 353 test6851 = #convos :test6851 @batman
:hybrid8.debian.local 353 test6851 = #convos :@bar +foo %super
:hybrid8.debian.local 366 test6851 #convos :End of /NAMES list.
