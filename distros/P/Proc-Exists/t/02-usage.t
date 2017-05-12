#!perl -w

use strict;
use Test::More 'no_plan';

use lib "blib/lib";  #pm
use lib "blib/arch"; #xs
use Proc::Exists qw(pexists);

my @pids_to_strobe = (1..99999);

#for some of these tests we need >1 process, but we don't care what
#that other process is, so long as it is in memory for the duration
#of this test.
my $nonexistent_pid = 99999; #TODO: is there any OS that could have this?
my $another_pid;
eval { $another_pid = getppid(); };
# win32 crud
if ($^O eq 'MSWin32') {
	#note cygwin never gets here, it returns $^O eq "cygwin"
	#System Idle process is always at pid 0 on winXP, and hopefully
	#others. also "System": is at 8 in w2k, 4 in XP/server 2003
	$another_pid = 4; #System Idle Process on Windows XP
	#note on windows xp, pids are always =0 mod 4
	#http://blogs.msdn.com/oldnewthing/archive/2008/02/28/7925962.aspx
	if(defined($ENV{OS})) {
		if($ENV{OS} eq "Windows_NT") {
			#FIXME: this is not a contract, but an observation about
			#winnt behavior, and thus it's wrong to depend on it...
			#apparently w95 pids were "regularly in the 4billion range"
			#so let's hope... say... 99999*4 never matches
			@pids_to_strobe = map { $_ * 4 } (0..19999);
			$nonexistent_pid = 99999 * 4; #here's hoping!
		} else {
			# win95/98/me, i presume...
			warn "wow, will i really run on $ENV{OS}?"; 
		}
	} else {
		warn "unsupported win32 OS - no \$ENV{OS} set...";
	}
} elsif (!$another_pid) {
	if($^O eq "darwin") {
		$another_pid = 0;
	} else {
		$another_pid = 1; #gulp, hopefully there is something init-esque w/ pid 1?
	}
}

my @t;
#a negative pid should give an error: "got negative pid"
eval { pexists('-2'); };
ok($@ && $@ =~ /^got negative pid/);

eval { pexists('-2', 3); };
ok($@ && $@ =~ /^got negative pid/);
#force call to _list_pexists, not _scalar_pexists
eval { my @x = pexists('-2', 3); };
ok($@ && $@ =~ /^got negative pid/);

#a non-numeric pid should give an error: "got non-integer pid"
eval { pexists('abc'); };
ok($@ && $@ =~ /^got non-number pid/);
eval { pexists('abc', 3); };
ok($@ && $@ =~ /^got non-number pid/);
#force call to _list_pexists, not _scalar_pexists
eval { my @x = pexists('abc', 3); };
ok($@ && $@ =~ /^got non-number pid/);

#a non-integer pid should give an error: "got non-integer pid"
eval { pexists('1.23'); };
ok($@ && $@ =~ /^got non-integer pid/);
eval { pexists('1.23', 3); };
ok($@ && $@ =~ /^got non-integer pid/);
#force call to _list_pexists, not _scalar_pexists
eval { my @x = pexists('1.23', 3); };
ok($@ && $@ =~ /^got non-integer pid/);

#API tests: In list context, giving any/all should error out.
eval { @t = pexists($$, $$, {any => 1}); };
ok($@ && $@ =~ /^can't specify 'any' argument in list context/);
eval { @t = pexists($$, $$, {all => 1}); };
ok($@ && $@ =~ /^can't specify 'all' argument in list context/);

#'any' and 'all' makes no sense for us.
eval { pexists(1, 2, {any => 1, all => 1}) };
ok($@);

#make sure this process exists
ok(pexists($$));
#this process and another should give a count of 2
ok(2 == pexists($another_pid, $$));
#check array context return
@t = pexists($another_pid, $$);
#also check *order* of results
ok(@t == 2);
ok($t[0] == $another_pid);
ok($t[1] == $$);
#check return values from "any" and "all" args
ok($another_pid == pexists($another_pid, $$, {any => 1}));
ok(2 == pexists($another_pid, $$, {all => 1}));

#three-way tests - 2 exist, 1 doesn't, test any and all and plain
ok(2 == pexists($$, $another_pid, $nonexistent_pid));
@t = pexists($$, $another_pid, $nonexistent_pid);
ok(@t == 2);
ok($t[0] == $$);
ok($t[1] == $another_pid);
ok($$ == pexists($$, $another_pid, $nonexistent_pid, {any => 1}));
ok(0 == pexists($nonexistent_pid, $nonexistent_pid));
ok(!pexists($$, $another_pid, $nonexistent_pid, {all => 1}));
#NOTE: as documented in the pod, any returns undef for false,
#      because some systems use pid==0
ok(!defined(pexists($nonexistent_pid, $nonexistent_pid, {any => 1})));
#also make sure we get a defined value when we check for $another_pid,
#  (which is 0 on OSX)
ok(defined(pexists($another_pid)));

#TODO: these tests are non-deterministic, unless our range a) covers
#a process we're guaranteed won't go away (e.g. parent on unix, idle on win)
#b) has at least one hole in it. for this to work, the range of pids to
#strobe must be long enough that we'll get both hits and misses, but
#small enough to run relatively quickly

#check array form (slow)
@t = pexists(@pids_to_strobe);
ok(scalar @t <  scalar @pids_to_strobe);
#tests on scalar form follow...
ok(pexists(@pids_to_strobe) < scalar @pids_to_strobe);
#make sure "all" arg works properly
ok(!pexists(@pids_to_strobe, {all => 1}));

