#
# $Id: RIP.pm 49 2009-05-31 13:15:34Z VinsWorldcom $
#
package Net::Frame::Layer::RIP;
use strict; use warnings;

our $VERSION = '1.02';

use Net::Frame::Layer qw(:consts :subs);
use Exporter;
our @ISA = qw(Net::Frame::Layer Exporter);

use Net::Frame::Layer::RIP::v1 qw(:consts);
use Net::Frame::Layer::RIP::v2 qw(:consts);
my @consts;
for my $c (sort(keys(%constant::declared))) {
    if ($c =~ /^Net::Frame::Layer::RIP::v[12]::/) {
        $c =~ s/^Net::Frame::Layer::RIP::v[12]:://;
        push @consts, $c
    }
}

our %EXPORT_TAGS = (
   consts => [@consts, qw(
      NF_RIP_V1_DEST_HWADDR
      NF_RIP_V1_DEST_ADDR
      NF_RIP_V1_DEST_PORT
      NF_RIP_V2_DEST_HWADDR
      NF_RIP_V2_DEST_ADDR
      NF_RIP_V2_DEST_PORT
      NF_RIP_V1_COMMAND_REQUEST
      NF_RIP_V1_COMMAND_RESPONSE
      NF_RIP_V1_COMMAND_TRACEON
      NF_RIP_V1_COMMAND_TRACEOFF
      NF_RIP_V1_COMMAND_SUNRESV
      NF_RIP_V1_COMMAND_TRIGGEREDREQUEST
      NF_RIP_V1_COMMAND_TRIGGEREDRESPONSE
      NF_RIP_V1_COMMAND_TRIGGEREDACK
      NF_RIP_V1_COMMAND_UPDATEREQUEST
      NF_RIP_V1_COMMAND_UPDATERESPONSE
      NF_RIP_V1_COMMAND_UPDATEACK
      NF_RIP_V2_COMMAND_REQUEST
      NF_RIP_V2_COMMAND_RESPONSE
      NF_RIP_V2_COMMAND_TRACEON
      NF_RIP_V2_COMMAND_TRACEOFF
      NF_RIP_V2_COMMAND_SUNRESV
      NF_RIP_V2_COMMAND_TRIGGEREDREQUEST
      NF_RIP_V2_COMMAND_TRIGGEREDRESPONSE
      NF_RIP_V2_COMMAND_TRIGGEREDACK
      NF_RIP_V2_COMMAND_UPDATEREQUEST
      NF_RIP_V2_COMMAND_UPDATERESPONSE
      NF_RIP_V2_COMMAND_UPDATEACK
   )],
);
our @EXPORT_OK = (
   @{$EXPORT_TAGS{consts}},
);

use constant NF_RIP_V1_DEST_HWADDR               => 'ff:ff:ff:ff:ff:ff';
use constant NF_RIP_V1_DEST_ADDR                 => '255.255.255.255';
use constant NF_RIP_V1_DEST_PORT                 => 520;
use constant NF_RIP_V2_DEST_HWADDR               => '01:00:5e:00:00:09';
use constant NF_RIP_V2_DEST_ADDR                 => '224.0.0.9';
use constant NF_RIP_V2_DEST_PORT                 => 520;
use constant NF_RIP_V1_COMMAND_REQUEST           => 1;
use constant NF_RIP_V1_COMMAND_RESPONSE          => 2;
use constant NF_RIP_V1_COMMAND_TRACEON           => 3;
use constant NF_RIP_V1_COMMAND_TRACEOFF          => 4;
use constant NF_RIP_V1_COMMAND_SUNRESV           => 5;
use constant NF_RIP_V1_COMMAND_TRIGGEREDREQUEST  => 6;
use constant NF_RIP_V1_COMMAND_TRIGGEREDRESPONSE => 7;
use constant NF_RIP_V1_COMMAND_TRIGGEREDACK      => 8;
use constant NF_RIP_V1_COMMAND_UPDATEREQUEST     => 9;
use constant NF_RIP_V1_COMMAND_UPDATERESPONSE    => 10;
use constant NF_RIP_V1_COMMAND_UPDATEACK         => 11;
use constant NF_RIP_V2_COMMAND_REQUEST           => 1;
use constant NF_RIP_V2_COMMAND_RESPONSE          => 2;
use constant NF_RIP_V2_COMMAND_TRACEON           => 3;
use constant NF_RIP_V2_COMMAND_TRACEOFF          => 4;
use constant NF_RIP_V2_COMMAND_SUNRESV           => 5;
use constant NF_RIP_V2_COMMAND_TRIGGEREDREQUEST  => 6;
use constant NF_RIP_V2_COMMAND_TRIGGEREDRESPONSE => 7;
use constant NF_RIP_V2_COMMAND_TRIGGEREDACK      => 8;
use constant NF_RIP_V2_COMMAND_UPDATEREQUEST     => 9;
use constant NF_RIP_V2_COMMAND_UPDATERESPONSE    => 10;
use constant NF_RIP_V2_COMMAND_UPDATEACK         => 11;

our @AS = qw(
   command
   version
   reserved
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

#no strict 'vars';

$Net::Frame::Layer::UDP::Next->{520} = "RIP";

sub new {
   shift->SUPER::new(
      command  => NF_RIP_V2_COMMAND_REQUEST,
      version  => 2,
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
   if (($sCmd == NF_RIP_V1_COMMAND_REQUEST)
   &&  ($wCmd == NF_RIP_V1_COMMAND_RESPONSE)
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
         return 'RIP::v1';
      } elsif ($self->version == 2) {
         return 'RIP::v2';
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

Net::Frame::Layer::RIP - Routing Information Protocol layer object

=head1 SYNOPSIS

   use Net::Frame::Simple;
   use Net::Frame::Layer::RIP qw(:consts);

   my $layer = Net::Frame::Layer::RIP->new(
      command  => NF_RIP_V2_COMMAND_REQUEST,
      version  => 2,
      reserved => 0,
   );

   #
   # Read a raw layer
   #

   my $layer = Net::Frame::Layer::RIP->new(raw => $raw);

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the RIP layer.

RFC: ftp://ftp.rfc-editor.org/in-notes/rfc1058.txt

RFC: ftp://ftp.rfc-editor.org/in-notes/rfc2453.txt

See also B<Net::Frame::Layer> for other attributes and methods.

=head1 ATTRIBUTES

=over 4

=item B<command>

RIP command.  See B<CONSTANTS> for more information.

=item B<version>

RIP protocol version: 1 or 2 valid.

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

=item B<match> (Net::Frame::Layer::RIP object)

This method is mostly used internally. You pass a B<Net::Frame::Layer::RIP> layer as a parameter, and it returns true if this is a response corresponding for the request, or returns false if not.

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

Load them: use Net::Frame::Layer::RIP qw(:consts);

=over 4

=item B<NF_RIP_V1_DEST_HWADDR>

=item B<NF_RIP_V1_DEST_ADDR>

=item B<NF_RIP_V1_DEST_PORT>

=item B<NF_RIP_V2_DEST_HWADDR>

=item B<NF_RIP_V2_DEST_ADDR>

=item B<NF_RIP_V2_DEST_PORT>

Default destination Ethernet address, IPv4 address and UDP port.

=item B<NF_RIP_V1_COMMAND_REQUEST>

=item B<NF_RIP_V1_COMMAND_RESPONSE>

=item B<NF_RIP_V1_COMMAND_TRACEON>

=item B<NF_RIP_V1_COMMAND_TRACEOFF>

=item B<NF_RIP_V1_COMMAND_SUNRESV>

=item B<NF_RIP_V1_COMMAND_TRIGGEREDREQUEST>

=item B<NF_RIP_V1_COMMAND_TRIGGEREDRESPONSE>

=item B<NF_RIP_V1_COMMAND_TRIGGEREDACK>

=item B<NF_RIP_V1_COMMAND_UPDATEREQUEST>

=item B<NF_RIP_V1_COMMAND_UPDATERESPONSE>

=item B<NF_RIP_V1_COMMAND_UPDATEACK>

=item B<NF_RIP_V2_COMMAND_REQUEST>

=item B<NF_RIP_V2_COMMAND_RESPONSE>

=item B<NF_RIP_V2_COMMAND_TRACEON>

=item B<NF_RIP_V2_COMMAND_TRACEOFF>

=item B<NF_RIP_V2_COMMAND_SUNRESV>

=item B<NF_RIP_V2_COMMAND_TRIGGEREDREQUEST>

=item B<NF_RIP_V2_COMMAND_TRIGGEREDRESPONSE>

=item B<NF_RIP_V2_COMMAND_TRIGGEREDACK>

=item B<NF_RIP_V2_COMMAND_UPDATEREQUEST>

=item B<NF_RIP_V2_COMMAND_UPDATERESPONSE>

=item B<NF_RIP_V2_COMMAND_UPDATEACK>

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
