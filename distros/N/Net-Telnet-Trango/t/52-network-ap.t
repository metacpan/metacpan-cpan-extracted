#!perl -T
# $RedRiver: 52-network-ap.t,v 1.3 2007/02/06 20:59:10 andrew Exp $

use Test::More tests => 13;
use File::Spec;

BEGIN {
	use_ok( 'Net::Telnet::Trango' );
}

diag("52: AP tests");

my $cfg_file = File::Spec->catfile('t', 'tests.cfg');

SKIP: {
    my $skipped = 12;
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

    ok($t->login($pass), "Logging in");

    ok($t->logged_in, "logged in");

    my $sudb = [];
    if ((!ok($sudb = $t->sudb_view, "Getting sudb"))
        && $t->last_error ) {
        diag('ERR: ' . $t->last_error);
    }

    my $opmode;
    ok($opmode = $t->opmode, "getting current opmode");

    SKIP: {
        skip("no SUDB", 1) unless @{ $sudb };
        skip("already opmode ap", 1) if $opmode->{Opmode} eq 'ap';

        if ((! ok($result = $t->opmode('ap y'), "Setting opmode ap y")) 
            && $t->last_error ) {
            diag('ERR: ' . $t->last_error);
        }
    }

    my $opmode_should_be = 'ap';
    if (! @{ $sudb }) {
        $opmode_should_be = 'off';
    }

    $opmode = {};
    if ((! ok($opmode = $t->opmode, "getting current opmode")) 
        && $t->last_error) {
        diag('ERR: ' . $t->last_error);
    }

    is($opmode->{Opmode}, $opmode_should_be, 
        "current Opmode $opmode_should_be");

    if (! ok($result = $t->save_ss, "Saving systemsetting") 
        && $t->last_error ) {
        diag('ERR: ' . $t->last_error);
    }

    ok($t->bye, "Goodbye");
}
