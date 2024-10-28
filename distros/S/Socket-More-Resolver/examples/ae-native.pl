use v5.36;
use AnyEvent;
use Net::DNS::Native;
use Socket;
 
my $dns = Net::DNS::Native->new;
 
 
#for my $host ('google.com', 'google.ru', 'google.cy') {
my $host="www.google.com";
say "asf";
my $fh = $dns->getaddrinfo($host);
say fileno $fh;     
my $w; $w = AE::io fileno($fh), 0, sub {
      my $ip = $dns->get_result($fh);
      say "READ ready $ip";
      warn $host, $ip ? " has ip " . inet_ntoa($ip) : " has no ip";

};
my $cv=AE::cv; 
$cv->recv;
