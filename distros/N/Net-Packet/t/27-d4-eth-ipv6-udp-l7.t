use Test;
BEGIN { plan(tests => 1) }

skip(! $ENV{NP_DO_TEST6} ? 'Skip since env variable NP_DO_TEST6=0' : '', sub {
   my $ok;
   use Net::Packet::Env qw($Env);
   use Net::Packet::Consts qw(:desc :layer);

   $Env->dev($ENV{NP_ETH_DEV});
   $Env->ip6($ENV{NP_ETH_IP6});
   $Env->debug(3) if $ENV{NP_DEBUG};

   require Net::Packet::DescL4;
   my $d4 = Net::Packet::DescL4->new(
      target   => $ENV{NP_ETH_TARGET_IP6},
      protocol => NP_DESC_IPPROTO_UDP,
      family   => NP_LAYER_IPv6,
   );

   require Net::Packet::UDP;
   require Net::Packet::Layer7;
   require Net::Packet::Frame;

   my $l4 = Net::Packet::UDP->new(
      dst => $ENV{NP_ETH_TARGET_PORT},
   );

   my $l7 = Net::Packet::Layer7->new(
      data => 'test0',
   );

   my $frame = Net::Packet::Frame->new(l4 => $l4, l7 => $l7);
   $frame->send;

#  XXX: waiting ICMPv6
#  until ($Env->dump->timeout) {
#     if ($frame->recv) {
#        $ok++;
#        last;
#     }
#  }

   $Env->dump->stop;
   $Env->dump->clean;

   ++$ok;
});
