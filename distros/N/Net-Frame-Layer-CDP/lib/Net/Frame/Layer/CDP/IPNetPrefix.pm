#
# $Id: IPNetPrefix.pm 1640 2013-03-28 17:58:27Z VinsWorldcom $
#
package Net::Frame::Layer::CDP::IPNetPrefix;
use strict; use warnings;

use Net::Frame::Layer qw(:consts :subs);
our @ISA = qw(Net::Frame::Layer);

our @AS = qw(
   type
   length
);
our @AA = qw(
   IpNetPrefix
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);
__PACKAGE__->cgBuildAccessorsArray(\@AA);

#no strict 'vars';

use Net::Frame::Layer::CDP::Constants qw(:consts);

sub new {
   shift->SUPER::new(
      type        => NF_CDP_TYPE_IPNET_PREFIX,
      length      => 9,
      IpNetPrefix => ['127.0.0.1/8'],
      @_,
   );
}

sub getLength {
   my $self = shift;

   my $length = 4;
   $length += 5 for $self->IpNetPrefix;

   return $length
}

sub pack {
   my $self = shift;

   my $raw = $self->SUPER::pack('nn',
      $self->type,
      $self->length
   ) or return;

   for ($self->IpNetPrefix) {
      my ($prefix, $mask) = split /\//, $_;
      $raw .= $self->SUPER::pack('a4C',
         inetAton($prefix),
         $mask
      ) or return;
   }

   return $self->raw($raw);
}

sub unpack {
   my $self = shift;

   my ($type, $length, $tail) = 
      $self->SUPER::unpack('nna*', $self->raw)
         or return;

   $self->type($type);
   $self->length($length);

   my $valLen = $length - 4;
   my ($IpNetPrefix, $payload) = 
      $self->SUPER::unpack("a$valLen a*", $tail)
         or return;

   my @prefixList;
   for (1..$valLen/5) {
      my ($prefix, $mask) = 
         $self->SUPER::unpack("a4C", $IpNetPrefix)
            or return;

      $prefix = inetNtoa($prefix);
      $prefix .= "/$mask";
      push @prefixList, $prefix;
      $IpNetPrefix = substr $IpNetPrefix, 5
   }

   $self->IpNetPrefix(\@prefixList);
   $self->payload($payload);

   return $self;
}

sub computeLengths {
   my $self = shift;

   my $length = 4;
   $length += 5 for $self->IpNetPrefix;
   $self->length($length);

   return 1;
}

sub print {
   my $self = shift;

   my $l = $self->layer;
   my $buf = sprintf
      "$l: type:0x%04x  length:%d",
         $self->type, $self->length;
         
   for ($self->IpNetPrefix) {
      $buf .= sprintf
      "\n$l: IpNetPrefix:%s",
         $_
   }

   return $buf;
}

1;

__END__

=head1 NAME

Net::Frame::Layer::CDP::IPNetPrefix - CDP IPNetPrefix TLV

=head1 SYNOPSIS

   use Net::Frame::Simple;
   use Net::Frame::Layer::CDP qw(:consts);

   my $layer = Net::Frame::Layer::CDP::IPNetPrefix->new(
      type        => NF_CDP_TYPE_IPNET_PREFIX
      length      => 9,
      IpNetPrefix => ['127.0.0.1/8'],
   );

   #
   # Read a raw layer
   #
   my $layer = Net::Frame::Layer::CDP->new(raw => $raw);

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the IPNetPrefix CDP message type.

=head1 ATTRIBUTES

=over 4

=item B<type>

Type.

=item B<length>

Length of TLV option.

=item B<IpNetPrefix>

Array of IP network prefixes with slash mask notation.  See B<SYNOPSIS> for example.

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

L<Net::Frame::Layer::CDP>, L<Net::Frame::Layer>

=head1 AUTHOR

Michael Vincent

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2013, Michael Vincent

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
