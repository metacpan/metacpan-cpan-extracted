use strict;
use warnings;

my $app = sub {
  my $env = shift;

  if ($env->{REQUEST_METHOD} eq 'POST' && $env->{PATH_INFO} eq '/submit') {
      my $request_body = '';
      if (exists $env->{'psgi.input'}) {
          my $input = $env->{'psgi.input'};
          while (my $line = <$input>) {
              $request_body .= $line;
          }
      }

      return [
          200,
          ['Content-Type' => 'text/plain'],
          ["Received POST data:\n$request_body"],
      ];
  }

  use DDP;
  p $env;

  return sub {
    my $responder = $_[0];
    my $writer = $responder->([ 201, ['Content-Type' => 'text/html'] ]);
    sleep 2;
    $writer->write("<html><body><h1>Hello from Plack::Handler::H2!</h1><p>This is a streamed response served over HTTP/2.</p>");
    sleep 2;
    $writer->write("<p>Streaming data in chunks...</p>");
    sleep 2;
    $writer->write("<p>Final chunk of data.</p></body></html>");
    $writer->close();
  };
};