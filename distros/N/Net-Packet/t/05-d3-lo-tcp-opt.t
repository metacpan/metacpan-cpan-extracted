use Test;
BEGIN { plan(tests => 1) }

skip(! $ENV{NP_DO_TEST} ? 'Skip since env variable NP_DO_TEST=0' : '', sub {
   my $ok;
   use Net::Packet::Env qw($Env);

   $Env->dev($ENV{NP_LO_DEV});
   $Env->ip ($ENV{NP_LO_IP});
   $Env->debug(3) if $ENV{NP_DEBUG};

   require Net::Packet::IPv4;
   require Net::Packet::TCP;
   require Net::Packet::Frame;

   my $l3 = Net::Packet::IPv4->new(
      dst => $ENV{NP_LO_TARGET_IP},
   );

   my $l4 = Net::Packet::TCP->new(
      dst => $ENV{NP_LO_TARGET_PORT},
      options => "\x02\x04\x05\xb4",
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
