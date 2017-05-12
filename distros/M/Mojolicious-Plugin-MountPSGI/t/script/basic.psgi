my $app = sub {
    my $env = shift;
    my $hvalue = $env->{HTTP_X_EXTRA_HEADER};
    return [200, ['Content-Type' => 'text/plain', 'X-Extra-Reply' => $hvalue], ["hello, world\n"]];
}
