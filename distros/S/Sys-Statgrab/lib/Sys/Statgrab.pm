package Sys::Statgrab;

$VERSION = 0.01;

use strict;
use warnings;

use constant STATGRAB_CONSTANTS => qw(
	SG_ERROR_ASPRINTF
	SG_ERROR_DEVSTAT_GETDEVS
	SG_ERROR_DEVSTAT_SELECTDEVS
	SG_ERROR_ENOENT
	SG_ERROR_GETIFADDRS
	SG_ERROR_GETMNTINFO
	SG_ERROR_GETPAGESIZE
	SG_ERROR_KSTAT_DATA_LOOKUP
	SG_ERROR_KSTAT_LOOKUP
	SG_ERROR_KSTAT_OPEN
	SG_ERROR_KSTAT_READ
	SG_ERROR_KVM_GETSWAPINFO
	SG_ERROR_KVM_OPENFILES
	SG_ERROR_MALLOC
	SG_ERROR_NONE
	SG_ERROR_OPEN
	SG_ERROR_OPENDIR
	SG_ERROR_PARSE
	SG_ERROR_SETEGID
	SG_ERROR_SETEUID
	SG_ERROR_SETMNTENT
	SG_ERROR_SOCKET
	SG_ERROR_SWAPCTL
	SG_ERROR_SYSCONF
	SG_ERROR_SYSCTL
	SG_ERROR_SYSCTLBYNAME
	SG_ERROR_SYSCTLNAMETOMIB
	SG_ERROR_UNAME
	SG_ERROR_UNSUPPORTED
	SG_ERROR_XSW_VER_MISMATCH
	SG_IFACE_DUPLEX_FULL
	SG_IFACE_DUPLEX_HALF
	SG_IFACE_DUPLEX_UNKNOWN
	SG_PROCESS_STATE_RUNNING
	SG_PROCESS_STATE_SLEEPING
	SG_PROCESS_STATE_STOPPED
	SG_PROCESS_STATE_UNKNOWN
	SG_PROCESS_STATE_ZOMBIE
);
use constant STATGRAB_BASE_FUNCTIONS => qw(
	get_error drop_privileges 
	get_host_info 
	get_cpu_stats get_cpu_stats_diff get_cpu_percents
	get_disk_io_stats get_disk_io_stats_diff
	get_fs_stats
	get_load_stats
	get_mem_stats
	get_swap_stats
	get_network_io_stats get_network_io_stats_diff
	get_network_iface_stats
	get_page_stats get_page_stats_diff
	get_user_stats
	get_process_stats
);
use constant STATGRAB_SORT_FUNCTIONS => qw(
	sort_procs_by_name
	sort_procs_by_pid
	sort_procs_by_uid
	sort_procs_by_gid
	sort_procs_by_size
	sort_procs_by_res
	sort_procs_by_cpu
	sort_procs_by_time
);

BEGIN {
	use Exporter ();
	use vars		qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
	@ISA			= qw(Exporter);
	@EXPORT			= (STATGRAB_CONSTANTS, STATGRAB_BASE_FUNCTIONS, STATGRAB_SORT_FUNCTIONS);
	@EXPORT_OK		= (STATGRAB_CONSTANTS, STATGRAB_BASE_FUNCTIONS, STATGRAB_SORT_FUNCTIONS);
	%EXPORT_TAGS	= ( 'all' => [ STATGRAB_CONSTANTS, STATGRAB_BASE_FUNCTIONS, STATGRAB_SORT_FUNCTIONS ] );

	if ($^O eq 'cygwin') {
		require Unix::Statgrab;
		import Unix::Statgrab (STATGRAB_CONSTANTS);
		
		# Natively supported by Statgrab (>= 0.8) on cygwin
		*drop_privileges = *drop_privileges = \&Unix::Statgrab::drop_privileges;
		*get_host_info = *get_host_info = \&Unix::Statgrab::get_host_info;
		*get_cpu_stats = *get_cpu_stats = \&Unix::Statgrab::get_cpu_stats;
		*get_cpu_stats_diff = *get_cpu_stats_diff = \&Unix::Statgrab::get_cpu_stats_diff;
		*get_cpu_percents = *get_cpu_percents = \&Unix::Statgrab::get_cpu_percents;
		*get_mem_stats = *get_mem_stats = \&Unix::Statgrab::get_mem_stats;
		*get_swap_stats = *get_swap_stats = \&Unix::Statgrab::get_swap_stats;
		*get_page_stats = *get_page_stats = \&Unix::Statgrab::get_page_stats;
		*get_page_stats_diff = *get_page_stats_diff = \&Unix::Statgrab::get_page_stats_diff;
		*get_user_stats = *get_user_stats = \&Unix::Statgrab::get_user_stats;

		# Known as not supported by Statgrab (<= 0.13, at least) on cygwin
		*get_disk_io_stats = *get_disk_io_stats = sub { return Unix::Statgrab::get_disk_io_stats(@_) || Sys::Statgrab::Cygwin::sg_disk_io_stats->new(); };
		*get_disk_io_stats_diff = *get_disk_io_stats_diff = sub { return Unix::Statgrab::get_disk_io_stats_diff(@_) || Sys::Statgrab::Cygwin::sg_disk_io_stats->new('diff'); };
		*get_fs_stats = *get_fs_stats = sub { return Unix::Statgrab::get_fs_stats(@_) || Sys::Statgrab::Cygwin::sg_fs_stats->new(); };
		*get_load_stats = *get_load_stats = sub { return Unix::Statgrab::get_load_stats(@_) || Sys::Statgrab::Cygwin::sg_load_stats->new(); };
		*get_network_io_stats = *get_network_io_stats = sub { return Unix::Statgrab::get_network_io_stats(@_) || Sys::Statgrab::Cygwin::sg_network_io_stats->new(); };
		*get_network_io_stats_diff = *get_network_io_stats_diff = sub { return Unix::Statgrab::get_network_io_stats_diff(@_) || Sys::Statgrab::Cygwin::sg_network_io_stats->new('diff'); };
		*get_network_iface_stats = *get_network_iface_stats = sub { return Unix::Statgrab::get_network_iface_stats(@_) || Sys::Statgrab::Cygwin::sg_network_iface_stats->new(); };
		*get_process_stats = *get_process_stats = sub { return Unix::Statgrab::get_process_stats(@_) || Sys::Statgrab::Cygwin::sg_process_stats->new(); };
		
		*sort_procs_by_name = \&Sys::Statgrab::Cygwin::sg_process_stats::_sort_procs_by_name;
		*sort_procs_by_pid = \&Sys::Statgrab::Cygwin::sg_process_stats::_sort_procs_by_pid;
		*sort_procs_by_uid = \&Sys::Statgrab::Cygwin::sg_process_stats::_sort_procs_by_uid;
		*sort_procs_by_gid = \&Sys::Statgrab::Cygwin::sg_process_stats::_sort_procs_by_gid;
		*sort_procs_by_size = \&Sys::Statgrab::Cygwin::sg_process_stats::_sort_procs_by_size;
		*sort_procs_by_res = \&Sys::Statgrab::Cygwin::sg_process_stats::_sort_procs_by_res;
		*sort_procs_by_cpu = \&Sys::Statgrab::Cygwin::sg_process_stats::_sort_procs_by_cpu;
		*sort_procs_by_time = \&Sys::Statgrab::Cygwin::sg_process_stats::_sort_procs_by_time;
	}
	elsif ($^O eq 'MSWin32')
	{
		die "$^O not yet supported by ".__PACKAGE__;
		require Unix::Statgrab;
		import Unix::Statgrab (STATGRAB_CONSTANTS);
		require Win32::Process::Info;
		import Unix::Statgrab (STATGRAB_CONSTANTS);

	}
	else {
		require Unix::Statgrab;
		import Unix::Statgrab (STATGRAB_CONSTANTS, STATGRAB_BASE_FUNCTIONS, STATGRAB_SORT_FUNCTIONS);
	}
}


package Sys::Statgrab::Cygwin::sg_disk_io_stats;
use strict;
use warnings;

sub new {
	my $type = shift;
	my $class = ref($type) || $type;
	my $diff = 1 if shift;
	
	warn "get_disk_io_stats not yet implemented";
	return undef;
}

package Sys::Statgrab::Cygwin::sg_fs_stats;
use strict;
use warnings;

sub new {
	my $type = shift;
	my $class = ref($type) || $type;
	
	warn "get_fs_stats not yet implemented";
	return undef;
}

package Sys::Statgrab::Cygwin::sg_load_stats;
use strict;
use warnings;

sub new {
	my $type = shift;
	my $class = ref($type) || $type;
	
	warn "get_load_stats not yet implemented";
	return undef;
}

package Sys::Statgrab::Cygwin::sg_network_io_stats;
use strict;
use warnings;

sub new {
	my $type = shift;
	my $class = ref($type) || $type;
	my $diff = 1 if shift;
	
	warn "get_network_io_stats not yet implemented";
	return undef;
}

package Sys::Statgrab::Cygwin::sg_network_iface_stats;
use strict;
use warnings;

sub new {
	my $type = shift;
	my $class = ref($type) || $type;
	
	warn "get_network_iface_stats not yet implemented";
	return undef;
}

package Sys::Statgrab::Cygwin::sg_process_stats;
use strict;
use warnings;

use constant SORT_METHOD_PREFIX => '_sort_procs_by_';
use constant SORT_METHODS => qw(
	name
	pid
	uid
	gid
	size
	res
	cpu
	time
);

sub new {
	my $type = shift;
	my $class = ref($type) || $type;
	
	### generate process stat objects ###
	my @procs;
	opendir(PROCDIR, '/proc') || die "Can't read dir /proc: $!";
	push @procs, Sys::Statgrab::Cygwin::sg_process_stats::all_procs->new($_) foreach grep(/^\d+$/o, (readdir(PROCDIR)));
	closedir PROCDIR;
	
	### optimization for pcpu stat ###
	my %cpu_map;
	my @line;
	if (open(IPCCMD, "procps -e -opid -opcpu |")) {
		foreach my $l (<IPCCMD>) {
			$l =~ s/^\s+//o;
			@line = split(/\s+/o, $l);
			chomp @line;
			$cpu_map{$line[0]} = $line[1];
		}
		close IPCCMD;
		foreach my $proc (@procs) {
			$proc->{cpu_percent} = $cpu_map{$proc->{pid}};
		}
	}
	else {
		warn "Can't obtain cpu_percent stats: Can't execute procps: $!";
	}
	
	return bless(\@procs, $class);
}

sub all_procs {
	my $self = shift;
	return @{$self};
}

sub sort_by {
	my $self = shift;
	my $meth = shift;
	die "Usage: ".__PACKAGE__."::sort_by(obj, meth)" unless defined $meth;
	
	my $regex = quotemeta $meth;
	my $sort_method = SORT_METHOD_PREFIX.$meth;
	@{$self} = sort $sort_method @{$self} if grep(/^$regex$/, SORT_METHODS);
	return $self;
}

sub _sort_procs_by_name ($$) { shift->proc_name cmp shift->proc_name }
sub _sort_procs_by_pid ($$) { shift->pid <=> shift->pid }
sub _sort_procs_by_uid ($$) { shift->uid <=> shift->uid }
sub _sort_procs_by_gid ($$) { shift->gid <=> shift->gid }
sub _sort_procs_by_size ($$) { shift->proc_size <=> shift->proc_size }
sub _sort_procs_by_res ($$) { shift->proc_resident <=> shift->proc_resident }
sub _sort_procs_by_cpu ($$) { shift->cpu_percent <=> shift->cpu_percent }
sub _sort_procs_by_time ($$) { shift->time_spent <=> shift->time_spent }

package Sys::Statgrab::Cygwin::sg_process_stats::all_procs;
use strict;
use warnings;

our $AUTOLOAD;

sub new {
	my $type = shift;
	my $class = ref($type) || $type;
	my $pid = shift;
	
	my $o = bless(\$pid, $class);
	my $self = {
		proc_name		=> $o->_proc_name,
		proc_title		=> $o->_proc_title,
		pid				=> $o->_pid,
		parent_pid		=> $o->_parent_pid,
		pgid			=> $o->_pgid,
		uid				=> $o->_uid,
		euid			=> $o->_euid,
		gid				=> $o->_gid,
		egid			=> $o->_egid,
		proc_size		=> $o->_proc_size,
		proc_resident	=> $o->_proc_resident,
		time_spent		=> $o->_time_spent,
		cpu_percent		=> undef,	#efficiently calculated later by caller class
		nice			=> $o->_nice,
		state			=> $o->_state,
	};
	return bless($self, $class);
}

sub AUTOLOAD {	#read-only
	my $self = shift;
	my $class = ref($self) || $self;
	my $name = $AUTOLOAD;
	$name =~ s/.*://o;   # strip fully-qualified portion
	no strict 'refs';
	Carp::confess "Can't access '$name' field in class $class" unless (exists $self->{$name});
	return $self->{$name};
}
sub DESTROY {}
sub CLONE {}

sub _proc_name {
	my $self = shift;
	return Sys::Statgrab::Util::get_hash_value("/proc/${$self}/status", ':', 'Name', 1);
}
sub _proc_title {
	my $self = shift;
	my $cmdline = Sys::Statgrab::Util::get_value("/proc/${$self}/cmdline");
	$cmdline =~ s/\x0/ /go;
	return $cmdline;
}
sub _pid {
	my $self = shift;
	return ${$self};
}
sub _parent_pid {
	my $self = shift;
	return Sys::Statgrab::Util::get_value("/proc/${$self}/ppid");
}
sub _pgid {
	my $self = shift;
	return Sys::Statgrab::Util::get_value("/proc/${$self}/pgid");
}
sub _uid {
	my $self = shift;
	return Sys::Statgrab::Util::get_value("/proc/${$self}/uid");
}
sub _euid { return _uid(@_); }	#bug: is euid accessable on cygwin?
sub _gid {
	my $self = shift;
	return Sys::Statgrab::Util::get_value("/proc/${$self}/gid");
}
sub _egid { return _gid(@_); }	#bug: is egid accessable on cygwin?
sub _proc_size {	#note: approximated to nearest unit (default is kB)
	my $self = shift;
	my @size = split(/ /, Sys::Statgrab::Util::get_hash_value("/proc/${$self}/status", ':', 'VmSize', 1));
	return $size[0] * (lc $size[1] eq 'kb' ? 1000 : lc $size[1] eq 'mb' ? 1000000 : lc $size[1] eq 'gb' ? 1000000000 : 1);
}
sub _proc_resident {	#note: approximated to nearest unit (default is kB)
	my $self = shift;
	my @rss = split(/ /, Sys::Statgrab::Util::get_hash_value("/proc/${$self}/status", ':', 'VmRSS', 1));
	return $rss[0] * (lc $rss[1] eq 'kb' ? 1000 : lc $rss[1] eq 'mb' ? 1000000 : lc $rss[1] eq 'gb' ? 1000000000 : 1);
}
sub _time_spent {
	my $self = shift;
	my ($utime, $stime) = (split(/ /, Sys::Statgrab::Util::get_value("/proc/${$self}/stat")))[13..14];
	return $utime + $stime;
}
sub _cpu_percent {	#note: using more efficient method
	my $self = shift;
	return Sys::Statgrab::Util::get_procps_value(${$self}, 'pcpu');
	return undef;
}
sub _nice {
	my $self = shift;
#	return Sys::Statgrab::Util::get_procps_value(${$self}, 'ni');
	return (split(/ /, Sys::Statgrab::Util::get_value("/proc/${$self}/stat")))[18];
}
sub _state {
	my $self = shift;
	my $state = (split(/ /, Sys::Statgrab::Util::get_value("/proc/${$self}/stat")))[2];
#	return $state eq 'R' ? Sys::Statgrab::SG_PROCESS_STATE_RUNNING
#		: $state eq 'S' ? Sys::Statgrab::SG_PROCESS_STATE_SLEEPING
#		: $state eq 'T' ? Sys::Statgrab::SG_PROCESS_STATE_STOPPED
#		: $state eq 'Z' ? Sys::Statgrab::SG_PROCESS_STATE_ZOMBIE	#kludge: not sure if this is the correct letter
#		: Sys::Statgrab::SG_PROCESS_STATE_UNKNOWN
}

package Sys::Statgrab::Util;

use strict;
use warnings;

sub get_value ($) {
	my $file = shift;
	open(PROCFILE, "<$file") || die "Can't open file $file";
	my @line = <PROCFILE>;
	close PROCFILE;
	chomp @line;
	return $line[0];
}

sub get_array_index ($$$) {
	my $file = shift;
	my $delimiter = shift;
	my $idx = shift;
	open(PROCFILE, "<$file") || die "Can't open file $file";
	my @line = split(/\s*$delimiter\s*/, <PROCFILE>);
	close PROCFILE;
	chomp @line;
	return $line[$idx];
}

sub get_hash_value ($$$;$) {
	my $file = shift;
	my $delimiter = shift;
	my $key = shift;
	my $idx = shift;
	open(PROCFILE, "<$file") || die "Can't open file $file";
	my @line;
	while (@line = split(/\s*$delimiter\s*/, <PROCFILE>)) {
		last if $line[0] eq $key;
	}
	chomp @line;
	close PROCFILE;
	return defined $idx ? $line[$idx] : wantarray ? @line : $line[1];
}

sub get_procps_value ($$) {
	my $pid = shift;
	my $format = shift;
	if (open(IPCCMD, "procps -e -opid -o$format |")) {
		my @line;
		foreach my $l (<IPCCMD>) {
			$l =~ s/^\s+//o;
			@line = split(/\s+/o, $l);
			last if $line[0] eq $pid;
		}
		close IPCCMD;
		chomp @line;
		return $line[1];
	}
	else {
		warn "Can't obtain cpu_percent stats: Can't execute procps: $!";
		return undef;
	}
}

1;

__END__
=head1 NAME

Sys::Statgrab - Extension of Unix::Statgrab for greater portability

=head1 SYNOPSIS

    use Sys::Statgrab;

    local $, = "\n";
    
    my $host = get_host_info or 
	die get_error;
	
    print $host->os_name, 
	  $host->os_release,
	  $host->os_version,
	  ...;

    my $disks = get_disk_io_stats or
	die get_error;
	
    for (0 .. $disks->num_disks - 1) {
	print $disks->disk_name($_),
	      $disks->read_bytes($_),
	      ...;
    }

=head1 DESCRIPTION

Sys::Statgrab is an attempt to provide support for platforms unsupported by L<Unix::Statgrab>, and to complete support for other platforms that L<Unix::Statgrab> currently only partially supports.  If your platform natively supports all L<Unix::Statgrab> interface functions, then this module will silently act as a pass-through wrapper for L<Unix::Statgrab>.

=head1 BACKGROUND

=head2 What is Unix::Statgrab?

L<Unix::Statgrab> is a wrapper for libstatgrab as available from L<http://www.i-scream.org/libstatgrab/>. It is a reasonably portable attempt to query interesting stats about your computer. It covers information on the operating system, CPU, memory usage, network interfaces, hard-disks etc. 

=head2 Why did I make this module?

...instead of spending the time directly supporting the native C libstatgrab project?  I am a strong believer in the interface of libstatgrab and use it in many Perl projects, but I simply cannot find the time necessary code and debug large C patches for that project.  Also, there are some current limitations in some platforms (e.g. cygwin) at this time that prevent libstatgrab from being able to be completely ported without using a combination of external utilities and other open-source libraries.

Thus, the next best contribution I can offer is to encourage greater interest in libstatgrab, starting with the Perl user community, such that other developers may take an interest in working with the libstatgrab authors to add and complete native support for new platforms.  Ideally, as libstatgrab platform support grows, this module will eventually be reduced to a simple pass-through for L<Unix::Statgrab>, at which time that module would likely inherit the Sys:: package namespace of this module.

=head1 USAGE

See L<Unix::Statgrab> for complete usage documentation.

=head1 TODO

Complete as much support as possible for Cygwin (beyond libstatgrab's support, only get_process_stats() has been implemented).  Possibly use combo of cygwin netstat and Win32::NetPacket.  Maybe try interfacing with other open source tools tools like Etherial.

Complete support for Win32 (extending upon the prelimiary libstatgrab support in MinGW).

Support other platforms, or missing native libstatgrab support for some functions in your current platform?  Contact me (or send me your patches), and I'll see what we can do!

=head1 CAVIATS

If using Cygwin, you must have procps (available as a Cygwin package) installed to be able to obtain process-level CPU utilization percentage stats; otherwise, cpu_percent will return undef.

=head1 BUGS

None known at this time, although there may be a few minor ones lurking about. Bug reports and suggestions are always welcome.

=head1 CREDITS

=over

=item Tassilo von Parseval

For writing L<Unix::Statgrab>, for the base test script for this module, and for supporting ideas of portability beyond libstatgrab's current capabilities.

=back

=head1 AUTHOR

Eric Rybski

=head1 COPYRIGHT AND LICENSE

Copyright 2006 by Eric Rybski, All Rights Reserved

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=head1 SEE ALSO

L<Unix::Statgrab>

=cut
