#!perl -T
# $RedRiver: 59-network-cleanup.t,v 1.3 2007/02/06 20:59:10 andrew Exp $

use Test::More tests => 25;
use File::Spec;

BEGIN {
	use_ok( 'Net::Telnet::Trango' );
}

diag("59: Cleanup settings from other tests");

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

    if ($cfg{$type . '_PASSWD'} && $cfg{$type . '_PASSWD'} =~ /^(.*)$/) {
        $pass = $1;
    }

    if ($cfg{SU_ID} && $cfg{SU_ID} =~ /^(\d+)$/) {
        $su_id= $1;
    }

    if ($cfg{SU_MAC} && length $cfg{SU_MAC} >= 12 && $cfg{SU_MAC} =~ /^(.*)$/) {
        $su_mac = $1;
    }

    $type = 'SU';
    if ($cfg{$type} && $cfg{$type} =~ /^(\d+\.\d+\.\d+.\d+)$/) {
        $su = $1;
    }

    if ($cfg{$type . '_PASSWD'} && $cfg{$type . '_PASSWD'} =~ /^(.*)$/) {
        $su_pass = $1;
    }

    my $in_sudb = 0;
    my $already_gone = 0;
    SKIP: {
        skip 'No valid AP in config file',        7 unless $host; 
        skip 'No valid AP_PASSWD in config file', 7 unless $pass;

        my $t;
        ok($t = Net::Telnet::Trango->new(), "Instantiating object");
        ok($t->open($host), "Opening connection to $host");
        ok($t->is_connected, "connected");
        ok($t->login($pass), "Logging in");
        ok($t->logged_in, "logged in");

        SKIP: {
            skip 'No valid SU_ID in config file',  1 unless $su_id;
            skip 'No valid SU_MAC in config file', 1 unless $su_mac;

            my $sudb = [];
            if ((!ok($sudb = $t->sudb_view, "Getting sudb"))
                && $t->last_error ) {
                diag('ERR: ' . $t->last_error);
            }

            foreach my $su (@{ $sudb }) {
                if ($su_id == $su->{suid}) {
                    if (lc($su_mac) eq lc($su->{mac})) {
                        $in_sudb = 1;
                    } else {
                        $in_sudb = -1;
                        diag("Incorrect mac for SUID $su_id");
                        diag("  Should be $su_mac");
                        diag("  Really is $su->{mac}");
                    }
                    last;
                }
            }
            
            if ($in_sudb != 1) {
                $already_gone = 1;
            }
        }
        ok($t->bye, "Goodbye");
    }

    SKIP: {
        skip 'No valid SU in config file',        6 unless $su; 
        skip 'No valid SU_PASSWD in config file', 6 unless $su_pass;
        skip 'SU already removed', 6 if $already_gone;

        my $t;
        ok($t = Net::Telnet::Trango->new(), "Instantiating object");
        ok($t->open($su), "Opening connection to $su");
        ok($t->is_connected, "connected");
        ok($t->login($su_pass), "Logging in");
        ok($t->logged_in, "logged in");

        ok($t->bye, "Goodbye");
    }

    SKIP: {
        skip 'No valid AP in config file',        11 unless $host; 
        skip 'No valid AP_PASSWD in config file', 11 unless $pass;

        my $t;
        ok($t = Net::Telnet::Trango->new(), "Instantiating object");
        ok($t->open($host), "Opening connection to $host");
        ok($t->is_connected, "connected");
        ok($t->login($pass), "Logging in");
        ok($t->logged_in, "logged in");

        SKIP: {
            skip 'No valid SU_ID in config file',  5 unless $su_id;
            skip 'No valid SU_MAC in config file', 5 unless $su_mac;
            skip 'SU already removed', 4 if $already_gone;

            is($in_sudb, 1, "Correct SU is in SUDB");

            if ((!ok($t->sudb_delete($su_id), "deleting su"))
                && $t->last_error ) {
                diag('ERR: ' . $t->last_error);
            }

            my $sudb = [];
            if ((!ok($sudb = $t->sudb_view, "Getting sudb"))
                && $t->last_error ) {
                diag('ERR: ' . $t->last_error);
            }

            $in_sudb = 0;
            foreach my $su (@{ $sudb }) {
                if ($su_id == $su->{suid}) {
                    if (lc($su_mac) eq lc($su->{mac})) {
                        $in_sudb = 1;
                    } else {
                        $in_sudb = -1;
                        diag("Incorrect mac for SUID $su_id");
                        diag("  Should be $su_mac");
                        diag("  Really is $su->{mac}");
                    }
                    last;
                }
            }

            is($in_sudb, 0, "SU is NOT in SUDB");

            if ( (! ok($t->save_sudb, "Saving sudb")) 
                && $t->last_error ) {
                diag('ERR: ' . $t->last_error);
            }
        }

        ok($t->bye, "Goodbye");
    }


}
