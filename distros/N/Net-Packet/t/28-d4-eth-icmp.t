use Test;
BEGIN { plan(tests => 1) }

skip(! $ENV{NP_DO_TEST} ? 'Skip since env variable NP_DO_TEST=0' : '', sub {
   my $ok;
   use Net::Packet::Env qw($Env);
   use Net::Packet::Consts qw(:desc);

   $Env->dev($ENV{NP_ETH_DEV});
   $Env->ip ($ENV{NP_ETH_IP});
   $Env->debug(3) if $ENV{NP_DEBUG};

   require Net::Packet::DescL4;
   my $d4 = Net::Packet::DescL4->new(
      target   => $ENV{NP_ETH_TARGET_IP},
      protocol => NP_DESC_IPPROTO_ICMPv4,
   );

   require Net::Packet::ICMPv4;
   require Net::Packet::Frame;

   my $l4 = Net::Packet::ICMPv4->new(
      data => 'test0',
   );

   my $frame = Net::Packet::Frame->new(l4 => $l4);
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
