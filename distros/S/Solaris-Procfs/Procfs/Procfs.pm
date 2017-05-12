#---------------------------------------------------------------------------

package Solaris::Procfs;

# Copyright (c) 1999-2002 John Nolan. All rights reserved.
# This program is free software.  You may modify and/or
# distribute it under the same terms as Perl itself.
# This copyright notice must remain attached to the file.
#
# You can run this file through either pod2text, pod2man or
# pod2html to produce pretty documentation in text, manpage or
# html file format (these utilities are part of the
# Perl 5 distribution).

use vars qw($VERSION @ISA $AUTOLOAD @EXPORT_OK %EXPORT_TAGS);
use vars qw($WARNSTRINGS $DEBUG );
use vars qw( $not_implemented $not_owner $insufficient_memory $read_failed);
use strict;
use DynaLoader;
use Carp;
use File::Find;

require Exporter;
require Cwd;  # Don't use "use", otherwise we'll import the cwd() function

$VERSION     = '0.26';
$DEBUG       = 1;
@ISA         = qw(DynaLoader Exporter);
@EXPORT_OK   = qw( 
		root cwd getpids writectl

		fd prcred sigact status lstatus psinfo 
		lpsinfo usage lusage map rmap lwp auxv 
		proot pcwd xmap 
);

%EXPORT_TAGS = (

	procfiles => [ qw(
		fd prcred sigact status lstatus psinfo 
		lpsinfo usage lusage map rmap lwp auxv 
		proot pcwd xmap 
	) ],
	'dont_preload_tty_list' => [],
);


# Pull in all the flags and extra export tags.
# This syntax is non-portable, but we are only interested
# in Solaris systems anyway.  ;) 
#
require 'Solaris/Procfs/include/sys/procfs.ph';

sub import {

	my $pkg = shift;
	my(%flags);
	grep($flags{$_}++,@_);

	# On some systems, the list of devices is enormous
	# and it takes a long time to read them all. 
	# If you use the 'dont_preload_tty_list' pragma then we
	# will not try to load the list at launch time.
	#
	get_tty_list() unless $flags{':dont_preload_tty_list'};

	my($oldlevel) = $Exporter::ExportLevel;
	$Exporter::ExportLevel = 1;
	Exporter::import($pkg,keys %flags);
	$Exporter::ExportLevel = $oldlevel;
}


$not_implemented  = "NOT IMPLEMENTED";
$not_owner = "ENOPERM: You are not owner or root and do not have permissions to open the process";
$insufficient_memory = "ENOMEM: Request for memory failed";
$read_failed = "pread failed";

bootstrap Solaris::Procfs $VERSION;


#-------------------------------------------------------------
# Generate a hash mapping TTY numbers to paths.
# This code is called one time at module load time,
# and then the module accesses the hash $Solaris::Procfs::TTYDEVS.
# This code was inspired by similar code in the
# module Proc::ProcessTable by Daniel Urist. 
#
sub get_tty_list {

	undef %Solaris::Procfs::TTYDEVS;

	find(
		sub{
			my $rdev = (stat $File::Find::name)[6];
			$Solaris::Procfs::TTYDEVS{$rdev} = $File::Find::name if($rdev);
		},
		"/dev/pts"
	);
}  

#-------------------------------------------------------------
#
sub getpids  { 

	unless (opendir (DIR, "/proc") ) {

		carp "Couldn't open directory /proc : $!";
		return;
	}

	my @pids = grep /^\d+$/, readdir DIR;

	close(DIR);

	return  @pids;
}



#-------------------------------------------------------------
#
sub cwd {

	return if not defined $_[0] or ref($_[0]) or $_[0] =~ /^\D$/
		or not -d "/proc/$_[0]";

	my $pid = $_[0];

	my $err = 0;

	local $SIG{__WARN__} = sub { $err = 1; return; };
	return unless stat "/proc/$pid";

	my $hoo = Cwd::abs_path("/proc/$pid/cwd/.");
	my $path = $hoo;

	return if $err;

	# Previous to perl 5.005, Cwd::abs_path() returned ""
	# when it actually meant to return "/".  
	#
	return unless defined $path;
	return "/" if $path eq "";
	return $path;
}

#-------------------------------------------------------------
#
sub root {

	return if not defined $_[0] or ref($_[0]) or $_[0] =~ /^\D$/
		or not -d "/proc/$_[0]";

	my $pid = $_[0];

	my $err = 0;

	local $SIG{__WARN__} = sub { $err = 1; return; };
	return unless stat "/proc/$pid";

	my $path = Cwd::abs_path("/proc/$pid/root/.");

	# Previous to perl 5.005, Cwd::abs_path() returned ""
	# when it actually meant to return "/".  
	#
	return unless defined $path;
	return "/" if $path eq "";
	return $path;
}



#-------------------------------------------------------------
#  These names are more exportable
#
*proot = *root;
*pcwd  = *cwd;


#-------------------------------------------------------------
#
sub fd  { 

	return if not defined $_[0] or ref($_[0]) or $_[0] =~ /^\D$/
		or not -d "/proc/$_[0]";

	my $pid = $_[0];

	my %retval;

	unless (opendir (DIR, "/proc/$pid/fd") ) {

		carp "Couldn't open directory /proc/$pid/fd : $!";
		return;
	}

	foreach ( grep /^\d+$/, readdir DIR ) {

		$retval{$_} = 
			-d "/proc/$pid/fd/$_"
				? Cwd::abs_path("/proc/$pid/fd/$_/.") 
				: ""
				; 
	}

	close (DIR);

	return \%retval;
}


#-------------------------------------------------------------
#
sub sigact  {

	return if not defined $_[0] or ref($_[0]) or $_[0] =~ /\D/;
	return _sigact($_[0]);
}

#-------------------------------------------------------------
#
sub psinfo  {

	return if not defined $_[0] or ref($_[0]) or $_[0] =~ /\D/;
	return _psinfo($_[0]);
}

#-------------------------------------------------------------
#
sub status  {

	return if not defined $_[0] or ref($_[0]) or $_[0] =~ /\D/;
	return _status($_[0]);
}

#-------------------------------------------------------------
#
sub prcred  {

	return if not defined $_[0] or ref($_[0]) or $_[0] =~ /\D/;
	return _prcred($_[0]);
}

#-------------------------------------------------------------
#
sub lpsinfo  {

	return if not defined $_[0] or ref($_[0]) or $_[0] =~ /\D/;
	return _lpsinfo($_[0]);
}

#-------------------------------------------------------------
#
sub lstatus  {

	return if not defined $_[0] or ref($_[0]) or $_[0] =~ /\D/;
	return _lstatus($_[0]);
}

#-------------------------------------------------------------
#
sub lusage  {

	return if not defined $_[0] or ref($_[0]) or $_[0] =~ /\D/;
	return _lusage($_[0]);
}

#-------------------------------------------------------------
#
sub usage  {

	return if not defined $_[0] or ref($_[0]) or $_[0] =~ /\D/;
	return _usage($_[0]);
}

#-------------------------------------------------------------
#
sub map  {

	return if not defined $_[0] or ref($_[0]) or $_[0] =~ /\D/;
	return _map($_[0]);
}

#-------------------------------------------------------------
#
sub xmap  {

	return if not defined $_[0] or ref($_[0]) or $_[0] =~ /\D/;
	return _xmap($_[0]);
}

#-------------------------------------------------------------
#
sub auxv  {

	return if not defined $_[0] or ref($_[0]) or $_[0] =~ /\D/;
	return _auxv($_[0]);
}

#-------------------------------------------------------------
#
sub writectl  {

	return if not defined $_[0] or ref($_[0]) or $_[0] =~ /\D/;

	my ($pid, @args) = @_;

	return unless scalar @args > 0;

	return _writectl($pid,@args);
}


#-------------------------------------------------------------
#
sub rmap  {

	return if not defined $_[0] or ref($_[0]) or $_[0] =~ /\D/;
	return _rmap($_[0]);
}

#-------------------------------------------------------------
#
sub lwp  {

	return if not defined $_[0] or ref($_[0]) or $_[0] =~ /\D/;
	return _lwp($_[0]);
}

1;

__END__


=head1 NAME

Solaris::Procfs - access Solaris process information from Perl

=head1 SYNOPSIS

(See the EXAMPLES section below for more info.)

=head1 DESCRIPTION

This module is an interface the /proc filesystem 
on Solaris systems.

Each process on a Solaris system has a corresponding 
directory under /proc, named after the process id.  
In each of these directories are a series of files 
and subdirectories, which contain information about 
each process.  The proc(4) manpage gives complete details 
about these files.  Basically, the files contain one or 
more C structs with data about its corresponding process, 
maintained by the kernel.  

This module provides methods which access these files 
and convert the C structs contained in them into Perl 
data structures.  A few utility functions are also 
included for manipulating these files. 


=head1 STATUS

This is pre-alpha software.  It is far from finished.  
Parts of it need extensive rewriting and testing.  
However, the core functionality does seem to work properly. 

Contributions and critiques would be warmly welcomed. 


=head1 EXAMPLES

There are several different ways to invoke the functions in this module:
as object methods, as functions, or as a tied hash. 

As functions:

	use Solaris::Procfs;

	my $psinfo = Solaris::Procfs::psinfo( $pid );

As exported functions:

	use Solaris::Procfs (:procfiles);

	my $psinfo = psinfo( $pid );

As process objects:

	use Solaris::Procfs;
	use Solaris::Procfs::Process;

	my $p = new Solaris::Procfs::Process $pid;
	my $psinfo = $p->psinfo;

As process objects with tied hashes:

	use Solaris::Procfs;
	use Solaris::Procfs::Process;

	my $p = new Solaris::Procfs::Process $pid;
	my $psinfo = $p->{psinfo};

As a filesystem object with tied hashes:

	use Solaris::Procfs;
	use Solaris::Procfs::Filesystem;

	my $fs = new Solaris::Procfs::Filesystem;
	my $psinfo = $fs->{$pid}->{psinfo};

By default the module will fill the hash
%Solaris::Procfs::TTYDEVS with a mapping of 
TTY device ids to the name of the TTY (it examines
each file under /dev/pts).  The module uses this mapping 
to populate fields in other hashes. If your system 
has a very large list of these TTYs, and you want to 
suppress this preloading behavior, then use the following pragma:

	use Solaris::Procfs qw(:dont_preload_tty_list);

The module will then use the string '??' to populate
fields which normally contain TTY names. 


=head1 FUNCTIONS

This module defines functions which each correspond to 
the files available under the directories in /proc. 
Complete descriptions of these files are available
in the proc(4) manpage.  

Unless otherwise noted, the corresponding function in the 
Solaris::Procfs module simply returns the contents of the file 
in the form of a set of nested hashrefs.  Exceptions to this 
are listed below. 

These functions can also be accessed implcitly as elements 
in a tied hash.  When used this way, each process can be
accessed as if it were one giant Perl structure, containing
all the data related to that process id in the files
under /proc/{pid}.  To do this, you must use either the
Solaris::Procfs::Process or the Solaris::Procfs::Filesystem
modules.  If you only use the Solaris::Procfs module,
then you can only use the function-oriented interface. 

Additional functions are also available. 

=head2 as

Not yet implemented.  The 'as' file contains the address-space
image of the process. 

=head2 auxv

The 'auxv' file contains the initial values of the process's 
aux vector in an array of auxv_t structures (see <sys/auxv.h>). 

=head2 ctl

Not implemented as a function.  The 'ctl' file is a write-only file 
to which structured messages are written directing the system to change 
some aspect of the process's state or control its behavior in some way.  
This file somewhat like a device file.  See the examples
directory 'examples' included in this package for some simple 
examples showing how to write to this file. 

=head2 cwd or pcwd

Returns a string containing the absolute path to
the process' current working directory.  The 'cwd' file
is a symbolic link to the process's current working directory. 

=head2 fd

Returns a hash whose keys are the process' open file descriptors,
and whose values are the absolute paths to the open files, as far 
as can be determined.  The 'fd' directory contains references 
to the open files of the process.  Each entry is a decimal number 
corresponding to an open file descriptor in the process. 

=head2 ldt

Not yet implemented.  The 'ldt' file exists only on x86 based machines. 
It is non-empty only if the process has established a local descriptor 
table (LDT).  If non-empty, the file contains the array of currently 
active LDT entries in an array of elements of type struct ssd, 
defined in <sys/sysi86.h>, one element for each active LDT entry.

=head2 lpsinfo

The 'lpsinfo' file contains a prheader structure followed by 
an array of lwpsinfo structures, one for each lwp in the process. 

=head2 lstatus

The 'lstatus' file contains a prheader structure followed 
by an array of lwpstatus structures, one for each lwp in the process. 

=head2 lusage

The 'lusage' file contains a prheader structure followed by an array  of
prusage structures, one for each lwp in the process plus an additional 
element at the beginning that contains the summation over all defunct lwps.

=head2 lwp

The 'lwp' directory contains entries each of which names 
an lwp within the process.  These entries are themselves 
directories containing additional files.  This function 
returns the contents of the files 'lwpstatus', 'lwpsinfo', 
and 'lwpusage', translated into a set of nested hashes.  
Interfaces to the files 'asrs', 'gwindoes', 'lwpctl' 
and 'xregs' have not been implemented. 

=head2 map

The 'map' file contains information about the virtual address map 
of the process.  The file contains an array of prmap structures, 
each of which describes a contiguous virtual address region 
in the address space of the traced process.  

=head2 object

Not yet implemented.  The 'object' directory containing read-only files 
with names corresponding to the entries in the map and pagedata files. 
Opening such a file yields a file descriptor for the underlying 
mapped file associated with an address-space mapping in the process.

=head2 pagedata

Not yet implemented.  Opening the 'pagedata' file enables tracking of 
address space references and modifications on a per-page basis. 

=head2 prcred

The 'prcred' file contains a description of the credentials 
associated with the process (UID, GID, etc.).

=head2 psinfo

The 'psinfo' file ontains miscellaneous information about the process 
and the representative lwp needed by the ps(1) command. 

=head2 rmap

The 'rmap' file contains information about the reserved address 
ranges of the process.  Examples  of such reservations include 
the address ranges reserved for the process stack and the individual 
thread stacks of a multi-threaded process. 

=head2 root or proot

Returns a string containing the absolute path to the process' root 
directory. The 'root' file is a symbolic link to the process' 
current working directory. 

=head2 sigact

The 'sigact' file contains an array of sigaction structures describing the
current dispositions of all signals associated with the
traced process (see sigaction(2)).

=head2 status

The 'status' file ontains state information about the process and the
representative lwp.  

=head2 usage      

The 'usage' file contains process usage information 
described by a prusage structure. 

=head2 watch

Not yet implemented.  The 'watch' file contains an array of 
prwatch structures, one for each watched area established 
by the PCWATCH control operation. 

=head2 xmap

The 'xmap' file contains information about the virtual address map 
of the process.  This file is not documented in the proc manpage.


=head1 OTHER FUNCTIONS

=head2 writectl

Write control directives to a process control file (/proc/<pid>/ctl).
For example, the following code will turn on microstate accounting
for a given process ($pid):

	use Solaris::Procfs qw(writectl);
	writectl($pid,PCSET,PR_MSACCT); 



=head1 ERROR HANDLING

Most of these functions are essentially wrappers around the system calls
open(), read() and write().  Basically, we are reading and writing to 
the files under C</proc>.  If any of these system calls fail, they will 
set the system errno variable, and the function calling them
will just return.  

When using these functions, you should check the return value just
like you would check the return value of a system call.  Make sure
that that the return value is defined before using it.  If the value
is not defined, print out the variable C<$!> for a verbose description 
of the error.  The most likely error message will be "No such file or directory" 
if the process you are accessing does not exist, or "Permission denied" 
or "Bad file number" if you do not have permission to access the file.  

Here is an example from the file examples/ptree:

	my $psinfo = psinfo($pid);

	unless (defined $psinfo and ref $psinfo eq 'HASH') {

		warn "Cannot get psinfo on process $pid: $!\n";
	}

Here is an example from the file examples/pstop:

	writectl($pid,PCSTOP) or warn "Can't control process $pid: $!\n";


=head1 CHANGES

=over 4

=item * Version 0.26

	Made some changes to the macros.
	Also applied a small patch to the lwp() function, 
	provided by Stephen Youndt. Thanks!

=item * Version 0.25

	Plugged a memory leak in the _psinfo2hash() function.
	Thanks to Dmitry Frolov for catching this and sending a patch. 

=item * Version 0.23

	Fixed one bug in the basic.t and process.t test scripts. 
	Added more notes to the usage instructions. 

=item * Version 0.22

	Fixed a bug in the _prcred function, reported by
	David Landgren and Chris Lamb.  Also fixed a bug 
	in the _lwp function, which prevented the module 
	from building properly on multi-threaded perls.   
	Thanks to Marek Rouchal for assisting with this bug.  
	Also fixed a problem with the get_tty_devs program, 
	thanks to Norbert Klasen for reporting this.   
	Thanks also to the CPAN testers,
	whose reports are very useful.  

=item * Version 0.21

	Brian Farrell sent a very useful patch which handles
	inspection of argv and environment of processes 
	other than the currently running process. 

=item * Version 0.20

	Thomas Whateley sent a patch with functions for
	accessing the /proc/<pid>/xmap file.
	Dominic Dunlop submitted a small patch to the XS function
	which accesses the map file.

=item * Version 0.19

	Kenneth Skaar sent a patch which fixed some memory leaks.
	Updated the documentation.
	Expanded the regression tests. 

=item * Version 0.18

	Cleaned up the error handling.
	Created regression tests. 
	Added several more example scripts. 
	Reorganized files in the install package. 

=item * Version 0.16

	Added a writectl() function for sending signals to processes.
	Defined a set of constants which correspond to the #define's
	in the sys/procfs.h header.  Added a few example scripts. 

=item * Version 0.14

	Separated the Filesystem and Process modules from the 
	main Procfs module.  The module Procfs.pm itself now contains 
	no object-oriented code.  All OO code is in Filesystem.pm
	and Process.pm. 

=item * Version 0.10

	Initial release on CPAN

=back

=head1 TO DO

=over

=item *

Improve the documentation, test scripts and sample scripts.  
Create examples of the use of the writectl() functions.   
Add and test a writelwp() function similar to writectl().

=item *

Add functions which can read the 'as' file.  

=item *

Finish implementing Perl scripts which correspond to each of
the procutils binaries (under /usr/proc/bin).
These are described in the proc(1) manpage. 

=back

=head1 THANKS

Much of this code is modeled after code written by Alan Burlison, 
and I received some helpful and timely advice from Tye McQueen.  

Thanks to Daniel J. Urist for writing Proc::ProcessTable.
I used his method for keeping track of TTY numbers. 

Thanks to Kennth Skaar (kenneths@regina.uio.no) for fixing
some memory leaks and teaching me to count (references).  

Thanks to Thomas Whateley for sending a patch with functions for
accessing the /proc/<pid>/xmap file.

Thanks to Dominic Dunlop for submitting a patch to the functions
which access the map file.

Thanks to Brian Farrell, for sending a very useful patch 
which allows Solaris::Procfs to inspect the argv and environment 
of processes other than the currently running process. 


=head1 AUTHOR

John Nolan jpnolan@sonic.net 1999-2003.  
A copyright statment is contained in the source code itself. 

=cut

1;
