# use IO::Socket::SSL qw(debug3);
use Mojo::Base -strict;
use Mojo::APNS;
use Test::More;
use File::Basename;
use Mojo::IOLoop::Stream;

my $dir = File::Spec->catdir(dirname($INC{'Mojo/IOLoop/Stream.pm'}), 'resources');
my $port = Mojo::IOLoop::Server->generate_port;
my $message;

plan skip_all => 'Could not find Mojo cert' unless -e "$dir/server.crt";
plan skip_all => 'Could not find Mojo key'  unless -e "$dir/server.key";

my $time   = time;
my $device = 'c9d4a07cfbbc21d6ef87a47d53e169831096a5d5faa15b7556f59ddda715dff4';
my ($apns, @cb);

Mojo::IOLoop->server(
  port     => $port,
  address  => '127.0.0.1',
  tls      => 1,
  tls_cert => "$dir/server.crt",
  tls_key  => "$dir/server.key",
  sub {
    my ($loop, $stream, $id) = @_;
    $stream->write(pack 'N n/a', $time, $device);
  },
);

$apns = Mojo::APNS->new(
  key              => "$dir/server.key",
  cert             => "$dir/server.crt",
  sandbox          => 1,
  _gateway_address => '127.0.0.1',
  _feedback_port   => $port,
);

$apns->ioloop->timer(
  0 => sub {
    $apns->on(error => sub { diag "ERROR: $_[1]"; $_[0]->ioloop->stop; });
    $apns->on(feedback => sub { @cb = @_; $apns->ioloop->stop; });
  }
);

$apns->ioloop->start;

isa_ok($cb[0], 'Mojo::APNS');
is $cb[1]->{ts},     $time,   'got ts';
is $cb[1]->{device}, $device, 'got device';

done_testing;
