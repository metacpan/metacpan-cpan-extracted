#!/usr/bin/perl -w

#
#   Proc::PID::File - test suite
#   Copyright (C) 2001-2003 Erick Calder
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#

use strict;
use warnings;

#   make sure this script can find the module
#   without being run by 'make test' (see --deamon switch below).

use lib "blib/lib";

use Proc::PID::File;
use Test::Simple tests => 12;
use Config;

$|++; $\ = "\n";
my %args = (name => "test", dir => ".", debug => $ENV{DEBUG} || "");
my $cmd = shift || "";

# - deamon -------------------------------------------------------------------

if ($cmd eq "--daemon") {
	print "-- daemon --";
	$args{verify} = 1;
    die "Already running!" if Proc::PID::File->running(%args);
    sleep(5);
	print "-- deamon: exiting --";
    exit();
    }

exit() if $cmd eq "--short";

my $pid;
sub rundaemon {
	my $pipes = $args{debug} =~ /D/ ? "" : "> /dev/null 2>&1";
	system qq|$^X $0 --daemon $pipes &|;
	sleep 1;
	chomp($pid = qx|cat $args{dir}/$args{name}.pid|);
	}

# - thread-safety test -------------------------------------------------------

ok(1, "SKIPPED - simple: thread safe") unless
	$] >= 5.008001
	&& $Config{"useithreads"}
	&& eval { 
		require threads; 
		Proc::PID::File->running(%args);
		threads->create(sub {})->join();
		sleep(2);
		ok(-f "test.pid", "simple: thread safe");
	};

# - basic run test -----------------------------------------------------------

unlink("test.pid") || die $! if -e "test.pid";
rundaemon();
my $rc = Proc::PID::File->running(%args);
ok($rc, "simple: running");

# - verification tests -------------------------------------------------------

ok(1, "SKIPPED - simple: verified (real)") unless
	$^O =~ /linux|freebsd|cygwin/i
	&& eval {
		$rc = Proc::PID::File->running(%args, verify => 1);
		ok($rc, "simple: verified (real)");
		};

ok(1, "SKIPPED - simple: verified (false)") unless
	$^O =~ /linux|freebsd|cygwin/i
	&& eval {
		# WARNING: the following test takes over the pidfile from
		# the daemon such that he cannot clean it up.  this is as
		# it should be since no one but us should occupy our pidfile 

		$rc = Proc::PID::File->running(%args, verify => "falsetest");
		ok(! $rc, "simple: verified (false)");
		};

# - single instance test -----------------------------------------------------

sleep 1 while kill 0, $pid;

$rc = Proc::PID::File->running(%args);
ok(! $rc, "simple: single instance");

# - destroy test -------------------------------------------------------------

system qq|$^X $0 --short > /dev/null 2>&1|;
ok(-f "test.pid", "simple: destroy");

# - OO Interface tests -------------------------------------------------------

my $c1 = Proc::PID::File->new(%args);
ok($c1->{path}, "oo: object initialised");

$c1->touch();
ok(-f $c1->{path}, "oo: file touched");

ok(!$c1->alive(), "oo: alive (with current process)");

unlink("test.pid") || die $! if -e "test.pid";
rundaemon();
ok($c1->alive(), "oo: alive (with daemon)");

ok(1, "SKIPPED - oo: alive (verified)") unless
	$^O =~ /linux|freebsd|cygwin/i
	&& eval {
		ok($c1->alive(verify => 1), "oo: alive (verified)");
		};

$c1->release();
ok(! -f $c1->{path}, "oo: released");

# - wait for daemon to exit --------------------------------------------------

$\ = undef;
print "waiting for daemon death";
sleep 1, print "." while kill 0, $pid;
print "\ndone\n";
exit 0;
