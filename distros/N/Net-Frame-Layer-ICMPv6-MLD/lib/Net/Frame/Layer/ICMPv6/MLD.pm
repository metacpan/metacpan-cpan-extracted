#
# $Id: MLD.pm 49 2009-05-31 13:15:34Z VinsWorldcom $
#
package Net::Frame::Layer::ICMPv6::MLD;
use strict; use warnings;

our $VERSION = '1.00';

use Net::Frame::Layer qw(:consts :subs);
use Exporter;
our @ISA = qw(Net::Frame::Layer Exporter);

our %EXPORT_TAGS = (
   consts => [qw(
      NF_MLD_ALLMLDRTRS
      NF_MLD_ALLMLDRTRS_MAC
      NF_MLD_TYPE_QUERY
      NF_MLD_TYPE_REPORTv1
      NF_MLD_TYPE_DONE
      NF_MLD_TYPE_REPORTv2
   )],
);
our @EXPORT_OK = (
   @{$EXPORT_TAGS{consts}},
);

use constant NF_MLD_ALLMLDRTRS     => 'ff02::16';
use constant NF_MLD_ALLMLDRTRS_MAC => '33:33:00:00:00:16';
use constant NF_MLD_TYPE_QUERY     => 130;
use constant NF_MLD_TYPE_REPORTv1  => 131;
use constant NF_MLD_TYPE_DONE      => 132;
use constant NF_MLD_TYPE_REPORTv2  => 143;

our @AS = qw(
   maxResp
   reserved
   groupAddress
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

#no strict 'vars';
use Net::Frame::Layer::ICMPv6::MLD::Query;
use Net::Frame::Layer::ICMPv6::MLD::Report;
use Net::Frame::Layer::ICMPv6::MLD::Report::Record qw(:consts);

sub new {
   shift->SUPER::new(
      maxResp      => 0,
      reserved     => 0,
      groupAddress => '::',
      @_,
   );
}

sub getLength { 20 }

sub pack {
   my $self = shift;

   my $raw = $self->SUPER::pack('nna*',
         $self->maxResp,
         $self->reserved,
         inet6Aton($self->groupAddress)
      ) or return;

   return $self->raw($raw);
}

sub unpack {
   my $self = shift;

   my ($maxResp, $reserved, $group, $payload) =
      $self->SUPER::unpack('nna16 a*', $self->raw)
         or return;

   $self->maxResp($maxResp);
   $self->reserved($reserved);
   $self->groupAddress(inet6Ntoa($group));

   $self->payload($payload);

   return $self;
}

sub encapsulate {
   my $self = shift;

   return $self->nextLayer if $self->nextLayer;

   if ($self->payload) {
      return 'ICMPv6::MLD::Query';
   }

   NF_LAYER_NONE;
}

sub print {
   my $self = shift;

   my $l = $self->layer;
   my $buf .= sprintf
      "$l: maxResp:%d  reserved:%d\n".
      "$l: groupAddress:%s",
         $self->maxResp, $self->reserved,
         $self->groupAddress;

   return $buf;
}

1;

__END__

=head1 NAME

Net::Frame::Layer::ICMPv6::MLD - Multicast Listener Discovery layer object

=head1 SYNOPSIS

   use Net::Frame::Simple;
   use Net::Frame::Layer::ICMPv6::MLD qw(:consts);

   my $layer = Net::Frame::Layer::ICMPv6::MLD->new(
      maxResp      => 0,
      reserved     => 0,
      groupAddress => '::',
   );

   #
   # Read a raw layer
   #

   my $layer = Net::Frame::Layer::ICMPv6::MLD->new(raw => $raw);

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the MLD layer.

RFC: ftp://ftp.rfc-editor.org/in-notes/rfc3810.txt

See also B<Net::Frame::Layer> for other attributes and methods.

=head1 ATTRIBUTES

=over 4

=item B<maxResp>

Maximum time allowed before sending a responding report.

=item B<reserved>

Ignored - set to 0.

=item B<groupAddress>

Multicast group address.

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

=head1 CONSTANTS

Load them: use Net::Frame::Layer::ICMPv6::MLD qw(:consts);

=over 4

=item B<NF_MLD_ALLMLDRTRS_MAC>

Default Layer 2 destination addresses.

=item B<NF_MLD_ALLMLDRTRS>

Default Layer 3 destination addresses.

=item B<NF_MLD_TYPE_QUERY>

=item B<NF_MLD_TYPE_REPORTv1>

=item B<NF_MLD_TYPE_DONE>

=item B<NF_MLD_TYPE_REPORTv2>

MLD message types.

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
