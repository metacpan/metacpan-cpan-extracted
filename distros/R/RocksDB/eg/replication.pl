#!/usr/bin/env perl
use strict;
use warnings;
use blib;

use RocksDB;
use File::Temp;

my $write_interval = 1;
my $read_interval = 5;
my $repl_interval = 2;
my $times = 10;
RocksDB->new(my $master_dbname = File::Temp::tmpnam, { create_if_missing => 1 });
RocksDB->new(my $slave_dbname  = File::Temp::tmpnam, { create_if_missing => 1 });
$SIG{INT} = sub { cleanup(); exit 1 };

my $master_pid = fork // die $!;
master_process() unless $master_pid;
my $slave_pid = fork // die $!;
slave_process() unless $slave_pid;
my $repl_pid = fork // die $!;
repl_process() unless $repl_pid;
waitpid($_, 0) for ($master_pid, $slave_pid, $repl_pid);
cleanup();
exit;

sub master_process {
    my $db = RocksDB->new($master_dbname, {
        WAL_ttl_seconds => 10,
    });
    warn "[master] dbname: $master_dbname";
    while ($times--) {
        my $key = rand();
        my $value = rand();
        warn "[master] $key: $value";
        $db->put($key, $value);
        sleep $write_interval;
    }
    exit;
}

sub slave_process {
    warn "[slave] dbname: $slave_dbname";
    while ($times--) {
        my $db = RocksDB->new($slave_dbname, { read_only => 1 });
        my $iter = $db->new_iterator->seek_to_first;
        while (my ($key, $value) = $iter->each) {
            warn "[slave] $key: $value";
        }
        sleep $read_interval;
    }
    exit;
}

sub repl_process {
    warn "[repl] started";
    my $since = 0;
    my $slave = RocksDB->new($slave_dbname);
    while ($times--) {
        my $master = RocksDB->new($master_dbname, { read_only => 1 });
        for (my $iter = $master->get_updates_since($since); $iter->valid; $iter->next) {
            my $result = $iter->get_batch;
            warn "[repl] sequence: " . $result->sequence;
            $slave->write($result->write_batch);
            $slave->flush;
            $since = $result->sequence + 1;
        }
        sleep $repl_interval;
    }
    exit;
}

sub cleanup {
    eval {
        RocksDB->destroy_db($master_dbname);
        warn "[master] destroyed";
    };
    eval {
        RocksDB->destroy_db($slave_dbname);
        warn "[slave] destroyed";
    };
}

__END__
