#
# $Id: Report.pm 49 2009-05-31 13:15:34Z VinsWorldcom $
#
package Net::Frame::Layer::ICMPv6::MLD::Report;
use strict; use warnings;

use Net::Frame::Layer qw(:consts :subs);
our @ISA = qw(Net::Frame::Layer);

our @AS = qw(
   reserved
   numGroupRecs
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

sub new {
   shift->SUPER::new(
      reserved     => 0,
      numGroupRecs => 0,
      @_,
   );
}

sub getLength { 4 }

sub pack {
   my $self = shift;

   my $raw = $self->SUPER::pack('nn',
         $self->reserved,
         $self->numGroupRecs
      ) or return;

   return $self->raw($raw);
}

sub unpack {
   my $self = shift;

   my ($reserved, $numGroupRecs, $payload) =
      $self->SUPER::unpack('nn a*', $self->raw)
         or return;

   $self->reserved($reserved);
   $self->numGroupRecs($numGroupRecs);

   $self->payload($payload);

   return $self;
}

sub encapsulate {
   my $self = shift;

   return $self->nextLayer if $self->nextLayer;

   if ($self->payload) {
      return 'ICMPv6::MLD::Report::Record';
   }

   NF_LAYER_NONE;
}

sub print {
   my $self = shift;

   my $l = $self->layer;
   my $buf .= sprintf
      "$l: reserved:%d  numGroupRecs:%d",
         $self->reserved, $self->numGroupRecs;

   return $buf;
}

1;

__END__

=head1 NAME

Net::Frame::Layer::ICMPv6::MLD::Report - Multicast Listener Discovery layer object

=head1 SYNOPSIS

   use Net::Frame::Simple;
   use Net::Frame::Layer::ICMPv6::MLD qw(:consts);

   # v2 Report
   my $layer = Net::Frame::Layer::ICMPv6::MLD::Report->new(
      reserved     => 0,
      numGroupRecs => 0,
   );

   #
   # Read a raw layer
   #

   my $layer = Net::Frame::Layer::ICMPv6::MLD::Report->new(raw => $raw);

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the MLD layer.

RFC: ftp://ftp.rfc-editor.org/in-notes/rfc3810.txt

See also B<Net::Frame::Layer> for other attributes and methods.

=head1 ATTRIBUTES

=over 4

=item B<reserved>

Ignored - set to 0.

=item B<numGroupRecs>

How many multicast address records are present in this report.

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

=item B<pack>

=item B<unpack>

=item B<encapsulate>

=item B<getLength>

=item B<getPayloadLength>

=item B<print>

=item B<dump>

=back

=head1 SEE ALSO

L<Net::Frame::Layer>, L<Net::Frame::Layer::ICMPv6>

=head1 AUTHOR

Michael Vincent

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2017, Michael Vincent

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
