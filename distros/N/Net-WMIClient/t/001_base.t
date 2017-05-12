# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl WMIClient.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 2;
BEGIN { use_ok('Net::WMIClient', qw(wmiclient)) };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# Test default output with no parameters:
my $help = <<END;
Usage: [-?NPV] [-?|--help] [--usage] [-d|--debuglevel DEBUGLEVEL]
        [--debug-stderr] [-s|--configfile CONFIGFILE] [--option=name=value]
        [-l|--log-basename LOGFILEBASE] [--leak-report] [--leak-report-full]
        [-R|--name-resolve NAME-RESOLVE-ORDER]
        [-O|--socket-options SOCKETOPTIONS] [-n|--netbiosname NETBIOSNAME]
        [-W|--workgroup WORKGROUP] [--realm=REALM] [-i|--scope SCOPE]
        [-m|--maxprotocol MAXPROTOCOL] [-U|--user [DOMAIN\\]USERNAME[%PASSWORD]]
        [-N|--no-pass] [--password=STRING] [-A|--authentication-file FILE]
        [-S|--signing on|off|required] [-P|--machine-pass]
        [--simple-bind-dn=STRING] [-k|--kerberos STRING]
        [--use-security-mechanisms=STRING] [-V|--version] [--namespace=STRING]
        [--delimiter=STRING]
        //host query

Example: wmic -U [domain/]adminuser%password //host "select * from Win32_ComputerSystem"
END

my ($rc, $output) = wmiclient();
ok($output eq $help, "Help Test");
