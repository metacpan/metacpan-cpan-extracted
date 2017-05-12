#!/usr/bin/perl

use strict;
use warnings;

use Net::OpenSSH::Parallel;
use Net::OpenSSH::Parallel::Constants qw(OSSH_ON_ERROR_IGNORE);

my $p = Net::OpenSSH::Parallel->new;

$p->add_host('root@172.26.9.122');

$p->all(cmd => 'echo hello');
$p->all(cmd => { on_error => OSSH_ON_ERROR_IGNORE }, 'reboot');
$p->all(cmd => { reconnections => 500 }, 'echo hello again');

$Net::OpenSSH::Parallel::debug = -1;

$p->run;
