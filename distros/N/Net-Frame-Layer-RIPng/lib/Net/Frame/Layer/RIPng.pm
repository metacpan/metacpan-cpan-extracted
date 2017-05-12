#
# $Id: RIPng.pm 49 2009-05-31 13:15:34Z VinsWorldcom $
#
package Net::Frame::Layer::RIPng;
use strict; use warnings;

our $VERSION = '1.02';

use Net::Frame::Layer qw(:consts :subs);
use Exporter;
our @ISA = qw(Net::Frame::Layer Exporter);

use Net::Frame::Layer::RIPng::v1 qw(:consts);
my @consts;
for my $c (sort(keys(%constant::declared))) {
    if ($c =~ /^Net::Frame::Layer::RIPng::v1::/) {
        $c =~ s/^Net::Frame::Layer::RIPng::v1:://;
        push @consts, $c
    }
}

our %EXPORT_TAGS = (
   consts => [@consts, qw(
      NF_RIPNG_DEST_HWADDR
      NF_RIPNG_DEST_ADDR
      NF_RIPNG_DEST_PORT
      NF_RIPNG_COMMAND_REQUEST
      NF_RIPNG_COMMAND_RESPONSE
   )],
);
our @EXPORT_OK = (
   @{$EXPORT_TAGS{consts}},
);

use constant NF_RIPNG_DEST_HWADDR               => '33:33:00:00:00:09';
use constant NF_RIPNG_DEST_ADDR                 => 'ff02::9';
use constant NF_RIPNG_DEST_PORT                 => 521;
use constant NF_RIPNG_COMMAND_REQUEST           => 1;
use constant NF_RIPNG_COMMAND_RESPONSE          => 2;

our @AS = qw(
   command
   version
   reserved
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

#no strict 'vars';

$Net::Frame::Layer::UDP::Next->{521} = "RIPng";

sub new {
   shift->SUPER::new(
      command  => NF_RIPNG_COMMAND_REQUEST,
      version  => 1,
      reserved => 0,
      @_,
   );
}

sub match {
   my $self = shift;
   my ($with) = @_;
   my $sVer = $self->version;
   my $wVer = $with->version;
   my $sCmd = $self->command;
   my $wCmd = $with->command;
   if (($sCmd == NF_RIPNG_COMMAND_REQUEST)
   &&  ($wCmd == NF_RIPNG_COMMAND_RESPONSE)
   &&  ($sVer == $wVer)) {
      return 1;
   }
   0;
}

# XXX: may be better, by keying on type also
sub getKey        { shift->layer }
sub getKeyReverse { shift->layer }

sub getLength { 4 }

sub pack {
   my $self = shift;

   my $raw = $self->SUPER::pack('CCn',
      $self->command,
      $self->version,
      $self->reserved
   ) or return;

   return $self->raw($raw);
}

sub unpack {
   my $self = shift;

   my ($command, $version, $reserved, $payload) =
      $self->SUPER::unpack('CCn a*', $self->raw)
         or return;

   $self->command($command);
   $self->version($version);
   $self->reserved($reserved);

   $self->payload($payload);

   return $self;
}

sub encapsulate {
   my $self = shift;

   return $self->nextLayer if $self->nextLayer;

   if ($self->payload) {
      if ($self->version == 1) {
         return 'RIPng::v1';
      }
   }

   NF_LAYER_NONE;
}

sub print {
   my $self = shift;

   my $l = $self->layer;
   my $buf = sprintf
      "$l: command:%d  version:%d  reserved:%d",
         $self->command, $self->version, $self->reserved;

   return $buf;
}

1;

__END__

=head1 NAME

Net::Frame::Layer::RIPng - Routing Information Protocol ng layer object

=head1 SYNOPSIS

   use Net::Frame::Simple;
   use Net::Frame::Layer::RIPng qw(:consts);

   my $layer = Net::Frame::Layer::RIPng->new(
      command  => NF_RIPNG_COMMAND_REQUEST,
      version  => 1,
      reserved => 0,
   );

   #
   # Read a raw layer
   #

   my $layer = Net::Frame::Layer::RIPng->new(raw => $raw);

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the RIPng layer.

RFC: ftp://ftp.rfc-editor.org/in-notes/rfc2080.txt

See also B<Net::Frame::Layer> for other attributes and methods.

=head1 ATTRIBUTES

=over 4

=item B<command>

RIP command.  See B<CONSTANTS> for more information.

=item B<version>

RIPng protocol version: 1 valid.

=item B<reserved>

Default set to 0.

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

=item B<getKey>

=item B<getKeyReverse>

These two methods are basically used to increase the speed when using B<recv> method from B<Net::Frame::Simple>. Usually, you write them when you need to write B<match> method.

=item B<match> (Net::Frame::Layer::RIPng object)

This method is mostly used internally. You pass a B<Net::Frame::Layer::RIPng> layer as a parameter, and it returns true if this is a response corresponding for the request, or returns false if not.

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

Load them: use Net::Frame::Layer::RIPng qw(:consts);

=over 4

=item B<NF_RIPNG_DEST_HWADDR>

=item B<NF_RIPNG_DEST_ADDR>

=item B<NF_RIPNG_DEST_PORT>

Default destination Ethernet address, IPv6 address and UDP port.

=item B<NF_RIPNG_COMMAND_REQUEST>

=item B<NF_RIPNG_COMMAND_RESPONSE>

Commands.

=back

=head1 SEE ALSO

L<Net::Frame::Layer>

=head1 AUTHOR

Michael Vincent

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012, Michael Vincent

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
