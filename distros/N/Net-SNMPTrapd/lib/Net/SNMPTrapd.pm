package Net::SNMPTrapd;

########################################################
# AUTHOR = Michael Vincent
# www.VinsWorld.com
########################################################

use strict;
use warnings;
use version;
BEGIN { *Version:: = \*version:: }
# version module conflicts with 'sub version()' below.
# poor man's Package::Alias to avoid additional dependency
# http://www.perlmonks.org/?node_id=823772
use Convert::ASN1;
use Socket qw(inet_ntoa AF_INET IPPROTO_TCP);

my $AF_INET6 = eval { Socket::AF_INET6() };
my $NI_NUMERICHOST = eval { Socket::NI_NUMERICHOST() };

our $VERSION = '0.17';
our @ISA;

my $HAVE_IO_Socket_IP = 0;
eval "use IO::Socket::IP -register";
if(!$@) {
    $HAVE_IO_Socket_IP = 1;
    push @ISA, "IO::Socket::IP"
} else {
    require IO::Socket::INET;
    push @ISA, "IO::Socket::INET";
}

########################################################
# Start Variables
########################################################
use constant SNMPTRAPD_DEFAULT_PORT => 162;
use constant SNMPTRAPD_RFC_SIZE     => 484;   # RFC limit
use constant SNMPTRAPD_REC_SIZE     => 1472;  # Recommended size
use constant SNMPTRAPD_MAX_SIZE     => 65467; # Actual limit (65535 - IP/UDP)

my @TRAPTYPES = qw(COLDSTART WARMSTART LINKDOWN LINKUP AUTHFAIL EGPNEIGHBORLOSS ENTERPRISESPECIFIC);
my @PDUTYPES  = qw(GetRequest GetNextRequest Response SetRequest Trap GetBulkRequest InformRequest SNMPv2-Trap Report);
our $LASTERROR;

my $asn = Convert::ASN1->new;
$asn->prepare("
    PDU ::= SEQUENCE {
        version   INTEGER,
        community STRING,
        pdu_type  PDUs
    }
    PDUs ::= CHOICE {
        response        Response_PDU,
        trap            Trap_PDU,
        inform_request  InformRequest_PDU,
        snmpv2_trap     SNMPv2_Trap_PDU
    }
    Response_PDU      ::= [2] IMPLICIT PDUv2
    Trap_PDU          ::= [4] IMPLICIT PDUv1
    InformRequest_PDU ::= [6] IMPLICIT PDUv2
    SNMPv2_Trap_PDU   ::= [7] IMPLICIT PDUv2

    IPAddress ::= [APPLICATION 0] STRING
    Counter32 ::= [APPLICATION 1] INTEGER
    Guage32   ::= [APPLICATION 2] INTEGER
    TimeTicks ::= [APPLICATION 3] INTEGER
    Opaque    ::= [APPLICATION 4] STRING
    Counter64 ::= [APPLICATION 6] INTEGER

    PDUv1 ::= SEQUENCE {
        ent_oid         OBJECT IDENTIFIER,
        agent_addr      IPAddress,
        generic_trap    INTEGER,
        specific_trap   INTEGER,
        timeticks       TimeTicks,
        varbindlist     VARBINDS
    }
    PDUv2 ::= SEQUENCE {
        request_id      INTEGER,
        error_status    INTEGER,
        error_index     INTEGER,
        varbindlist     VARBINDS
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
my $snmpasn = $asn->find('PDU');
########################################################
# End Variables
########################################################

########################################################
# Start Public Module
########################################################

sub new {
    my $self = shift;
    my $class = ref($self) || $self;

    # Default parameters
    my %params = (
        'Proto'     => 'udp',
        'LocalPort' => SNMPTRAPD_DEFAULT_PORT,
        'Timeout'   => 10,
        'Family'    => AF_INET
    );

    if (@_ == 1) {
        $LASTERROR = "Insufficient number of args - @_";
        return undef
    } else {
        my %cfg = @_;
        for (keys(%cfg)) {
            if (/^-?localport$/i) {
                $params{LocalPort} = $cfg{$_}
            } elsif (/^-?localaddr$/i) {
                $params{LocalAddr} = $cfg{$_}
            } elsif (/^-?family$/i) {
                 if ($cfg{$_} =~ /^(?:(?:(:?ip)?v?(?:4|6))|${\AF_INET}|$AF_INET6)$/) {
                    if ($cfg{$_} =~ /^(?:(?:(:?ip)?v?4)|${\AF_INET})$/) {
                        $params{Family} = AF_INET
                    } else {
                        if (!$HAVE_IO_Socket_IP) {
                            $LASTERROR = "IO::Socket::IP required for IPv6";
                            return undef
                        }
                        $params{Family} = $AF_INET6;
                        if ($^O ne 'MSWin32') {
                            $params{V6Only} = 1
                        }
                    }
                } else {
                    $LASTERROR = "Invalid family - $cfg{$_}";
                    return undef
                }
            } elsif (/^-?timeout$/i) {
                if ($cfg{$_} =~ /^\d+$/) {
                    $params{Timeout} = $cfg{$_}
                } else {
                    $LASTERROR = "Invalid timeout - $cfg{$_}";
                    return undef
                }
            # pass through
            } else {
                $params{$_} = $cfg{$_}
            }
        }
    }

    if (my $udpserver = $class->SUPER::new(%params)) {
        return bless {
                      %params,         # merge user parameters
                      '_UDPSERVER_' => $udpserver
                     }, $class
    } else {
        $LASTERROR = "Error opening socket for listener: $@";
        return undef
    }
}

sub get_trap {
    my $self  = shift;
    my $class = ref($self) || $self;

    my $trap;

    foreach my $key (keys(%{$self})) {
        # everything but '_xxx_'
        $key =~ /^\_.+\_$/ and next;
        $trap->{$key} = $self->{$key}
    }

    my $datagramsize = SNMPTRAPD_MAX_SIZE;
    if (@_ == 1) {
        $LASTERROR = "Insufficient number of args: @_";
        return undef
    } else {
        my %args = @_;        
        for (keys(%args)) {
            # -maxsize
            if (/^-?(?:max)?size$/i) {
                if ($args{$_} =~ /^\d+$/) {
                    if (($args{$_} >= 1) && ($args{$_} <= SNMPTRAPD_MAX_SIZE)) {
                        $datagramsize = $args{$_}
                    }
                } elsif ($args{$_} =~ /^rfc$/i) {
                    $datagramsize = SNMPTRAPD_RFC_SIZE
                } elsif ($args{$_} =~ /^rec(?:ommend)?(?:ed)?$/i) {
                    $datagramsize = SNMPTRAPD_REC_SIZE
                } else {
                    $LASTERROR = "Not a valid size: $args{$_}";
                    return undef
                }
            # -timeout
            } elsif (/^-?timeout$/i) {
                if ($args{$_} =~ /^\d+$/) {
                    $trap->{Timeout} = $args{$_}
                } else {
                    $LASTERROR = "Invalid timeout - $args{$_}";
                    return undef
                }
            }
        }
    }

    my $Timeout = $trap->{Timeout};
    my $udpserver = $self->{_UDPSERVER_};
    my $datagram;

    if ($Timeout != 0) {
        # vars for IO select
        my ($rin, $rout, $ein, $eout) = ('', '', '', '');
        vec($rin, fileno($udpserver), 1) = 1;

        # check if a message is waiting
        if (! select($rout=$rin, undef, $eout=$ein, $Timeout)) {
            $LASTERROR = "Timed out waiting for datagram";
            return(0)
        }
    }

    # read the message
    if ($udpserver->recv($datagram, $datagramsize)) {

        $trap->{_UDPSERVER_} = $udpserver;
        $trap->{_TRAP_}{PeerPort} = $udpserver->SUPER::peerport;
        $trap->{_TRAP_}{PeerAddr} = $udpserver->SUPER::peerhost;
        $trap->{_TRAP_}{datagram} = $datagram;

        return bless $trap, $class
    }

    $LASTERROR = sprintf "Socket RECV error: $!";
    return undef
}

sub process_trap {
    my $self = shift;
    my $class = ref($self) || $self;

    ### Allow to be called as subroutine
    # Net::SNMPTrapd->process_trap($data)
    if (($self eq $class) && ($class eq __PACKAGE__)) {
        my %th;
        $self = \%th;
        ($self->{_TRAP_}{datagram}) = @_
    }
    # Net::SNMPTrapd::process_trap($data)
    if ($class ne __PACKAGE__) {
        my %th;
        $self = \%th;
        ($self->{_TRAP_}{datagram}) = $class;
        $class = __PACKAGE__
    }

    my $RESPONSE = 1; # Default is to send Response PDU for InformRequest
    # If more than 1 argument, parse the options
    if (@_ != 1) {
        my %args = @_;
        for (keys(%args)) {
            # -datagram
            if ((/^-?data(?:gram)?$/i) || (/^-?pdu$/i)) {
                $self->{_TRAP_}{datagram} = $args{$_}
            # -noresponse
            } elsif (/^-?noresponse$/i) {
                if (($args{$_} =~ /^\d+$/) && ($args{$_} > 0)) {
                    $RESPONSE = 0
                }
            }
        }
    }

    my $trap;
    if (!defined($trap = $snmpasn->decode($self->{_TRAP_}{datagram}))) {
        $LASTERROR = sprintf "Error decoding PDU - %s", (defined($snmpasn->error) ? $snmpasn->error : "Unknown Convert::ASN1->decode() error.  Consider $class dump()");
        return undef
    }
    #DEBUG: use Data::Dumper; print Dumper \$trap;

    # Only understand SNMPv1 (0) and v2c (1)
    if ($trap->{version} > 1) {
        $LASTERROR = sprintf "Unrecognized SNMP version - %i", $trap->{version};
        return undef
    }

    # set PDU Type for later use
    my $pdutype = sprintf "%s", keys(%{$trap->{pdu_type}});

    ### Assemble decoded trap object
    # Common
    $self->{_TRAP_}{version} = $trap->{version};
    $self->{_TRAP_}{community} = $trap->{community};
    if ($pdutype eq 'trap') {
        $self->{_TRAP_}{pdu_type} = 4
    
    } elsif ($pdutype eq 'inform_request') {
        $self->{_TRAP_}{pdu_type} = 6;

        # send response for InformRequest
        if ($RESPONSE) {
            if ((my $r = _InformRequest_Response(\$self, $trap, $pdutype)) ne 'OK') {
                $LASTERROR = sprintf "Error sending InformRequest Response - %s", $r;
                return undef
            }
        }

    } elsif ($pdutype eq 'snmpv2_trap') { 
        $self->{_TRAP_}{pdu_type} = 7
    }

    # v1
    if ($trap->{version} == 0) {
        $self->{_TRAP_}{ent_oid}       =           $trap->{pdu_type}->{$pdutype}->{ent_oid};
        $self->{_TRAP_}{agent_addr}    = _inetNtoa($trap->{pdu_type}->{$pdutype}->{agent_addr});
        $self->{_TRAP_}{generic_trap}  =           $trap->{pdu_type}->{$pdutype}->{generic_trap};
        $self->{_TRAP_}{specific_trap} =           $trap->{pdu_type}->{$pdutype}->{specific_trap};
        $self->{_TRAP_}{timeticks}     =           $trap->{pdu_type}->{$pdutype}->{timeticks};

    # v2c
    } elsif ($trap->{version} == 1) {
        $self->{_TRAP_}{request_id}   = $trap->{pdu_type}->{$pdutype}->{request_id};
        $self->{_TRAP_}{error_status} = $trap->{pdu_type}->{$pdutype}->{error_status};
        $self->{_TRAP_}{error_index}  = $trap->{pdu_type}->{$pdutype}->{error_index};
    }

    # varbinds
    my @varbinds;
    for my $i (0..$#{$trap->{pdu_type}->{$pdutype}->{varbindlist}}) {
        my %oidval;
        for (keys(%{$trap->{pdu_type}->{$pdutype}->{varbindlist}[$i]->{value}})) {
            # defined
            if (defined($trap->{pdu_type}->{$pdutype}->{varbindlist}[$i]->{value}{$_})) {
                # special cases:  IP address, null
                if ($_ eq 'ipaddr') {
                    $oidval{$trap->{pdu_type}->{$pdutype}->{varbindlist}[$i]->{oid}} = _inetNtoa($trap->{pdu_type}->{$pdutype}->{varbindlist}[$i]->{value}{$_})
                } elsif ($_ eq 'null') {
                    $oidval{$trap->{pdu_type}->{$pdutype}->{varbindlist}[$i]->{oid}} = '(NULL)'
                # no special case:  just assign it
                } else {
                    $oidval{$trap->{pdu_type}->{$pdutype}->{varbindlist}[$i]->{oid}} =           $trap->{pdu_type}->{$pdutype}->{varbindlist}[$i]->{value}{$_}
                }
            # not defined - ""
            } else {
                $oidval{$trap->{pdu_type}->{$pdutype}->{varbindlist}[$i]->{oid}} = ""
            }
        }
        push @varbinds, \%oidval
    }
    $self->{_TRAP_}{varbinds} = \@varbinds;

    return bless $self, $class
}

sub server {
    my $self = shift;
    return $self->{_UDPSERVER_}
}

sub datagram {
    my ($self, $arg) = @_;

    if (defined($arg) && ($arg >= 1)) {
        return unpack ('H*', $self->{_TRAP_}{datagram})
    } else {
        return $self->{_TRAP_}{datagram}
    }
}

sub remoteaddr {
    my $self = shift;
    return $self->{_TRAP_}{PeerAddr}
}

sub remoteport {
    my $self = shift;
    return $self->{_TRAP_}{PeerPort}
}

sub version {
    my $self = shift;
    return $self->{_TRAP_}{version} + 1
}

sub community {
    my $self = shift;
    return $self->{_TRAP_}{community}
}

sub pdu_type {
    my ($self, $arg) = @_;

    if (defined($arg) && ($arg >= 1)) {
        return $self->{_TRAP_}{pdu_type}
    } else {
        return $PDUTYPES[$self->{_TRAP_}{pdu_type}]
    }
}

sub ent_OID {
    my $self = shift;
    return $self->{_TRAP_}{ent_oid}
}

sub agentaddr {
    my $self = shift;
    return $self->{_TRAP_}{agent_addr}
}

sub generic_trap {
    my ($self, $arg) = @_;

    if (defined($arg) && ($arg >= 1)) {
        return $self->{_TRAP_}{generic_trap}
    } else {
        return $TRAPTYPES[$self->{_TRAP_}{generic_trap}]
    }
}

sub specific_trap {
    my $self = shift;
    return $self->{_TRAP_}{specific_trap}
}

sub timeticks {
    my $self = shift;
    return $self->{_TRAP_}{timeticks}
}

sub request_ID {
    my $self = shift;
    return $self->{_TRAP_}{request_id}
}

sub error_status {
    my $self = shift;
    return $self->{_TRAP_}{error_status}
}

sub error_index {
    my $self = shift;
    return $self->{_TRAP_}{error_index}
}

sub varbinds {
    my $self = shift;
    return $self->{_TRAP_}{varbinds}
}

sub error {
    return $LASTERROR
}

sub dump {
    my $self = shift;
    my $class = ref($self) || $self;

    ### Allow to be called as subroutine
    # Net::SNMPTrapd->dump($datagram)
    if (($self eq $class) && ($class eq __PACKAGE__)) {
        my %th;
        $self = \%th;
        ($self->{_TRAP_}{datagram}) = @_
    }
    # Net::SNMPTrapd::dump($datagram)
    if ($class ne __PACKAGE__) {
        my %th;
        $self = \%th;
        ($self->{_TRAP_}{datagram}) = $class;
        $class = __PACKAGE__
    }

    if (defined($self->{_TRAP_}{datagram})) {
        Convert::ASN1::asn_dump($self->{_TRAP_}{datagram});
        Convert::ASN1::asn_hexdump($self->{_TRAP_}{datagram});
    } else {
        $LASTERROR = "Missing datagram to dump";
        return undef
    }

    return 1
}

########################################################
# End Public Module
########################################################

########################################################
# Start Private subs
########################################################

sub _InformRequest_Response {

    my ($self, $trap, $pdutype) = @_;
    my $class = ref($$self) || $$self;

    #DEBUG print "BUFFER = $buffer\n";
    if (!defined $$self->{_UDPSERVER_}) {
        return "Server not defined"
    }

    # Change from request to response
    $trap->{pdu_type}{response} = delete $trap->{pdu_type}{inform_request};
    my $buffer = $snmpasn->encode($trap);
    if (!defined($buffer)) {
        return $snmpasn->error
    }

    # send Inform response
    my $socket = $$self->{_UDPSERVER_};
    $socket->send($buffer);

    # Change back to request from response
    $trap->{pdu_type}{inform_request} = delete $trap->{pdu_type}{response};
    return "OK"
}

sub _inetNtoa {
    my ($addr) = @_;

    if (Version->parse($Socket::VERSION) >= Version->parse(1.94)) {
        my $name;
        if (length($addr) == 4) {
            $name = Socket::pack_sockaddr_in(0, $addr)
        } else {
            $name = Socket::pack_sockaddr_in6(0, $addr)
        }
        my ($err, $address) = Socket::getnameinfo($name, $NI_NUMERICHOST);
        if (defined($address)) {
            return $address
        } else {
            $LASTERROR = "getnameinfo($addr) failed - $err";
            return undef
        }
    } else {
        if (length($addr) == 4) {
            return inet_ntoa($addr)
        } else {
            # Poor man's IPv6
            return join ':', (unpack '(a4)*', unpack ('H*', $addr))
        }
    }
}

########################################################
# End Private subs
########################################################

1;

__END__

########################################################
# Start POD
########################################################

=head1 NAME

Net::SNMPTrapd - Perl implementation of SNMP Trap Listener

=head1 SYNOPSIS

  use Net::SNMPTrapd;

  my $snmptrapd = Net::SNMPTrapd->new()
    or die "Error creating SNMPTrapd listener: ", Net::SNMPTrapd->error;

  while (1) {
      my $trap = $snmptrapd->get_trap();

      if (!defined($trap)) {
          printf "$0: %s\n", Net::SNMPTrapd->error;
          exit 1
      } elsif ($trap == 0) {
          next
      }

      if (!defined($trap->process_trap())) {
          printf "$0: %s\n", Net::SNMPTrapd->error
      } else {
          printf "%s\t%i\t%i\t%s\n", 
                 $trap->remoteaddr, 
                 $trap->remoteport, 
                 $trap->version, 
                 $trap->community
      }
  }

=head1 DESCRIPTION

Net::SNMPTrapd is a class implementing a simple SNMP Trap listener in 
Perl.  Net::SNMPTrapd will accept traps on the default SNMP Trap port 
(UDP 162) and attempt to decode them.  Net::SNMPTrapd supports SNMP v1 
and v2c traps and SNMPv2 InformRequest and implements the Reponse.

Net::SNMPTrapd uses Convert::ASN1 by Graham Barr to do the decoding.

=head1 METHODS

=head2 new() - create a new Net::SNMPTrapd object

  my $snmptrapd = Net::SNMPTrapd->new([OPTIONS]);

Create a new Net::SNMPTrapd object with OPTIONS as optional parameters.
Valid options are:

  Option     Description                            Default
  ------     -----------                            -------
  -Family    Address family IPv4/IPv6                  IPv4
               Valid values for IPv4:
                 4, v4, ip4, ipv4, AF_INET (constant)
               Valid values for IPv6:
                 6, v6, ip6, ipv6, AF_INET6 (constant)
  -LocalAddr Interface to bind to                       any
  -LocalPort Port to bind server to                     162
  -timeout   Timeout in seconds for socket               10
             operations and to wait for request

B<NOTE>:  IPv6 requires B<IO::Socket::IP>.  Failback is B<IO::Socket::INET> 
and only IPv4 support.
             
Allows the following accessors to be called.

=head3 server() - return IO::Socket::IP object for server

  $snmptrapd->server();

Return B<IO::Socket::IP> object for the created server.
All B<IO::Socket::IP> accessors can then be called.

=head2 get_trap() - listen for SNMP traps

  my $trap = $snmptrapd->get_trap([OPTIONS]);

Listen for SNMP traps.  Timeout after default or user specified
timeout set in C<new> method and return '0'.  If trap is received
before timeout, return is defined.  Return is not defined if error
encountered.

Valid options are:

  Option     Description                            Default
  ------     -----------                            -------
  -maxsize   Max size in bytes of acceptable PDU.     65467
             Value can be integer 1 <= # <= 65467.
             Keywords: 'RFC'         =  484
                       'recommended' = 1472
  -timeout   Timeout in seconds to wait for              10
             request.  Overrides value set with
             new().

Allows the following accessors to be called.

=head3 remoteaddr() - return remote address from SNMP trap

  $trap->remoteaddr();

Return remote address value from a received (C<get_trap()>)
SNMP trap.  This is the address from the IP header on the UDP
datagram.

=head3 remoteport() - return remote port from SNMP trap

  $trap->remoteport();

Return remote port value from a received (C<get_trap()>)
SNMP trap.  This is the port from the IP header on the UDP
datagram.

=head3 datagram() - return datagram from SNMP trap

  $trap->datagram([1]);

Return the raw datagram from a received (C<get_trap()>)
SNMP trap.  This is ASN.1 encoded datagram.  For a hex
dump, use the optional boolean argument.

=head2 process_trap() - process received SNMP trap

  $trap->process_trap([OPTIONS]);

Process a received SNMP trap.  Decodes the received (C<get_trap()>)
PDU.  Varbinds are extracted and decoded.  If PDU is SNMPv2
InformRequest, the Response PDU is generated and sent to IP 
address and UDP port found in the original datagram header 
(C<get_trap()> methods C<remoteaddr()> and C<remoteport()>).

Called with one argument, interpreted as the datagram to process.  
Valid options are:

  Option      Description                           Default
  ------      -----------                           -------
  -datagram   Datagram to process                   -Provided by
                                                     get_trap()-
  -noresponse Binary switch (0|1) meaning 'Do not    0
              send Response-PDU for InformRequest'  -Send Response-

This can also be called as a procedure if one is inclined to write 
their own UDP listener instead of using C<get_trap()>.  For example: 

  $sock = IO::Socket::IP->new( blah blah blah );
  $sock->recv($datagram, 1500);
  # process the ASN.1 encoded datagram in $datagram variable
  $trap = Net::SNMPTrapd->process_trap($datagram);

or

  # process the ASN.1 encoded datagram in $datagram variable
  # Do *NOT* send Response PDU if trap comes as InformRequest PDU
  $trap = Net::SNMPTrapd->process_trap(
                                       -datagram   => $datagram,
                                       -noresponse => 1
                                      );

In any instantiation, allows the following accessors to be called.

=head3 version() - return version from SNMP trap

  $trap->version();

Return SNMP Trap version from a received and processed 
(C<process_trap()>) SNMP trap.

B<NOTE:>  This module only supports SNMP v1 and v2c.

=head3 community() - return community from SNMP trap

  $trap->community();

Return community string from a received and processed 
(C<process_trap()>) SNMP trap.

=head3 pdu_type() - return PDU type from SNMP trap

  $trap->pdu_type([1]);

Return PDU type from a received and processed (C<process_trap()>) 
SNMP trap.  This is the text representation of the PDU type.  
For the raw number, use the optional boolean argument.

=head3 varbinds() - return varbinds from SNMP trap

  $trap->varbinds();

Return varbinds from a received and processed 
(C<process_trap()>) SNMP trap.  This returns a pointer to an array 
containing a hash as each array element.  The key/value pairs of 
each hash are the OID/value pairs for each varbind in the received 
trap.

  [{OID => value}]
  [{OID => value}]
  ...
  [{OID => value}]

An example extraction of the varbind data is provided:

  for my $vals (@{$trap->varbinds}) {
      for (keys(%{$vals})) {
          $p .= sprintf "%s: %s; ", $_, $vals->{$_}
      }
  }
  print "$p\n";

The above code will print the varbinds as:

  OID: value; OID: value; OID: value; [...]

=head3 SNMP v1 SPECIFIC

The following methods are SNMP v1 trap specific.

=head3 ent_OID() - return enterprise OID from SNMP v1 trap

  $trap->ent_OID();

Return enterprise OID from a received and processed 
(C<process_trap()>) SNMP v1 trap.

=head3 agentaddr() - return agent address from SNMP v1 trap

  $trap->agentaddr();

Return agent address from a received and processed 
(C<process_trap()>) SNMP v1 trap.

=head3 generic_trap() - return generic trap from SNMP v1 trap

  $trap->generic_trap([1]);

Return generic trap type from a received and processed 
(C<process_trap()>) SNMP v1 trap.  This is the text representation 
of the generic trap type.  For the raw number, use the optional 
boolean argument.

=head3 specific_trap() - return specific trap from SNMP v1 trap

  $trap->specific_trap();

Return specific trap type from a received and processed 
(C<process_trap()>) SNMP v1 trap.

=head3 timeticks() - return timeticks from SNMP v1 trap

  $trap->timeticks();

Return timeticks from a received and processed 
(C<process_trap()>) SNMP v1 trap.

=head3 SNMP v2c SPECIFIC

The following methods are SNMP v2c trap specific.

=head3 request_ID() - return request ID from SNMP v2c trap

  $trap->request_ID();

Return request ID from a received and processed 
(C<process_trap()>) SNMP v2c trap.

=head3 error_status() - return error status from SNMP v2c trap

  $trap->error_status();

Return error_status from a received and processed 
(C<process_trap()>) SNMP v2c trap.

=head3 error_index() - return error index from SNMP v2c trap

  $trap->error_index();

Return error index from a received and processed 
(C<process_trap()>) SNMP v2c trap.

=head2 error() - return last error

  printf "Error: %s\n", Net::SNMPTrapd->error;

Return last error.

=head2 dump() - Convert::ASN1 direct decode and hex dump

  $trap->dump();

or

  Net::SNMPTrapd->dump($datagram);

This does B<not> use any of the Net::SNMPTrapd ASN.1 structures; 
rather, it uses the Convert::ASN1 module debug routines (C<asn_dump> 
and C<asn_hexdump>) to attempt a decode and hex dump of the supplied 
datagram.  This is helpful to eliminate the entire Net::SNMPTrapd 
module code when troubleshooting issues with decoding and focus solely 
on the ASN.1 decode of the given datagram.

Called as a method, operates on the value returned from the 
C<datagram()> method.  Called as a subroutine, operates on the 
value passed.

Output is printed directly to STDERR.  Return is defined unless there 
is an error encountered in getting the datagram to operate on.

=head1 EXPORT

None by default.

=head1 EXAMPLES

This distribution comes with several scripts (installed to the default
"bin" install directory) that not only demonstrate example uses but also
provide functional execution.

=head1 SEE ALSO

Convert::ASN1

=head1 LICENSE

This software is released under the same terms as Perl itself.
If you don't know what that means visit L<http://perl.com/>.

=head1 AUTHOR

Copyright (C) Michael Vincent 2010

L<http://www.VinsWorld.com>

All rights reserved

=cut
