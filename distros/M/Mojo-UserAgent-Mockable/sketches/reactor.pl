use 5.014;
use Mojo::UserAgent;
use Mojo::IOLoop;

my $reactor = Mojo::IOLoop->singleton->reactor;
Mojo::IOLoop->singleton->reactor->io(
  $server => sub {
    my $reactor = shift;

    my $client = $server->accept;
    $client->blocking(0);
    my ($address, $port);
    $reactor->io(
      $client => sub {
        my $reactor = shift;

        my $err = $IO::Socket::Socks::SOCKS_ERROR;
        if ($client->ready) {

          if ($address) {
            $reactor->remove($client);
            Mojo::IOLoop->client(
              {address => $address, port => $port} => sub {
                my ($loop, $err, $server) = @_;
                $last = $server->handle->sockport;
                weaken $server;
                $client = Mojo::IOLoop::Stream->new($client);
                Mojo::IOLoop->stream($client);
                $client->on(read  => sub { $server->write(pop) });
                $client->on(close => sub { $server && $server->close });
                $server->on(read  => sub { $client->write(pop) });
                $server->on(close => sub { $client && $client->close });
              }
            );
          }

          else {
            ($address, $port) = @{$client->command}[1, 2];
            $client->command_reply(IO::Socket::Socks::REPLY_SUCCESS(),
              $address, $port);
          }
        }
        elsif ($err == IO::Socket::Socks::SOCKS_WANT_WRITE()) {
          $reactor->watch($client, 1, 1);
        }
        elsif ($err == IO::Socket::Socks::SOCKS_WANT_READ()) {
          $reactor->watch($client, 1, 0);
        }
      }
    );
  }
);

