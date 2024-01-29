use v5.36;
use Data::Dumper;
use Time::HiRes qw<sleep>;
use Socket::More::Resolver {prefork=>0, max_workers=>100};

my $addr;
for(1..100){
  say "";
  say "user loop";
  getaddrinfo("rmbp.local", 80, {}, sub {
    say "===USER CALLBACK===";
    #say Dumper $_[0]
    $addr=$_[0]{addr};
    say unpack "H*", $addr;
  },
  sub {
    say "=====ERROR====";
  });
  sleep 0.1;
}

say "OIJSDF";
while(getaddrinfo){
  sleep 0.5;
}
