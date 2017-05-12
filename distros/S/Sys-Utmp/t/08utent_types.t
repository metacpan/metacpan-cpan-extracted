#!/usr/bin/perl

use Sys::Utmp;
use Test::More tests => 10;

my $utmp = Sys::Utmp->new();
my $utent = $utmp->getutent();

ok(defined $utent->accounting(),"accounting");
ok(defined $utent->boot_time(),"boot_time");
ok(defined $utent->dead_process(),"dead_process");
ok(defined $utent->empty(),"empty");
ok(defined $utent->init_process(),"init_process");
ok(defined $utent->login_process(),"login_process");
ok(defined $utent->new_time(),"new_time");
ok(defined $utent->old_time(),"old_time");
ok(defined $utent->run_lvl(),"run_lvl");
ok(defined $utent->user_process(),"user_process");
