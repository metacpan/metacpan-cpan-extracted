package Platform;

#
# Ask the platform, without SimpleFlow, for what a test needs and the platform
# may not give, so that the test is skipped for the platform's sake and fails
# for the module's.
#
# Each returns '' when the platform does it, and otherwise the reason to give
# skip(). Both were written for reports on SimpleFlow 0.196, whose tests
# guessed instead, by user id and by $^O:
#
# - modes_ignored: report a5d923fc-e398-11f1-9d95-ca6b7133da09, Cygwin perl
#   5.44.0 on Windows. The tester's uid was 197608, not 0, but a file with
#   mode 0000 could still be written, and one made read-only by "protect" was
#   still -w. A Windows administrator holds backup and restore privileges,
#   which open a file whatever its permissions, so to file modes such a user
#   is root by another uid.
# - children_cpu_unreported: reports fa1e66f8-e39c-11f1-aaa0-b0af0db2ccff and
#   000fce8a-e39d-11f1-aaa0-b0af0db2ccff, GNU/Hurd 0.9, perls 5.24.4 and
#   5.44.0, where a child that spun for 0.3 s of user time was given 0. In
#   glibc's sysdeps/mach/hurd/times.c (master, read 2026-11-18), times() sets
#   tms_cutime and tms_cstime to 0 unless glibc was built with
#   HAVE_HURD_PROC_GETCHILDREN_RUSAGE, so whether the Hurd reports them depends
#   on the build, and only asking can tell.
#

use strict;
use warnings FATAL => 'all';
require 5.010;
use Exporter 'import';
use File::Spec;
use File::Temp 'tempdir';
our @EXPORT_OK = qw(modes_ignored children_cpu_unreported);

# Whether this user can get past a file mode: given 0444, whether it can write
# the file; given 0000, whether it can read or write it. Ask only for the
# mode a test relies on: MSWin32 maps any mode without write permission to
# the read-only attribute and has no unreadable files, so 0444 holds there
# and 0000 does not.
sub modes_ignored {
	my $mode = shift;
	my $dir = tempdir(CLEANUP => 1);
	my $file = File::Spec->catfile($dir, sprintf('mode%04o', $mode));
	open my $fh, '>', $file or die "cannot write \"$file\": $!";
	close $fh;
	chmod $mode, $file or return "cannot chmod \"$file\": $!";
	my $read  = (($mode & 0400) == 0) && open(my $r, '<', $file);
	my $write = open my $w, '>>', $file;
	close $r if $read;
	close $w if $write;
	chmod 0600, $file; # so that tempdir's cleanup can remove it
	return '' if !$read && !$write;
	return sprintf('this user %s a file of mode %04o, as root does (or, on Cygwin, a Windows administrator), '
		. 'so file modes prove nothing here', ($read ? 'read' : 'wrote'), $mode);
}

# Whether times() counts the CPU time of a child that was waited for.
sub children_cpu_unreported {
	my $before = (times)[2];
	# 0.05 s is 5 ticks of times()'s 1/100 s, so a count of 0 is not rounding
	system($^X, '-e', '1 while (times)[0] < 0.05') == 0 or return "cannot run \"$^X\": $?";
	return '' if (times)[2] > $before;
	return 'times() gives no CPU time for a finished child here (as on a GNU/Hurd whose glibc lacks '
		. 'HAVE_HURD_PROC_GETCHILDREN_RUSAGE), so there is none for cpu.user to report';
}

1;
