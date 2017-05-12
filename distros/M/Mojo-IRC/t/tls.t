use strict;
use warnings;
use Mojo::IRC;
use Test::More;

plan skip_all => 'Need TEST_TLS=1' unless $ENV{TEST_TLS};

my $irc = Mojo::IRC->new;
my $err;

is $irc->tls, undef, 'tls is disabled by default';

$irc->server('irc.freenode.net:7000');
$irc->nick('mojo-irc-' . int rand 1000);
$irc->tls({});
$irc->connect(sub { (my $irc, $err) = @_; Mojo::IOLoop->stop; });

ok $irc->{stream_id}, 'stream_id is set';

$err = 'ioloop-failed';
Mojo::IOLoop->timer(1 => sub { Mojo::IOLoop->stop; });
Mojo::IOLoop->start;
is $err, '', 'no error';

done_testing;
