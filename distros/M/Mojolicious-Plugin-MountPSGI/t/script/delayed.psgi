my $app = sub {
  return sub {
    my $responder = shift;
    $responder->([200, ['Content-Type' => 'text/plain'], ["hello, world\n"]]);
  };
}
