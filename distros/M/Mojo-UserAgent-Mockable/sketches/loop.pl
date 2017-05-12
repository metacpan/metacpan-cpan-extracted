use 5.016;
use Mojo::IOLoop;

Mojo::IOLoop->server(
    { port => 3000 } => sub {
        my ( $loop, $stream ) = @_;
        $stream->on(
            read => sub {
                my ( $stream, $chunk ) = @_;
                say qq{GOT CHUNK $chunk};
                $stream->write('HTTP/1.1 200 OK');
            }
        );
    }
);
Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

