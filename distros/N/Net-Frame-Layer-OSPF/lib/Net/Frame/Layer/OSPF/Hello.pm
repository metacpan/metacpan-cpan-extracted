#
# $Id: Hello.pm 73 2015-01-14 06:42:49Z gomor $
#
package Net::Frame::Layer::OSPF::Hello;
use strict; use warnings;

use Net::Frame::Layer qw(:consts :subs);
our @ISA = qw(Net::Frame::Layer);

our @AS = qw(
   networkMask
   helloInterval
   options
   routerPri
   routerDeadInterval
   designatedRouter
   backupDesignatedRouter
   lls
);
our @AA = qw(
   neighborList
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);
__PACKAGE__->cgBuildAccessorsArray (\@AA);

use Net::Frame::Layer::OSPF qw(:consts);

sub new {
   shift->SUPER::new(
      networkMask            => '255.255.255.0',
      helloInterval          => 60,
      options                => 0,
      routerPri              => 0,
      routerDeadInterval     => 120,
      designatedRouter       => '0.0.0.0',
      backupDesignatedRouter => '0.0.0.0',
      neighborList           => [],
      @_,
   );
}

sub getLength {
   my $self = shift;
   my $len = 20;
   for ($self->neighborList) {
      $len += 4;
   }
   $len;
}

sub pack {
   my $self = shift;

   my $raw = $self->SUPER::pack('a4nCCNa4a4',
      inetAton($self->networkMask), $self->helloInterval, $self->options,
      $self->routerPri, $self->routerDeadInterval,
      inetAton($self->designatedRouter),
      inetAton($self->backupDesignatedRouter),
   ) or return undef;

   for ($self->neighborList) {
      $raw .= $self->SUPER::pack('a4', inetAton($_)) or return undef;
   }

   $self->raw($raw);
}

sub unpack {
   my $self = shift;

   my ($netmask, $helloInt, $options, $pri, $deadInt, $desRouter, $backup,
      $payload) = $self->SUPER::unpack('a4nCCNa4a4 a*', $self->raw)
         or return undef;

   $self->networkMask(inetNtoa($netmask));
   $self->helloInterval($helloInt);
   $self->options($options);
   $self->routerPri($pri);
   $self->routerDeadInterval($deadInt);
   $self->designatedRouter(inetNtoa($desRouter));
   $self->backupDesignatedRouter(inetNtoa($backup));

   my @neighborList = ();
   if ($payload) {
      while ($payload) {
         my ($neighbor, $tail) = $self->SUPER::unpack('a4 a*', $payload)
            or return undef;
         push @neighborList, inetNtoa($neighbor);
         $payload = $tail;
      }
   }

   $self->neighborList(\@neighborList);

   $self->payload($payload);

   $self;
}

sub print {
   my $self = shift;

   my $l = $self->layer;
   my $buf = sprintf
      "$l: networkMask:%s  helloInterval:%d\n".
      "$l: options:0x%02x  routerPri:0x%02x  routerDeadInterval:%d\n".
      "$l: designatedRouter:%s  backupDesignatedRouter:%s",
         $self->networkMask,
         $self->helloInterval,
         $self->options,
         $self->routerPri,
         $self->routerDeadInterval,
         $self->designatedRouter,
         $self->backupDesignatedRouter,
   ;

   for ($self->neighborList) {
      $buf .= "\n$l: neighbor: $_";
   }

   if ($self->lls) {
      $buf .= "\n".$self->lls->print;
   }

   $buf;
}

1;

__END__

=head1 NAME

Net::Frame::Layer::OSPF::Hello - OSPF Hello type object

=head1 SYNOPSIS

   use Net::Frame::Layer::OSPF::Hello;

   my $layer = Net::Frame::Layer::OSPF::Hello->new(
      networkMask            => '255.255.255.0',
      helloInterval          => 60,
      options                => 0,
      routerPri              => 0,
      routerDeadInterval     => 120,
      designatedRouter       => '0.0.0.0',
      backupDesignatedRouter => '0.0.0.0',
      neighborList           => [],
   );
   $layer->pack;

   print 'RAW: '.$layer->dump."\n";

   # Read a raw layer
   my $layer = Net::Frame::Layer::OSPF::Hello->new(raw => $raw);

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the OSPF Hello object.

See also B<Net::Frame::Layer> for other attributes and methods.

=head1 ATTRIBUTES

=over 4

=item B<networkMask>

=item B<helloInterval>

=item B<options>

=item B<routerPri>

=item B<routerDeadInterval>

=item B<designatedRouter>

=item B<backupDesignatedRouter>

=item B<lls>

Previous attributes set and get scalar values.

=item B<neighborList> ( [ B<IP address>, ... ] )

This attribute takes an array ref of IP addresses.

=back

The following are inherited attributes. See B<Net::Frame::Layer> for more information.

=over 4

=item B<raw>

=item B<payload>

=item B<nextLayer>

=back

=head1 METHODS

=over 4

=item B<new>

=item B<new> (hash)

Object constructor. You can pass attributes that will overwrite default ones. See B<SYNOPSIS> for default values.

=back

The following are inherited methods. Some of them may be overriden in this layer, and some others may not be meaningful in this layer. See B<Net::Frame::Layer> for more information.

=over 4

=item B<layer>

=item B<computeLengths>

=item B<computeChecksums>

=item B<pack>

=item B<unpack>

=item B<encapsulate>

=item B<getLength>

=item B<getPayloadLength>

=item B<print>

=item B<dump>

=back

=head1 CONSTANTS

No constants here.

=head1 SEE ALSO

L<Net::Frame::Layer::OSPF>, L<Net::Frame::Layer>

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
