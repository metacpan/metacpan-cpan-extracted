use Test;
BEGIN { plan(tests => 1) }

skip(! $ENV{NP_DO_TEST} ? 'Skip since env variable NP_DO_TEST=0' : '', sub {
   my $ok;
   use Net::Packet::Env qw($Env);
   use Net::Packet::Consts qw(:ipv4);

   $Env->dev($ENV{NP_LO_DEV});
   $Env->ip ($ENV{NP_LO_IP});
   $Env->debug(3) if $ENV{NP_DEBUG};

   require Net::Packet::IPv4;
   require Net::Packet::UDP;
   require Net::Packet::Frame;

   my $l3 = Net::Packet::IPv4->new(
      dst      => $ENV{NP_LO_TARGET_IP},
      protocol => NP_IPv4_PROTOCOL_UDP,
   );

   my $l4 = Net::Packet::UDP->new(
      dst => $ENV{NP_LO_TARGET_PORT},
   );

   my $frame = Net::Packet::Frame->new(l3 => $l3, l4 => $l4);
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
