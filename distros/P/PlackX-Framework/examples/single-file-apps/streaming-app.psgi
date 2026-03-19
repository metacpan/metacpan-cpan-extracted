#!perl
use v5.36;
use PXF::Util ();

package StreamingApp {
  use PlackX::Framework;
  use StreamingApp::Router;
  route '/stream-example' => sub ($request, $response) {
    # This part is not streaming
    $response->print("<html><head></head><body>\n");

    # Many browsers will buffer the response until several KB have been sent
    # Some seem to always buffer (Safari), others always stream (Chrome)
    # If server is behind a reverse proxy you have even more to worry about
    $response->print("<!-- Filler -->\n" x 1024);

    # Here is the streaming part
    return $response->render_stream(sub {
      # Only use $response->print() inside the code block
      # Calling other methods on the $response object will not make sense
      # PXF will emulate PSGI streaming if it is not available.
      for my $i (0..5) {
        $response->print("Hello $i<br>\n");
        # Simulate a slow response with sleep
        # sleep 1;
        PXF::Util::minisleep($i/10);
      }
      $response->print("</body></html>\n");
    });
  };
}

StreamingApp->app;

=pod

This is what a similar streaming app would look like with straight PSGI
(minus the html above):

    my $app = sub {
        my $env = shift;
        return sub {
            my $responder = shift;
            my $writer    = $responder->([200, ['Content-Type' => 'text/html']]);
            $writer->write("I am about to stream...\n");
            for my $i (0..10) {
              $writer->write("Hello $i\n");
              sleep 1;
            }
            $writer->close;
        };
    };

PlackX::Framework supports streaming body, but does not support delayed response
at this time (headers are sent immediately).

Simply call $response->stream with a coderef and print your content to the same
response object.

The coderef return value is ignored, but don't forget to return your $response
object at the end of your route action, to send the response headers and
coderef to PXF.

If the server does not support PSGI streaming, then PXF's streaming interface
will be emulated.

The PSGI writer, $response->stream_writer, should not be used directly.

PXF does not handle the Content-Encoding header, but most HTTP 1.1 servers will
take care of this. It has been tested and works correctly with perl/PSGI
servers Starman, Starlet, and Gazelle.

The default plackup server, HTTP::Server::PSGI, is a HTTP 1.0 server and will
not chunk the response. User agents (most consumer-grade web browsers) are more
likely to buffer these responses.

You are encouraged to put newlines at the end of each $response->print call to
encourage the server to clear the buffer and send the line to the client.

Note Plack supports setting the body to an IO-Handle-like object. Mixing this
type of "special" body with PXF print() and body() statements is not supported
and will result in undefined behavior.
