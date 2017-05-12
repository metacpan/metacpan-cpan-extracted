#
# Router Advertisement message wrapper
# pvenegas@infoweapons.com
#
#
# $Id: RouterAdvertisement.pm 45 2014-04-09 06:32:08Z gomor $
#
package Net::Frame::Layer::ICMPv6::RouterAdvertisement;
use strict; use warnings;

use Net::Frame::Layer qw(:consts :subs);
our @ISA = qw(Net::Frame::Layer);

our @AS = qw(
   curHopLimit
   flags
   reserved
   routerLifetime
   reachableTime
   retransTimer
);
our @AA = qw(
   options
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);
__PACKAGE__->cgBuildAccessorsArray (\@AA);

use Net::Frame::Layer::ICMPv6 qw(:consts);
use Bit::Vector;
use Net::Frame::Layer::ICMPv6::Option;

# TODO: Double-check if defaults are sane
sub new {
   shift->SUPER::new(
      curHopLimit    => 0,
      flags          => 0,
      reserved       => 0,
      routerLifetime => 0,
      reachableTime  => 0,
      retransTimer   => 0,
      options        => [],
      @_,
   );
}

sub getOptionsLength {
   my $self = shift;
   my $len = 0;
   $len += $_->getLength for $self->options;
   return $len;
}

sub getLength {
   my $self = shift;
   return 12 + $self->getOptionsLength;
}

sub pack {
   my $self = shift;

   my $flags    = Bit::Vector->new_Dec(6, $self->flags);
   my $reserved = Bit::Vector->new_Dec(2, $self->reserved);
   my $v8       = $flags->Concat_List($reserved);

   my $raw = $self->SUPER::pack("CcnLL",
      $self->curHopLimit, $v8->to_Dec, $self->routerLifetime,
      $self->reachableTime, $self->retransTimer
   ) or return;

   for ($self->options) {
      $raw .= $_->pack;
   }

   $self->raw($raw);
}

sub _unpackOptions {
   my $self = shift;
   my ($payload) = @_;
 
   my @options = ();
   while (defined($payload) && length($payload)) {
      my $opt = Net::Frame::Layer::ICMPv6::Option->new(raw => $payload)->unpack;
      push @options, $opt;
      $payload = $opt->payload;
      $opt->payload(undef);
   }
   $self->options(\@options);
   return $payload;
}

sub unpack {
   my $self = shift;

   my ($curHopLimit, $flagsReserved, $routerLifetime,
       $reachableTime, $retransTimer, $payload) =
          $self->SUPER::unpack("CcnLL a*", $self->raw);

   my $v8 = Bit::Vector->new_Dec(8, $flagsReserved);

   $self->curHopLimit($curHopLimit);
   $self->reserved($v8->Chunk_Read(2, 0));
   $self->flags   ($v8->Chunk_Read(6, 2));
   $self->routerLifetime($routerLifetime);
   $self->reachableTime($reachableTime);
   $self->retransTimer($retransTimer);
 
   if (defined($payload) && length($payload)) {
      $payload = $self->_unpackOptions($payload);
   }

   $self->payload($payload);

   return $self;
}

sub print {
   my $self = shift;

   my $l = $self->layer;
   my $buf = sprintf "$l: curHopLimit: %d  flags: 0x%02x  reserved: 0x%02x\n" .
      "$l: routerLifetime: %d  reachableTime: %d  retransTimer: %d",
      $self->curHopLimit,
      $self->flags,
      $self->reserved,
      $self->routerLifetime,
      $self->reachableTime,
      $self->retransTimer;

   for ($self->options) {
      $buf .= "\n" . $_->print;
   }

   return $buf;
}

1;

__END__

=head1 NAME

Net::Frame::Layer::ICMPv6::RouterAdvertisement - ICMPv6 Router Advertisement type object

=head1 SYNOPSIS

   use Net::Frame::Layer::ICMPv6::RouterAdvertisement;

   my $layer = Net::Frame::Layer::ICMPv6::RouterAdvertisement->new(
      curHopLimit   => 64,
      flags         => NF_ICMPv6_FLAG_MANAGEDADDRESSCONFIGURATION,
   );
   $layer->pack;

   print 'RAW: '.$layer->dump."\n";

   # Read a raw layer
   my $layer = Net::Frame::Layer::ICMPv6::RouterAdvertisement->new(
      raw => $raw,
   );

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the ICMPv6 Router Advertisement object.

See also B<Net::Frame::Layer> for other attributes and methods.

=head1 ATTRIBUTES

Refer to RFC 5175 for information on these attributes

=over 4

=item B<curHopLimit>
   
=item B<flags>

=item B<reserved>

=item B<routerLifetime>
   
=item B<reachableTime>
   
=item B<retransTimer>

=item B<options>

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
   
=item B<getOptionsLength>

Returns the length in bytes of options, 0 if none.

=back

The following are inherited methods. Some of them may be overridden in this layer, and some others may not be meaningful in this layer. See B<Net::Frame::Layer> for more information.

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

L<Net::Frame::Layer::ICMPv6>, L<Net::Frame::Layer>

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret
Paolo Vanni Venegas

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2014, Patrice E<lt>GomoRE<gt> Auffret
Copyright (c) 2009-2014, Paolo Vanni Venegas

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
