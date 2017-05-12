#!/usr/bin/perl

use Test::More qw(no_plan);

use Proc::PID::File::Fcntl;

my $cwd = `pwd`;
chomp $cwd;

my $pf;
ok($pf = Proc::PID::File::Fcntl->new(path => "$cwd/test"));
ok(-e "$cwd/test.pid");
undef $pf;
ok(! -e "$cwd/test.pid");
