#!perl -T
# $RedRiver: 56-network-su.t,v 1.2 2007/02/06 20:59:10 andrew Exp $

use Test::More tests => 7;
use File::Spec;

BEGIN {
	use_ok( 'Net::Telnet::Trango' );
}

diag("56:  SU tests");

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

    my $type = 'SU';
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

    # XXX Additional tests go here.
    # XXX Although right now just logging it is all I can think of.

    ok($t->bye, "Goodbye");
}
