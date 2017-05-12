use Test::Mojo::IRC -ua;

my $t      = Test::Mojo::IRC->new;
my $server = $ENV{TEST_IRC_SERVER} || $t->start_server;
my $irc    = Mojo::IRC::UA->new(server => $server, user => "test$$");

my $err = 'somethingweird';
$irc->part_channel("", sub { $err = $_[1]; Mojo::IOLoop->stop });
Mojo::IOLoop->start;
is $err, 'Cannot part without channel name.', 'channel name missing';

$err = 'somethingweird';
$irc->part_channel("channel with space", sub { $err = $_[1]; Mojo::IOLoop->stop });
Mojo::IOLoop->start;
is $err, 'Cannot part channel with spaces.', 'channel name with whitespace';

$irc->connect(sub { Mojo::IOLoop->stop });
Mojo::IOLoop->start;

$t->run(
  [qr{USER} => ['main', 'join.irc']],
  sub {
    $err = 'somethingweird';
    $irc->join_channel("#test123", sub { $err = $_[1]; Mojo::IOLoop->stop });
    Mojo::IOLoop->start;
    is $err, '', 'channel joined';
  }
);

$t->run(
  [qr{PART} => ['main', 'not-on-that-channel.irc']],
  sub {
    $err = 'somethingweird';
    $irc->part_channel("#foo", sub { $err = $_[1]; Mojo::IOLoop->stop });
    Mojo::IOLoop->start;
    is $err, 'You are not on that channel', 'need to join first';
  }
);

$t->run(
  [qr{PART} => ['main', 'part.irc']],
  sub {
    $err = 'somethingweird';
    $irc->part_channel("#test123", sub { $err = $_[1]; Mojo::IOLoop->stop });
    Mojo::IOLoop->start;
    is $err, '', 'channel parted';
  }
);

done_testing;

__DATA__
@@ join.irc
:test21362!test21362@i.love.debian.org JOIN :#test123
:hybrid8.debian.local 332 test21362 #test123 :some cool topic
:hybrid8.debian.local 333 test21362 #test123 jhthorsen!jhthorsen@i.love.debian.org 1432932059
:hybrid8.debian.local 353 test21362 = #test123 :Test21362 @batman
:hybrid8.debian.local 366 test21362 #test123 :End of /NAMES list.
@@ not-on-that-channel.irc
:hades.arpa 442 test21362 #foo :You are not on that channel
@@ part.irc
:test21362!~test96908@0::1 PART #test123
