#!perl -T
# $RedRiver: 53-network-add_su-ap-su.t,v 1.4 2007/02/06 20:59:10 andrew Exp $

use Test::More tests => 17;
use File::Spec;

BEGIN {
	use_ok( 'Net::Telnet::Trango' );
}

diag("53: AP tests when adding an SU to an AP and the SU should associate");

my $cfg_file = File::Spec->catfile('t', 'tests.cfg');
my ($cir, $mir) = (128, 256);

SKIP: {
    my $skipped = 16;
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

    ok($t->open($host), "Opening connection to $host");

    ok($t->is_connected, "connected");

    ok($t->login($pass), "Logging in");

    ok($t->logged_in, "logged in");

    my $sudb;
    if ((!ok($sudb = $t->sudb_view, "Getting sudb"))
      && $t->last_error ) {
        diag('ERR: ' . $t->last_error);
    }

    my $in_sudb = 0;
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

    is($in_sudb, 1, "Correct SU is in SUDB");

    my $opmode;
    ok($opmode = $t->opmode, "getting current opmode");

    SKIP: {
        skip("already opmode ap", 1) if $opmode->{Opmode} eq 'ap';

        if ((! ok($result = $t->opmode('ap y'), "Setting opmode ap y")) 
            && $t->last_error ) {
            diag('ERR: ' . $t->last_error);
        }
    }

    $opmode = {};
    if ((! ok($opmode = $t->opmode, "getting current opmode")) 
        && $t->last_error) {
        diag('ERR: ' . $t->last_error);
    }

    is($opmode->{Opmode}, 'ap', "current Opmode ap");

    if (! ok($result = $t->save_ss, "Saving systemsetting") 
        && $t->last_error ) {
        diag('ERR: ' . $t->last_error);
    }

    my $sysinfo;
    if ((!ok($sysinfo = $t->sysinfo, "Getting sysinfo"))
      && $t->last_error ) {
        diag('ERR: ' . $t->last_error);
    }

    # XXX This is probably the wrong way to do this, but it should work 
    # XXX most of the time.
    my $su_subnet  = $sysinfo->{'Subnet Mask'};
    my $su_gateway = $sysinfo->{'Gateway'};

    if ( (! ok($t->su_password($su_pass, $su_id), "set SU password")) 
      && $t->last_error ) {
        diag('ERR: ' . $t->last_error);
    }

    if ( (! ok($t->su_ipconfig($su_id, $su, $su_subnet, $su_gateway), 
                "set SU IP"))
      && $t->last_error ) {
        diag('ERR: ' . $t->last_error);
    }

    ok($t->bye, "Goodbye");

    if ($su && $su_pass) {
        diag("Waiting 30 seconds for SU to associate");
        sleep 30;
    }

}
