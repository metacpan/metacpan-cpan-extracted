#!/usr/bin/perl

use Test::More tests => 7;
use Sys::Utmp;

my $utmp = Sys::Utmp->new();

my $utent = $utmp->getutent();

ok(defined $utent->ut_user(),"ut_user");
ok(defined $utent->ut_id(),"ut_id");
ok(defined $utent->ut_line(),"ut_line");
ok(defined $utent->ut_pid(),"ut_pid");
ok(defined $utent->ut_type(),"ut_type");
ok(defined $utent->ut_host(),"ut_host");
ok(defined $utent->ut_time(),"ut_time");
