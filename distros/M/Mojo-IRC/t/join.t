use Test::Mojo::IRC -basic;

plan skip_all => 'No test data' unless -r 't/data/irc.perl.org';

my $t   = Test::Mojo::IRC->start_server;
my $irc = Mojo::IRC->new(server => $t->server);
my $err = '';
my ($message, @any, %got);

isa_ok($irc, 'Mojo::IRC', 'Constructor returns right object');
$irc->nick('test123');
is $irc->nick, 'test123', 'nick setter works';
$irc->user('my name');
is $irc->server, $t->server, 'server setter works';

$irc->on(message => sub { push @any, $_[1] });
$irc->on(irc_join => sub { (my $self, $message) = @_; Mojo::IOLoop->stop; });
$irc->on(irc_rpl_motdstart => sub { $got{rpl_motdstart}++ });
$irc->on(irc_rpl_motd      => sub { $got{rpl_motd}++ });
$irc->on(irc_rpl_endofmotd => sub { $got{rpl_endofmotd}++ });

$t->run(
  [qr{\bNICK\b} => \'t/data/welcome', qr{\bJOIN\b} => \'t/data/join.mojo'],
  sub {
    my $err;
    $irc->connect(sub { $err = $_[1]; $irc->write(JOIN => '#mojo'); });
    Mojo::IOLoop->start unless $message;
    is $err, '', 'connected';
  },
);

is_deeply $message->{params}, ['#mojo'], 'got join #mojo event';
is $message->{prefix}, 'test123!~my@1.2.3.4.foo.com', '...with prefix';
is $got{rpl_motdstart}, 1,  'motdstart event';
is $got{rpl_motd},      19, 'motd events';
is $got{rpl_endofmotd}, 1,  'endofmotd event';

#is $read, "NICK test123\r\nUSER my name 8 * :Mojo IRC\r\nJOIN #mojo\r\n", 'nick, user and join got sent';
is + ($err || ''), '', 'no error';
is @any, 40, 'messages';

done_testing;
