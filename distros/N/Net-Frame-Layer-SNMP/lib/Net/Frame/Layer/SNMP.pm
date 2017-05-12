#
# $Id: SNMP.pm 49 2013-03-04 13:15:34Z VinsWorldcom $
#
package Net::Frame::Layer::SNMP;
use strict; use warnings;

our $VERSION = '1.02';

use Net::Frame::Layer qw(:consts :subs);
use Exporter;
our @ISA = qw(Net::Frame::Layer Exporter);

our %EXPORT_TAGS = (
   consts => [qw(
      NF_SNMP_VERSION_1
      NF_SNMP_VERSION_2
      NF_SNMP_PDUTYPE_GET
      NF_SNMP_PDUTYPE_GETNEXT
      NF_SNMP_PDUTYPE_RESPONSE
      NF_SNMP_PDUTYPE_SET
      NF_SNMP_PDUTYPE_TRAP
      NF_SNMP_PDUTYPE_GETBULK
      NF_SNMP_PDUTYPE_INFORM
      NF_SNMP_PDUTYPE_V2TRAP
      NF_SNMP_PDUTYPE_REPORT
      NF_SNMP_GENERICTRAP_COLDSTART
      NF_SNMP_GENERICTRAP_WARMSTART
      NF_SNMP_GENERICTRAP_LINKDOWN
      NF_SNMP_GENERICTRAP_LINKUP
      NF_SNMP_GENERICTRAP_AUTHFAIL
      NF_SNMP_GENERICTRAP_EGPNEIGHBORLOSS
      NF_SNMP_GENERICTRAP_ENTERPRISESPECIFIC
      NF_SNMP_VARBINDTYPE_INTEGER
      NF_SNMP_VARBINDTYPE_STRING
      NF_SNMP_VARBINDTYPE_OID
      NF_SNMP_VARBINDTYPE_IPADDR
      NF_SNMP_VARBINDTYPE_COUNTER32
      NF_SNMP_VARBINDTYPE_GUAGE32
      NF_SNMP_VARBINDTYPE_TIMETICKS
      NF_SNMP_VARBINDTYPE_OPAQUE
      NF_SNMP_VARBINDTYPE_COUNTER64
      NF_SNMP_VARBINDTYPE_NULL
   )],
   subs => [qw(
      varbinds
      v2trap_varbinds
   )],
);
our @EXPORT_OK = (
   @{$EXPORT_TAGS{consts}},
   @{$EXPORT_TAGS{subs}},
);

use constant NF_SNMP_VERSION_1        => 0;
use constant NF_SNMP_VERSION_2        => 1;
use constant NF_SNMP_PDUTYPE_GET      => 0;
use constant NF_SNMP_PDUTYPE_GETNEXT  => 1;
use constant NF_SNMP_PDUTYPE_RESPONSE => 2;
use constant NF_SNMP_PDUTYPE_SET      => 3;
use constant NF_SNMP_PDUTYPE_TRAP     => 4;
use constant NF_SNMP_PDUTYPE_GETBULK  => 5;
use constant NF_SNMP_PDUTYPE_INFORM   => 6;
use constant NF_SNMP_PDUTYPE_V2TRAP   => 7;
use constant NF_SNMP_PDUTYPE_REPORT   => 8;
use constant NF_SNMP_GENERICTRAP_COLDSTART          => 0;
use constant NF_SNMP_GENERICTRAP_WARMSTART          => 1;
use constant NF_SNMP_GENERICTRAP_LINKDOWN           => 1;
use constant NF_SNMP_GENERICTRAP_LINKUP             => 3;
use constant NF_SNMP_GENERICTRAP_AUTHFAIL           => 4;
use constant NF_SNMP_GENERICTRAP_EGPNEIGHBORLOSS    => 5;
use constant NF_SNMP_GENERICTRAP_ENTERPRISESPECIFIC => 6;
use constant NF_SNMP_VARBINDTYPE_INTEGER   => 0;
use constant NF_SNMP_VARBINDTYPE_STRING    => 1;
use constant NF_SNMP_VARBINDTYPE_OID       => 2;
use constant NF_SNMP_VARBINDTYPE_IPADDR    => 3;
use constant NF_SNMP_VARBINDTYPE_COUNTER32 => 4;
use constant NF_SNMP_VARBINDTYPE_GUAGE32   => 5;
use constant NF_SNMP_VARBINDTYPE_TIMETICKS => 6;
use constant NF_SNMP_VARBINDTYPE_OPAQUE    => 7;
use constant NF_SNMP_VARBINDTYPE_COUNTER64 => 8;
use constant NF_SNMP_VARBINDTYPE_NULL      => 9;

our @AS = qw(
   version
   community
   pdu_type
   requestId
   errorStatus
   errorIndex
   entOid
   agentAddr
   genericTrap
   specificTrap
   timeticks
   nonRepeaters
   maxRepetitions
);
our @AA = qw(
   varbindlist
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);
__PACKAGE__->cgBuildAccessorsArray(\@AA);

#no strict 'vars';

use Socket qw(inet_ntoa AF_INET IPPROTO_TCP);

my $AF_INET6 = eval { Socket::AF_INET6() };
my $NI_NUMERICHOST = eval { Socket::NI_NUMERICHOST() };

use Convert::ASN1;

our $asn = Convert::ASN1->new;
$asn->prepare("
   Message ::= SEQUENCE {
      version   INTEGER,
      community STRING,
      pdu_type  PDUs
   }
   PDUs ::= CHOICE {
      get_request      GetRequest_PDU,
      get_next_request GetNextRequest_PDU,
      response         Response_PDU,
      set_request      SetRequest_PDU,
      trap             Trap_PDU,
      get_bulk_request GetBulkRequest_PDU,
      inform_request   InformRequest_PDU,
      snmpV2_trap      SNMPv2_Trap_PDU,
      report           Report_PDU
   }
   GetRequest_PDU     ::= [0] IMPLICIT PDU
   GetNextRequest_PDU ::= [1] IMPLICIT PDU
   Response_PDU       ::= [2] IMPLICIT PDU
   SetRequest_PDU     ::= [3] IMPLICIT PDU
   Trap_PDU           ::= [4] IMPLICIT TrapPDU
   GetBulkRequest_PDU ::= [5] IMPLICIT BulkPDU
   InformRequest_PDU  ::= [6] IMPLICIT PDU
   SNMPv2_Trap_PDU    ::= [7] IMPLICIT PDU
   Report_PDU         ::= [8] IMPLICIT PDU

   IPAddress ::= [APPLICATION 0] STRING
   Counter32 ::= [APPLICATION 1] INTEGER
   Guage32   ::= [APPLICATION 2] INTEGER
   TimeTicks ::= [APPLICATION 3] INTEGER
   Opaque    ::= [APPLICATION 4] STRING
   Counter64 ::= [APPLICATION 6] INTEGER

   PDU ::= SEQUENCE {
      requestId   INTEGER,
      errorStatus INTEGER,
      errorIndex  INTEGER,
      varbindlist VARBINDS
   }
   TrapPDU ::= SEQUENCE {
      entOid       OBJECT IDENTIFIER,
      agentAddr    IPAddress,
      genericTrap  INTEGER,
      specificTrap INTEGER,
      timeticks    TimeTicks,
      varbindlist  VARBINDS
   }
   BulkPDU ::= SEQUENCE {
      requestId      INTEGER,
      nonRepeaters   INTEGER,
      maxRepetitions INTEGER,
      varbindlist    VARBINDS
   }
   VARBINDS ::= SEQUENCE OF SEQUENCE {
      oid    OBJECT IDENTIFIER,
      value  CHOICE {
         integer   INTEGER,
         string    STRING,
         oid       OBJECT IDENTIFIER,
         ipaddr    IPAddress,
         counter32 Counter32,
         guage32   Guage32,
         timeticks TimeTicks,
         opaque    Opaque,
         counter64 Counter64,
         null      NULL
      }
   }
");
our $snmpasn = $asn->find('Message');
our @PDUTYPES = qw(get_request get_next_request response set_request trap get_bulk_request inform_request snmpV2_trap report);
our %PDUTYPES;
for (0..$#PDUTYPES) {
   $PDUTYPES{$PDUTYPES[$_]} = $_
}
our @VARBINDTYPES = qw(integer string oid ipaddr counter32 guage32 timeticks opaque counter64 null);

$Net::Frame::Layer::UDP::Next->{161} = "SNMP";
$Net::Frame::Layer::UDP::Next->{162} = "SNMP";

sub new {
   shift->SUPER::new(
      version     => NF_SNMP_VERSION_2,
      community   => 'public',
      requestId   => getRandom16bitsInt(),
      errorStatus => 0,
      errorIndex  => 0,
      varbindlist => [],
      @_,
      pdu_type    => NF_SNMP_PDUTYPE_GET,
   );
}

sub Get {
   shift->SUPER::new(
      version     => NF_SNMP_VERSION_2,
      community   => 'public',
      requestId   => getRandom16bitsInt(),
      errorStatus => 0,
      errorIndex  => 0,
      varbindlist => [],
      @_,
      pdu_type    => NF_SNMP_PDUTYPE_GET,
   );
}

sub GetNext {
   shift->SUPER::new(
      version     => NF_SNMP_VERSION_2,
      community   => 'public',
      requestId   => getRandom16bitsInt(),
      errorStatus => 0,
      errorIndex  => 0,
      varbindlist => [],
      @_,
      pdu_type    => NF_SNMP_PDUTYPE_GETNEXT,
   );
}

sub Response {
   shift->SUPER::new(
      version     => NF_SNMP_VERSION_2,
      community   => 'public',
      requestId   => getRandom16bitsInt(),
      errorStatus => 0,
      errorIndex  => 0,
      varbindlist => [],
      @_,
      pdu_type    => NF_SNMP_PDUTYPE_RESPONSE,
   );
}

sub Set {
   shift->SUPER::new(
      version     => NF_SNMP_VERSION_2,
      community   => 'public',
      requestId   => getRandom16bitsInt(),
      errorStatus => 0,
      errorIndex  => 0,
      varbindlist => [],
      @_,
      pdu_type    => NF_SNMP_PDUTYPE_SET,
   );
}

sub Trap {
   shift->SUPER::new(
      version      => NF_SNMP_VERSION_1,
      community    => 'public',
      entOid       => '1.3.6.1.4.1.50000',
      agentAddr    => '127.0.0.1',
      genericTrap  => NF_SNMP_GENERICTRAP_ENTERPRISESPECIFIC,
      specificTrap => 1,
      timeticks    => time(),
      varbindlist  => [],
      @_,
      pdu_type     => NF_SNMP_PDUTYPE_TRAP,
   );
}

sub GetBulk {
   shift->SUPER::new(
      version        => NF_SNMP_VERSION_2,
      community      => 'public',
      requestId      => getRandom16bitsInt(),
      nonRepeaters   => 0,
      maxRepetitions => 0,
      varbindlist    => [],
      @_,
      pdu_type       => NF_SNMP_PDUTYPE_GETBULK,
   );
}

sub Inform {
   shift->SUPER::new(
      version     => NF_SNMP_VERSION_2,
      community   => 'public',
      requestId   => getRandom16bitsInt(),
      errorStatus => 0,
      errorIndex  => 0,
      varbindlist => [],
      @_,
      pdu_type    => NF_SNMP_PDUTYPE_INFORM,
   );
}

sub V2Trap {
   shift->SUPER::new(
      version     => NF_SNMP_VERSION_2,
      community   => 'public',
      requestId   => getRandom16bitsInt(),
      errorStatus => 0,
      errorIndex  => 0,
      varbindlist => [],
      @_,
      pdu_type    => NF_SNMP_PDUTYPE_V2TRAP,
   );
}

sub Report {
   shift->SUPER::new(
      version     => NF_SNMP_VERSION_2,
      community   => 'public',
      requestId   => getRandom16bitsInt(),
      errorStatus => 0,
      errorIndex  => 0,
      varbindlist => [],
      @_,
      pdu_type    => NF_SNMP_PDUTYPE_REPORT,
   );
}

sub match {
   my $self = shift;
   my ($with) = @_;
   my $sPduType = $self->pdu_type;
   my $sReqId   = $self->requestId;
   my $wPduType = $with->pdu_type;
   my $wReqId   = $with->requestId;
   if ((($sPduType == NF_SNMP_PDUTYPE_GET) 
     || ($sPduType == NF_SNMP_PDUTYPE_GETNEXT) 
     || ($sPduType == NF_SNMP_PDUTYPE_SET) 
     || ($sPduType == NF_SNMP_PDUTYPE_GETBULK) 
     || ($sPduType == NF_SNMP_PDUTYPE_INFORM))

     && ($wPduType == NF_SNMP_PDUTYPE_RESPONSE)
     && ($sReqId == $wReqId)) {
      return 1;
   }
   0;
}

# XXX: may be better, by keying on type also
sub getKey        { shift->layer }
sub getKeyReverse { shift->layer }

sub getLength {    
   my $self = shift;

   return length($self->pack)
}

sub pack {
   my $self = shift;

   my $raw;
   if (($self->pdu_type == NF_SNMP_PDUTYPE_GET)
   ||  ($self->pdu_type == NF_SNMP_PDUTYPE_GETNEXT)
   ||  ($self->pdu_type == NF_SNMP_PDUTYPE_RESPONSE)
   ||  ($self->pdu_type == NF_SNMP_PDUTYPE_SET)
   ||  ($self->pdu_type == NF_SNMP_PDUTYPE_INFORM)
   ||  ($self->pdu_type == NF_SNMP_PDUTYPE_V2TRAP)
   ||  ($self->pdu_type == NF_SNMP_PDUTYPE_REPORT)) {
      $raw = $snmpasn->encode(
         version   => $self->version,
         community => $self->community,
         pdu_type  => {
            $PDUTYPES[$self->pdu_type] => {
               requestId   => $self->requestId,
               errorStatus => $self->errorStatus,
               errorIndex  => $self->errorIndex,
               varbindlist => [$self->varbindlist]
            }
         }
      );
      if (defined($snmpasn->error)) {
         print $snmpasn->error;
         return
      }
   } elsif ($self->pdu_type == NF_SNMP_PDUTYPE_TRAP) {
      my $agent_addr;
      if ($self->agentAddr =~ /:/) {
         $agent_addr = inet6Aton($self->agentAddr)
      } else {
         $agent_addr = inetAton($self->agentAddr)
      }
      $raw = $snmpasn->encode(
         version   => $self->version,
         community => $self->community,
         pdu_type  => {
            $PDUTYPES[$self->pdu_type] => {
               entOid       => $self->entOid,
               agentAddr    => $agent_addr,
               genericTrap  => $self->genericTrap,
               specificTrap => $self->specificTrap,
               timeticks    => $self->timeticks,
               varbindlist  => [$self->varbindlist]
            }
         }
      );
      if (defined($snmpasn->error)) {
         print $snmpasn->error;
         return
      }
   } elsif ($self->pdu_type == NF_SNMP_PDUTYPE_GETBULK) {
      $raw = $snmpasn->encode(
         version   => $self->version,
         community => $self->community,
         pdu_type  => {
            $PDUTYPES[$self->pdu_type] => {
               requestId      => $self->requestId,
               nonRepeaters   => $self->nonRepeaters,
               maxRepetitions => $self->maxRepetitions,
               varbindlist    => [$self->varbindlist]
            }
         }
      );
      if (defined($snmpasn->error)) {
         print $snmpasn->error;
         return
      }
   }

   return $self->raw($raw);
}

sub unpack {
   my $self = shift;

   my $pdu = $snmpasn->decode($self->raw);
   if (defined($snmpasn->error)) {
      print $snmpasn->error;
      return
   }

   $self->version($pdu->{version});
   $self->community($pdu->{community});
   my $pdutype = sprintf "%s", keys(%{$pdu->{pdu_type}});
   $self->pdu_type($PDUTYPES{$pdutype});
   if (($self->pdu_type == NF_SNMP_PDUTYPE_GET)
   ||  ($self->pdu_type == NF_SNMP_PDUTYPE_GETNEXT)
   ||  ($self->pdu_type == NF_SNMP_PDUTYPE_RESPONSE)
   ||  ($self->pdu_type == NF_SNMP_PDUTYPE_SET)
   ||  ($self->pdu_type == NF_SNMP_PDUTYPE_INFORM)
   ||  ($self->pdu_type == NF_SNMP_PDUTYPE_V2TRAP)
   ||  ($self->pdu_type == NF_SNMP_PDUTYPE_REPORT)) {
      $self->requestId($pdu->{pdu_type}->{$pdutype}->{requestId});
      $self->errorStatus($pdu->{pdu_type}->{$pdutype}->{errorStatus});
      $self->errorIndex($pdu->{pdu_type}->{$pdutype}->{errorIndex});
      $self->varbindlist($pdu->{pdu_type}->{$pdutype}->{varbindlist});
   } elsif ($self->pdu_type == NF_SNMP_PDUTYPE_TRAP) {
      $self->entOid($pdu->{pdu_type}->{$pdutype}->{entOid});
      $self->agentAddr(_inetNtoa($pdu->{pdu_type}->{$pdutype}->{agentAddr}));
      $self->genericTrap($pdu->{pdu_type}->{$pdutype}->{genericTrap});
      $self->specificTrap($pdu->{pdu_type}->{$pdutype}->{specificTrap});
      $self->timeticks($pdu->{pdu_type}->{$pdutype}->{timeticks});
      $self->varbindlist($pdu->{pdu_type}->{$pdutype}->{varbindlist});
   } elsif ($self->pdu_type == NF_SNMP_PDUTYPE_GETBULK) {
      $self->requestId($pdu->{pdu_type}->{$pdutype}->{requestId});
      $self->nonRepeaters($pdu->{pdu_type}->{$pdutype}->{nonRepeaters});
      $self->maxRepetitions($pdu->{pdu_type}->{$pdutype}->{maxRepetitions});
      $self->varbindlist($pdu->{pdu_type}->{$pdutype}->{varbindlist});
   }

   return $self;
}

sub encapsulate {
   my $self = shift;

   return $self->nextLayer if $self->nextLayer;

   if ($self->payload) {
      return 'SNMP';
   }

   NF_LAYER_NONE;
}

sub print {
   my $self = shift;

   my $l = $self->layer;

   my $buf = sprintf
      "$l: version:%d  community:%s  pdu:%s\n",
         $self->version, $self->community, $PDUTYPES[$self->pdu_type];

   if (($self->pdu_type == NF_SNMP_PDUTYPE_GET)
   ||  ($self->pdu_type == NF_SNMP_PDUTYPE_GETNEXT)
   ||  ($self->pdu_type == NF_SNMP_PDUTYPE_RESPONSE)
   ||  ($self->pdu_type == NF_SNMP_PDUTYPE_SET)
   ||  ($self->pdu_type == NF_SNMP_PDUTYPE_INFORM)
   ||  ($self->pdu_type == NF_SNMP_PDUTYPE_V2TRAP)
   ||  ($self->pdu_type == NF_SNMP_PDUTYPE_REPORT)) {
      $buf .= sprintf
         "$l: requestId:%d  errorStatus:%d  errorIndex:%d\n".
         "$l: varbindlist:",
            $self->requestId, $self->errorStatus, $self->errorIndex;
         if ($self->varbindlist != 0) {
            for my $varbind ($self->varbindlist) {
               $buf .= sprintf "\n$l: %s = ", $varbind->{oid};
               my $valueType = sprintf "%s", keys(%{$varbind->{value}});
               if ($valueType eq 'ipaddr') {
                  $buf .= sprintf "%s (%s)", _inetNtoa($varbind->{value}->{$valueType}), $valueType
               } elsif ($valueType eq 'null') {
                  $buf .= sprintf "(%s)", $valueType
               } elsif ($varbind->{value}->{$valueType} =~ /[\x00-\x1f\x7f-\xff]/s) {
                  $buf .= sprintf "0x%s ([hex]%s)", CORE::unpack ("H*", $varbind->{value}->{$valueType}), $valueType
               } else {
                  $buf .= sprintf "%s (%s)", $varbind->{value}->{$valueType}, $valueType
               }
            }
         }
   } elsif ($self->pdu_type == NF_SNMP_PDUTYPE_TRAP) {
      $buf .= sprintf
         "$l: entOid:%s  agentAddr:%s  genericTrap:%s\n".
         "$l: specificTrap:%d  timeTicks:%d\n".
         "$l: varbindlist:",
            $self->entOid, $self->agentAddr, $self->genericTrap,
            $self->specificTrap, $self->timeticks;
         if ($self->varbindlist != 0) {
            for my $varbind ($self->varbindlist) {
               $buf .= sprintf "\n$l: %s = ", $varbind->{oid};
               my $valueType = sprintf "%s", keys(%{$varbind->{value}});
               if ($valueType eq 'ipaddr') {
                  $buf .= sprintf "%s (%s)", _inetNtoa($varbind->{value}->{$valueType}), $valueType
               } elsif ($valueType eq 'null') {
                  $buf .= sprintf "(%s)", $valueType
               } elsif ($varbind->{value}->{$valueType} =~ /[\x00-\x1f\x7f-\xff]/s) {
                  $buf .= sprintf "0x%s ([hex]%s)", CORE::unpack ("H*", $varbind->{value}->{$valueType}), $valueType
               } else {
                  $buf .= sprintf "%s (%s)", $varbind->{value}->{$valueType}, $valueType
               }
            }
         }
   } elsif ($self->pdu_type == NF_SNMP_PDUTYPE_GETBULK) {
      $buf .= sprintf
         "$l: requestId:%d  nonRepeaters:%d  maxRepetitions:%d\n".
         "$l: varbindlist:",
            $self->requestId, $self->nonRepeaters, $self->maxRepetitions;
         if ($self->varbindlist != 0) {
            for my $varbind ($self->varbindlist) {
               $buf .= sprintf "\n$l: %s = ", $varbind->{oid};
               my $valueType = sprintf "%s", keys(%{$varbind->{value}});
               if ($valueType eq 'ipaddr') {
                  $buf .= sprintf "%s (%s)", _inetNtoa($varbind->{value}->{$valueType}), $valueType
               } elsif ($valueType eq 'null') {
                  $buf .= sprintf "(%s)", $valueType
               } elsif ($varbind->{value}->{$valueType} =~ /[\x00-\x1f\x7f-\xff]/s) {
                  $buf .= sprintf "0x%s ([hex]%s)", CORE::unpack ("H*", $varbind->{value}->{$valueType}), $valueType
               } else {
                  $buf .= sprintf "%s (%s)", $varbind->{value}->{$valueType}, $valueType
               }
            }
         }
   }

   return $buf;
}

####

sub varbinds {
   my $self = shift;

   my %params = (
      oid   => '1.3.6.1.4.1.50000',
      type  => $VARBINDTYPES[NF_SNMP_VARBINDTYPE_INTEGER],
      value => 1,
   );
   if (@_ == 1) {
      return(undef)
   } else {
      my %cfg = @_;
      for (keys(%cfg)) {
         if (/^-?oid$/i) {
            $params{'oid'} = $cfg{$_}
         } elsif (/^-?type$/i) {
            if (defined($VARBINDTYPES[$cfg{$_}])) {
               $params{'type'} = $VARBINDTYPES[$cfg{$_}]
            } else {
            print "$cfg{$_}\n";
               return undef
            }
         } elsif (/^-?value$/i) {
            $params{'value'} = $cfg{$_}
         }
      }
   }

   if ($params{'type'} eq 'ipaddr') {
      $params{'value'} = inetAton $params{'value'}
   }

   if ($params{'type'} eq 'null') {
      $params{'value'} = 1
   }

   my %hash = (
      oid   => $params{'oid'},
      value => {
         $params{'type'} => $params{'value'}
      }
   );

   return \%hash;
}

sub v2trap_varbinds {
   my $self = shift;

   my %params = (
      oid       => '1.3.6.1.4.1.50000',
      timeticks => time(),
   );
   if (@_ == 1) {
      return(undef)
   } else {
      my %cfg = @_;
      for (keys(%cfg)) {
         if (/^-?oid$/i) {
            $params{'oid'} = $cfg{$_}
         } elsif (/^-?time(?:ticks)?$/i) {
            $params{'timeticks'} = $cfg{$_}
         }
      }
   }

   my %hash1 = (
      oid   => '1.3.6.1.2.1.1.3.0',
      value => {
         timeticks => $params{'timeticks'}
      }
   );

   my %hash2 = (
      oid   => '1.3.6.1.6.3.1.1.4.1.0',
      value => {
         oid => $params{'oid'}
      }
   );

   my @varbinds;
   push @varbinds, \%hash1;
   push @varbinds, \%hash2;

   return @varbinds;
}

sub _inetNtoa {
    my ($addr) = @_;
    if (length($addr) == 4) {
        return inet_ntoa($addr)
    } else {
        return inet6Ntoa($addr)
    }
}

1;

__END__

=head1 NAME

Net::Frame::Layer::SNMP - Simple Network Management Protocol layer object

=head1 SYNOPSIS

   use Net::Frame::Simple;
   use Net::Frame::Layer::SNMP qw(:consts);

   my $snmp = Net::Frame::Layer::SNMP->new(
      version     => NF_SNMP_VERSION_2,
      community   => 'public',
      requestId   => getRandom16bitsInt(),
      errorStatus => 0,
      errorIndex  => 0,
      varbindlist => [],
   );

   #
   # Read a raw layer
   #

   my $layer = Net::Frame::Layer::SNMP->new(raw => $raw);

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the SNMP layer.

See also B<Net::Frame::Layer> for other attributes and methods.

=head1 ATTRIBUTES

=over 4

=item B<version>

SNMP version.  This module supports version 1 and version 2(c).

=item B<community>

SNMP community string.

=item B<requestId>

=item B<errorStatus>

=item B<errorIndex>

SNMP fields for Get, GetNext, Response, Set, Inform, V2Trap and Report PDU types.

=item B<entOid>

=item B<agentAddr>

=item B<genericTrap>

=item B<specificTrap>

=item B<timeticks>

SNMP fields for Trap PDU type.

=item B<nonRepeaters>

=item B<maxRepetitions>

SNMP fields for GetBulk PDU type.

=item B<varbindlist>

Variable bindings list.

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

Object constructor. You can pass attributes that will overwrite default ones. Synonymous with B<Get>.  See B<SYNOPSIS> for default values.

=item B<Get>

=item B<Get> (hash)

   my $snmp = Net::Frame::Layer::SNMP->Get(
      version     => NF_SNMP_VERSION_2,
      community   => 'public',
      requestId   => getRandom16bitsInt(),
      errorStatus => 0,
      errorIndex  => 0,
      varbindlist => [],
   );

=item B<GetNext>

=item B<GetNext> (hash)

   my $snmp = Net::Frame::Layer::SNMP->GetNext(
      version     => NF_SNMP_VERSION_2,
      community   => 'public',
      requestId   => getRandom16bitsInt(),
      errorStatus => 0,
      errorIndex  => 0,
      varbindlist => [],
   );

=item B<Response>

=item B<Response> (hash)

   my $snmp = Net::Frame::Layer::SNMP->Response(
      version     => NF_SNMP_VERSION_2,
      community   => 'public',
      requestId   => getRandom16bitsInt(),
      errorStatus => 0,
      errorIndex  => 0,
      varbindlist => [],
   );

=item B<Set>

=item B<Set> (hash)

   my $snmp = Net::Frame::Layer::SNMP->Set(
      version     => NF_SNMP_VERSION_2,
      community   => 'public',
      requestId   => getRandom16bitsInt(),
      errorStatus => 0,
      errorIndex  => 0,
      varbindlist => [],
   );

=item B<Trap>

=item B<Trap> (hash)

   my $snmp = Net::Frame::Layer::SNMP->Trap(
      version      => NF_SNMP_VERSION_1,
      community    => 'public',
      entOid       => '1.3.6.1.4.1.50000',
      agentAddr    => '127.0.0.1',
      genericTrap  => NF_SNMP_GENERICTRAP_ENTERPRISESPECIFIC,
      specificTrap => 1,
      timeticks    => time(),
      varbindlist  => [],
   );

=item B<GetBulk>

=item B<GetBulk> (hash)

   my $snmp = Net::Frame::Layer::SNMP->GetBulk(
      version        => NF_SNMP_VERSION_2,
      community      => 'public',
      requestId      => getRandom16bitsInt(),
      nonRepeaters   => 0,
      maxRepetitions => 0,
      varbindlist    => [],
   );

=item B<Inform>

=item B<Inform> (hash)

   my $snmp = Net::Frame::Layer::SNMP->Inform(
      version     => NF_SNMP_VERSION_2,
      community   => 'public',
      requestId   => getRandom16bitsInt(),
      errorStatus => 0,
      errorIndex  => 0,
      varbindlist => [],
   );

=item B<V2Trap>

=item B<V2Trap> (hash)

   my $snmp = Net::Frame::Layer::SNMP->V2Trap(
      version     => NF_SNMP_VERSION_2,
      community   => 'public',
      requestId   => getRandom16bitsInt(),
      errorStatus => 0,
      errorIndex  => 0,
      varbindlist => [],
   );

=item B<Report>

=item B<Report> (hash)

   my $snmp = Net::Frame::Layer::SNMP->Report(
      version     => NF_SNMP_VERSION_2,
      community   => 'public',
      requestId   => getRandom16bitsInt(),
      errorStatus => 0,
      errorIndex  => 0,
      varbindlist => [],
   );

Object constructors for SNMP PDU types.

=item B<getKey>

=item B<getKeyReverse>

These two methods are basically used to increase the speed when using B<recv> method from B<Net::Frame::Simple>. Usually, you write them when you need to write B<match> method.

=item B<match> (Net::Frame::Layer::SNMP object)

This method is mostly used internally. You pass a B<Net::Frame::Layer::SNMP> layer as a parameter, and it returns true if this is a response corresponding for the request, or returns false if not.

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

=head1 USEFUL SUBROUTINES

Load them: use Net::Frame::Layer::SNMP qw(:subs);

=over 4

=item B<varbinds> (hash)

   my $varbind = Net::Frame::Layer::SNMP->varbinds(
      oid   => '1.3.6.1.4.1.50000',
      type  => NF_SNMP_VARBINDTYPE_INTEGER,
      value => 1,
   );

Creates variable bindings.

=item B<v2trap_varbinds> (hash)

   my @varbinds = Net::Frame::Layer::SNMP->v2trap_varbinds(
      timeticks => time(),
      oid       => '1.3.6.1.4.1.50000'
   );

Creates the first two variable bindings for SNMPv2 traps.

=back

=head1 CONSTANTS

Load them: use Net::Frame::Layer::SNMP qw(:consts);

=over 4

=item B<NF_SNMP_VERSION_1>

=item B<NF_SNMP_VERSION_2>

SNMP versions.

=item B<NF_SNMP_PDUTYPE_GET>

=item B<NF_SNMP_PDUTYPE_GETNEXT>

=item B<NF_SNMP_PDUTYPE_RESPONSE>

=item B<NF_SNMP_PDUTYPE_SET>

=item B<NF_SNMP_PDUTYPE_TRAP>

=item B<NF_SNMP_PDUTYPE_GETBULK>

=item B<NF_SNMP_PDUTYPE_INFORM>

=item B<NF_SNMP_PDUTYPE_V2TRAP>

=item B<NF_SNMP_PDUTYPE_REPORT>

SNMP PDU types.

=item B<NF_SNMP_GENERICTRAP_COLDSTART>

=item B<NF_SNMP_GENERICTRAP_WARMSTART>

=item B<NF_SNMP_GENERICTRAP_LINKDOWN>

=item B<NF_SNMP_GENERICTRAP_LINKUP>

=item B<NF_SNMP_GENERICTRAP_AUTHFAIL>

=item B<NF_SNMP_GENERICTRAP_EGPNEIGHBORLOSS>

=item B<NF_SNMP_GENERICTRAP_ENTERPRISESPECIFIC>

SNMP version 1 generic trap types.

=item B<NF_SNMP_VARBINDTYPE_INTEGER>

=item B<NF_SNMP_VARBINDTYPE_STRING>

=item B<NF_SNMP_VARBINDTYPE_OID>

=item B<NF_SNMP_VARBINDTYPE_IPADDR>

=item B<NF_SNMP_VARBINDTYPE_COUNTER32>

=item B<NF_SNMP_VARBINDTYPE_GUAGE32>

=item B<NF_SNMP_VARBINDTYPE_TIMETICKS>

=item B<NF_SNMP_VARBINDTYPE_OPAQUE>

=item B<NF_SNMP_VARBINDTYPE_COUNTER64>

=item B<NF_SNMP_VARBINDTYPE_NULL>

SNMP variable binding types.

=back

=head1 LIMITATIONS

All OIDs must be entered in numerical format.

=head1 SEE ALSO

L<Net::Frame::Layer>

For a non B<Net::Frame::Layer> SNMP solution in Perl, L<Net::SNMP>.

=head1 AUTHOR

Michael Vincent

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2013, Michael Vincent

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
