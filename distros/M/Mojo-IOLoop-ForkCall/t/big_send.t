BEGIN { $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll' }

use Test::More;

use Mojo::IOLoop;
use Mojo::IOLoop::ForkCall;

sub gen_string {
  my $l = shift || 1e6;
  my @chars = ("A".."Z", "a".."z");
  my $string;
  while (length $string < $l) {
    $string .= $chars[rand @chars];
  }
  return $string;
}

my $s = gen_string;
ok length $s > 65536, 'test is useful';

my $got;

my $fc = Mojo::IOLoop::ForkCall->new;
$fc->run(
  sub { sleep 1; return $s },
  sub { $got = pop; Mojo::IOLoop->stop }
);

Mojo::IOLoop->start;

is $got, $s, 'got large string back';

done_testing;

