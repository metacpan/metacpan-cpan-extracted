use v5.36;
use IO::Async::Loop;
use IO::Async::Timer::Periodic;

use Socket::More::Resolver {prefork=>0, max_workers=>10};

my $loop=IO::Async::Loop->new;


$loop->add($Socket::More::Resolver::Shared);

my $timer=IO::Async::Timer::Periodic->new(interval=>1, on_tick=>sub {
say "asdf";
  getaddrinfo("rmbp23.local", "80", {}, sub {
    #use Data::Dumper;
    #say Dumper @_;
    say "CALLBACK";
  },
  sub {
    say "on error";
}
)

});


$timer->start;
$loop->add($timer);

$loop->run;
