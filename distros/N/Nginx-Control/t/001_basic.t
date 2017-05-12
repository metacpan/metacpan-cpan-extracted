#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 17;
use Test::Exception;
use Test::WWW::Mechanize;
use Test::TempDir;
use File::Basename;

BEGIN {
    use_ok('Nginx::Control');
}

level_flight: {
    my $ctl = Nginx::Control->new(
        config_file => [$ENV{PWD}, qw[ t conf nginx.dev.conf ]],
        pid_file    => '/tmp/nginx.control.pid', # this doesn't work on < 0.7.04
    );
    isa_ok($ctl, 'Nginx::Control');

    SKIP: {
        
        skip "No nginx installed (or at least none found), why are you testing this anyway?", 6 
            unless eval { $ctl->binary_path };

        ok(!$ctl->is_server_running, '... the server process is not yet running');

        $ctl->start;

        diag "Wait a moment for nginx to start";
        sleep(2);

        ok($ctl->is_server_running, '... the server process is now running');

        my $mech = Test::WWW::Mechanize->new;
        $mech->get_ok('http://localhost:3333/' . $ctl->pid_file->basename);
        $mech->content_contains($ctl->server_pid, '... got the content we expected');

        $ctl->stop;

        diag "Wait a moment for Nginx to stop";
        sleep(2);

        ok(!-e $ctl->pid_file, '... PID file has been removed by Nginx');
        ok(!$ctl->is_server_running, '... the server process is no longer running');

    }
}

no_nginx: {
    my ( $fh, $file ) = tempfile();
    print $fh "#!/bin/sh\necho Woot!\n";
    close $fh;

    $Nginx::Control::NGINX_BIN = basename($file);
    @Nginx::Control::SEARCH_PATH = ( dirname($file) );

    not_executable: {
        my $ctl = Nginx::Control->new(
            config_file => [$ENV{PWD}, $file],
            pid_file    => '/tmp/nginx.control.pid',
        );
        isa_ok($ctl, 'Nginx::Control');
        dies_ok {
            diag $ctl->binary_path;
        } "binary_path dies with no nginx in our path";
    }

    executable_no_pid: {
        chmod 0755, $file;
        my $ctl = Nginx::Control->new(
            config_file => [$ENV{PWD}, qw[ t conf nginx.dev.conf ]],
            pid_file    => '/tmp/nginx.control.pid',
        );
        isa_ok($ctl, 'Nginx::Control');
        dies_ok {
            diag $ctl->start;
        } "start fails when there's no pid";
        ok(!$ctl->is_server_running, "is_server_running fails when there's no pid");
    }

    no_conf: {
        my $ctl = Nginx::Control->new(
            config_file => [$ENV{PWD}, "nothinghere.conf"],
            pid_file    => '/tmp/nginx.control.pid',
        );
        isa_ok($ctl, 'Nginx::Control');
        dies_ok {
            diag $ctl->start;
        } "start fails when there's no config file";
    }

    no_file: {
        unlink $file;
        my $ctl = Nginx::Control->new(
            config_file => [$ENV{PWD}, qw[ t conf nginx.dev.conf ]],
            pid_file    => '/tmp/nginx.control.pid',
        );
        isa_ok($ctl, 'Nginx::Control');
        dies_ok {
            diag $ctl->binary_path;
        } "binary_path dies when nginx is not executable";
    }
}
