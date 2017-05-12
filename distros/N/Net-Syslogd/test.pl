#!/usr/bin/perl
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Net-SNMPTrapd.t'

use strict;
use warnings;
use Test::Simple tests => 21;
use ExtUtils::MakeMaker qw(prompt);

my $NUM_TESTS = 21;
my $VERBOSE   = 0;

use Net::Syslogd;
ok(1, "Loading Module"); # If we made it this far, we're ok.

#########################

print <<STOP;

  Net::Syslogd needs to open a network interface and fork 
  a server to perform the full set of tests.  If you're not 
  sure if you have this capability, this will test for it 
  before running.

  To continue without running the tests (if perhaps you 
  know they won't work), simply press 'Enter'.


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
    my $syslogd = Net::Syslogd->new();
    if (defined($syslogd)) {
        return $syslogd
    } else {
        printf "Error: %s\nDo you have a Syslog program listening already?\n  ('netstat -an | grep 514')\n", Net::Syslogd->error;
        return undef
    }
}
my $syslogd = start_server();
if (!defined($syslogd)) {
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
if ($syslogd->server->sockport == 514) {
    ok(1, "server() accessor");
} else {
    ok(0, "server() accessor");
}

#########################
# Test 4 - 20
sub receive_message {
    my @tests = (
        {
            name => 'Strict RFC 3164 format',
            data => '<189>Dec 11 12:31:15 10.10.10.1 AGENT[1234]: Strict RFC 3164 format'
        },

        {
            name => 'Net::Syslog format',
            data => '<189>AGENT[1234]: Net::Syslog format'
        },

        {
            name => 'Cisco: service timestamps log datetime',
            data => '<189>10: *Jan  7 16:28:06: %SYS-5-CONFIG_I: Configured from console by console'
        },

        {
            name => 'Cisco: service timestamps log datetime localtime',
            data => '<189>11: *Jan  7 11:36:06: %SYS-5-CONFIG_I: Configured from console by console'
        },

        {
            name => 'Cisco: service timestamps log datetime show-timezone',
            data => '<189>12: *Jan  7 16:36:41 UTC: %SYS-5-CONFIG_I: Configured from console by console'
        },

        {
            name => 'Cisco: service timestamps log datetime msec',
            data => '<189>13: *Jan  7 16:37:23.439: %SYS-5-CONFIG_I: Configured from console by console'
        },

        {
            name => 'Cisco: service timestamps log datetime year',
            data => '<189>14: *Jan  7 2011 16:38:17: %SYS-5-CONFIG_I: Configured from console by console'
        },

        {
            name => 'Cisco: service timestamps log datetime localtime show-timezone',
            data => '<189>15: *Jan  7 11:39:50 EST: %SYS-5-CONFIG_I: Configured from console by console'
        },

        {
            name => 'Cisco: service timestamps log datetime msec localtime',
            data => '<189>16: *Jan  7 11:40:20.723: %SYS-5-CONFIG_I: Configured from console by console'
        },

        {
            name => 'Cisco: service timestamps log datetime localtime year',
            data => '<189>17: *Jan  7 2011 11:40:47: %SYS-5-CONFIG_I: Configured from console by console'
        },

        {
            name => 'Cisco: service timestamps log datetime msec show-timezone',
            data => '<189>18: *Jan  7 16:41:20.575 UTC: %SYS-5-CONFIG_I: Configured from console by console'
        },

        {
            name => 'Cisco: service timestamps log datetime show-timezone year',
            data => '<189>19: *Jan  7 2011 16:41:51 UTC: %SYS-5-CONFIG_I: Configured from console by console'
        },

        {
            name => 'Cisco: service timestamps log datetime msec year',
            data => '<189>20: *Jan  7 2011 16:42:34.315: %SYS-5-CONFIG_I: Configured from console by console'
        },

        {
            name => 'Cisco: service timestamps log datetime msec localtime show-timezone',
            data => '<189>21: *Jan  7 11:42:56.387 EST: %SYS-5-CONFIG_I: Configured from console by console'
        },

        {
            name => 'Cisco: service timestamps log datetime localtime show-timezone year',
            data => '<189>22: *Jan  7 2011 11:43:15 EST: %SYS-5-CONFIG_I: Configured from console by console'
        },

        {
            name => 'Cisco: service timestamps log datetime msec show-timezone year',
            data => '<189>23: *Jan  7 2011 16:43:37.031 UTC: %SYS-5-CONFIG_I: Configured from console by console'
        },

        {
            name => 'Cisco: service timestamps log datetime msec localtime show-timezone year',
            data => '<189>24: *Jan  7 2011 11:44:02.671 EST: %SYS-5-CONFIG_I: Configured from console by console'
        }
    );

    my $pid = fork();

    if (!defined($pid)) {
        print "Error: fork() - $!\n";
        return 1
    } elsif ($pid == 0) {
        #child
        sleep 2;
        use IO::Socket::INET;
        my $sock=new IO::Socket::INET(
            PeerAddr => 'localhost',
            PeerPort => 514,
            Proto    => 'udp'
        );
        if (!defined($sock)) {
            printf "Error: Syslog send test could not start: %s\n", $sock->sockopt(SO_ERROR);
            return 1
        }

        for (@tests) {
            print $sock "$_->{data}"
        }
        $sock->close();
        exit
    } else {
        # parent
        my $FAILED = 0;

        for (@tests) {
            my $message;
            if (!($message = $syslogd->get_message())) {
                printf "Error: %s\n", Net::Syslogd->error;
                return 1
            }
            if (!(defined($message->process_message()))) {
                printf "Error: %s\n", Net::Syslogd->error;
                return 1
            } else {
                print "  -- $_->{name} --\n" if ($VERBOSE);

                print "  remoteaddr = " if ($VERBOSE);
                if (defined($message->remoteaddr) && ($message->remoteaddr eq "127.0.0.1")) { 
                    printf "%s\n", $message->remoteaddr if ($VERBOSE)
                } else { 
                    printf "  !ERROR! - %s\n", $message->remoteaddr if ($VERBOSE);
                    $FAILED++
                }

                print "  remoteport = " if ($VERBOSE);
                if (defined($message->remoteport) && ($message->remoteport =~ /^\d{1,5}$/)) {
                    printf "%s\n", $message->remoteport if ($VERBOSE);
                } else {
                    printf "  !ERROR! - %s\n", $message->remoteport if ($VERBOSE);
                    $FAILED++
                } 

                print "  facility = " if ($VERBOSE);
                if (defined($message->facility) && ($message->facility =~ /^local[567]$/)) {
                    printf "%s\n", $message->facility if ($VERBOSE);
                } else {
                    printf "  !ERROR! - %s\n", $message->facility if ($VERBOSE);
                    $FAILED++
                } 

                print "  severity = " if ($VERBOSE);
                if (defined($message->severity) && ($message->severity eq "Notice")) {
                    printf "%s\n", $message->severity if ($VERBOSE);
                } else {
                    printf "  !ERROR! - %s\n", $message->severity if ($VERBOSE);
                    $FAILED++
                }

                print "  time     = " if ($VERBOSE);
                if (defined($message->time) && (($message->time eq "0") || ($message->time =~ /^((?:[JFMASONDjfmasond]\w\w) {1,2}(?:\d+)(?: \d{4})* (?:\d{2}:\d{2}:\d{2}[\.\d{1,3}]*)(?: [A-Z]{1,3})*)$/))) {
                    printf "%s\n", $message->time if ($VERBOSE);
                } else {
                    printf "  !ERROR! - %s\n", $message->time if ($VERBOSE);
                    $FAILED++
                }

                print "  hostname = " if ($VERBOSE);
                if (defined($message->hostname) && (($message->hostname eq "0") || ($message->hostname eq "10.10.10.1"))) {
                    printf "%s\n", $message->hostname if ($VERBOSE);
                } else {
                    printf "  !ERROR! - %s\n", $message->hostname if ($VERBOSE);
                    $FAILED++
                } 

                print "  message  = " if ($VERBOSE);
                if (defined($message->message)) {
                    printf "%s\n", $message->message if ($VERBOSE);
                } else {
                    $FAILED++
                }
            }
            ok(!$FAILED, "$_->{name}");
            $FAILED = 0
        }
    }
}
receive_message();

#########################
# Test 21
sub process_as_sub {
    my $FAILED = 0;

    my $message = Net::Syslogd->process_message("<174>Dec 11 12:31:15 10.10.10.1 AGENT[0]: Strict RFC 3164 format");
#    print "  facility = "; if (defined($message->facility) && ($message->facility =~ /^local[567]$/))                                                 { printf "%s\n", $message->facility } else { printf "  !ERROR! - %s\n", $message->facility; $FAILED++ } 
#    print "  severity = "; if (defined($message->severity) && ($message->severity eq "Informational"))                                                { printf "%s\n", $message->severity } else { printf "  !ERROR! - %s\n", $message->severity; $FAILED++ } 
#    print "  time     = "; if (defined($message->time)     && (($message->time eq "0") || ($message->time =~ /^Dec\s+[14]{1,2}\s12:31:15[\.087]*$/))) { printf "%s\n", $message->time     } else { printf "  !ERROR! - %s\n", $message->time;     $FAILED++ } 
#    print "  hostname = "; if (defined($message->hostname) && (($message->hostname eq "0") || ($message->hostname eq "10.10.10.1")))                  { printf "%s\n", $message->hostname } else { printf "  !ERROR! - %s\n", $message->hostname; $FAILED++ } 
#    print "  message  = "; if (defined($message->message))                                                                                            { printf "%s\n", $message->message  } else { $FAILED++ }
                print "  facility = " if ($VERBOSE);
                if (defined($message->facility) && ($message->facility eq 'local5')) {
                    printf "%s\n", $message->facility if ($VERBOSE);
                } else {
                    printf "  !ERROR! - %s\n", $message->facility if ($VERBOSE);
                    $FAILED++
                } 

                print "  severity = " if ($VERBOSE);
                if (defined($message->severity) && ($message->severity eq 'Informational')) {
                    printf "%s\n", $message->severity if ($VERBOSE);
                } else {
                    printf "  !ERROR! - %s\n", $message->severity if ($VERBOSE);
                    $FAILED++
                }

                print "  time     = " if ($VERBOSE);
                if (defined($message->time) && ($message->time eq 'Dec 11 12:31:15')) {
                    printf "%s\n", $message->time if ($VERBOSE);
                } else {
                    printf "  !ERROR! - %s\n", $message->time if ($VERBOSE);
                    $FAILED++
                }

                print "  hostname = " if ($VERBOSE);
                if (defined($message->hostname) && ($message->hostname eq "10.10.10.1")) {
                    printf "%s\n", $message->hostname if ($VERBOSE);
                } else {
                    printf "  !ERROR! - %s\n", $message->hostname if ($VERBOSE);
                    $FAILED++
                } 

                print "  message  = " if ($VERBOSE);
                if (defined($message->message)) {
                    printf "%s\n", $message->message if ($VERBOSE);
                } else {
                    $FAILED++
                }
    return $FAILED
}
ok(process_as_sub() == 0, "Process as sub");
