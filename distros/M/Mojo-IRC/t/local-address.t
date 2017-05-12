use Mojo::Base -strict;
use Mojo::IRC;
use Test::More;

$ENV{MOJO_IRC_CONNECT_TIMEOUT} = 42;
my $irc = Mojo::IRC->new(server => '127.0.0.1', local_address => '10.20.30.40');

is $irc->local_address, '10.20.30.40', 'local_address';

my @args;
Mojo::Util::monkey_patch('Mojo::IOLoop', 'client', sub { @args = @_ });
$irc->connect(sub { });

shift @args;    # class
pop @args;      # $cb

is_deeply(
  \@args,
  [address => '127.0.0.1', port => '6667', timeout => 42, local_address => '10.20.30.40'],
  'connect with local_address',
);

done_testing;
