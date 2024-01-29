use v5.36;
use AnyEvent;
use Socket::More::Resolver {prefork=>0, max_workers=>3};
use Socket::More::Lookup qw<gai_strerror>;
use Data::Dumper;

my $timer;
my $sub=sub { 
  #say Dumper @_
  say "CALLBACK-->".Dumper @_;
};

$timer=AE::timer 0, 0.1, sub {
  getaddrinfo("rmbp.local", 80, {}, $sub, sub {
    say "GOT ERROR: $_[0]";
    say gai_strerror($_[0]);
  });
};
my $cv=AE::cv;
$cv->recv;
