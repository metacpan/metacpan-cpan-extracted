use strict;
use warnings;

my $app = sub {
  my $env = shift;
  return sub {
    my $responder = $_[0];
    sleep 1;
    $responder->([ 201, ['Content-Type' => 'text/html'], ['Foo Bar'] ]);
  };
};