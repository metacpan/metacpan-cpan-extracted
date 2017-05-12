use Test;
BEGIN { plan tests => 1 };

use Net::Write::Fast;

skip(
   $< != 0 ? "Skip as non-root user" : 0,
   sub {
      eval {
         my $r = Net::Write::Fast::l4_send_tcp_syn_multi(
            '127.0.0.1',     # source IP
            [ '127.0.0.1' ], # destination IP list
            [ 11 ],          # destination port list
            200,             # packets per second
            3,               # number of tries
            0,               # use IPv6 (or not)
            1,               # enable warnings
         );
         if ($r == 0) {
            die(Net::Write::Fast::nwf_geterror()."\n");
         }
      };
      if ($@) {
         return 0;   # NOK
      }
      return 1;   # OK
   },
   1,
   $@,
);
