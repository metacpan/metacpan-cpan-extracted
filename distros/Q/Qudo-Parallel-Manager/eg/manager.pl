#! /usr/bin/env perl
use strict;
use warnings;
use Qudo::Parallel::Manager;

my $m = Qudo::Parallel::Manager->new(
    databases => [+{
        dsn      => 'dbi:mysql:qudo',
        username => 'root',
        password => '',
    }],
    manager_abilities  => [qw/Worker::Test/],
    min_spare_workers  => 10,
    max_spare_workers  => 20,
    max_workers        => 50,
    work_delay         => 3,
    max_request_par_child => 2,
    admin              => 1,
    admin_host         => '192.168.1.17',
    admin_port         => 90000,
    debug => 1,
);

$m->run;
