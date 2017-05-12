#!perl
use strict;
use warnings;
use Test::More 0.87_01;
use HTTP::Request::Common 'GET';
use Plack::Test 'test_psgi';
use Plack::Builder;

my $x;
my $app = builder {
  enable 'Cleanup';
  sub {
    my $env = shift;
    $env->{'cleanup.register'}->(sub { $x++ });
    return sub {
      my $respond = shift;
      my $writer = $respond->([200,[]]);
      ok( ! $x );
      $writer->write("some data");
      ok( ! $x );
      $writer->close;
      ok( ! $x );
    };
  };
};

test_psgi $app, sub {
  my $cb = shift;
  my $res = $cb->(GET '/');
  ok( $x );
};

done_testing;
