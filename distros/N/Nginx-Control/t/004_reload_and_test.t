#!/usr/bin/perl

use strict;
use warnings;
use File::Basename;

use Test::More tests => 15;
use Test::Exception;
use Test::WWW::Mechanize;
use Test::TempDir;

BEGIN {
    use_ok('Nginx::Control');
}

my $test_tempdir = temp_root();
my %conf = (
    startup => <<EOF,
worker_processes  1;
pid        /tmp/nginx.control.pid;
error_log /tmp/nginx.control.error.log;
events {
    worker_connections  1024;
}
http {
    access_log /tmp/nginx.control.access.log;
	server {
		listen 3333;
		location / {
			root    /tmp;
		}		
	}
}
EOF
    bad => <<EOF,
worker_processes  1;
pid        /tmp/nginx.control.pid;
events {
    worker_connections  1024;
http {
	server {
		listen 3333;
		location / {
			root    /tmp;
EOF
    reload => <<EOF,
worker_processes  1;
pid        /tmp/nginx.control.pid;
error_log /tmp/nginx.control.error.log;
events {
    worker_connections  1024;
}
http {
    access_log /tmp/nginx.control.access.log;
	server {
		listen 3333;
		location / {
			root    $ENV{PWD}/$test_tempdir;
		}		
	}
}
EOF
);
        
my ( $fh, $file ) = tempfile();
print $fh $conf{startup};
close $fh;

my $ctl = Nginx::Control->new(
    config_file => [ $ENV{PWD}, $file ],
);
isa_ok($ctl, 'Nginx::Control');

SKIP: {
    skip "No nginx installed (or at least none found), why are you testing this anyway?", 13
        unless eval { $ctl->binary_path };

    ok($ctl->test, "startup conf tests good");

    ok(!$ctl->is_server_running, '... the server process is not yet running');
    $ctl->start;

    diag "Wait a moment for nginx to start";
    sleep(2);

    ok($ctl->is_server_running, '... the server process is now running');
    ok($ctl->test, "startup conf still good while server is running");

    my $mech = Test::WWW::Mechanize->new;
    $mech->get_ok('http://localhost:3333/' . $ctl->pid_file->basename);
    $mech->content_contains($ctl->server_pid, '... got the content we expected');

    open $fh, ">$file";
    print $fh $conf{bad};
    close $fh;

    ok(!$ctl->test, "bad conf causes test to return false");

    open $fh, ">$file";
    print $fh $conf{reload};
    close $fh;

    ok($ctl->test, "good conf causes test to return true");
    $ctl->reload;
    ok($ctl->is_server_running, '... the server is running immediately after a reload');

    diag "Wait a moment for Nginx to reload";
    sleep 2;

    $mech->get_ok('http://localhost:3333/' . basename($file));
    $mech->content_contains(basename($test_tempdir), '... got the content we expected from the new conf');

    $ctl->stop;

    diag "Wait a moment for Nginx to stop";
    sleep(2);

    ok(!-e $ctl->pid_file, '... PID file has been removed by Nginx');
    ok(!$ctl->is_server_running, '... the server process is no longer running');
}
