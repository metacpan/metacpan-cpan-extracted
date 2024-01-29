use v5.36;

use Time::HiRes qw<time>;
use AnyEvent;
use Socket::More::Resolver {prefork=>1};
use Getopt::Long;





my $host="www.google.com";
my $port;
my $counter=100;
GetOptions "host=s"=>\$host;

my $cv=AE::cv;

my $start=time;
my $t;

sub do_it;


sub do_it {
  getaddrinfo($host, 0, undef, sub {
    if($counter--){
      $t=AE::timer 0,0, \&do_it; 
    }
    else{
      $cv->send;
    }
  },
  sub {
    say "ERROR ", gai_strerror $_[0];
  }
);
}
do_it;
$cv->recv;
say time-$start;



