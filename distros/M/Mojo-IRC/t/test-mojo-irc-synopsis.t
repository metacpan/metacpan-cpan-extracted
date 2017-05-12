use Test::Mojo::IRC -basic;

my $t      = Test::Mojo::IRC->new;
my $server = $t->start_server;
my $irc    = Mojo::IRC->new(server => $server);

# simulate server/client communication
$t->run(
  [
    # Send "welcome.irc" from the DATA section when client sends "NICK"
    qr{\bNICK\b} => ["main", "motd.irc"],
  ],
  sub {
    my $err;
    my $motd = 0;
    $t->on($irc, irc_rpl_motd      => sub { $motd++ });
    $t->on($irc, irc_rpl_endofmotd => sub { Mojo::IOLoop->stop; });    # need to manually stop the IOLoop
    $irc->connect(sub { $err = $_[1]; });
    Mojo::IOLoop->start;                                               # need to manually start the IOLoop
    is $err,  "", "connected";
    is $motd, 3,  "message of the day";
  },
);

# extra code to test on()
ok !$irc->has_subscribers('irc_rpl_motd'), 'irc_rpl_motd event removed';

done_testing;
__DATA__
@@ motd.irc
:spectral.shadowcat.co.uk 375 test123 :- spectral.shadowcat.co.uk Message of the Day -
:spectral.shadowcat.co.uk 372 test123 :- We scan all connecting clients for open proxies and other
:spectral.shadowcat.co.uk 372 test123 :- exploitable nasties. If you don't wish to be scanned,
:spectral.shadowcat.co.uk 372 test123 :- don't connect again, and sorry for scanning you this time.
:spectral.shadowcat.co.uk 376 test123 :End of /MOTD command.
