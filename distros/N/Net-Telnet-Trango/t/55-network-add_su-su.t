#!perl -T
# $RedRiver: 55-network-add_su-su.t,v 1.5 2007/02/06 20:59:10 andrew Exp $

use Test::More tests => 7;
use File::Spec;

BEGIN {
	use_ok( 'Net::Telnet::Trango' );
}

diag("55: SU tests when adding an SU to an AP");

my $cfg_file = File::Spec->catfile('t', 'tests.cfg');

SKIP: {
    my $skipped = 6;
    my %cfg;
    if (-e $cfg_file) {
        if (open my $fh, $cfg_file) {
            while (<$fh>) {
                chomp;
                my ($key, $value) = split /\t/, $_, 2;
                $cfg{$key} = $value;
            }
            close $fh;
        }
    }

    my $type = 'AP';
    my ($host, $pass, $su, $su_pass, $su_id, $su_mac);

    if ($cfg{$type} && $cfg{$type} =~ /^(\d+\.\d+\.\d+.\d+)$/) {
        $host = $1;
    }

    skip 'No valid ' . $type . ' in config file',        $skipped unless $host; 

    if ($cfg{$type . '_PASSWD'} && $cfg{$type . '_PASSWD'} =~ /^(.*)$/) {
        $pass = $1;
    }

    skip 'No valid ' . $type . '_PASSWD in config file', $skipped unless $pass;

    if ($cfg{SU_ID} && $cfg{SU_ID} =~ /^(\d+)$/) {
        $su_id= $1;
    }

    skip 'No valid SU_ID in config file', $skipped unless $su_id;

    if ($cfg{SU_MAC} && length $cfg{SU_MAC} >= 12 && $cfg{SU_MAC} =~ /^(.*)$/) {
        $su_mac = $1;
    }

    skip 'No valid SU_MAC in config file', $skipped unless $su_mac;

    $type = 'SU';
    if ($cfg{$type} && $cfg{$type} =~ /^(\d+\.\d+\.\d+.\d+)$/) {
        $su = $1;
    }

    skip 'No valid SU in config file',        $skipped unless $su; 

    if ($cfg{$type . '_PASSWD'} && $cfg{$type . '_PASSWD'} =~ /^(.*)$/) {
        $su_pass = $1;
    }

    skip 'No valid SU_PASSWD in config file', $skipped unless $su_pass;


    my $t;
    ok($t = Net::Telnet::Trango->new(), "Instantiating object");

    ok($t->open($host), "Opening connection to $su");

    ok($t->is_connected, "connected");

    ok($t->login($pass), "Logging in");

    ok($t->logged_in, "logged in");

    # XXX Additional tests go here.
    # XXX Although right now just logging it is all I can think of.

    ok($t->bye, "Goodbye");
}
