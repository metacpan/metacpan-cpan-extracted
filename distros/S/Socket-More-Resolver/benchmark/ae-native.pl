use v5.36;

use Time::HiRes qw<time>;
use AnyEvent;
use Net::DNS::Native;
use Getopt::Long;

use Socket;
my $dns = Net::DNS::Native->new;
 

my $host="www.google.com";
my $port;
my $counter=100;
GetOptions "host=s"=>\$host;

 
#for my $host ('google.com', 'google.ru', 'google.cy') {
my $cv=AE::cv; 
my $start=time;
my $t;
my $w;
my $fh;
sub do_it;

sub do_it {
  $fh = $dns->getaddrinfo($host);
  $w = AE::io fileno($fh), 0, sub {
        my @ip = $dns->get_result($fh);
        $w=undef;
        $fh=undef;
        if($counter--){
          $t=AE::timer 0, 0, \&do_it;
        }
        else{
          $cv->send;
        }
  };
}
do_it;
$cv->recv;
say time-$start;
