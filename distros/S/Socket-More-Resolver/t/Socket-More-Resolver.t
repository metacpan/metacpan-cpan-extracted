use strict;
use warnings;

use feature "say";
use Test::More;
use Time::HiRes qw<sleep>;
#BEGIN { use_ok('Socket::More::Resolver') };

# This tests the polling of the resolver. 

use Socket::More::Resolver {max_workers=>5};

use Data::Dumper;
my $run=2;
getaddrinfo("www.google.com",0, {},
  sub { 
    ok 1, "Resolved google";
    getnameinfo($_[0]{addr}, 0, sub {
        say STDERR "name info test",Dumper $_[0];
        ok 1, "Resolved google";
        $run--;
    },
    sub {
      print STDERR "ERROR FOR NAME:", gai_strerror $_[0];
      $run=0;
    });
  },
  sub {
  # print STDERR Dumper @_;
    $run=0;
  }
);

getaddrinfo("localhost",0, {}, sub {
    ok 1, "Resolved localhost";
    getnameinfo($_[0]{addr}, 0, sub {
        ok 1, "Resolved localhost";
        $run--;
    },
    sub {
      print STDERR "ERROR FOR NAME:", gai_strerror $_[0];
      $run=0;
    });
  },
  sub {
  # print STDERR Dumper @_;
    $run=0;
  }
);

sleep 0.1 and getaddrinfo while($run);
done_testing;
