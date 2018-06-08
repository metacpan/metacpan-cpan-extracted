# use IO::Socket::SSL qw(debug3);
use Mojo::Base -strict;
use Mojo::APNS;
use Mojo::IOLoop;
use Mojo::JSON 'j';
use Data::Dumper ();
use File::Basename;
use Test::More;

my $dir = File::Spec->catdir(dirname($INC{'Mojo/IOLoop/Stream.pm'}), 'resources');
my $port = Mojo::IOLoop::Server->generate_port;
my ($err, @messages);

plan skip_all => 'Could not find Mojo cert' unless -e "$dir/server.crt";
plan skip_all => 'Could not find Mojo key'  unless -e "$dir/server.key";

Mojo::IOLoop->server(
  port     => $port,
  address  => '127.0.0.1',
  tls      => 1,
  tls_cert => "$dir/server.crt",
  tls_key  => "$dir/server.key",
  sub {
    my ($loop, $stream, $id) = @_;
    $stream->on(
      read => sub {
        my ($stream, $buf) = @_;

        while ($buf =~ s/^\0//) {
          my $message = {};
          $message->{pack32} = unpack 'n',  substr $buf, 0, 2,  '';
          $message->{token}  = unpack 'H*', substr $buf, 0, 32, '';
          $message->{length} = unpack 'n',  substr $buf, 0, 2,  '';
          $message->{message} = substr $buf, 0, $message->{length}, '';
          $message->{json} = j delete $message->{message};
          push @messages, $message;
        }

        Mojo::IOLoop->stop if @messages == 2;
      }
    );
  },
);

my $apns = Mojo::APNS->new(
  key              => "$dir/server.key",
  cert             => "$dir/server.crt",
  insecure         => 1,
  sandbox          => 1,
  _gateway_address => '127.0.0.1',
  _gateway_port    => $port,
);

$apns->on(error => sub { diag "ERROR: $_[1]"; $_[0]->ioloop->stop; });

$apns->send(
  "c9d4a07c fbbc21d6 ef87a47d 53e16983 1096a5d5 faa15b75 56f59ddd a715dff4",
  "tooooooooooooooooooooooooooooooooooooooooooooooooo looooooooooooooooooooooooooooong meeeeeeeeeeeeeeeeeeeeeesssssssssssssssssssssaaaaaaaaaaaaaaaaaaaaaaaaaaaage",
  badge  => 2000000000000000,
  other  => 'stuff',
  also   => 'takes up',
  length => 1234567890,
  sub {
    my ($apns, $error) = @_;
    like $error, qr{too long}i, 'got too long message error';
  },
);

$apns->send("c9d4a07c fbbc21d6 ef87a47d 53e16983 1096a5d5 faa15b75 56f59ddd a715dff4", "New cool stuff!", badge => 2,);

$apns->send(
  "19d4    a07afbbc21d6 ef87a47d 53e169831096a5d5 faa15b75 56f59ddd a715dff3", "More arguments",
  badge             => 2,
  content_available => 1,
  sound             => 'cool',
);

$apns->ioloop->start;

is_deeply(
  \@messages,
  [
    {
      pack32 => 32,
      token  => 'c9d4a07cfbbc21d6ef87a47d53e169831096a5d5faa15b7556f59ddda715dff4',
      length => 45,
      json   => {aps => {alert => 'New cool stuff!', badge => 2}},
    },
    {
      pack32 => 32,
      token  => '19d4a07afbbc21d6ef87a47d53e169831096a5d5faa15b7556f59ddda715dff3',
      length => 81,
      json   => {aps => {'content-available' => 1, sound => 'cool', badge => 2, alert => 'More arguments'}},
    },
  ],
  'got messages',
) or diag Data::Dumper::Dumper(\@messages);

done_testing;
