#!perl -T
# $RedRiver: 54-network-ap-su.t,v 1.4 2007/02/06 20:59:10 andrew Exp $

use Test::More tests => 37;
use File::Spec;

BEGIN {
	use_ok( 'Net::Telnet::Trango' );
}

diag("54: Tests that run on both APs and SUs associated or not");

my $cfg_file = File::Spec->catfile('t', 'tests.cfg');

foreach my $type ('AP', 'SU') {
    SKIP: {
        my $skipped = 18;
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

        my ($host, $pass);

        if ($cfg{$type} && $cfg{$type} =~ /^(\d+\.\d+\.\d+.\d+)$/) {
            $host = $1;
        }

        skip 'No valid ' . $type . ' in config file',        $skipped unless $host; 

        if ($cfg{$type . '_PASSWD'} && $cfg{$type . '_PASSWD'} =~ /^(.*)$/) {
            $pass = $1;
        }

        skip 'No valid ' . $type . '_PASSWD in config file', $skipped unless $pass;

        my $t;
        ok($t = Net::Telnet::Trango->new(), "Instantiating object");

        ok($t->open($host), "Opening connection to $host");

        ok($t->is_connected, "connected");

        like($t->login_banner,     qr/^Welcome to Trango Broadband Wireless/, 
            "login banner");
        like($t->firmware_version, qr/^[A-Z]+\s\d+p\d+r[A-Z0-9]+$/, 
            "firmware_version");
        like($t->host_type,        qr/^[A-Z0-9]+[- ][A-Z0-9]+$/, "host type");

        ok($t->login($pass), "Logging in");

        ok($t->logged_in, "logged in");

        if ( (! ok($t->pipe, "Getting pipe stats")) 
            && $t->last_error ) {
            diag('ERR: ' . $t->last_error);
        } 

        if ( (! ok($t->maclist, "Getting maclist")) 
            && $t->last_error ) {
            diag('ERR: ' . $t->last_error);
        } 

        if ( (! ok($t->maclist_reset, "Resetting maclist")) 
            && $t->last_error ) {
            diag('ERR: ' . $t->last_error);
        } 

        if ( (! ok($t->enable_tftpd, "Enabling TFTPd")) 
            && $t->last_error ) {
            diag('ERR: ' . $t->last_error);
        } 

        my $tftpd;
        if ( (! ok($tftpd = $t->tftpd, "checking TFTPd")) 
            && $t->last_error ) {
            diag('ERR: ' . $t->last_error);
        } 

        is($tftpd->{Tftpd}, 'listen', "TFTPd is listening");

        if ( (! ok($t->disable_tftpd, "Disabling TFTPd")) 
            && $t->last_error ) {
            diag('ERR: ' . $t->last_error);
        } 

        if ( (! ok($tftpd = $t->tftpd, "checking TFTPd")) 
            && $t->last_error ) {
            diag('ERR: ' . $t->last_error);
        } 

        is($tftpd->{Tftpd}, 'disabled', "TFTPd is disabled");

        # no TODO because I don't want to upgrade Test::Harness
        #TODO: {
        #    # XXX for some reason this doesn't return Success. 
        #    # XXX at least not on the fox I am testing on.
        #    if ( (! ok($t->eth_link, "Getting eth link")) 
        #        && $t->last_error ) {
        #        diag('ERR: ' . $t->last_error);
        #    } 
        #}

        ok($t->bye, "Goodbye");
    }
}
#        if ( (! ok($t->, "")) 
#            && $t->last_error ) {
#            diag('ERR: ' . $t->last_error);
#        } 

