# -*- mode: Perl -*-

BEGIN { unshift @INC, "lib", "../lib" }
use strict;
use FileHandle;
use SNMP::MIB::Compiler;
use Data::Compare;

local $^W = 1;
$| = 1;

print "1..1\n";
my $t = 1;

my $mib = new SNMP::MIB::Compiler();
$mib->{'filename'} = '<DATA>';
$mib->{'debug_lexer'} = 0;

# create a stream to the pseudo MIB file
my $s = Stream->new(*DATA);
$mib->{'stream'} = $s;

my ($res, $ref, $token, $value);

# Test 1
($token, $value) = $mib->get_token('IDENTIFIER');
my $node = $value;
($token, $value) = $mib->get_token('TYPEMODREFERENCE');
unless ($value eq 'AGENT-CAPABILITIES') {
  print "not ok $t\n";
  exit 0;
}
$res = $mib->parse_agentcapabilities();
my $good = {
  'supports' => {
    'SNMPv2-MIB' => {
      'variation' => {
        'coldStart' => {
          'description' => '"A coldStart trap is generated on all
                         reboots."'
        }
      },
      'includes' => [ 'systemGroup', 'snmpGroup', 'snmpSetGroup',
		      'snmpBasicNotificationsGroup' ]
    },
    'TCP-MIB' => {
      'variation' => {
        'tcpConnState' => {
          'access' => 'read-only',
          'description' => '"Unable to set this on 4BSD"'
        }
      },
      'includes' => [ 'tcpGroup' ]
    },
    'IF-MIB' => {
      'variation' => {
        'ifOperStatus' => {
          'description' => '"Information limited on 4BSD"',
          'syntax' => {
            'values' => { 1 => 'up', 2 => 'down' },
            'type' => 'INTEGER'
          }
        },
        'ifAdminStatus' => {
          'description' => '"Unable to set test mode on 4BSD"',
          'syntax' => {
            'values' => { 1 => 'up', 2 => 'down' },
            'type' => 'INTEGER'
          }
        }
      },
      'includes' => [ 'ifGeneralGroup', 'ifPacketGroup' ]
    },
    'EVAL-MIB' => {
      'variation' => {
        'exprEntry' => {
          'creation-requires' => [ 'evalString' ],
          'description' => '"Conceptual row creation supported"'
        }
      },
      'includes' => [ 'functionsGroup', 'expressionsGroup' ]
    },
    'UDP-MIB' => {
      'includes' => [ 'udpGroup' ]
    },
    'IP-MIB' => {
      'variation' => {
        'ipInAddrErrors' => {
          'access' => 'not-implemented',
          'description' => '"Information not available on 4BSD"'
        },
        'ipDefaultTTL' => {
          'description' => '"Hard-wired on 4BSD"',
          'syntax' => {
            'type' => 'INTEGER',
            'range' => { 'min' => 255, 'max' => 255 }
          }
        },
        'ipNetToMediaEntry' => {
          'creation-requires' => [ 'ipNetToMediaPhysAddress' ],
          'description' => '"Address mappings on 4BSD require
                         both protocol and media addresses"'
        }
      },
      'includes' => [ 'ipGroup', 'icmpGroup' ]
    }
  },
  'oid' => [ 'acmeAgents', 1 ],
  'description' => '"ACME agent for 4BSD"',
  'status' => 'current',
  'product-release' => '"ACME Agent release 1.1 for 4BSD"'
};

print Compare ($res, $good) ? "" : "not ", "ok 1\n";

# end

__DATA__

-- extracted from rfc1904.txt

exampleAgent AGENT-CAPABILITIES
    PRODUCT-RELEASE      "ACME Agent release 1.1 for 4BSD"
    STATUS               current
    DESCRIPTION          "ACME agent for 4BSD"

    SUPPORTS             SNMPv2-MIB
        INCLUDES         { systemGroup, snmpGroup, snmpSetGroup,
                           snmpBasicNotificationsGroup }

        VARIATION        coldStart
            DESCRIPTION  "A coldStart trap is generated on all
                         reboots."

    SUPPORTS             IF-MIB
        INCLUDES         { ifGeneralGroup, ifPacketGroup }

        VARIATION        ifAdminStatus
            SYNTAX       INTEGER { up(1), down(2) }
            DESCRIPTION  "Unable to set test mode on 4BSD"

        VARIATION        ifOperStatus
            SYNTAX       INTEGER { up(1), down(2) }
            DESCRIPTION  "Information limited on 4BSD"

    SUPPORTS             IP-MIB
        INCLUDES         { ipGroup, icmpGroup }

        VARIATION        ipDefaultTTL
            SYNTAX       INTEGER (255..255)
            DESCRIPTION  "Hard-wired on 4BSD"

        VARIATION        ipInAddrErrors
            ACCESS       not-implemented
            DESCRIPTION  "Information not available on 4BSD"

        VARIATION        ipNetToMediaEntry
            CREATION-REQUIRES { ipNetToMediaPhysAddress }
            DESCRIPTION  "Address mappings on 4BSD require
                         both protocol and media addresses"

    SUPPORTS             TCP-MIB
        INCLUDES         { tcpGroup }
        VARIATION        tcpConnState
            ACCESS       read-only
            DESCRIPTION  "Unable to set this on 4BSD"

    SUPPORTS             UDP-MIB
        INCLUDES         { udpGroup }

    SUPPORTS             EVAL-MIB
        INCLUDES         { functionsGroup, expressionsGroup }
        VARIATION        exprEntry
            CREATION-REQUIRES { evalString }
            DESCRIPTION "Conceptual row creation supported"

    ::= { acmeAgents 1 }
