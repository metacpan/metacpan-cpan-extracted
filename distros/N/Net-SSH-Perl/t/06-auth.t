#!/usr/bin/perl

use strict;
use warnings;

use Net::SSH::Perl;

use Test::More;
BEGIN {
	  plan skip_all => 'Test not enabled yet';
	  plan tests => 4;
	  }

use vars qw( $PORT $KNOWN_HOSTS $IDENTITY $PSSHD $PID_FILE );
BEGIN { unshift @INC, 't/' }
require 'test-common.pl';

use vars qw( $DEBUG );
$DEBUG = 1;

my $TEST_PHRASE = "foo bar";
my $TIMEOUT = 20;

startup_psshd($PSSHD, $PORT, $DEBUG);

$SIG{ALRM} = sub { die "Died waiting for server to come up.\n" };
alarm $TIMEOUT;
while (!-e $PID_FILE) {
    warn "--Waiting for server pid file $PID_FILE.\n" if $DEBUG;
    sleep 5;
}
alarm 0;

warn "Starting tests.\n" if $DEBUG;

my @auth = qw( password rsa rhosts rhosts_rsa );
for my $a (@auth) {
    my $auth = "auth_$a";
    my %not_this = map { "auth_" . $_ => 0 } grep $_ ne $a, @auth;

    my $ssh = Net::SSH::Perl->new("localhost",
        user_known_hosts => $KNOWN_HOSTS,
        port => $PORT,
        debug => $DEBUG,
        %not_this,
        identity_files => [ $IDENTITY ]);
    $ssh->login('dummy', 'dummy');
    my($out) = $ssh->cmd(qq( echo -n "$TEST_PHRASE" ));
    ok($out eq $TEST_PHRASE, 'Test passed');
}

kill_psshd($PID_FILE);

sub startup_psshd {
    my($psshd, $port, $debug) = @_;
    if (!defined(my $pid = fork)) {
        die "Can't fork: $!";
    }
    elsif ($pid) {
        warn "Forked, waiting for server startup\n" if $DEBUG;
        sleep 2;
    }
    else {
        my $lib = "";
        if (-e "blib/lib") {
            $lib = "-Iblib/lib";
        }
        elsif (-e "../blib/lib") {
            $lib = "-I../blib/lib";
        }
        my $cmd = "perl $lib $psshd -g -p $port";
        $cmd .= " -d" if $debug;
        warn "Invoking psshd as:\n--'$cmd'--\n" if $DEBUG;
        exec "$cmd 2>&1";
    }
}

sub kill_psshd {
    my $pid_file = shift;
    open my $fh, '<', $pid_file or warn("Can't open $pid_file: $!"), return;
    chomp(my $pid = <$fh>);
	close $fh or warn qq{Could not close "$pid_file": $!\n};
    warn "Killing psshd on pid $pid.\n" if $DEBUG;
    kill 15, $pid;
}
