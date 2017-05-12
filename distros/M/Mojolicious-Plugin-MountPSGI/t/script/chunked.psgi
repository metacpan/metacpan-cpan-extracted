my $app = sub {
  return sub {
    my $responder = shift;
    my $writer = $responder->([200, ['Content-Type' => 'text/plain', 'Transfer-Encoding' => 'chunked']]);
    $writer->write("hello, world\n");
    $writer->close;
  };
}
