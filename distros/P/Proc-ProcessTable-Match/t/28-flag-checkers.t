#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

use Proc::ProcessTable::Match::EGIDset;
use Proc::ProcessTable::Match::EUIDset;
use Proc::ProcessTable::Match::Idle;
use Proc::ProcessTable::Match::KernProc;
use Proc::ProcessTable::Match::Swapped;
use Proc::ProcessTable::Process;

# Creates a mock Proc::ProcessTable::Process object. The accessors
# are provided via that module's AUTOLOAD, which maps method names
# to hash keys.
sub mock_process {
	my %process_fields = @_;
	return bless {%process_fields}, 'Proc::ProcessTable::Process';
}

#
# Idle
#

my $idle_checker = Proc::ProcessTable::Match::Idle->new( {} );

is( $idle_checker->match(),                0, 'Idle match returns 0 for undef' );
is( $idle_checker->match('not a process'), 0, 'Idle match returns 0 for a non-process' );

is( $idle_checker->match( mock_process( uid => 0, fname => 'idle', cmndline => '' ) ),
	1, 'Idle matches the idle process' );
is( $idle_checker->match( mock_process( uid => 1000, fname => 'idle', cmndline => '' ) ),
	0, 'Idle does not match when the uid is not 0' );
is( $idle_checker->match( mock_process( uid => 0, fname => 'perl', cmndline => '' ) ),
	0, 'Idle does not match when the fname is not idle' );
is( $idle_checker->match( mock_process( uid => 0, fname => 'idle', cmndline => '/sbin/idle' ) ),
	0, 'Idle does not match when the cmndline is not blank' );

#
# KernProc
#

my $kern_proc_checker = Proc::ProcessTable::Match::KernProc->new( {} );

is( $kern_proc_checker->match( mock_process( uid => 0, cmndline => '', state => 'sleep' ) ),
	1, 'KernProc matches a kernel process' );
is( $kern_proc_checker->match( mock_process( uid => 0, cmndline => '', state => 'zombie' ) ),
	0, 'KernProc does not match a zombie' );
is( $kern_proc_checker->match( mock_process( uid => 0, cmndline => '', state => 'defunct' ) ),
	0, 'KernProc does not match a defunct process' );
is( $kern_proc_checker->match( mock_process( uid => 0, cmndline => '/sbin/init', state => 'sleep' ) ),
	0, 'KernProc does not match a process with a cmndline' );
is( $kern_proc_checker->match( mock_process( uid => 1000, cmndline => '', state => 'sleep' ) ),
	0, 'KernProc does not match a non-root process' );

#
# Swapped
#

my $swapped_checker = Proc::ProcessTable::Match::Swapped->new( {} );

is( $swapped_checker->match( mock_process( uid => 1000, cmndline => 'perl', state => 'sleep', rss => 0 ) ),
	1, 'Swapped matches a process with a rss of 0' );
is( $swapped_checker->match( mock_process( uid => 1000, cmndline => 'perl', state => 'sleep', rss => 4096 ) ),
	0, 'Swapped does not match a process with a non-zero rss' );
is( $swapped_checker->match( mock_process( uid => 1000, cmndline => 'perl', state => 'zombie', rss => 0 ) ),
	0, 'Swapped does not match a zombie' );
is( $swapped_checker->match( mock_process( uid => 0, cmndline => '', state => 'sleep', rss => 0 ) ),
	0, 'Swapped does not match a kernel process' );

#
# EUIDset
#

my $euid_set_checker = Proc::ProcessTable::Match::EUIDset->new( {} );

is( $euid_set_checker->match( mock_process( uid => 1000, euid => 0 ) ),
	1, 'EUIDset matches when the euid differs from the uid' );
is( $euid_set_checker->match( mock_process( uid => 1000, euid => 1000 ) ),
	0, 'EUIDset does not match when the euid and uid are the same' );
is( $euid_set_checker->match( mock_process( uid => 1000 ) ),
	0, 'EUIDset does not match when the euid is missing' );

#
# EGIDset
#

my $egid_set_checker = Proc::ProcessTable::Match::EGIDset->new( {} );

is( $egid_set_checker->match( mock_process( gid => 1000, egid => 0 ) ),
	1, 'EGIDset matches when the egid differs from the gid' );
is( $egid_set_checker->match( mock_process( gid => 1000, egid => 1000 ) ),
	0, 'EGIDset does not match when the egid and gid are the same' );
is( $egid_set_checker->match( mock_process( gid => 1000 ) ),
	0, 'EGIDset does not match when the egid is missing' );

done_testing();
