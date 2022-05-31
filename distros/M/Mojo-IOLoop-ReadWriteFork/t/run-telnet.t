use Mojo::Base -strict;
use Mojo::IOLoop;
use Mojo::IOLoop::ReadWriteFork;
use Test::More;

$ENV{PATH} ||= '';
plan skip_all => 'telnet is missing' unless grep { -x "$_/telnet" } split /:/, $ENV{PATH};

my $address = '127.0.0.1';
my $port    = Mojo::IOLoop::Server->generate_port;
my ($connected, $exit_value, $signal) = (0);

# echo server
Mojo::IOLoop->server(
  {address => $address, port => $port},
  sub {
    my ($ioloop, $stream) = @_;
    $stream->on(
      read => sub {
        my ($stream, $chunk) = @_;
        $stream->write("I heard you say: $chunk");
      }
    );
  }
);

my $rwf = Mojo::IOLoop::ReadWriteFork->new;
my ($drain, $output) = (0, '');

$rwf->on(finish => sub { ($exit_value, $signal) = @_[1, 2]; Mojo::IOLoop->stop });
$rwf->on(
  read => sub {
    my ($rwf, $chunk) = @_;
    $rwf->write("hey\r\n", sub { $drain++; }) if $chunk =~ /Connected/;
    $rwf->kill(15)                            if $chunk =~ /I heard you say/;
    $output .= $chunk;
  }
);

$rwf->start(program => 'telnet', program_args => [$address, $port], conduit => 'pty',);

my $guard;
Mojo::IOLoop->timer(1 => sub { $guard++; Mojo::IOLoop->stop });    # guard
Mojo::IOLoop->start;
plan skip_all => 'Saved by guard' if $guard;

like $output, qr{Connected},              'Connected';
like $output, qr{I heard you say:.*hey}s, 'got echo';
is $drain,      1,  'got drain event';
is $exit_value, 0,  'exit_value';
is $signal,     15, 'signal';

done_testing;
