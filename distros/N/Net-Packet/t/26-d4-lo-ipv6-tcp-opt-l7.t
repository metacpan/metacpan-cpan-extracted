use Test;
BEGIN { plan(tests => 1) }

skip(! $ENV{NP_DO_TEST6} ? 'Skip since env variable NP_DO_TEST6=0' : '', sub {
   my $ok;
   use Net::Packet::Env qw($Env);
   use Net::Packet::Consts qw(:desc :layer);

   $Env->dev($ENV{NP_LO_DEV});
   $Env->ip6($ENV{NP_LO_IP6});
   $Env->debug(3) if $ENV{NP_DEBUG};

   require Net::Packet::DescL4;
   my $d4 = Net::Packet::DescL4->new(
      target => $ENV{NP_LO_TARGET_IP6},
      family => NP_LAYER_IPv6,
   );

   require Net::Packet::TCP;
   require Net::Packet::Layer7;
   require Net::Packet::Frame;

   my $l4 = Net::Packet::TCP->new(
      dst => $ENV{NP_LO_TARGET_PORT},
      options => "\x02\x04\x05\xb4",
   );

   my $l7 = Net::Packet::Layer7->new(
      data => 'test0',
   );

   my $frame = Net::Packet::Frame->new(l4 => $l4, l7 => $l7);
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
