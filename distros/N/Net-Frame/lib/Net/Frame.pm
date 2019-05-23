#
# $Id: Frame.pm,v ce68fbcc7f6d 2019/05/23 05:58:40 gomor $
#
package Net::Frame;
use strict;
use warnings;

our $VERSION = '1.21';

1;

__END__

=head1 NAME

Net::Frame - the base framework for frame crafting

=head1 SYNOPSIS

   # Basic example, send a TCP SYN to a target, using all modules
   # the framework comprises. It also waits for the response, and 
   # prints it.

   my $target = '192.168.0.1';
   my $port   = 22;

   use Net::Frame::Device;
   use Net::Write::Layer3;
   use Net::Frame::Simple;
   use Net::Frame::Dump::Online;

   use Net::Frame::Layer::IPv4;
   use Net::Frame::Layer::TCP;

   my $oDevice = Net::Frame::Device->new(target => $target);

   my $ip4 = Net::Frame::Layer::IPv4->new(
      src => $oDevice->ip,
      dst => $target,
   );
   my $tcp = Net::Frame::Layer::TCP->new(
      dst     => $port,
      options => "\x02\x04\x54\x0b",
      payload => 'test',
   );
   my $oWrite = Net::Write::Layer3->new(dst => $target);

   my $oDump = Net::Frame::Dump::Online->new(dev => $oDevice->dev);
   $oDump->start;

   my $oSimple = Net::Frame::Simple->new(
      layers => [ $ip4, $tcp ],
   );
   $oWrite->open;
   $oSimple->send($oWrite);
   $oWrite->close;

   until ($oDump->timeout) {
      if (my $recv = $oSimple->recv($oDump)) {
         print "RECV:\n".$recv->print."\n";
         last;
      }
   }

   $oDump->stop;

=head1 DESCRIPTION

B<Net::Frame> is a fork of B<Net::Packet>. The goal here was to greatly simplify the use of the frame crafting framework. B<Net::Packet> does many things undercover, and it was difficult to document all the thingies.

Also, B<Net::Packet> may suffer from unease of use, because frames were assembled using layers stored in L2, L3, L4 and L7 attributes. B<Net::Frame> removes all this, and is split into different modules, for those who only want to use part of the framework, and not whole framework.

Finally, anyone can create a layer, and put it on his CPAN space, because of the modularity B<Net::Frame> offers. For an example, see B<Net::Frame::Layer::ICMPv4> on my CPAN space.

B<Net::Frame> does ship with basic layers, to start playing.

=head1 SEE ALSO

L<Net::Frame::Simple>, L<Net::Frame::Device>, L<Net::Frame::Layer>, L<Net::Frame::Dump>, L<Net::Frame::Layer::IPv4>, L<Net::Frame::Layer::TCP>, L<Net::Write>

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2019, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
