package OS2::Proc;

use strict;
use vars qw($VERSION @ISA @EXPORT %proc_type %thread_type %prio_type);

require Exporter;
require DynaLoader;
# use AutoLoader 'AUTOLOAD';

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	     proc_info global_info mod_info process_info );
$VERSION = '0.02';

%proc_type = qw(
		0 FullScreen
		1 RealMode
		2 VIO
		3 PM
		4 Detached
	       );

%thread_type = qw(
		1 Ready
		2 Blocked
		5 Running
	       );

%prio_type = qw(
		0 Idle-Time
		1 Regular
		2 Time-Critical
		3 Fixed-High
	       );

bootstrap OS2::Proc $VERSION;

# Preloaded methods go here.

sub global_info {
  my %out;
  @out{qw(threads procs modules)} = @{ global_info_int() };
  \%out;
}

sub thread_from_intnl {
  my $thread = shift;
  return { threadid => shift @$thread,
	   slotid => shift @$thread,
	   sleepid => shift @$thread,
	   priority_class => $prio_type{($_->[0]>>8) - 1},
	   priority_level => $_->[0] & 0xFF,
	   priority => shift @$thread,
	   systime => shift @$thread,
	   usertime => shift @$thread,
	   thread_state => $thread_type{$_->[0]} || "unknown",
	   state => shift @$thread,
	 };
}

sub state_to_array {
  my ($state, @arr) = (shift);
  push @arr, 'ExitList' if $state & 0x01;
  push @arr, 'ExitingT1' if $state & 0x02;
  push @arr, 'Exiting' if $state & 0x04;
  push @arr, 'NeedsWait' if $state & 0x10;
  push @arr, 'Parent-Waiting' if $state & 0x20;
  push @arr, 'Dying' if $state & 0x40;
  push @arr, 'Embrionic' if $state & 0x80;
  \@arr;
}

sub proc_info {
  my $data = proc_info_int(@_);
  my $have_mods = (@_ < 2 or $_[1] & 2);
  my %mods;
  %mods = %{ mod_info($data) } if $have_mods;
  my @procs = map {
    my @threads = map {thread_from_intnl($_)} @{ shift @$_ };
    my ($module, $handles);
    {
      threads => \@threads,
      pid => shift @$_,
      ppid => shift @$_,
      proc_type => $proc_type{$_->[0]},
      type => shift @$_,
      status_array => state_to_array($_->[0]),
      state => shift @$_,
      sessid => shift @$_,
      module_handle => ($module = shift @$_),
      threadcnt => shift @$_,
      privsem32cnt => shift @$_,
      sem16cnt => shift @$_,
      dllcnt => shift @$_,
      shrmemcnt => shift @$_,
      fdscnt => shift @$_,
      dynamic_handles => ($handles = shift @$_),
      ($have_mods ?
       (module_name => $mods{$module}->{name},
        dynamic_names => [map $mods{$_}->{name}, @$handles],
        static_names => $mods{$module}->{static_names},
        static_handles => $mods{$module}->{static_handles},) :
       ()),
    }
  } @{$data->[0]};
  return (\@procs, \%mods);
}

sub mod_info {
  my $data = shift || proc_info_int($$, 2);
  my %mods;
  my $mod;
  foreach $mod (@{$data->[1]}) {
    my $handle = shift @$mod;
    $mods{$handle} = { type => shift @$mod,
		       cnt_static => shift @$mod,
		       segcnt => shift @$mod,
		       name => shift @$mod,
		       static_handles => [@$mod],
		     };
  }
  foreach my $handle (keys %mods) {
    my @static_handles = @{$mods{$handle}{static_handles}};
    $mods{$handle}{static_names} = [map { $mods{$_}{name} } @static_handles];
  }
  \%mods;
}

sub process_info (;$) {
  my $pid = @_ ? shift : $$ or die "process info got zero argument";
  (proc_info($pid,1))[0]->[0];
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

OS2::Proc - Perl extension for get information about running processes
and loaded modules.

=head1 SYNOPSIS

  use OS2::Proc;
  $p_info = (proc_info($$,1))[0]->[0];
  $p_info->{pid} == $$ or die;
  $t_info = $p_info->{threads}[0];
  $ticks = ($t_info->{usertime}+$t_info->{systime});
  %i = OS2::SysInfo;
  $cpu_time = $ticks*$i{TIMER_INTERVAL}/10000;

=head1 DESCRIPTION

This module access internal tables keeping information of OS/2 processes.
The corresponding API call was present for a long time, but is documented
only around OS/2 v4.5.  Since older version are stable now, it should
be safe to use this call (with certain limitations) for any version of OS/2.

Keep in mind that due to certain bugs in the OS/2 kernel some calls to this
API may kill your system.  E.g., it is not safe to get an info about
non-existing PID until W3fp18.  (The module contains a safeguard against
this bug.)

This module allows querying the following data: 

=over

=item $href = global_info()

hash reference with sizes of internal tables for C<modules>, C<procs>,
C<threads>.

  print "$_ => $href->{$_}\n" for qw(modules procs threads);

=item $href_modules = mod_info()

$href_modules indexes modules by their handles, the value being a hash
reference with the following fields:

  cnt_static	 - No. of modules linked in at compile time
  name		 - Full path name (except for SYSINIT/basedevs?)
  segcnt	 - ?? Number of segments?
  static_handles - array reference with handles of modules linked
			at compile time
  static_names	 - same with names
  type		 - ?? SYSINIT/IFS/DMD/SYS=0, DLL/EXE=1, 

=item ($aref_processes, $href_modules) = proc_info(0)

information about all processes and modules on the system.
Each entry referenced by $aref_processes is a hash reference with the
following fields:

  threads	  - Array of hash references with thread information
  pid		  - pid
  ppid		  - parent pid
  proc_type	  - FullScreen/RealMode/VIO/PM/Detached
  type		  - 0..4 (see proc_type)
  status_array    - combination of ExitList/ExitingT1/Exiting/
			NeedsWait/Parent-Waiting/Dying/Embrionic
  state		  - combination of flags in 0x01..0x80 (see status_array)
  sessid	  - SessionId
  module_name	  - full name of the executabale (!)
  module_handle	  - module handle of the executable
  threadcnt	  - No. of threads
  privsem32cnt    - No. of private 32bit semaphores
  sem16cnt	  - No. of 16bit semaphores
  dllcnt	  - length
  shrmemcnt	  - No. of shared memory segments
  fdscnt	  - No. of available file descriptors
  dynamic_names	  - reference to array with full names of
			runtime-loaded modules (!)
  dynamic_handles - same with handles
  static_handles  - array reference with handles of modules linked
			at compile time (!)
  static_names	  - same with names (!)

Each thread-information hash has the following entries

  priority	 - absolute priority (?)
  priority_class - Idle-Time/Regular/Time-Critical/Fixed-High
  priority_level - Priority shift inside class (larger is higher)
  sleepid	 - ???
  slotid	 - "Global" thread id
  state		 - 1,2,5 (see thread_state)
  systime	 - Cumulative no. of busy ticks spent in syscalls
  thread_state	 - Ready/Blocked/Running
  threadid	 - Thread Id "in the process"
  usertime	 - Cumulative no. of busy ticks spent in user code

Keep in mind that the semantic of priority_class is not monotonic,
monotonic is C<Idle-Time/Regular/Fixed-High/Time-Critical>.

The $href_modules is the same as for mod_info().

=item $aref = proc_info()

same info with processes restricted to the current process, and
modules to modules used by the current process.

=item $aref = proc_info($pid)

same about a given ProcessID.

=item $aref = proc_info($pid,$flags)

Allows restriction of the information restricted to one about

  processes	- 0x001
  modules	- 0x002
  semaphores	- 0x004
  shared memory - 0x008
  files		- 0x100

and without any parsing.  The description above corresponds to C<$flags==3>.
Only the combinations of 0x1 and 0x2 are allowed now.  If 0x2 is not
present, the fields marked with C<(!)> are omited from the process
list descriptions.

=item $href = process_info($pid)

Gives a reference to a hash with process information as above, except
for those marked with (!).

=back

=head1 AUTHOR

Ilya Zakharevich <ilya@math.ohio-state.edu>

=head1 SEE ALSO

perl(1).

=cut

