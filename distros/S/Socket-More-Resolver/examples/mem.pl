use v5.36;
use Import::These qw<Socket::More:: Lookup Constants>;

use Time::HiRes qw<sleep>;

while(){
  my @results;
  getaddrinfo("rmbp.local", "80", {hints=>NI_NUMERICHOST}, @results);
  say "loop";
  sleep 0.01;
}
