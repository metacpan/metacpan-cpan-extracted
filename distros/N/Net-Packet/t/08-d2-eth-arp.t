use Test;
BEGIN { plan(tests => 1) }

skip(! $ENV{NP_DO_TEST} ? 'Skip since env variable NP_DO_TEST=0' : '', sub {
   my $ok;
   use Net::Packet::Env qw($Env);
   use Net::Packet::Consts qw(:eth :arp);

   $Env->dev($ENV{NP_ETH_DEV});
   $Env->ip ($ENV{NP_ETH_IP});
   $Env->mac($ENV{NP_ETH_MAC});
   $Env->debug(3) if $ENV{NP_DEBUG};

   require Net::Packet::ETH;
   require Net::Packet::ARP;
   require Net::Packet::Frame;

   my $l2 = Net::Packet::ETH->new(
      type => NP_ETH_TYPE_ARP,
   );

   my $l3 = Net::Packet::ARP->new(
      opCode => NP_ARP_OPCODE_REQUEST,
      dstIp  => $ENV{NP_ETH_TARGET_IP},
   );

   my $frame = Net::Packet::Frame->new(l2 => $l2, l3 => $l3);
   $frame->send;

   until ($Env->dump->timeout) {
      if ($frame->recv) {
         $ok++;
         last;
      }
   }

   $Env->dump->stop;
   $Env->dump->clean;

   $ok;
});
