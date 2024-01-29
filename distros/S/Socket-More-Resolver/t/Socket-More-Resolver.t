use strict;
use warnings;

use Test::More;
use Time::HiRes qw<sleep>;
#BEGIN { use_ok('Socket::More::Resolver') };

# This tests the polling of the resolver. 

use Socket::More::Resolver {max_workers=>5};

use Data::Dumper;
my $run=1;
getaddrinfo("www.google.com",0, {},
  sub { 
    ok 1, "Resolved google";
    getnameinfo($_[0]{addr}, 0, {}, sub {
        ok 1, "Resolved google";
        $run=0;
    },
    sub {
      print STDERR "ERROR FOR NAME:", gai_strerror $_[0];
    });
  },
  sub {
  # print STDERR Dumper @_;
    $run=0;
  }
);

sleep 0.1 and getaddrinfo while($run);
done_testing;
