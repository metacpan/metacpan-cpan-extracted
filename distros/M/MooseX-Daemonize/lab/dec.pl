#!/usr/bin/env perl -l

package TestDaemon;
use Moose;
with('MooseX::Daemonize');

before 'daemonize' => sub {
    warn 'forking ' . $$;
};

after 'start' => sub {
    return unless $_[0]->is_daemon;
    while (1) {
        local *LOG;
        open LOG, '>>', '/tmp/testdaemon.log';
        print LOG "$0:$$";
        close LOG;
        sleep 1;
    }
};

package main;
my $td = new_with_options TestDaemon( pidbase => '/tmp' );
use YAML;
warn Dump $td->pidfile;
warn $td->check;
print "PARENT: $$";
print 'PID: ' . $td->get_pid;
print $td->start;
