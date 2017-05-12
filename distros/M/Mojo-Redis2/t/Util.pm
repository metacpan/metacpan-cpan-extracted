package t::Util;

sub compile_lite_app {
  require Mojo::Redis2;
  open my $POD, '<', $INC{'Mojo/Redis2.pm'} or die "Could not read Mojo/Redis2.pm: $@";
  my $code = '';

  while (<$POD>) {
    last if $code and /app->start/;
    $code = 'package main;' if /^\s+use Mojolicious::Lite/;
    $code .= $_ if $code;
    next unless $code;
  }

  eval $code or die "$code\n\n\n$@";
}

sub get_documented_redis_methods {
  require Mojo::Redis2;
  open my $POD, '<', $INC{'Mojo/Redis2.pm'} or die "Could not read Mojo/Redis2.pm: $@";
  my ($capture, %ops);
  my $re = qr{\W*(\w+)(?:\,|\.|\sand)};

  while (<$POD>) {
    last if $capture and /^=\w+/;
    $capture = 1 if /^=head1 METHODS/;
    next unless $capture;
    next unless /^$re/;
    $ops{$1}++ while /$re/g;
  }

  return %ops;
}

1;
