use v5.36;
use Mojo::IOLoop;
use Socket::More::Resolver {prefork=>1, max_workers=>5};

Mojo::IOLoop->recurring(2, sub {
  getaddrinfo("rmbp.local", 80, {}, sub {
    #use Data::Dumper;

    #say Dumper @_;
    say "callback";
  })
  
});

say "sTARTING LOOP";
Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
