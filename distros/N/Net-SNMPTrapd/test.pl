#!/usr/bin/perl
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Net-SNMPTrapd.t'

use strict;
use warnings;
use Test::Simple tests => 5;
use ExtUtils::MakeMaker qw(prompt);

my $NUM_TESTS = 5;
my $VERBOSE = 0;

use Net::SNMPTrapd;
ok(1, "Loading Module"); # If we made it this far, we're ok.

#########################

print <<STOP;

  Net::SNMPTrapd needs the Net::SNMP module to perform 
  the full set of tests.  If you're not sure if you have 
  the Net::SNMP module, this will test for it before 
  running.

  To continue without running the tests (if perhaps you 
  know Net::SNMP is not available), simply press 'Enter'.


STOP

my $answer = prompt("Continue with tests? ('y' and 'Enter')", 'n');

if (lc($answer) ne 'y') {
    for (2..$NUM_TESTS) {
        ok(1, "Skipping test ...")
    }
    exit
}

#########################
# Test 2
sub start_server {
    my $snmptrapd = Net::SNMPTrapd->new();
    if (defined($snmptrapd)) {
        return $snmptrapd
    } else {
        printf "Error: %s\nDo you have a SNMP Trap receiver listening already?\n  ('netstat -an | grep 162')\n", Net::SNMPTrapd->error;
        return undef
    }
}
my $snmptrapd = start_server();
if (!defined($snmptrapd)) {
    ok(1, "Starting Server - Skipping remaining tests");
    for (3..$NUM_TESTS) {
        ok(1, "Skipping test ...")
    }
    exit
} else {
    ok(1, "Starting Server");
}

#########################
# Test 3
if ($snmptrapd->server->sockport == 162) {
    ok(1, "server() accessor");
} else {
    ok(0, "server() accessor");
}

#########################
# Test 4
sub test4 {

    eval 'use Net::SNMP qw(:ALL)';
    if ($@) {
        print "Error: Net::SNMP not found - skipping test ...\n";
        return 255
    }

    # Start Server
    my $FAILED = 0;

    # Fork: Server = Parent, Client = Child
    my $pid = fork();

    if (!defined($pid)) {
        print "Error: fork() - $!\n";
        return 1
    } elsif ($pid == 0) {
        #child
        sleep 2;

        # SNMPv1 Trap
        my ($session, $error) = Net::SNMP->session(
            -hostname  => 'localhost',
            -version   => 1,
            -community => 'public',
            -port      => 162
        );

        if (!defined($session)) {
           printf "Error: Starting SNMP session (v1 trap) - %s\n", $error;
           return 1
        }

        my $result = $session->trap(
            -enterprise   => '1.3.6.1.4.1.50000',
            -generictrap  => 6,
            -specifictrap => 1,
            -timestamp    => time(),
            -varbindlist  => [
                '1.3.6.1.4.1.50000.1.3',  0x02, 1,
                '1.3.6.1.4.1.50000.1.4',  0x04, 'String',
                '1.3.6.1.4.1.50000.1.5',  0x06, '1.2.3.4.5.6.7.8.9',
                '1.3.6.1.4.1.50000.1.6',  0x40, '10.10.10.1',
                '1.3.6.1.4.1.50000.1.7',  0x41, 32323232,
                '1.3.6.1.4.1.50000.1.8',  0x42, 42424242,
                '1.3.6.1.4.1.50000.1.9',  0x43, time(),
                '1.3.6.1.4.1.50000.1.10', 0x44, 'opaque data'
            ]
        );
        $session->close;

        # SNMPv2 Trap
        ($session, $error) = Net::SNMP->session(
            -hostname  => 'localhost',
            -version   => 2,
            -community => 'public',
            -port      => 162
        );

        if (!defined($session)) {
           printf "Error: Starting SNMP session (v2c trap) - %s\n", $error;
           return 1
        }

        $result = $session->snmpv2_trap(
            -varbindlist  => [
                '1.3.6.1.2.1.1.3.0',      0x43, time(),
                '1.3.6.1.6.3.1.1.4.1.0',  0x06, '1.3.6.1.4.1.50000',
                '1.3.6.1.4.1.50000.1.3',  0x02, 1,
                '1.3.6.1.4.1.50000.1.4',  0x04, 'String',
                '1.3.6.1.4.1.50000.1.5',  0x06, '1.2.3.4.5.6.7.8.9',
                '1.3.6.1.4.1.50000.1.6',  0x40, '10.10.10.1',
                '1.3.6.1.4.1.50000.1.7',  0x41, 32323232,
                '1.3.6.1.4.1.50000.1.8',  0x42, 42424242,
                '1.3.6.1.4.1.50000.1.9',  0x43, time(),
                '1.3.6.1.4.1.50000.1.10', 0x44, 'opaque data'
            ]
        );
        $session->close;

        # SNMPv2 InformRequest
        # This will keep sending until a Response is successfully sent from the Server or until timeout
        ($session, $error) = Net::SNMP->session(
            -hostname  => 'localhost',
            -version   => 2,
            -community => 'public',
            -port      => 162
        );

        if (!defined($session)) {
           printf "Error: Starting SNMP session (v2c InformRequest) - %s\n", $error;
           return 1
        }

        $result = $session->inform_request(
            -varbindlist  => [
                '1.3.6.1.2.1.1.3.0',      0x43, time(),
                '1.3.6.1.6.3.1.1.4.1.0',  0x06, '1.3.6.1.4.1.50000',
                '1.3.6.1.4.1.50000.1.3',  0x02, 1,
                '1.3.6.1.4.1.50000.1.4',  0x04, 'String',
                '1.3.6.1.4.1.50000.1.5',  0x06, '1.2.3.4.5.6.7.8.9',
                '1.3.6.1.4.1.50000.1.6',  0x40, '10.10.10.1',
                '1.3.6.1.4.1.50000.1.7',  0x41, 32323232,
                '1.3.6.1.4.1.50000.1.8',  0x42, 42424242,
                '1.3.6.1.4.1.50000.1.9',  0x43, time(),
                '1.3.6.1.4.1.50000.1.10', 0x44, 'opaque data'
            ]
        );
        $session->close;
        exit
    } else {
        # parent

        # PDU Type counter, see each PDU type (4, 7, 6) only once each
        my %T;

        # Loop 4 times, once for each PDU type and extra to see if InformRequest (6)
        # is send again meaning the server Response didn't work
        for (1..4) {
            my $trap;
            if (!($trap = $snmptrapd->get_trap())) {
                if (((my $error = sprintf "%s", Net::SNMPTrapd->error) eq "Timed out waiting for datagram") && ($_ == 4)) {
                    return $FAILED
                } else {
                    printf "Error: %s\n", Net::SNMPTrapd->error;
                    return 1
                }
            }
            if (!(defined($trap->process_trap()))) {
                printf "Error: %s\n", Net::SNMPTrapd->error;
                return 1
            } else {
if ($VERBOSE) {
                print "  -- $_ --\n";
                print "  remoteaddr = "; if (defined($trap->remoteaddr)  && ($trap->remoteaddr eq "127.0.0.1"))            { printf "%s\n", $trap->remoteaddr                         } else { printf "  !ERROR! - %s\n", $trap->remoteaddr; $FAILED++ }
                print "  remoteport = "; if (defined($trap->remoteport)  && ($trap->remoteport =~ /^\d{1,5}$/))            { printf "%s\n", $trap->remoteport                         } else { printf "  !ERROR! - %s\n", $trap->remoteport; $FAILED++ }

                print "  version    = "; if (defined($trap->version)     && ($trap->version =~ /^[12]$/))                  { printf "%s\n", $trap->version                            } else { printf "  !ERROR! - %s\n", $trap->version;   $FAILED++ }
                print "  community  = "; if (defined($trap->community)   && ($trap->community eq 'public'))                { printf "%s\n", $trap->community                          } else { printf "  !ERROR! - %s\n", $trap->community; $FAILED++ }
                print "  pdu_type   = "; if (defined($trap->pdu_type)    && ($trap->pdu_type(1) =~ /^[467]$/))             { printf "%s\n", $trap->pdu_type; $T{$trap->pdu_type(1)}++ } else { printf "  !ERROR! - %s\n", $trap->pdu_type;  $FAILED++ }
                # Make sure we've seen each PDU type only once
                for (keys(%T)) {
                    if ($T{$_} > 1) {
                        print "  !ERROR! - PDU type $_ seen $T{$_} times\n";  $FAILED++ 
                    }
                }
                if ($trap->version == 1) {
                print "  ent_OID    = "; if (defined($trap->ent_OID)       && ($trap->ent_OID eq "1.3.6.1.4.1.50000"))       { printf "%s\n", $trap->ent_OID       } else { printf "  !ERROR! - %s\n", $trap->ent_OID;       $FAILED++ }
                print "  agentaddr  = "; if (defined($trap->agentaddr)     && ($trap->agentaddr eq "127.0.0.1"))             { printf "%s\n", $trap->agentaddr     } else { printf "  !ERROR! - %s\n", $trap->agentaddr;     $FAILED++ }
                print "  generic    = "; if (defined($trap->generic_trap)  && ($trap->generic_trap eq "ENTERPRISESPECIFIC")) { printf "%s\n", $trap->generic_trap  } else { printf "  !ERROR! - %s\n", $trap->generic_trap;  $FAILED++ }
                print "  specific   = "; if (defined($trap->specific_trap) && ($trap->specific_trap == 1))                   { printf "%s\n", $trap->specific_trap } else { printf "  !ERROR! - %s\n", $trap->Specific_trap; $FAILED++ }
                print "  timeticks  = "; if (defined($trap->timeticks)     && ($trap->timeticks =~ /^\d+$/))                 { printf "%s\n", $trap->timeticks     } else { printf "  !ERROR! - %s\n", $trap->timeticks;     $FAILED++ }
                print "  varbind    = "; if (defined($trap->varbinds->[0]->{'1.3.6.1.4.1.50000.1.3'})  && ($trap->varbinds->[0]->{'1.3.6.1.4.1.50000.1.3'} == 1))                   { printf "%s\n", $trap->varbinds->[0]->{'1.3.6.1.4.1.50000.1.3'}  } else { printf "  !ERROR! - %s\n", $trap->varbinds->[0]->{'1.3.6.1.4.1.50000.1.3'}; $FAILED++ }
                print "  varbind    = "; if (defined($trap->varbinds->[1]->{'1.3.6.1.4.1.50000.1.4'})  && ($trap->varbinds->[1]->{'1.3.6.1.4.1.50000.1.4'} eq 'String'))            { printf "%s\n", $trap->varbinds->[1]->{'1.3.6.1.4.1.50000.1.4'}  } else { printf "  !ERROR! - %s\n", $trap->varbinds->[1]->{'1.3.6.1.4.1.50000.1.4'}; $FAILED++ }
                print "  varbind    = "; if (defined($trap->varbinds->[2]->{'1.3.6.1.4.1.50000.1.5'})  && ($trap->varbinds->[2]->{'1.3.6.1.4.1.50000.1.5'} eq '1.2.3.4.5.6.7.8.9')) { printf "%s\n", $trap->varbinds->[2]->{'1.3.6.1.4.1.50000.1.5'}  } else { printf "  !ERROR! - %s\n", $trap->varbinds->[2]->{'1.3.6.1.4.1.50000.1.5'}; $FAILED++ }
                print "  varbind    = "; if (defined($trap->varbinds->[3]->{'1.3.6.1.4.1.50000.1.6'})  && ($trap->varbinds->[3]->{'1.3.6.1.4.1.50000.1.6'} eq '10.10.10.1'))        { printf "%s\n", $trap->varbinds->[3]->{'1.3.6.1.4.1.50000.1.6'}  } else { printf "  !ERROR! - %s\n", $trap->varbinds->[3]->{'1.3.6.1.4.1.50000.1.6'}; $FAILED++ }
                print "  varbind    = "; if (defined($trap->varbinds->[4]->{'1.3.6.1.4.1.50000.1.7'})  && ($trap->varbinds->[4]->{'1.3.6.1.4.1.50000.1.7'} == 32323232))            { printf "%s\n", $trap->varbinds->[4]->{'1.3.6.1.4.1.50000.1.7'}  } else { printf "  !ERROR! - %s\n", $trap->varbinds->[4]->{'1.3.6.1.4.1.50000.1.7'}; $FAILED++ }
                print "  varbind    = "; if (defined($trap->varbinds->[5]->{'1.3.6.1.4.1.50000.1.8'})  && ($trap->varbinds->[5]->{'1.3.6.1.4.1.50000.1.8'} == 42424242))            { printf "%s\n", $trap->varbinds->[5]->{'1.3.6.1.4.1.50000.1.8'}  } else { printf "  !ERROR! - %s\n", $trap->varbinds->[5]->{'1.3.6.1.4.1.50000.1.8'}; $FAILED++ }
                print "  varbind    = "; if (defined($trap->varbinds->[6]->{'1.3.6.1.4.1.50000.1.9'})  && ($trap->varbinds->[6]->{'1.3.6.1.4.1.50000.1.9'} =~ /^\d+$/))             { printf "%s\n", $trap->varbinds->[6]->{'1.3.6.1.4.1.50000.1.9'}  } else { printf "  !ERROR! - %s\n", $trap->varbinds->[6]->{'1.3.6.1.4.1.50000.1.9'}; $FAILED++ }
                print "  varbind    = "; if (defined($trap->varbinds->[7]->{'1.3.6.1.4.1.50000.1.10'}) && ($trap->varbinds->[7]->{'1.3.6.1.4.1.50000.1.10'} eq 'opaque data'))      { printf "%s\n", $trap->varbinds->[7]->{'1.3.6.1.4.1.50000.1.10'} } else { printf "  !ERROR! - %s\n", $trap->varbinds->[7]->{'1.3.6.1.4.1.50000.1.10'}; $FAILED++ }
                } else {
                print "  requestID  = "; if (defined($trap->request_ID)    && ($trap->request_ID =~ /^\d+$/))                { printf "%s\n", $trap->request_ID    } else { printf "  !ERROR! - %s\n", $trap->request_ID;   $FAILED++ } 
                print "  errorstat  = "; if (defined($trap->error_status)  && ($trap->error_status =~ /^\d+$/))              { printf "%s\n", $trap->error_status  } else { printf "  !ERROR! - %s\n", $trap->error_status; $FAILED++ } 
                print "  errorindx  = "; if (defined($trap->error_index)   && ($trap->error_index =~ /^\d+$/))               { printf "%s\n", $trap->error_index   } else { printf "  !ERROR! - %s\n", $trap->error_index;  $FAILED++ } 
                print "  varbind    = "; if (defined($trap->varbinds->[0]->{'1.3.6.1.2.1.1.3.0'})      && ($trap->varbinds->[0]->{'1.3.6.1.2.1.1.3.0'} =~ /^\d+$/))                 { printf "%s\n", $trap->varbinds->[0]->{'1.3.6.1.2.1.1.3.0'}      } else { printf "  !ERROR! - %s\n", $trap->varbinds->[0]->{'1.3.6.1.2.1.1.3.0'}; $FAILED++ }
                print "  varbind    = "; if (defined($trap->varbinds->[1]->{'1.3.6.1.6.3.1.1.4.1.0'})  && ($trap->varbinds->[1]->{'1.3.6.1.6.3.1.1.4.1.0'} eq '1.3.6.1.4.1.50000')) { printf "%s\n", $trap->varbinds->[1]->{'1.3.6.1.6.3.1.1.4.1.0'}  } else { printf "  !ERROR! - %s\n", $trap->varbinds->[1]->{'1.3.6.1.6.3.1.1.4.1.0'}; $FAILED++ }
                print "  varbind    = "; if (defined($trap->varbinds->[2]->{'1.3.6.1.4.1.50000.1.3'})  && ($trap->varbinds->[2]->{'1.3.6.1.4.1.50000.1.3'} == 1))                   { printf "%s\n", $trap->varbinds->[2]->{'1.3.6.1.4.1.50000.1.3'}  } else { printf "  !ERROR! - %s\n", $trap->varbinds->[2]->{'1.3.6.1.4.1.50000.1.3'}; $FAILED++ }
                print "  varbind    = "; if (defined($trap->varbinds->[3]->{'1.3.6.1.4.1.50000.1.4'})  && ($trap->varbinds->[3]->{'1.3.6.1.4.1.50000.1.4'} eq 'String'))            { printf "%s\n", $trap->varbinds->[3]->{'1.3.6.1.4.1.50000.1.4'}  } else { printf "  !ERROR! - %s\n", $trap->varbinds->[3]->{'1.3.6.1.4.1.50000.1.4'}; $FAILED++ }
                print "  varbind    = "; if (defined($trap->varbinds->[4]->{'1.3.6.1.4.1.50000.1.5'})  && ($trap->varbinds->[4]->{'1.3.6.1.4.1.50000.1.5'} eq '1.2.3.4.5.6.7.8.9')) { printf "%s\n", $trap->varbinds->[4]->{'1.3.6.1.4.1.50000.1.5'}  } else { printf "  !ERROR! - %s\n", $trap->varbinds->[4]->{'1.3.6.1.4.1.50000.1.5'}; $FAILED++ }
                print "  varbind    = "; if (defined($trap->varbinds->[5]->{'1.3.6.1.4.1.50000.1.6'})  && ($trap->varbinds->[5]->{'1.3.6.1.4.1.50000.1.6'} eq '10.10.10.1'))        { printf "%s\n", $trap->varbinds->[5]->{'1.3.6.1.4.1.50000.1.6'}  } else { printf "  !ERROR! - %s\n", $trap->varbinds->[5]->{'1.3.6.1.4.1.50000.1.6'}; $FAILED++ }
                print "  varbind    = "; if (defined($trap->varbinds->[6]->{'1.3.6.1.4.1.50000.1.7'})  && ($trap->varbinds->[6]->{'1.3.6.1.4.1.50000.1.7'} == 32323232))            { printf "%s\n", $trap->varbinds->[6]->{'1.3.6.1.4.1.50000.1.7'}  } else { printf "  !ERROR! - %s\n", $trap->varbinds->[6]->{'1.3.6.1.4.1.50000.1.7'}; $FAILED++ }
                print "  varbind    = "; if (defined($trap->varbinds->[7]->{'1.3.6.1.4.1.50000.1.8'})  && ($trap->varbinds->[7]->{'1.3.6.1.4.1.50000.1.8'} == 42424242))            { printf "%s\n", $trap->varbinds->[7]->{'1.3.6.1.4.1.50000.1.8'}  } else { printf "  !ERROR! - %s\n", $trap->varbinds->[7]->{'1.3.6.1.4.1.50000.1.8'}; $FAILED++ }
                print "  varbind    = "; if (defined($trap->varbinds->[8]->{'1.3.6.1.4.1.50000.1.9'})  && ($trap->varbinds->[8]->{'1.3.6.1.4.1.50000.1.9'} =~ /^\d+$/))             { printf "%s\n", $trap->varbinds->[8]->{'1.3.6.1.4.1.50000.1.9'}  } else { printf "  !ERROR! - %s\n", $trap->varbinds->[8]->{'1.3.6.1.4.1.50000.1.9'}; $FAILED++ }
                print "  varbind    = "; if (defined($trap->varbinds->[9]->{'1.3.6.1.4.1.50000.1.10'}) && ($trap->varbinds->[9]->{'1.3.6.1.4.1.50000.1.10'} eq 'opaque data'))      { printf "%s\n", $trap->varbinds->[9]->{'1.3.6.1.4.1.50000.1.10'} } else { printf "  !ERROR! - %s\n", $trap->varbinds->[9]->{'1.3.6.1.4.1.50000.1.10'}; $FAILED++ }
                }
}
            }
        }
    }
    return $FAILED
}
my $result = test4();
if ($result == 0) {
    ok(1, "Received Message")
} elsif ($result == 255) {
    ok(1, "Received Message - Can't test since no Net::SNMP")
} else {
    ok(0, "Received Message")
}

$snmptrapd = undef;

#########################
# Test 5
sub test5 {

    eval 'use Net::SNMP qw(:ALL)';
    if ($@) {
        print "Error: Net::SNMP not found - skipping test ...\n";
        return 255
    }

    # Start Server
    my $FAILED = 0;

    use IO::Socket::INET;
    my $snmptrapd = IO::Socket::INET->new(
        'Proto'     => 'udp',
        'LocalPort' => 162,
        'Timeout'   => 10
    );

    if (!defined($snmptrapd)) {
        print "Error: creating socket\n";
        return 1
    }

    # Fork: Server = Parent, Client = Child
    my $pid = fork();

    if (!defined($pid)) {
        print "Error: fork() - $!\n";
        return 1
    } elsif ($pid == 0) {
        #child
        sleep 2;

        # SNMPv2 InformRequest
        # This will keep sending until a Response is successfully sent from the Server or until timeout
        my ($session, $error) = Net::SNMP->session(
            -hostname  => 'localhost',
            -version   => 2,
            -community => 'public',
            -port      => 162
        );

        if (!defined($session)) {
           printf "Error: Starting SNMP session (v2c InformRequest) - %s\n", $error;
           return 1
        }

        $result = $session->inform_request(
            -varbindlist  => [
                '1.3.6.1.2.1.1.3.0',      0x43, time(),
                '1.3.6.1.6.3.1.1.4.1.0',  0x06, '1.3.6.1.4.1.50000',
                '1.3.6.1.4.1.50000.1.3',  0x02, 1,
                '1.3.6.1.4.1.50000.1.4',  0x04, 'String',
                '1.3.6.1.4.1.50000.1.5',  0x06, '1.2.3.4.5.6.7.8.9',
                '1.3.6.1.4.1.50000.1.6',  0x40, '10.10.10.1',
                '1.3.6.1.4.1.50000.1.7',  0x41, 32323232,
                '1.3.6.1.4.1.50000.1.8',  0x42, 42424242,
                '1.3.6.1.4.1.50000.1.9',  0x43, time(),
                '1.3.6.1.4.1.50000.1.10', 0x44, 'opaque data'
            ]
        );
        $session->close;
        exit
    } else {
        # parent

        my $buffer;
        $snmptrapd->recv($buffer, 1500);
        my $trap;
        if (!defined($trap = Net::SNMPTrapd->process_trap($buffer))) {
            if ((my $error = sprintf "%s", Net::SNMPTrapd->error) eq "Error sending InformRequest Response - Server not defined") {
if ($VERBOSE) {
                printf "  -- Datagram with no address --\n  %s\n", Net::SNMPTrapd->error
}
            } else {
                return 1
            }
        }

        if (!defined($trap = Net::SNMPTrapd->process_trap(-datagram => $buffer, -noresponse => 1))) {
            printf "Error: %s\n", Net::SNMPTrapd->error;
            return 1
        } else {
if ($VERBOSE) {
            print "  -- process_trap() as sub --\n";
            print "  version   = "; if (defined($trap->version)       && ($trap->version =~ /^[12]$/))                  { printf "%s\n", $trap->version       } else { printf "  !ERROR! - %s\n", $trap->version;   $FAILED++ }
            print "  community = "; if (defined($trap->community)     && ($trap->community eq 'public'))                { printf "%s\n", $trap->community     } else { printf "  !ERROR! - %s\n", $trap->community; $FAILED++ }
            print "  pdu_type  = "; if (defined($trap->pdu_type)      && ($trap->pdu_type(1) =~ /^[467]$/))             { printf "%s\n", $trap->pdu_type;     } else { printf "  !ERROR! - %s\n", $trap->pdu_type;  $FAILED++ }
            print "  requestID = "; if (defined($trap->request_ID)    && ($trap->request_ID =~ /^\d+$/))                { printf "%s\n", $trap->request_ID    } else { printf "  !ERROR! - %s\n", $trap->request_ID;   $FAILED++ }
            print "  errorstat = "; if (defined($trap->error_status)  && ($trap->error_status =~ /^\d+$/))              { printf "%s\n", $trap->error_status  } else { printf "  !ERROR! - %s\n", $trap->error_status; $FAILED++ }
            print "  errorindx = "; if (defined($trap->error_index)   && ($trap->error_index =~ /^\d+$/))               { printf "%s\n", $trap->error_index   } else { printf "  !ERROR! - %s\n", $trap->error_index;  $FAILED++ }
            print "  varbind   = "; if (defined($trap->varbinds->[0]->{'1.3.6.1.2.1.1.3.0'})      && ($trap->varbinds->[0]->{'1.3.6.1.2.1.1.3.0'} =~ /^\d+$/))                 { printf "%s\n", $trap->varbinds->[0]->{'1.3.6.1.2.1.1.3.0'}      } else { printf "  !ERROR! - %s\n", $trap->varbinds->[0]->{'1.3.6.1.2.1.1.3.0'}; $FAILED++ }
            print "  varbind   = "; if (defined($trap->varbinds->[1]->{'1.3.6.1.6.3.1.1.4.1.0'})  && ($trap->varbinds->[1]->{'1.3.6.1.6.3.1.1.4.1.0'} eq '1.3.6.1.4.1.50000')) { printf "%s\n", $trap->varbinds->[1]->{'1.3.6.1.6.3.1.1.4.1.0'}  } else { printf "  !ERROR! - %s\n", $trap->varbinds->[1]->{'1.3.6.1.6.3.1.1.4.1.0'}; $FAILED++ }
            print "  varbind   = "; if (defined($trap->varbinds->[2]->{'1.3.6.1.4.1.50000.1.3'})  && ($trap->varbinds->[2]->{'1.3.6.1.4.1.50000.1.3'} == 1))                   { printf "%s\n", $trap->varbinds->[2]->{'1.3.6.1.4.1.50000.1.3'}  } else { printf "  !ERROR! - %s\n", $trap->varbinds->[2]->{'1.3.6.1.4.1.50000.1.3'}; $FAILED++ }
            print "  varbind   = "; if (defined($trap->varbinds->[3]->{'1.3.6.1.4.1.50000.1.4'})  && ($trap->varbinds->[3]->{'1.3.6.1.4.1.50000.1.4'} eq 'String'))            { printf "%s\n", $trap->varbinds->[3]->{'1.3.6.1.4.1.50000.1.4'}  } else { printf "  !ERROR! - %s\n", $trap->varbinds->[3]->{'1.3.6.1.4.1.50000.1.4'}; $FAILED++ }
            print "  varbind   = "; if (defined($trap->varbinds->[4]->{'1.3.6.1.4.1.50000.1.5'})  && ($trap->varbinds->[4]->{'1.3.6.1.4.1.50000.1.5'} eq '1.2.3.4.5.6.7.8.9')) { printf "%s\n", $trap->varbinds->[4]->{'1.3.6.1.4.1.50000.1.5'}  } else { printf "  !ERROR! - %s\n", $trap->varbinds->[4]->{'1.3.6.1.4.1.50000.1.5'}; $FAILED++ }
            print "  varbind   = "; if (defined($trap->varbinds->[5]->{'1.3.6.1.4.1.50000.1.6'})  && ($trap->varbinds->[5]->{'1.3.6.1.4.1.50000.1.6'} eq '10.10.10.1'))        { printf "%s\n", $trap->varbinds->[5]->{'1.3.6.1.4.1.50000.1.6'}  } else { printf "  !ERROR! - %s\n", $trap->varbinds->[5]->{'1.3.6.1.4.1.50000.1.6'}; $FAILED++ }
            print "  varbind   = "; if (defined($trap->varbinds->[6]->{'1.3.6.1.4.1.50000.1.7'})  && ($trap->varbinds->[6]->{'1.3.6.1.4.1.50000.1.7'} == 32323232))            { printf "%s\n", $trap->varbinds->[6]->{'1.3.6.1.4.1.50000.1.7'}  } else { printf "  !ERROR! - %s\n", $trap->varbinds->[6]->{'1.3.6.1.4.1.50000.1.7'}; $FAILED++ }
            print "  varbind   = "; if (defined($trap->varbinds->[7]->{'1.3.6.1.4.1.50000.1.8'})  && ($trap->varbinds->[7]->{'1.3.6.1.4.1.50000.1.8'} == 42424242))            { printf "%s\n", $trap->varbinds->[7]->{'1.3.6.1.4.1.50000.1.8'}  } else { printf "  !ERROR! - %s\n", $trap->varbinds->[7]->{'1.3.6.1.4.1.50000.1.8'}; $FAILED++ }
            print "  varbind   = "; if (defined($trap->varbinds->[8]->{'1.3.6.1.4.1.50000.1.9'})  && ($trap->varbinds->[8]->{'1.3.6.1.4.1.50000.1.9'} =~ /^\d+$/))             { printf "%s\n", $trap->varbinds->[8]->{'1.3.6.1.4.1.50000.1.9'}  } else { printf "  !ERROR! - %s\n", $trap->varbinds->[8]->{'1.3.6.1.4.1.50000.1.9'}; $FAILED++ }
            print "  varbind   = "; if (defined($trap->varbinds->[9]->{'1.3.6.1.4.1.50000.1.10'}) && ($trap->varbinds->[9]->{'1.3.6.1.4.1.50000.1.10'} eq 'opaque data'))      { printf "%s\n", $trap->varbinds->[9]->{'1.3.6.1.4.1.50000.1.10'} } else { printf "  !ERROR! - %s\n", $trap->varbinds->[9]->{'1.3.6.1.4.1.50000.1.10'}; $FAILED++ }
}
        }

        my ($rin, $rout, $ein, $eout) = ('', '', '', '');
        vec($rin, fileno($snmptrapd), 1) = 1;

        # check if a message is waiting
        if (select($rout=$rin, undef, $eout=$ein, 10)) {
            if ($snmptrapd->recv($buffer, 1500)) {
if ($VERBOSE) {
                print "  -- OK! Received extra InformRequest due to -noresponse --\n"
}
            } else {
if ($VERBOSE) {
                print "  -- FAIL! recv() error waiting for extra InformRequest --\n"
}
            }
        } else {
if ($VERBOSE) {
            print "  -- FAIL! Did *NOT* receive extra InformRequest --\n"
}
        }
    }
    return $FAILED
}
$result = test5();
if ($result == 0) {
    ok(1, "Process as sub")
} elsif ($result == 255) {
    ok(1, "Process as sub - Can't test since no Net::SNMP")
} else {
    ok(0, "Process as sub")
}
