# -*- mode: Perl -*-

BEGIN { unshift @INC, "lib" }
use strict;
use FileHandle;
use SNMP::MIB::Compiler;
use Data::Compare;

local $^W = 1;
$| = 1;

print "1..3\n";
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
unless ($value eq 'MODULE-COMPLIANCE') {
  print "not ok $t\n";
  exit 0;
}
$res = $mib->parse_modulecompliance();
my $good = {
  'oid' => [ 'fooMIBCompliances', 2 ],
  'description' => '"description of foo."',
  'status' => 'current',
  'module' => {
    'this' => {
      'mandatory-groups' => [
        'fooGroup',
        'fooSetGroup',
        'systemGroup',
        'fooBasicNotificationsGroup'
      ],
      'group' => {
        'fooCommunityGroup2' =>
		  '"This group is mandatory for foo entities too."',
        'fooCommunityGroup' =>
		  '"This group is mandatory for foo entities."'
      }
    }
  }
};
print Compare($res, $good) ? "" : "not ", "ok ", $t++, "\n";

# Test 2
($token, $value) = $mib->get_token('IDENTIFIER');
$node = $value;
($token, $value) = $mib->get_token('TYPEMODREFERENCE');
unless ($value eq 'MODULE-COMPLIANCE') {
  print "not ok $t\n";
  exit 0;
}
$res = $mib->parse_modulecompliance();
$good = {
  'oid' => [
    'snmpNotifyCompliances',
    1
  ],
  'description' => '"The compliance statement for minimal SNMP entities which
            implement only SNMP Traps and read-create operations on
            only the snmpTargetAddrTable."',
  'status' => 'current',
  'module' => {
    'this' => {
      'mandatory-groups' => [
        'snmpNotifyGroup'
      ],
      'object' => {
        'snmpNotifyType' => {
          'min-access' => 'read-only',
          'description' => '"Create/delete/modify access is not required.
                Support of the value notify(2) is not required."',
          'syntax' => {
            'values' => {
              1 => 'trap'
            },
            'type' => 'INTEGER'
          }
        },
        'snmpNotifyRowStatus' => {
          'min-access' => 'read-only',
          'description' => '"Create/delete/modify access to the
                snmpNotifyTable is not required.
                Support of the values notInService(2), notReady(3),
                createAndGo(4), createAndWait(5), and destroy(6) is
                not required."',
          'syntax' => {
            'values' => {
              1 => 'active'
            },
            'type' => 'INTEGER'
          }
        },
        'snmpNotifyTag' => {
          'min-access' => 'read-only',
          'description' => '"Create/delete/modify access is not required."'
        },
        'snmpNotifyStorageType' => {
          'min-access' => 'read-only',
          'description' => '"Create/delete/modify access is not required.
                Support of the values other(1), volatile(2),
                nonVolatile(3), and permanent(4) is not required."',
          'syntax' => {
            'values' => {
              5 => 'readOnly'
            },
            'type' => 'INTEGER'
          }
        }
      }
    },
    'SNMP-TARGET-MIB' => {
      'mandatory-groups' => [
        'snmpTargetBasicGroup'
      ],
      'object' => {
        'snmpTargetParamsStorageType' => {
          'min-access' => 'read-only',
          'description' => '"Create/delete/modify access is not required.
                Support of the values other(1), volatile(2),
                nonVolatile(3), and permanent(4) is not required."',
          'syntax' => {
            'values' => {
              5 => 'readOnly'
            },
            'type' => 'INTEGER'
          }
        },
        'snmpTargetParamsSecurityLevel' => {
          'min-access' => 'read-only',
          'description' => '"Create/delete/modify access is not required."'
        },
        'snmpTargetParamsSecurityName' => {
          'min-access' => 'read-only',
          'description' => '"Create/delete/modify access is not required."'
        },
        'snmpTargetParamsSecurityModel' => {
          'min-access' => 'read-only',
          'description' => '"Create/delete/modify access is not required."'
        },
        'snmpTargetParamsRowStatus' => {
          'min-access' => 'read-only',
          'description' => '"Create/delete/modify access to the
                snmpTargetParamsTable is not required.
                Support of the values notInService(2), notReady(3),
                createAndGo(4), createAndWait(5), and destroy(6) is
                not required."',
          'syntax' => {
            'values' => {
              1 => 'active'
            },
            'type' => 'INTEGER'
          }
        },
        'snmpTargetParamsMPModel' => {
          'min-access' => 'read-only',
          'description' => '"Create/delete/modify access is not required."'
        }
      }
    }
  }
};
print Compare($res, $good) ? "" : "not ", "ok ", $t++, "\n";

# Test 3
($token, $value) = $mib->get_token('IDENTIFIER');
$node = $value;
($token, $value) = $mib->get_token('TYPEMODREFERENCE');
unless ($value eq 'MODULE-COMPLIANCE') {
  print "not ok $t\n";
  exit 0;
}
$res = $mib->parse_modulecompliance();
$good = {
  'oid' => [ 'snmpNotifyCompliances', 2 ],
  'description' =>
	  '"The compliance statement for SNMP entities which implement
            SNMP Traps with filtering, and read-create operations on
            all related tables."',
  'status' => 'current',
  'module' => {
    'this' => {
      'mandatory-groups' => [ 'snmpNotifyGroup', 'snmpNotifyFilterGroup' ]
    },
    'SNMP-TARGET-MIB' => {
      'mandatory-groups' => [ 'snmpTargetBasicGroup' ]
    }
  }
};
print Compare($res, $good) ? "" : "not ", "ok ", $t++, "\n";

# end

__DATA__

-- test for MODULE-COMPLIANCE MACRO

foo MODULE-COMPLIANCE
         STATUS  current
         DESCRIPTION
                 "description of foo."
         MODULE  -- this module
             MANDATORY-GROUPS { fooGroup, fooSetGroup, systemGroup,
                                fooBasicNotificationsGroup }

             GROUP   fooCommunityGroup
             DESCRIPTION
                 "This group is mandatory for foo entities."

             GROUP   fooCommunityGroup2
             DESCRIPTION
                 "This group is mandatory for foo entities too."
         ::= { fooMIBCompliances 2 }

-- extracted from rfc2273

snmpNotifyBasicCompliance MODULE-COMPLIANCE
       STATUS      current
       DESCRIPTION
           "The compliance statement for minimal SNMP entities which
            implement only SNMP Traps and read-create operations on
            only the snmpTargetAddrTable."
       MODULE SNMP-TARGET-MIB
           MANDATORY-GROUPS { snmpTargetBasicGroup }

           OBJECT snmpTargetParamsMPModel
           MIN-ACCESS    read-only
           DESCRIPTION
               "Create/delete/modify access is not required."

           OBJECT snmpTargetParamsSecurityModel
           MIN-ACCESS    read-only
           DESCRIPTION
               "Create/delete/modify access is not required."

           OBJECT snmpTargetParamsSecurityName
           MIN-ACCESS    read-only
           DESCRIPTION
               "Create/delete/modify access is not required."

           OBJECT snmpTargetParamsSecurityLevel
           MIN-ACCESS    read-only
           DESCRIPTION
               "Create/delete/modify access is not required."

           OBJECT snmpTargetParamsStorageType
           SYNTAX INTEGER {
               readOnly(5)
           }
           MIN-ACCESS    read-only
           DESCRIPTION
               "Create/delete/modify access is not required.
                Support of the values other(1), volatile(2),
                nonVolatile(3), and permanent(4) is not required."

           OBJECT snmpTargetParamsRowStatus
           SYNTAX INTEGER {
               active(1)
           }
           MIN-ACCESS    read-only
           DESCRIPTION
               "Create/delete/modify access to the
                snmpTargetParamsTable is not required.
                Support of the values notInService(2), notReady(3),
                createAndGo(4), createAndWait(5), and destroy(6) is
                not required."

       MODULE -- This Module
           MANDATORY-GROUPS { snmpNotifyGroup }

           OBJECT snmpNotifyTag
           MIN-ACCESS    read-only
           DESCRIPTION
               "Create/delete/modify access is not required."

           OBJECT snmpNotifyType
           SYNTAX INTEGER {
               trap(1)
           }
           MIN-ACCESS    read-only
           DESCRIPTION
               "Create/delete/modify access is not required.
                Support of the value notify(2) is not required."

           OBJECT snmpNotifyStorageType
           SYNTAX INTEGER {
               readOnly(5)
           }
           MIN-ACCESS    read-only
           DESCRIPTION
               "Create/delete/modify access is not required.
                Support of the values other(1), volatile(2),
                nonVolatile(3), and permanent(4) is not required."

           OBJECT snmpNotifyRowStatus
           SYNTAX INTEGER {
               active(1)
           }
           MIN-ACCESS    read-only
           DESCRIPTION
               "Create/delete/modify access to the
                snmpNotifyTable is not required.
                Support of the values notInService(2), notReady(3),
                createAndGo(4), createAndWait(5), and destroy(6) is
                not required."

       ::= { snmpNotifyCompliances 1 }

snmpNotifyBasicFiltersCompliance MODULE-COMPLIANCE
       STATUS      current
       DESCRIPTION
           "The compliance statement for SNMP entities which implement
            SNMP Traps with filtering, and read-create operations on
            all related tables."
       MODULE SNMP-TARGET-MIB
           MANDATORY-GROUPS { snmpTargetBasicGroup }
       MODULE -- This Module
           MANDATORY-GROUPS { snmpNotifyGroup,
                              snmpNotifyFilterGroup }
       ::= { snmpNotifyCompliances 2 }
