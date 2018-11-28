my $load_mode = $ENV{PLACK_ENV};
my $app = sub {
    my $env = shift;
    my @headers = (
      'Content-Type'  => 'text/plain',
      'X-Extra-Reply' => $env->{HTTP_X_EXTRA_HEADER},
      'X-Load-Mode'   => $load_mode,
      'X-Req-Mode'    => $ENV{PLACK_ENV},
    );
    return [200, \@headers, ["hello, world\n"]];
}
