#
# $Id: Question.pm 49 2009-05-31 13:15:34Z VinsWorldcom $
#
package Net::Frame::Layer::DNS::Question;
use strict; use warnings;

use Net::Frame::Layer qw(:consts :subs);
our @ISA = qw(Net::Frame::Layer Exporter);

use Net::Frame::Layer::DNS::Constants qw(:consts);
my @consts;
for my $c (sort(keys(%constant::declared))) {
    if ($c =~ /^Net::Frame::Layer::DNS::Constants::/) {
        $c =~ s/^Net::Frame::Layer::DNS::Constants:://;
        push @consts, $c
    }
}
our %EXPORT_TAGS = (
   consts => [@consts]
);
our @EXPORT_OK = (
   @{$EXPORT_TAGS{consts}},
);

our @AS = qw(
   name
   type
   class
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use Net::Frame::Layer::DNS qw(:subs);

sub new {
   shift->SUPER::new(
      name  => '',
      type  => NF_DNS_TYPE_A,
      class => NF_DNS_CLASS_IN,
      @_,
   );
}

sub getLength {
   my $self = shift;
   
   # 1 byte leading length, name, 1 byte trailing null, 2 bytes type, 2 bytes class
   if (length($self->name) == 0) {
      return length($self->name) + 5
   } else {
      return length($self->name) + 6
   }
}

sub pack {
   my $self = shift;

   my $name = dnsAton($self->name);

   $self->raw($self->SUPER::pack('H* nn',
      $name, $self->type, $self->class,
   )) or return;

   return $self->raw;
}

sub unpack {
   my $self = shift;

   my @parts = split /\0/, $self->raw, 2;
   my ($name) = dnsNtoa($parts[0]);

   my ($type, $class, $payload) =
      $self->SUPER::unpack('nn a*', $parts[1])
         or return;

   $self->name($name);
   $self->type($type);
   $self->class($class);
   $self->payload($payload);

   return $self;
}

sub encapsulate {
   my $self = shift;

   return $self->nextLayer if $self->nextLayer;

   if ($self->payload) {
      return 'DNS::RR';
   }

   NF_LAYER_NONE;
}

sub print {
   my $self = shift;

   my $l = $self->layer;
   my $buf = sprintf
      "$l: name:%s\n".
      "$l: type:%d  class:%d",
         $self->name,
         $self->type, $self->class;

   return $buf;
}

1;

__END__

=head1 NAME

Net::Frame::Layer::DNS::Question - DNS Question type object

=head1 SYNOPSIS

   use Net::Frame::Layer::DNS::Question qw(:consts);

   my $layer = Net::Frame::Layer::DNS::Question->new(
      name  => '',
      type  => NF_DNS_TYPE_A,
      class => NF_DNS_CLASS_IN,
   );
   $layer->pack;

   print 'RAW: '.$layer->dump."\n";

   # Read a raw layer
   my $layer = Net::Frame::Layer::DNS::Question->new(raw => $raw);

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the DNS Question object.

See also B<Net::Frame::Layer> for other attributes and methods.

=head1 ATTRIBUTES

=over 4

=item B<name>

Question name (hostname / domain).

=item B<type>

Record type requested.  See B<CONSTANTS> for more information.

=item B<class>

Class type requested.  See B<CONSTANTS> for more information.

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

Load them: use Net::Frame::Layer::DNS::Question qw(:consts);

See B<Net::Frame::Layer::DNS::Constants> for more information.

=head1 SEE ALSO

L<Net::Frame::Layer::DNS>, L<Net::Frame::Layer>

=head1 AUTHOR

Michael Vincent

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012, Michael Vincent

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
