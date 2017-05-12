#
# $Id: HSRP.pm 49 2009-05-31 13:15:34Z VinsWorldcom $
#
package Net::Frame::Layer::HSRP;
use strict; use warnings;

our $VERSION = '1.00';

use Net::Frame::Layer qw(:consts :subs);
use Exporter;
our @ISA = qw(Net::Frame::Layer Exporter);

our %EXPORT_TAGS = (
   consts => [qw(
      NF_HSRP_ALLHSRPRTRS
      NF_HSRP_ALLHSRPRTRS_MAC
      NF_HSRP_UDP_PORT
      NF_HSRP_VERSION_1
      NF_HSRP_OPCODE_HELLO
      NF_HSRP_OPCODE_COUP
      NF_HSRP_OPCODE_RESIGN
      NF_HSRP_STATE_INITIAL
      NF_HSRP_STATE_LEARN
      NF_HSRP_STATE_LISTEN
      NF_HSRP_STATE_SPEAK
      NF_HSRP_STATE_STANDBY
      NF_HSRP_STATE_ACTIVE
   )],
);
our @EXPORT_OK = (
   @{$EXPORT_TAGS{consts}},
);

use constant NF_HSRP_ALLHSRPRTRS     => '224.0.0.2';
use constant NF_HSRP_ALLHSRPRTRS_MAC => '01:00:5e:00:00:02';
use constant NF_HSRP_UDP_PORT      => 1985;
use constant NF_HSRP_VERSION_1     => 0;
use constant NF_HSRP_OPCODE_HELLO  => 0;
use constant NF_HSRP_OPCODE_COUP   => 1;
use constant NF_HSRP_OPCODE_RESIGN => 2;
use constant NF_HSRP_STATE_INITIAL => 0;
use constant NF_HSRP_STATE_LEARN   => 1;
use constant NF_HSRP_STATE_LISTEN  => 2;
use constant NF_HSRP_STATE_SPEAK   => 4;
use constant NF_HSRP_STATE_STANDBY => 8;
use constant NF_HSRP_STATE_ACTIVE  => 16;

our @AS = qw(
   version
   opcode
   state
   helloTime
   holdTime
   priority
   group
   reserved
   authData
   virtualIp
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

#no strict 'vars';

$Net::Frame::Layer::UDP::Next->{1985} = "HSRP";

sub new {
   shift->SUPER::new(
      version   => NF_HSRP_VERSION_1,
      opcode    => NF_HSRP_OPCODE_HELLO,
      state     => NF_HSRP_STATE_STANDBY,
      helloTime => 3,
      holdTime  => 10,
      priority  => 100,
      group     => 1,
      reserved  => 0,
      authData  => "cisco\0\0\0",
      virtualIp => '127.0.0.1',
      @_,
   );
}

sub getLength { 20 }

sub pack {
   my $self = shift;

   my $raw = $self->SUPER::pack('CCCCCCCCa8a4',
      $self->version,
      $self->opcode,
      $self->state,
      $self->helloTime,
      $self->holdTime,
      $self->priority,
      $self->group,
      $self->reserved,
      $self->authData,
      inetAton($self->virtualIp)
   ) or return;

   return $self->raw($raw);
}

sub unpack {
   my $self = shift;

   my ($version, $opcode, $state, $helloTime, $holdTime,
       $priority, $group, $reserved, $authData, $virtualIp, $payload) =
      $self->SUPER::unpack('CCCCCCCCa8a4 a*', $self->raw)
         or return;

   $self->version($version);
   $self->opcode($opcode);
   $self->state($state);
   $self->helloTime($helloTime);
   $self->holdTime($holdTime);
   $self->priority($priority);
   $self->group($group);
   $self->reserved($reserved);
   $self->authData($authData);
   $self->virtualIp(inetNtoa($virtualIp));

   $self->payload($payload);

   return $self;
}

sub encapsulate {
   my $self = shift;

   return $self->nextLayer if $self->nextLayer;

   # if ($self->payload) {
      # if ($self->version == 1) {
         # return 'HSRP::v1';
      # } elsif ($self->version == 2) {
         # return 'HSRP::v2';
      # }
   # }

   NF_LAYER_NONE;
}

sub print {
   my $self = shift;

   my $l = $self->layer;
   my $buf = sprintf
      "$l: version:%d  opcode:%d  state:%d  helloTime:%d\n".
      "$l: holdTime:%d  priority:%d  group:%d  reserved:%d\n".
      "$l: authData:%s\n".
      "$l: virtualIp:%s",
         $self->version, $self->opcode, $self->state, $self->helloTime,
         $self->holdTime, $self->priority, $self->group, $self->reserved,
         $self->authData,
         $self->virtualIp;

   return $buf;
}

1;

__END__

=head1 NAME

Net::Frame::Layer::HSRP - Hot Standby Router Protocol layer object

=head1 SYNOPSIS

   use Net::Frame::Simple;
   use Net::Frame::Layer::HSRP qw(:consts);

   my $layer = Net::Frame::Layer::HSRP->new(
      version   => NF_HSRP_VERSION_1,
      opcode    => NF_HSRP_OPCODE_HELLO,
      state     => NF_HSRP_STATE_STANDBY,
      helloTime => 3,
      holdTime  => 10,
      priority  => 100,
      group     => 1,
      reserved  => 0,
      authData  => "cisco\0\0\0",
      virtualIp => '127.0.0.1',
   );

   #
   # Read a raw layer
   #

   my $layer = Net::Frame::Layer::HSRP->new(raw => $raw);

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the HSRP layer.

RFC: ftp://ftp.rfc-editor.org/in-notes/rfc2281.txt

See also B<Net::Frame::Layer> for other attributes and methods.

=head1 ATTRIBUTES

=over 4

=item B<version>

HSRP protocol version.  See B<CONSTANTS> for more information.

=item B<opcode>

HSRP opcode.  See B<CONSTANTS> for more information.

=item B<state>

HSRP state.  See B<CONSTANTS> for more information.

=item B<helloTime>

Default set to 3.

=item B<holdTime>

Default set to 10.

=item B<priority>

Default set to 100.

=item B<group>

HSRP group.

=item B<reserved>

=item B<authData>

Clear text authentication data.  Default set to "cisco\0\0\0".

=item B<virtualIp>

HSRP virtual IP.

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

Load them: use Net::Frame::Layer::HSRP qw(:consts);

=over 4

=item B<NF_HSRP_ALLHSRPRTRS_MAC>

Default Layer 2 destination addresses.

=item B<NF_HSRP_ALLHSRPRTRS>

Default Layer 3 destination addresses.

=item B<NF_HSRP_UDP_PORT>

Default UDP port.

=item B<NF_HSRP_VERSION_1>

HSRP version.

=item B<NF_HSRP_OPCODE_HELLO>

=item B<NF_HSRP_OPCODE_COUP>

=item B<NF_HSRP_OPCODE_RESIGN>

HSRP opcodes.

=item B<NF_HSRP_STATE_INITIAL>

=item B<NF_HSRP_STATE_LEARN>

=item B<NF_HSRP_STATE_LISTEN>

=item B<NF_HSRP_STATE_SPEAK>

=item B<NF_HSRP_STATE_STANDBY>

=item B<NF_HSRP_STATE_ACTIVE>

HSRP states.

=back

=head1 LIMITATIONS

Currently only supports HSRP version 1.

=head1 SEE ALSO

L<Net::Frame::Layer>

=head1 AUTHOR

Michael Vincent

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2013, Michael Vincent

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
