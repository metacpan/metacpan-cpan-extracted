package Proc::ProcessTable::piddler;

use 5.006;
use strict;
use warnings;
use Proc::ProcessTable;
use Text::ANSITable;
use Term::ANSIColor;
use Proc::ProcessTable::InfoString;
use Sys::MemInfo qw(totalmem);
use Net::Connection::ncnetstat;
use JSON;

=head1 NAME

Proc::ProcessTable::piddler - Display all process table, open files, and network connections for a PID.

=head1 VERSION

Version 0.3.0

=cut

our $VERSION = '0.3.0';

=head1 SYNOPSIS

    use Proc::ProcessTable::piddler;

    # skip over the less useful stuff for less spammy output
    my $args={
              txt=>0,
              unix=>0,
              pipe=>0,
              fifo=>0,
              vregroot=>0,
              dont_dedup=>0,
              dont_resolv=>0,
              };

    my $piddler = Proc::ProcessTable::piddler->new( $args );

    print $piddler->run( [ 0, 1432 ] );

=head1 METHODS

=head2 new

Initiates the object.

One argument is taken and that is a option hash reference
of options.

    my $args={
              txt=>0,
              unix=>0,
              pipe=>0,
              fifo=>0,
              vregroot=>0,
              dont_dedup=>0,
              dont_resolv=>0,
              };

    my $piddler = Proc::ProcessTable::piddler->new( $args );

=head3 args hash

=head4 a_inode

Print a_inode types.

Defaults to 0, false.

=head4 dont_dedup

Don't dedup the file descriptor list.

When deduping a list it checks if a file is open in
rw, r, or w, only showing it once for any of those modes.
Any file with more than one open FD of that mode will have
+ appended to the value in the FD column.

The modes below are all also RW and considered that.

    u
    ur
    uw

Shared memory objects are rolled up as well, as per L</SHARED MEMORY>. A
process may hold a great many that print the same, anonymous ones having
nothing to tell them apart but their size and what else holds them, so
only the first of them is printed, with the number left off tacked onto
the FD.

    40u+43 SHM  262.144k

Defaults to 0, false.

=head4 dont_resolv

Don't resolve PTR addresses.

Defaults to 0, false.

=head4 fifo

Print named pipes, which is to say the FIFOs sitting on the file system
rather than the anonymous pipes B<pipe> covers.

Defaults to 1, true.

=head4 human_size

Print the size of a open file as a readable value rather than the raw
number of bytes, in the same manner as the process VSZ and RSS.

    SIZE/OFF
    823.640k

Only the SIZE/OFF values that are a size are touched, a offset being a
position rather than a amount.

Defaults to 1, true.

=head4 jail_info

Print what the process has been shut away in under its own section, that
being every parameter of the jail it is in on FreeBSD, as per L</JAILS>,
and the cgroups and namespaces it is in on Linux, as per L</CONTAINERS>.

    JAIL ARG      VALUE
    host.hostname test.example.org
    jid           1
    name          test
    path          /jails/test
    persist       true

    CONTAINER ARG VALUE
    cgroup        /system.slice/lldpd.service
    ns:ipc        4026531839
    ns:mnt        4026532643 private
    ns:net        4026531833

Nothing is printed for a process that is not in a jail, the cgroups and
namespaces being there to print either way.

Defaults to 0, false.

=head4 memreglib

Print memory mapped libraries that are of the type REG.

The following are used to match libraries.

    /\.so$/
    /\.so\.[0-9]+$/
    /\.so\.[0-9]+\.[0-9]+$/
    /\.so\.[0-9]+\.[0-9]+\.[0-9]+$/
    /\.jar$/

Defaults to 0, false.

=head4 peer_max

How many commands to print for the far end of a pipe, FIFO, unix socket,
or shared memory object and how many PIDs to print for any one of those
commands.

A endpoint may be held by any number of other processes, such as a shared
memory object inherited across a pile of forks, so this is what keeps
that from being more than is worth reading through. Whatever is left off
is noted as a count.

    17u SHM 288876 0 (firefox -contentproc...(7375, 24844, + 26 more))

Zero or less prints all of them.

Defaults to 0, printing all of them.

=head4 peers

For each pipe, FIFO, unix socket, and shared memory object printed, show
the command holding the far end of it.

    FD  TYPE DEVICE             SIZE/OFF NODE      NAME
    7u  unix 0xfffff80022630400 0                  ->0xfffff80022635000 (dbus-daemon --session(51092))
    14u unix 0xfffff80052dee800 0                  /tmp/dbus-nWRW4XDDoD (xfce4-panel(63471))
    3r  FIFO 0xe6               0t0      299839014 /tmp/testfifo (cat(12593))
    17u SHM                     288876   0         (firefox -contentproc...(7375, 24844, 32640, + 26 more))

The far end is found either by way of the endpoint this one points at,
by way of whatever points at this one, or by way of what else has the
same one open. The second is what covers the unix sockets lsof names
after the path they are bound to, such as the accepted end of a
connection, and the third the FIFOs, shared memory objects, and pipes
that both ends hold the same object for.

Commands longer than 40 characters are truncated. A endpoint whose far
end can not be looked up, such as one held by another user's process when
not running as root, is shown as a ?. Nothing is shown for one that has
no far end to speak of, such as a unix socket that is only bound and
listening or a FIFO no one else has open.

The process itself is never named as the far end of its own entry. It is
always one of the holders on systems that tie the two ends together via
the node, as Linux does, and on the ones that hand each end a object of
its own it comes up for the pipe or socket pair a process made for
itself, where the two rows pointing at each other are the whole of what
there is to say.

    63u PIPE 0xfffffe016dcb5cc0 16384    ->0xfffffe016dcb5e18
    64u PIPE 0xfffffe016dcb5e18 4096     ->0xfffffe016dcb5cc0

A endpoint may be held by any number of other processes, such as a shared
memory object inherited across a pile of forks, so the PIDs are gathered
up under the command they are running, with B<peer_max> capping how many
of each are printed.

Tying the two ends together requires a system wide lsof, so it is only
run when a pipe, FIFO, unix socket, or shared memory object is actually
going to be printed, and only once per call to run.

Unix sockets are tied together either by way of a lsof that points at the
far end of one, as FreeBSD does, or by way of B<lsof +E>, which is what is
used on Linux. A build of lsof with no B<+E> to it just leaves them
without a far end to speak of, everything else carrying on as it was.

Defaults to 1, true.

=head4 pipe

Print anonymous pipes, the sort a shell makes when it strings two
commands together.

Linux hands these the FIFO type rather than one of their own, naming them
pipe instead of after a path the way a named one is, which is what tells
the two apart there.

Defaults to 1, true.

=head4 pipe_chain_command_length

How long a command may be in a pipe chain before it is truncated, with
B<...> tacked onto the end of it to show that it was.

    ps auxw(4821) | grep -i --line-buffered --color=auto...(4822)

Zero or less does not truncate at all.

Only the pipe chains are touched, the commands shown for the far end of
a endpoint having a length of their own.

Defaults to 0, not truncating at all.

=head4 pipe_chains

Print the pipelines the process is a part of, showing the commands in
the order the data flows through them, oldest to newest.

    PIPE CHAINS
    ps auxw(4821) | grep foo(4822) | wc -l(4823)

Commands are truncated as per B<pipe_chain_command_length>. Any process
that can not be looked up, such as one belonging to another user when not
running as root, is shown as a ?. A process may sit on more than one
pipe, so at most 16 lines are shown for any one of them.

A pipe is a link in a pipeline where a process that was handed it is
writing at the one end and another is reading at the other, that being
what a shell makes when it strings two commands together. More than one
of them on a end, such as a log a whole pack of workers writes to, is a
link apiece rather than the one. Two processes each running a pipe at the
other are talking both ways, which is the one channel between them rather
than two pipelines pointed opposite ways.

    firefox(7375) <-> firefox -contentproc...(24844)

Anything else is left as the one pipe it is, printed as whatever is
writing to it against whatever is reading, rather than being strung into
a pipeline it is not. A worker pool sharing a queue out among its workers
is the usual sort.

    python process.py(8007) | python process.py(8007), inherited(94645, 94646, + 5 more)

A process forked off of one already holding a pipe is handed a copy of it
whether it has any use for it or not, and a pool that forks a worker at a
time ends up with every worker holding a end of every pipe made before
it. Those are printed as B<inherited> so they are not taken for something
that was given the pipe to use. A end sitting on stdin or stdout counts as
given either way, a shell wiring the last command of a pipeline onto the
very descriptor it is holding the pipe on itself, so leaving those to the
parent would break the chain a hop early. Stderr is left out of that, as
it is the one every child carries off of its parent whether it has any use
for it or not.

Tying the two ends of a pipe together requires a system wide lsof, so it
is only run for processes that actually have a pipe open, and only once
per call to run.

The direction of a pipe is taken from the r and w access characters when
lsof reports them. Systems such as FreeBSD report pipes as being open
read/write instead, in which case the descriptor number is used, 0 being
the input and 1 and 2 being the output.

Those systems also hand each end of a pipe a object of its own and point
the two at each other, so a end told by a descriptor in the one process is
that same end everywhere else it is held, and the far end of it goes the
other way. That is what puts a direction on the ends only ever held on a
descriptor there is nothing to be read off of, such as the stdin, stdout,
and stderr a supervisor keeps of everything it started.

    galla --name mail(96264) <-> baphomet start(95432)

A pipe a process made for itself never lands on a standard descriptor, so
on FreeBSD the buffer sitting behind either end is what is left to tell
the two apart. The read end is handed the one everything written to the
pipe lands in, which starts out at 16k and is grown to 64k for one that is
being pushed, against the 4k the write end is handed and never uses, so
the larger of the two is the end being read from. Both are made at the
smaller size when the kernel is low on room for them, in which case there
is nothing to go on.

A pipe with nothing on either side of it to go on is left out of the
chains, as are both ends of one with descriptors going both ways. So is
one with nothing on either end of it but the process itself, that being
the same command printed twice and no more than the open files already
say, which something like a browser holds a pile of.

Defaults to 1, true.

=head4 txt

Print the linked libraries used by the binary.

Defaults to 0, false.

=head4 unix

Print unix sockets.

Defaults to 1, true.

=head4 vregroot

Show VREG entries for /.

Defaults to 0, false.

=cut

sub new {
	my %args;
	if ( defined( $_[1] ) ) {
		%args = %{ $_[1] };
	}

	my $self = {
		timeColors  => [ 'GREEN',         'BRIGHT_GREEN',  'RED',            'BRIGHT_RED' ],
		vszColors   => [ 'GREEN',         'YELLOW',        'RED',            'BRIGHT_BLUE' ],
		rssColors   => [ 'BRIGHT_GREEN',  'BRIGHT_YELLOW', 'BRIGHT_RED',     'BRIGHT_BLUE' ],
		sizeColors  => [ 'GREEN',         'YELLOW',        'RED',            'BRIGHT_BLUE' ],
		file_colors => [ 'BRIGHT_YELLOW', 'BRIGHT_CYAN',   'BRIGHT_MAGENTA', 'BRIGHT_BLUE', 'MAGENTA', 'BRIGHT_RED' ],
		processColor              => 'BRIGHT_RED',
		varColor                  => 'GREEN',
		valColor                  => 'WHITE',
		pidColor                  => 'BRIGHT_CYAN',
		zero_time                 => 1,
		zero_flt                  => 1,
		files                     => 1,
		idColors                  => [ 'WHITE', 'BRIGHT_BLUE', 'MAGENTA', ],
		is                        => Proc::ProcessTable::InfoString->new,
		environ                   => 'BRIGHT_MAGENTA',
		txt                       => 0,
		pipe                      => 1,
		unix                      => 1,
		vregroot                  => 0,
		dont_dedup                => 0,
		dont_resolv               => 0,
		fifo                      => 1,
		a_inode                   => 0,
		jail_info                 => 0,
		memreglib                 => 0,
		pipe_chains               => 1,
		peers                     => 1,
		human_size                => 1,
		peer_command_length       => 40,
		peer_max                  => 0,
		pipe_chain_command_length => 0,
		pipe_chain_max            => 16,
		pipe_chain_max_depth      => 32,
	};
	bless $self;

	my @arg_feed = (
		'txt',  'pipe',    'unix', 'vregroot', 'dont_dedup', 'dont_resolv',
		'fifo', 'a_inode', 'memreglib', 'pipe_chains', 'peers', 'human_size', 'peer_max', 'jail_info',
		'pipe_chain_command_length'
	);

	foreach my $feed (@arg_feed) {
		if ( defined( $args{$feed} ) ) {
			$self->{$feed} = $args{$feed};
		}
	}

	return $self;
} ## end sub new

=head2 run

This runs it and returns a string.

One option is taken and that is a array ref of PIDs
to do.

    print $piddler->run( [ 0, 1432 ] );

=cut

sub run {
	my $self = $_[0];
	my @pids;
	if ( defined( $_[1] ) ) {
		@pids = @{ $_[1] };
	}

	if ( !defined( $pids[0] ) ) {
		return '';
	}

	my %pids_hash;
	foreach my $pid (@pids) {
		$pids_hash{$pid} = $pid;
	}

	my $p  = Proc::ProcessTable->new;
	my $pt = $p->table;

	if ( !defined( $pt->[0] ) ) {
		return '';
	}

	# figure out what all keys the process table is reporting
	my @proc_keys = keys( %{ $pt->[0] } );
	my %proc_keys_hash;
	foreach my $proc_key (@proc_keys) {
		$proc_keys_hash{$proc_key} = 1;
	}
	# remove the ones we actually use
	delete( $proc_keys_hash{pctcpu} );
	delete( $proc_keys_hash{uid} );
	delete( $proc_keys_hash{pid} );
	delete( $proc_keys_hash{gid} );
	delete( $proc_keys_hash{vmsize} );
	delete( $proc_keys_hash{rss} );
	delete( $proc_keys_hash{state} );
	delete( $proc_keys_hash{wchan} );
	delete( $proc_keys_hash{cmndline} );
	delete( $proc_keys_hash{size} );
	delete( $proc_keys_hash{time} );
	delete( $proc_keys_hash{pctmem} );
	delete( $proc_keys_hash{groups} );
	delete( $proc_keys_hash{euid} );
	delete( $proc_keys_hash{egid} );
	delete( $proc_keys_hash{cmdline} );
	@proc_keys = sort( keys(%proc_keys_hash) );

	my @procs;
	foreach my $proc ( @{$pt} ) {
		if ( defined( $pids_hash{ $proc->pid } ) ) {
			push( @procs, $proc );
		}
	}

	if ( !defined( $procs[0] ) ) {
		return '';
	}

	# the endpoints are only good for as long as the processes holding
	# them are, and a JID only for as long as the jail it names, so the
	# caches do not outlive the run they were built for
	$self->{all_files}       = undef;
	$self->{peer_pids}       = undef;
	$self->{jails}           = {};
	$self->{containers}      = {};
	$self->{host_namespaces} = undef;
	$self->{cgroup_files}    = {};
	$self->{ppids}           = {};
	$self->{pipe_holders}    = undef;
	# undef is what says there is no v2 hierarchy, so this one is cleared
	# out rather than set
	delete( $self->{cgroup_mount} );

	# what the PIDs in a pipe chain or on the far end of a endpoint get
	# printed as
	my %commands;
	if (   ( $self->{pipe_chains} )
		|| ( $self->{peers} )
		|| ( $self->{jail_info} ) )
	{
		foreach my $current_proc ( @{$pt} ) {
			my $command;
			if (   ( defined( $current_proc->{cmndline} ) )
				&& ( $current_proc->{cmndline} !~ /^[\ \t]*$/ ) )
			{
				$command = $current_proc->{cmndline};
			} elsif ( defined( $current_proc->{fname} ) ) {
				$command = $current_proc->{fname};
			}
			if ( defined($command) ) {
				# a command line may contain newlines and the like, which
				# would tear apart the single line a chain is printed on
				$command =~ s/\s+/ /g;
				$command =~ s/^\s+//;
				$command =~ s/\s+$//;
				$commands{ $current_proc->pid } = $command;
			}

			# what says whether a process was handed a pipe by way of being
			# forked off of something already holding it
			if ( defined( $current_proc->{ppid} ) ) {
				$self->{ppids}{ $current_proc->pid } = $current_proc->{ppid};
			}
		} ## end foreach my $current_proc ( @{$pt} )
	} ## end if ( ( $self->{pipe_chains} ) || ( $self->...))

	my $toReturn = '';
	my $first    = 1;
	foreach my $proc (@procs) {
		my $tb = Text::ANSITable->new;
		$tb->border_style('Default::none_ascii');
		$tb->color_theme('Default::no_color');
		$tb->show_header(0);
		$tb->set_column_style( 0, pad => 0 );
		$tb->set_column_style( 1, pad => 1 );
		$tb->columns( [ 'var', 'val' ] );

		#
		# PID
		#
		my @data;
		push(
			@data,
			[
				color( $self->{varColor} ) . 'PID' . color('reset'),
				color( $self->{pidColor} ) . $proc->pid . color('reset')
			]
		);

		#
		# UID
		#
		push(
			@data,
			[
				color( $self->{varColor} ) . 'UID' . color('reset'),
				$self->_userString( $proc->{uid} ) . ' ' . color('reset')
			]
		);

		#
		# EUID
		#
		if ( defined( $proc->{euid} ) ) {
			push(
				@data,
				[
					color( $self->{varColor} ) . 'EUID' . color('reset'),
					$self->_userString( $proc->{euid} ) . ' ' . color('reset')
				]
			);
		}

		#
		# GID
		#
		push(
			@data,
			[
				color( $self->{varColor} ) . 'GID' . color('reset'),
				$self->_groupString( $proc->{gid} ) . ' ' . color('reset')
			]
		);

		#
		# EGID
		#
		if ( defined( $proc->{egid} ) ) {
			push(
				@data,
				[
					color( $self->{varColor} ) . 'EGID' . color('reset'),
					$self->_groupString( $proc->{egid} ) . ' ' . color('reset')
				]
			);
		}

		#
		# Groups
		#
		if ( defined( $proc->{groups} ) ) {
			my @groups;
			foreach my $current_group ( @{ $proc->{groups} } ) {
				push( @groups, $self->_groupString($current_group) );
			}

			push( @data, [ color( $self->{varColor} ) . 'Groups' . color('reset'), join( ' ', @groups ) ] );
		}

		#
		# PCT CPU
		#
		# Linux pads the value out with leading spaces, and a freshly
		# started process may come back as inf or nan there, so it is
		# rebuilt rather than used as handed over.
		my $pctcpu = $proc->pctcpu;
		if (   ( !defined($pctcpu) )
			|| ( $pctcpu !~ /^\s*[0-9]*\.?[0-9]+\s*$/ ) )
		{
			$pctcpu = 0;
		}
		push(
			@data,
			[
				color( $self->{varColor} ) . 'CPU%' . color('reset'),
				color( $self->{valColor} ) . sprintf( '%.2f', $pctcpu ) . color('reset')
			]
		);

		#
		# PCT mem
		#
		my $mem;
		if ( !defined( $proc->{pctmem} ) ) {
			my $total_mem = totalmem;
			if ( $total_mem > 0 ) {
				$mem = ( $self->_procMem( $proc->{rss} ) / $total_mem ) * 100;
			} else {
				$mem = 0;
			}
			$mem = sprintf( '%.2f', $mem );
		} else {
			$mem = sprintf( '%.2f', $proc->{pctmem} );
		}
		push(
			@data,
			[
				color( $self->{varColor} ) . 'MEM%' . color('reset'),
				color( $self->{valColor} ) . $mem . color('reset')
			]
		);

		#
		# VSZ
		#
		push(
			@data,
			[
				color( $self->{varColor} ) . 'VSZ' . color('reset'),
				$self->memString( $self->_procMem( $proc->size ), 'vsz' )
			]
		);

		#
		# RSS
		#
		push(
			@data,
			[
				color( $self->{varColor} ) . 'RSS' . color('reset'),
				$self->memString( $self->_procMem( $proc->rss ), 'rss' )
			]
		);

		#
		# the open files are gathered in here as the total shared memory
		# is worked out from them, which belongs with the rest of the
		# memory bits rather than down with the table of them
		#
		my $pid   = $proc->pid;
		my $files = $self->_lsof( '-p ' . $pid );

		#
		# total SHM
		#
		my $shm_total = $self->_shmTotal($files);
		if ( $shm_total > 0 ) {
			push(
				@data,
				[
					color( $self->{varColor} ) . 'Total SHM' . color('reset'),
					$self->memString( $shm_total, 'size' )
				]
			);
		}

		#
		# time
		#
		push( @data, [ color( $self->{varColor} ) . 'Time' . color('reset'), $self->timeString( $proc->time ) ] );

		#
		# info
		#
		push(
			@data,
			[
				color( $self->{varColor} ) . 'Info' . color('reset'),
				color( $self->{valColor} ) . $self->{is}->info($proc) . color('reset')
			]
		);

		#
		# misc ones...
		#
		foreach my $key (@proc_keys) {
			if (   ( defined( $proc->{$key} ) )
				&& ( $proc->{$key} !~ /^$/ ) )
			{
				my $print_it = 1;
				my $value;

				# anything that is entirely zero, be it 0, 0.0, or the like
				my $is_zero = 0;
				if (   ( $proc->{$key} =~ /^[0-9]+(\.[0-9]+)?$/ )
					&& ( $proc->{$key} == 0 ) )
				{
					$is_zero = 1;
				}

				if (   ( $key =~ /time$/ )
					&& ($is_zero)
					&& ( $self->{zero_time} ) )
				{
					$print_it = 0;
				} elsif ( $key =~ /time$/ ) {
					$value = $self->timeString( $proc->{$key} );
				}

				if (   ( $key =~ /^environ$/ )
					&& ( ref( $proc->{environ} ) eq 'ARRAY' ) )
				{
					# A process is free to scribble over the memory the kernel
					# hands this back from, setproctitle and the like using it
					# for a command line of their own making, which leaves a
					# pile of empty strings where the environment was.
					my @environ;
					foreach my $variable ( @{ $proc->{environ} } ) {
						if (   ( defined($variable) )
							&& ( $variable !~ /^[\ \t]*$/ ) )
						{
							push( @environ, $variable );
						}
					}

					if ( !defined( $environ[0] ) ) {
						$print_it = 0;
					} else {
						$value = join( color( $self->{environ} ) . ', ' . color('reset'), @environ );
					}
				} ## end if ( ( $key =~ /^environ$/ ) && ( ref( $proc...)))

				if (   ( $key =~ /flt$/ )
					&& ($is_zero)
					&& ( $self->{zero_flt} ) )
				{
					$print_it = 0;
				}

				if ( $key =~ /^start$/ ) {
					$value = $self->startString( $proc->{start} );
				}

				if ( $key =~ /^jid$/ ) {
					$value = $self->_jailString( $proc->{jid} );
				}

				if ( !defined($value) ) {
					$value = color( $self->{valColor} ) . $proc->{$key} . color('reset');
				}

				if ($print_it) {
					push( @data, [ color( $self->{varColor} ) . $key . color('reset'), $value, ] );
				}
			} ## end if ( ( defined( $proc->{$key} ) ) && ( $proc...))
		} ## end foreach my $key (@proc_keys)

		#
		# what a Linux process has been shut away in, which is what stands
		# in for the JID the process table hands over on FreeBSD
		#
		my $cgroup_string = $self->_cgroupString( $proc->pid );
		if ( defined($cgroup_string) ) {
			push( @data, [ color( $self->{varColor} ) . 'Cgroup' . color('reset'), $cgroup_string ] );
		}

		my $container_string = $self->_containerString( $proc->pid );
		if ( defined($container_string) ) {
			push( @data, [ color( $self->{varColor} ) . 'Container' . color('reset'), $container_string ] );
		}

		my $namespace_string = $self->_namespaceString( $proc->pid );
		if ( defined($namespace_string) ) {
			push( @data, [ color( $self->{varColor} ) . 'Namespaces' . color('reset'), $namespace_string ] );
		}

		#
		# what the cgroup is using of what it is allowed. All of it covers
		# the whole cgroup rather than the one process, and each is left off
		# when it has nothing to say, be it a limit that was never set or a
		# controller that was never turned on.
		#
		my $cgroup_dir = $self->_cgroupDir( $proc->pid );
		if ( defined($cgroup_dir) ) {
			my @cgroup_rows = (
				[ 'Cgroup mem',      $self->_cgroupMemoryString($cgroup_dir) ],
				[ 'Cgroup cpu',      $self->_cgroupCpuString($cgroup_dir) ],
				[ 'Cgroup pids',     $self->_cgroupPidsString($cgroup_dir) ],
				[ 'Cgroup events',   $self->_cgroupEventsString($cgroup_dir) ],
				[ 'Cgroup pressure', $self->_cgroupPressureString($cgroup_dir) ],
			);
			foreach my $cgroup_row (@cgroup_rows) {
				if ( defined( $cgroup_row->[1] ) ) {
					push( @data, [ color( $self->{varColor} ) . $cgroup_row->[0] . color('reset'), $cgroup_row->[1] ] );
				}
			}
		} ## end if ( defined($cgroup_dir) )

		#
		# cmndline
		#
		if (   ( defined( $proc->{cmndline} ) )
			&& ( $proc->{cmndline} !~ /^$/ ) )
		{
			push(
				@data,
				[
					color( $self->{varColor} ) . 'Cmndline' . color('reset'),
					color( $self->{processColor} ) . $proc->{cmndline} . color('reset')
				]
			);
		} ## end if ( ( defined( $proc->{cmndline} ) ) && (...))

		#
		# gets the open files
		#
		my $open_files = '';
		my $has_pipes  = 0;
		if ( defined($files) ) {

			my $ftb = Text::ANSITable->new;
			$ftb->border_style('Default::none_ascii');
			$ftb->color_theme('Default::no_color');
			$ftb->show_header(1);
			$ftb->set_column_style( 0, pad => 0 );
			$ftb->set_column_style( 1, pad => 1 );
			$ftb->set_column_style( 2, pad => 0 );
			$ftb->set_column_style( 3, pad => 1 );
			$ftb->set_column_style( 4, pad => 0 );
			$ftb->columns(
				[
					color( $self->{varColor} ) . 'FD' . color('reset'),
					color( $self->{varColor} ) . 'TYPE' . color('reset'),
					color( $self->{varColor} ) . 'DEVICE' . color('reset'),
					color( $self->{varColor} ) . 'SIZE/OFF' . color('reset'),
					color( $self->{varColor} ) . 'NODE' . color('reset'),
					color( $self->{varColor} ) . 'NAME' . color('reset')
				]
			);

			my @fdata;

			#
			my %rw_filehandles;
			my %r_filehandles;
			my %w_filehandles;
			my %mem_filehandles;
			my %shm_alike;

			foreach my $file ( @{$files} ) {
				my $fd         = $file->{fd};
				my $type       = $file->{type};
				my $device     = $file->{device};
				my $size_off   = $file->{size_off};
				my $node       = $file->{node};
				my $file_name  = $file->{name};
				my $match_name = $file->{match_name};

				# noted so the pipe chains may be skipped entirely, and
				# the system wide lsof they require avoided, for any
				# process that does not have a pipe open
				if ( $self->_isPipe($file) ) {
					$has_pipes = 1;
				}

				# checks if it is a line we don't want
				my $dont_add = 0;
				if (
					# IP stuff... handled by ncnetstat
					( $type =~ /^IPv/ ) ||
					# library... spammy... only print if asked
					( ( $fd =~ /^txt$/ ) && ( !$self->{txt} ) )
					||
					# pipe... spammy... only print if asked
					( ( $self->_isPipeAnon($file) ) && ( !$self->{pipe} ) )
					||
					# unix... spammy... only print if asked
					( ( $self->_isUnix($file) ) && ( !$self->{unix} ) )
					||
					# fifo... spammy with elasticsearch and the like... only print if asked...
					( ( $self->_isFifo($file) ) && ( !$self->{fifo} ) )
					||
					# memory mapped libraries with REG type....
					# spammy.... ES tends to have lots of these
					(
						( $type =~ /^[Rr][Ee][Gg]$/ )
						&& (   ( $match_name =~ /\.so$/ )
							|| ( $match_name =~ /\.so\.[0-9]+$/ )
							|| ( $match_name =~ /\.so\.[0-9]+\.[0-9]+$/ )
							|| ( $match_name =~ /\.so\.[0-9]+\.[0-9]+\.[0-9]+$/ )
							|| ( $match_name =~ /\.jar$/ ) )
						&& ( !$self->{memreglib} )
					)
					||
					# a_inode... spammy with elasticsearch and the like... only print if asked...
					( ( $type =~ /^a\_inode$/ ) && ( !$self->{a_inode} ) )
					||
					# vreg /....can by spammy with somethings like firefox
					( ( $type =~ /^[Vv][Rr][Ee][Gg]$/ ) && ( $match_name =~ /^\/$/ ) && ( !$self->{vregroot} ) )
					)
				{
					$dont_add = 1;
				} ## end if ( ( $type =~ /^IPv/ ) || ( ( $fd =~ /^txt$/...)))

				# begin deduping
				my $name = color( $self->{file_colors}[5] ) . $file_name . color('reset');

				# tie the far end of a pipe, FIFO, unix socket, or shared
				# memory object to whatever is holding it, which is only
				# worth the system wide lsof it takes for one that is going
				# to be printed
				if (
					   ( !$dont_add )
					&& ( $self->{peers} )
					&& (   ( $self->_isUnix($file) )
						|| ( $self->_isPipe($file) )
						|| ( $self->_isShm($file) ) )
					)
				{
					my $peer = $self->_peerCommands( $file, \%commands );
					if ( defined($peer) ) {
						# a shared memory object has no name to speak of, so
						# there is nothing for this to trail after
						my $spacer = ' ';
						if ( $file_name =~ /^$/ ) {
							$spacer = '';
						}
						$name = $name . $spacer . color( $self->{valColor} ) . '(' . $peer . ')' . color('reset');
					}
				} ## end if ( ( !$dont_add ) && ( $self->{peers} ) ...)

				my $size_string = $self->_sizeString($file);

				# Noted here as the deduping is finalized from the rendered
				# rows, so what it needs rides along raw rather than being
				# fished back out from under the color codes. A shared memory
				# object is a REG like any other on Linux, so the name has to
				# be asked about while it is still to hand.
				my $is_shm = $self->_isShm($file);

				if (   ( !$self->{dont_dedup} )
					&& ( !$dont_add ) )
				{
					if ($is_shm) {
						# a process may hold a pile of shared memory objects
						# that all print the same, anonymous ones having
						# nothing to tell them apart but their size and what
						# else holds them, which are worth a single line and
						# a count of the rest
						$shm_alike{ $size_string . "\0" . $name }++;
					} elsif ( $self->_isDedupType($type) ) {
						if (   ( $fd =~ /u/ )
							|| ( $fd =~ /rw/ )
							|| ( $fd =~ /wr/ ) )
						{
							$rw_filehandles{$name}++;
						} elsif ( $fd =~ /r/ ) {
							$r_filehandles{$name}++;
						} elsif ( $fd =~ /w/ ) {
							$w_filehandles{$name}++;
						} else {
							$mem_filehandles{$name}++;
						}
					} ## end elsif ( $self->_isDedupType($type) )
				} ## end if ( ( !$self->{dont_dedup} ) && ( !$dont_add...))

				if ( !$dont_add ) {
					push(
						@fdata,
						[
							color( $self->{file_colors}[0] ) . $fd . color('reset'),
							color( $self->{file_colors}[1] ) . $type . color('reset'),
							color( $self->{file_colors}[2] ) . $device . color('reset'),
							$size_string,
							color( $self->{file_colors}[4] ) . $node . color('reset'),
							$name,
							$is_shm,
							$fd,
							$self->_isDedupType($type),
						]
					);
				} ## end if ( !$dont_add )
			} ## end foreach my $file ( @{$files} )

			# finalize deduping
			my @final_fdata;
			if ( !$self->{dont_dedup} ) {
				my %rw_dedup;
				my %r_dedup;
				my %w_dedup;
				my %mem_dedup;
				my %shm_dedup;
				foreach my $line (@fdata) {
					if ( $line->[6] ) {
						# the ones that print the same are rolled up into the
						# first of them, with the number left off tacked onto
						# the FD in the same manner as a duplicate handle
						my $key = $line->[3] . "\0" . $line->[5];
						if ( !defined( $shm_dedup{$key} ) ) {
							$shm_dedup{$key} = 1;
							if ( $shm_alike{$key} > 1 ) {
								$line->[0] = $line->[0] . '+' . ( $shm_alike{$key} - 1 );
							}
							push( @final_fdata, [ @{$line}[ 0 .. 5 ] ] );
						}
					} elsif ( $line->[8] ) {
						my $add_line = 1;
						if (   ( $line->[7] =~ /u/ )
							|| ( $line->[7] =~ /rw/ )
							|| ( $line->[7] =~ /wr/ ) )
						{
							if ( defined( $rw_dedup{ $line->[5] } ) ) {
								$add_line = 0;
							} else {
								if ( $rw_filehandles{ $line->[5] } > 1 ) {
									$line->[0] = $line->[0] . '+';
								}
								$rw_dedup{ $line->[5] } = 1;
							}
						} elsif ( $line->[7] =~ /r/ ) {
							if ( defined( $r_dedup{ $line->[5] } ) ) {
								$add_line = 0;
							} else {
								if ( $r_filehandles{ $line->[5] } > 1 ) {
									$line->[0] = $line->[0] . '+';
								}
								$r_dedup{ $line->[5] } = 1;
							}
						} elsif ( $line->[7] =~ /w/ ) {
							if ( defined( $w_dedup{ $line->[5] } ) ) {
								$add_line = 0;
							} else {
								if ( $w_filehandles{ $line->[5] } > 1 ) {
									$line->[0] = $line->[0] . '+';
								}
								$w_dedup{ $line->[5] } = 1;
							}
						} else {
							if ( defined( $mem_dedup{ $line->[5] } ) ) {
								$add_line = 0;
							} else {
								if ( $mem_filehandles{ $line->[5] } > 1 ) {
									$line->[0] = $line->[0] . '+';
								}
								$mem_dedup{ $line->[5] } = 1;
							}
						} ## end else [ if ( ( $line->[7] =~ /u/ ) || ( $line->[7]...))]

						if ($add_line) {
							push( @final_fdata, [ @{$line}[ 0 .. 5 ] ] );
						}
					} else {
						push( @final_fdata, [ @{$line}[ 0 .. 5 ] ] );
					}
				} ## end foreach my $line (@fdata)
				$ftb->add_rows( \@final_fdata );
			} else {
				# the raw values riding along past the name are only ever of
				# use to the deduping, so they are never handed to the table
				foreach my $line (@fdata) {
					push( @final_fdata, [ @{$line}[ 0 .. 5 ] ] );
				}
				$ftb->add_rows( \@final_fdata );
			}

			$open_files = $ftb->draw;
		} ## end if ( defined($files) )

		#
		# handle the netconnection
		#
		my $netstat = '';
		my @filters = (
			{
				type   => 'PID',
				invert => 0,
				args   => {
					pids => [ $proc->pid ],
				}
			}
		);
		my $ptr = 1;
		if ( $self->{dont_resolv} ) {
			$ptr = 0;
		}
		my $ncnetstat = Net::Connection::ncnetstat->new(
			{
				ptr          => $ptr,
				command      => 0,
				command_long => 0,
				wchan        => 0,
				pct_show     => 0,
				no_pid_user  => 1,
				match        => {
					checks => \@filters,
				}
			}
		);
		$netstat = $ncnetstat->run;

		# the headers are drawn regardless of if there are any connections
		# to show, so anything amounting to no more than the header row is
		# tossed as there is nothing worth saying
		my @netstat_lines = grep( { $_ =~ /\S/ } split( /\n/, $netstat ) );
		if ( scalar(@netstat_lines) < 2 ) {
			$netstat = '';
		}

		#
		# handle the pipe chains
		#
		my $pipe_chains = '';
		if (   ( $self->{pipe_chains} )
			&& ($has_pipes) )
		{
			$pipe_chains = $self->_pipeChainTable( $pid, \%commands );
		}

		#
		# handle the jail info, which on Linux is the cgroups and
		# namespaces standing in for it. Each of the two only has anything
		# to say on the system it belongs to, so there is no need to ask
		# which one this is.
		#
		my $jail_info = '';
		if ( $self->{jail_info} ) {
			$jail_info = $self->_jailTable( $proc->{jid} ) . $self->_containerTable( $proc->pid, \%commands );
		}

		#
		# adds the new item
		#
		$tb->add_rows( \@data );
		if ($first) {
			$first = 0;
		} else {
			$toReturn = $toReturn . "\n\n";
		}
		$toReturn = $toReturn . $tb->draw . $open_files . $netstat . $pipe_chains . $jail_info;
	} ## end foreach my $proc (@procs)

	return $toReturn;
} ## end sub run

#
# Runs lsof with the additional arguments passed to it and returns a
# array ref of hash refs, one per open file, with the keys pid, fd,
# type, device, size_off, node, node_id, share_count, name, and
# match_name. Undef is returned should lsof fail.
#
sub _lsof {
	my $self = $_[0];
	my $args = $_[1];

	if ( !defined($args) ) {
		$args = '';
	}

	# The field output is used rather than the columns as the latter may
	# only be picked apart via the widths worked out from the header, run
	# together when a value overflows, and have no place for the node
	# identifier and share count. lsof also has a habit of warning about
	# things of no interest here, such as rebuilding its device cache or
	# a directory it could not read, so stderr is sent off to be
	# forgotten about.
	my $output_raw = `lsof -n -l -P -F0 $args 2> /dev/null`;
	if ( ( $? != 0 )
		&& !( ( $^O =~ /linux/ ) && ( $? == 256 ) ) )
	{
		return undef;
	}

	my @files;
	my $pid = '';
	my $file;

	# Every field is NUL terminated and the first one of each set has a
	# newline stuck onto the front of it. A set beginning with p is a
	# process and one beginning with f a file belonging to the last
	# process seen.
	foreach my $field ( split( /\0/, $output_raw ) ) {
		$field =~ s/^\n//;

		# the newline the last set of all ends with is left sitting on its
		# own once taken off, with nothing to it beyond that
		if ( $field =~ /^$/ ) {
			next;
		}

		my $id    = substr( $field, 0, 1 );
		my $value = substr( $field, 1 );

		if ( $id eq 'p' ) {
			$pid = $value;
		} elsif ( $id eq 'f' ) {
			if ( defined($file) ) {
				push( @files, $self->_lsofFile($file) );
			}
			$file = {
				pid         => $pid,
				fd          => $value,
				type        => '',
				device      => '',
				size        => '',
				offset      => '',
				node        => '',
				node_id     => '',
				share_count => '',
				name        => '',
			};
		} elsif ( defined($file) ) {
			# the access and lock characters are printed as a part of the
			# FD column, which is what the rest of this expects them in
			if (   ( $id eq 'a' )
				|| ( $id eq 'l' ) )
			{
				if (   ( $value !~ /^[\ \t]*$/ )
					&& ( $value ne '-' ) )
				{
					$file->{fd} = $file->{fd} . $value;
				}
			} elsif ( $id eq 't' ) {
				$file->{type} = $value;
			} elsif ( $id eq 'd' ) {
				$file->{device} = $value;
			} elsif ( $id eq 'D' ) {
				# the device character code is the better of the two and
				# only some types have one
				if ( $file->{device} =~ /^$/ ) {
					$file->{device} = $value;
				}
			} elsif ( $id eq 's' ) {
				$file->{size} = $value;
			} elsif ( $id eq 'o' ) {
				$file->{offset} = $value;
			} elsif ( $id eq 'i' ) {
				$file->{node} = $value;
			} elsif ( $id eq 'N' ) {
				$file->{node_id} = $value;
			} elsif ( $id eq 'C' ) {
				$file->{share_count} = $value;
			} elsif ( $id eq 'n' ) {
				$file->{name} = $value;
			}
		} ## end elsif ( defined($file) )
	} ## end foreach my $field ( split( /\0/, $output_raw ) )

	if ( defined($file) ) {
		push( @files, $self->_lsofFile($file) );
	}

	return \@files;
} ## end sub _lsof

#
# Finishes off a file gathered by _lsof, filling in the values that are
# worked out from the fields rather than taken from one of them.
#
sub _lsofFile {
	my $self = $_[0];
	my $file = $_[1];

	# lsof prints the size when it has one and falls back to the offset,
	# which is what the SIZE/OFF column amounts to
	$file->{size_off} = $file->{size};
	if ( $file->{size_off} =~ /^$/ ) {
		$file->{size_off} = $file->{offset};
	}

	# lsof appends the file system, device, or the like to the name for
	# some types, which is not wanted when matching on the name
	my $match_name = $file->{name};
	$match_name =~ s/[\ \t]+\([^\)]*\)$//;
	$file->{match_name} = $match_name;

	return $file;
} ## end sub _lsofFile

#
# Returns a array ref of every open file on the system, as per _lsof.
# This is what the endpoint lookups are built from, so it is cached for
# the duration of the run, keeping the system wide lsof it takes to a
# single one.
#
sub _allFiles {
	my $self = $_[0];

	if ( defined( $self->{all_files} ) ) {
		return $self->{all_files};
	}

	# Linux does not point a unix socket at the far end of itself the way
	# FreeBSD does, leaving lsof +E as what ties the two together there. It
	# tacks the endpoints onto the name rather than handing back anything
	# more to work with, which is picked apart by _lsofEndpointPIDs, and
	# costs next to nothing on top of the lsof that is being run either
	# way. Not every build of lsof has it, so a failed run falls back to
	# going without.
	# lsof exits non-zero for a option it does not have, which on Linux is
	# the same exit it uses for a file it could not get at and so is let
	# by, leaving a run that came back with nothing at all as what says it
	# has no +E to it.
	my $files;
	if ( $^O =~ /linux/ ) {
		$files = $self->_lsof('+E');
	}
	if (   ( !defined($files) )
		|| ( !defined( $files->[0] ) ) )
	{
		$files = $self->_lsof;
	}
	if ( !defined($files) ) {
		$files = [];
	}

	$self->{all_files} = $files;

	return $self->{all_files};
} ## end sub _allFiles

#
# Picks the PIDs holding the far end of a file from _lsof out of the name
# lsof +E tacked them onto, returning a array ref of them. Each is printed
# as the PID, command, and FD run together with commas, trailing either a
# ->INO= pointing at the far end of a unix socket or the name of a pipe.
# The command is cut down to a handful of characters, so only the PID is
# taken, the full one being had from the process table.
#
sub _lsofEndpointPIDs {
	my $self = $_[0];
	my $file = $_[1];

	my @pids;
	my %seen;
	foreach my $field ( split( /[\ \t]+/, $file->{name} ) ) {
		# both a PID at the front and a FD at the back are wanted, as that
		# is a good deal more than any part of a path is going to look like
		if ( $field !~ /^([0-9]+),.*,[0-9]+[a-zA-Z]*$/ ) {
			next;
		}
		my $pid = $1;

		# a process may hold the far end on more than one FD, which is
		# worth mentioning no more than once
		if ( defined( $seen{$pid} ) ) {
			next;
		}
		$seen{$pid} = 1;

		push( @pids, $pid );
	} ## end foreach my $field ( split( /[\ \t]+/, $file->{name...}))

	return \@pids;
} ## end sub _lsofEndpointPIDs

#
# Returns true if lsof said the file from _lsof has a far end to it, which
# is what tells a unix socket that is only bound and listening from one
# that is connected to something out of reach.
#
sub _lsofHasEndpoint {
	my $self = $_[0];
	my $file = $_[1];

	if ( $file->{name} =~ /\-\>INO=/ ) {
		return 1;
	}

	return 0;
} ## end sub _lsofHasEndpoint

#
# Returns true if the file from _lsof is a pipe of some sort, be it a
# anonymous one or a named one.
#
sub _isPipe {
	my $self = $_[0];
	my $file = $_[1];

	if ( !defined($file) ) {
		return 0;
	}

	if (   ( $file->{type} =~ /^[Pp][Ii][Pp][Ee]$/ )
		|| ( $file->{type} =~ /^[Ff][Ii][Ff][Oo]$/ ) )
	{
		return 1;
	}

	return 0;
} ## end sub _isPipe

#
# Returns true if the file from _lsof is a anonymous pipe, the sort made
# by a shell stringing two commands together.
#
sub _isPipeAnon {
	my $self = $_[0];
	my $file = $_[1];

	if ( !defined($file) ) {
		return 0;
	}

	if ( $file->{type} =~ /^[Pp][Ii][Pp][Ee]$/ ) {
		return 1;
	}

	# Linux hands a anonymous pipe the FIFO type rather than one of its
	# own, naming it pipe instead of after the path a named one lives at,
	# which is the only thing telling the two apart there.
	if (   ( $file->{type} =~ /^[Ff][Ii][Ff][Oo]$/ )
		&& ( $file->{match_name} !~ /^\// ) )
	{
		return 1;
	}

	return 0;
} ## end sub _isPipeAnon

#
# Returns true if the file from _lsof is a named pipe, which is to say a
# FIFO sitting on the file system rather than a anonymous one.
#
sub _isFifo {
	my $self = $_[0];
	my $file = $_[1];

	if ( !defined($file) ) {
		return 0;
	}

	if (   ( $file->{type} =~ /^[Ff][Ii][Ff][Oo]$/ )
		&& ( !$self->_isPipeAnon($file) ) )
	{
		return 1;
	}

	return 0;
} ## end sub _isFifo

#
# Works out which way round a pipe entry from _lsof is pointed, returning
# r, w, or a empty string for one that can not be told. The access
# characters are not printed for pipes on all systems, so the descriptor
# number is used as a fallback, 0 being the input and 1 and 2 the output.
#
sub _pipeDirection {
	my $self = $_[0];
	my $file = $_[1];

	if ( $file->{fd} =~ /w/ ) {
		return 'w';
	} elsif ( $file->{fd} =~ /r/ ) {
		return 'r';
	} elsif ( $file->{fd} =~ /^([0-9]+)/ ) {
		my $fd_number = $1;
		if ( $fd_number == 0 ) {
			return 'r';
		} elsif ( ( $fd_number == 1 )
			|| ( $fd_number == 2 ) )
		{
			return 'w';
		}
	} ## end elsif ( $file->{fd} =~ /^([0-9]+)/ )

	return '';
} ## end sub _pipeDirection

#
# Returns a hash ref of every process holding either end of every pipe on
# the system, keyed by the pipe and then by which end, the two ends being
# brought under the one key so a pipe is the one thing rather than two.
# This requires a system wide lsof, so it is cached for the run.
#
sub _pipeHolders {
	my $self = $_[0];

	if ( defined( $self->{pipe_holders} ) ) {
		return $self->{pipe_holders};
	}

	my @pipes;
	my %votes;
	my %sizes;
	foreach my $file ( @{ $self->_allFiles } ) {
		if ( !$self->_isPipe($file) ) {
			next;
		}

		my $ids = $self->_peerIDs($file);
		if (   ( !defined($ids) )
			|| ( !defined( $ids->{peer_id} ) )
			|| ( $file->{pid} =~ /^$/ ) )
		{
			next;
		}

		my $direction = $self->_pipeDirection($file);
		if ( $direction !~ /^$/ ) {
			$votes{ $ids->{id} }{$direction} = 1;
		}

		# kept for _pipeSizeDirection, which is what is left to tell the
		# two ends of a pipe apart when nothing has a direction on it
		if ( $file->{size} =~ /^[0-9]+$/ ) {
			$sizes{ $ids->{id} } = $file->{size};
		}

		push(
			@pipes,
			{
				file      => $file,
				ids       => $ids,
				direction => $direction,
			}
		);
	} ## end foreach my $file ( @{ $self->_allFiles } )

	# Systems such as FreeBSD hand each end of a pipe a object of its own,
	# where every descriptor pointing at the one object is that same end of
	# it, so a end told by a descriptor in the one process says which way
	# round it is in every other. The far end goes the other way, which is
	# what puts a direction on the ends only ever held on a descriptor
	# there is nothing to be read off of, such as the stdin, stdout, and
	# stderr a supervisor keeps of what it started. None of this holds
	# where both ends share the one object, as they do on Linux, and a
	# object with descriptors going both ways is left to be told the one at
	# a time.
	my %resolved;
	foreach my $pipe (@pipes) {
		my $id      = $pipe->{ids}{id};
		my $peer_id = $pipe->{ids}{peer_id};
		if (   ( defined( $resolved{$id} ) )
			|| ( $id eq $peer_id ) )
		{
			next;
		}

		my $own = $self->_pipeVote( \%votes, $id );
		if ( defined($own) ) {
			$resolved{$id} = $own;
			next;
		}

		# nothing to be had off of this end, so the far end says it instead
		my $peer = $self->_pipeVote( \%votes, $peer_id );
		if ( defined($peer) ) {
			if ( $peer eq 'w' ) {
				$resolved{$id} = 'r';
			} else {
				$resolved{$id} = 'w';
			}
			next;
		}

		# neither end is held on a descriptor there is anything to be read
		# off of, which is every pipe a process made for itself rather than
		# being handed one on its standard descriptors, leaving the buffer
		# behind them as what tells the two apart
		my $sized = $self->_pipeSizeDirection( \%sizes, $id, $peer_id );
		if ( defined($sized) ) {
			$resolved{$id} = $sized;
		}
	} ## end foreach my $pipe (@pipes)

	my %holders;
	foreach my $pipe (@pipes) {
		my $file = $pipe->{file};
		my $ids  = $pipe->{ids};

		my $direction = $pipe->{direction};
		if (   ( $direction =~ /^$/ )
			&& ( defined( $resolved{ $ids->{id} } ) ) )
		{
			$direction = $resolved{ $ids->{id} };
		}
		if ( $direction =~ /^$/ ) {
			next;
		}

		# Systems such as FreeBSD hand each end of a pipe a ID of its own
		# and point them at each other, where Linux hands both the same one.
		# Sorting the pair puts either end of one under the same key on both.
		my $key = join( "\0", sort ( $ids->{id}, $ids->{peer_id} ) );

		# A end sitting on stdin or stdout was wired there for the process to
		# use, those being what a shell strings two commands together
		# through, where one on any other descriptor is as like as not just
		# a copy it was forked holding. Stderr is left out of it as that is
		# the one every child carries off of its parent whether it has any
		# use for it or not, a pack of piped loggers all sharing the stderr
		# of what started them being the usual sort. A process may hold the
		# same end on more than one descriptor, so any one of them being
		# stdin or stdout is enough.
		my $stdio = 0;
		if ( $file->{fd} =~ /^[01][^0-9]*$/ ) {
			$stdio = 1;
		}
		if (   ( !defined( $holders{$key}{$direction}{ $file->{pid} } ) )
			|| ($stdio) )
		{
			$holders{$key}{$direction}{ $file->{pid} } = $stdio;
		}
	} ## end foreach my $pipe (@pipes)

	$self->{pipe_holders} = \%holders;

	return $self->{pipe_holders};
} ## end sub _pipeHolders

#
# Returns which way round the descriptors pointing at a pipe end went, as
# gathered by _pipeHolders, or undef where nothing was said of it or the
# descriptors did not agree.
#
sub _pipeVote {
	my $self  = $_[0];
	my $votes = $_[1];
	my $id    = $_[2];

	# checked before anything reaches for a direction, as looking one up
	# would bring the end into being with nothing to it
	if ( !defined( $votes->{$id} ) ) {
		return undef;
	}

	if (   ( defined( $votes->{$id}{r} ) )
		&& ( !defined( $votes->{$id}{w} ) ) )
	{
		return 'r';
	}

	if (   ( defined( $votes->{$id}{w} ) )
		&& ( !defined( $votes->{$id}{r} ) ) )
	{
		return 'w';
	}

	return undef;
} ## end sub _pipeVote

#
# Works out which way round a pipe end is from the size of the buffer
# sitting behind it, returning r, w, or undef for a pair there is nothing
# to go on with.
#
# FreeBSD hands the read end of a pipe the buffer everything written to it
# lands in, which starts out at 16k and is grown to 64k for one that is
# being pushed, and the write end a 4k one that is never used, so the
# larger of the two is the end being read from. Both are made at the
# smaller size when the kernel is low on room for them, which says
# nothing, as does anything lsof reports no size for. This is the only
# thing separating the two ends on the pipes a process made for itself
# there, as those never land on a standard descriptor and lsof reports
# every one of them as being open read/write.
#
# Other systems are left out of it, the sizes they hand the two ends of a
# pipe being their own business rather than anything that follows from
# how a pipe works.
#
sub _pipeSizeDirection {
	my $self    = $_[0];
	my $sizes   = $_[1];
	my $id      = $_[2];
	my $peer_id = $_[3];

	if ( $^O !~ /freebsd/ ) {
		return undef;
	}

	if (   ( !defined( $sizes->{$id} ) )
		|| ( !defined( $sizes->{$peer_id} ) )
		|| ( $sizes->{$id} == $sizes->{$peer_id} ) )
	{
		return undef;
	}

	if ( $sizes->{$id} > $sizes->{$peer_id} ) {
		return 'r';
	}

	return 'w';
} ## end sub _pipeSizeDirection

#
# Splits the processes holding one end of a pipe into the ones it was made
# for and the ones that only came by it through being forked off of
# something already holding it, returning a hash ref with the keys own and
# inherited. A pool of workers ends up holding a end apiece of every pipe
# made before it was forked, which is what this is for.
#
sub _pipeEnd {
	my $self      = $_[0];
	my $holders   = $_[1];
	my $key       = $_[2];
	my $direction = $_[3];

	my @own;
	my @inherited;

	if ( !defined( $holders->{$key}{$direction} ) ) {
		return {
			own       => \@own,
			inherited => \@inherited,
		};
	}

	foreach my $pid ( sort { $a <=> $b } keys %{ $holders->{$key}{$direction} } ) {
		# A process holding the end on a standard descriptor was handed it to
		# use whether its parent still has it or not, the last command in a
		# pipeline being forked off of a shell that is sitting on the very
		# same end, so only the ones on a higher descriptor are taken for a
		# copy that came along with the fork.
		my $ppid = $self->{ppids}{$pid};
		if (   ( defined($ppid) )
			&& ( defined( $holders->{$key}{$direction}{$ppid} ) )
			&& ( !$holders->{$key}{$direction}{$pid} ) )
		{
			push( @inherited, $pid );
		} else {
			push( @own, $pid );
		}
	} ## end foreach my $pid ( sort { $a <=> $b } keys %{ $holders...})

	return {
		own       => \@own,
		inherited => \@inherited,
	};
} ## end sub _pipeEnd

#
# Returns true if the PID is the only thing holding either end of the
# pipe, which is what a process that made one for itself looks like.
#
sub _pipeIsSelfOnly {
	my $self    = $_[0];
	my $holders = $_[1];
	my $key     = $_[2];
	my $pid     = $_[3];

	foreach my $direction ( 'w', 'r' ) {
		foreach my $holder_pid ( keys %{ $holders->{$key}{$direction} } ) {
			if ( $holder_pid ne $pid ) {
				return 0;
			}
		}
	}

	return 1;
} ## end sub _pipeIsSelfOnly

#
# Returns true if the file from _lsof is a unix socket.
#
sub _isUnix {
	my $self = $_[0];
	my $file = $_[1];

	if ( !defined($file) ) {
		return 0;
	}

	if ( $file->{type} =~ /^[Uu][Nn][Ii][Xx]$/ ) {
		return 1;
	}

	return 0;
} ## end sub _isUnix

#
# Renders the SIZE/OFF column for a file from _lsof. Only a size is worth
# making readable, a offset being a position rather than a amount, and
# lsof marks those out by printing them as 0t<decimal> or 0x<hex>.
#
sub _sizeString {
	my $self = $_[0];
	my $file = $_[1];

	if (   ( $self->{human_size} )
		&& ( $file->{size} =~ /^[0-9]+$/ ) )
	{
		return $self->memString( $file->{size}, 'size' );
	}

	return color( $self->{file_colors}[3] ) . $file->{size_off} . color('reset');
} ## end sub _sizeString

#
# Renders a UID as the user it belongs to with the number after it,
# falling back to just the number for any that can't be looked up.
#
sub _userString {
	my $self = $_[0];
	my $uid  = $_[1];

	my $user = getpwuid($uid);
	if ( !defined($user) ) {
		return color( $self->{idColors}[0] ) . $uid . color('reset');
	}

	return
		  color( $self->{idColors}[0] )
		. $user
		. color( $self->{idColors}[1] ) . '('
		. color( $self->{idColors}[2] )
		. $uid
		. color( $self->{idColors}[1] ) . ')'
		. color('reset');
} ## end sub _userString

#
# The same as _userString, for a GID and the group it belongs to.
#
sub _groupString {
	my $self = $_[0];
	my $gid  = $_[1];

	my $group = getgrgid($gid);
	if ( !defined($group) ) {
		return color( $self->{idColors}[0] ) . $gid . color('reset');
	}

	return
		  color( $self->{idColors}[0] )
		. $group
		. color( $self->{idColors}[1] ) . '('
		. color( $self->{idColors}[2] )
		. $gid
		. color( $self->{idColors}[1] ) . ')'
		. color('reset');
} ## end sub _groupString

#
# Returns a hash ref of the parameters jls reports for a JID, which is
# cached for the duration of the run as any number of processes may be
# in the same jail. Undef is returned for the host, anything that is not
# FreeBSD, and any jail that could not be looked up.
#
sub _jailInfo {
	my $self = $_[0];
	my $jid  = $_[1];

	if (   ( $^O !~ /freebsd/ )
		|| ( !defined($jid) )
		|| ( $jid !~ /^[0-9]+$/ )
		|| ( $jid == 0 ) )
	{
		return undef;
	}

	if ( exists( $self->{jails}{$jid} ) ) {
		return $self->{jails}{$jid};
	}
	# noted as looked up either way, so a jail that is not there is not
	# asked after over and over
	$self->{jails}{$jid} = undef;

	# -n is what gets every parameter of the jail printed, jls otherwise
	# only reporting the handful of columns it has. It also has a habit of
	# printing a error for a jail that is not there, on top of the empty
	# list it hands back for one, so stderr is sent off to be forgotten
	# about.
	my $output_raw = `jls --libxo json -n -j $jid 2> /dev/null`;

	my $decoded;
	eval { $decoded = decode_json($output_raw); };
	if (   ( !defined($decoded) )
		|| ( ref($decoded) ne 'HASH' )
		|| ( ref( $decoded->{'jail-information'} ) ne 'HASH' )
		|| ( ref( $decoded->{'jail-information'}{jail} ) ne 'ARRAY' )
		|| ( ref( $decoded->{'jail-information'}{jail}[0] ) ne 'HASH' ) )
	{
		return undef;
	}

	$self->{jails}{$jid} = $decoded->{'jail-information'}{jail}[0];

	return $self->{jails}{$jid};
} ## end sub _jailInfo

#
# Renders a JID as the name of the jail with the number after it, in the
# same manner as _userString, with the hostname and path tacked on when
# they have anything to add. Just the number is used for the host and for
# any jail that can't be looked up.
#
sub _jailString {
	my $self = $_[0];
	my $jid  = $_[1];

	my $jail = $self->_jailInfo($jid);

	if (   ( !defined($jail) )
		|| ( !defined( $jail->{name} ) )
		|| ( $jail->{name} =~ /^$/ ) )
	{
		return color( $self->{valColor} ) . $jid . color('reset');
	}

	my $toReturn
		= color( $self->{idColors}[0] )
		. $jail->{name}
		. color( $self->{idColors}[1] ) . '('
		. color( $self->{idColors}[2] )
		. $jid
		. color( $self->{idColors}[1] ) . ')'
		. color('reset');

	# the hostname is more often than not just the name over again and the
	# path nothing worth mentioning for a jail sharing the file system it
	# was started from
	if (   ( defined( $jail->{'host.hostname'} ) )
		&& ( $jail->{'host.hostname'} !~ /^$/ )
		&& ( $jail->{'host.hostname'} ne $jail->{name} ) )
	{
		$toReturn = $toReturn . ' ' . color( $self->{valColor} ) . $jail->{'host.hostname'} . color('reset');
	}

	if (   ( defined( $jail->{path} ) )
		&& ( $jail->{path} !~ /^$/ )
		&& ( $jail->{path} ne '/' ) )
	{
		$toReturn = $toReturn . ' ' . color( $self->{valColor} ) . $jail->{path} . color('reset');
	}

	return $toReturn;
} ## end sub _jailString

#
# Renders a value jls reports for a jail parameter, the JSON it is taken
# from having booleans and lists in it on top of the plain scalars.
#
sub _jailValue {
	my $self  = $_[0];
	my $value = $_[1];

	if ( !defined($value) ) {
		return '';
	}

	if ( ref($value) eq 'ARRAY' ) {
		my @values;
		foreach my $item ( @{$value} ) {
			push( @values, $self->_jailValue($item) );
		}
		return join( ', ', @values );
	}

	# a JSON boolean stringifies as 1 or 0, which says less than it could
	# for something like persist or dying
	if ( ref($value) =~ /Boolean$/ ) {
		if ($value) {
			return 'true';
		}
		return 'false';
	}

	return $value;
} ## end sub _jailValue

#
# Builds the table of every parameter jls reports for the jail a PID is
# in, returning a empty string for a process that is not in one.
#
sub _jailTable {
	my $self = $_[0];
	my $jid  = $_[1];

	my $jail = $self->_jailInfo($jid);
	if ( !defined($jail) ) {
		return '';
	}

	my @rows;
	foreach my $key ( sort keys %{$jail} ) {
		push(
			@rows,
			[
				color( $self->{varColor} ) . $key . color('reset'),
				color( $self->{valColor} ) . $self->_jailValue( $jail->{$key} ) . color('reset'),
			]
		);
	}

	if ( !defined( $rows[0] ) ) {
		return '';
	}

	my $jtb = Text::ANSITable->new;
	$jtb->border_style('Default::none_ascii');
	$jtb->color_theme('Default::no_color');
	$jtb->show_header(1);
	$jtb->set_column_style( 0, pad => 0 );
	$jtb->set_column_style( 1, pad => 1 );
	$jtb->columns(
		[
			color( $self->{varColor} ) . 'JAIL ARG' . color('reset'),
			color( $self->{varColor} ) . 'VALUE' . color('reset')
		]
	);
	$jtb->add_rows( \@rows );

	return $jtb->draw;
} ## end sub _jailTable

#
# Returns a array ref of the cgroups a PID is in, each a hash ref with the
# keys controller and path. A empty list is handed back for anything that
# is not Linux and for any process that could not be read.
#
sub _cgroups {
	my $self = $_[0];
	my $pid  = $_[1];

	if (   ( $^O !~ /linux/ )
		|| ( !defined($pid) )
		|| ( $pid !~ /^[0-9]+$/ ) )
	{
		return [];
	}

	my $fh;
	if ( !open( $fh, '<', '/proc/' . $pid . '/cgroup' ) ) {
		return [];
	}
	my @lines = readline($fh);
	close($fh);

	my @cgroups;
	foreach my $line (@lines) {
		chomp($line);

		# the hierarchy ID, the controllers riding on it, and the path,
		# with the v2 one being the lone hierarchy zero that names no
		# controllers, carrying the lot of them
		if ( $line !~ /^([0-9]+):([^:]*):(.*)$/ ) {
			next;
		}
		my $controller = $2;
		my $path       = $3;

		if ( $path =~ /^$/ ) {
			next;
		}

		push(
			@cgroups,
			{
				controller => $controller,
				path       => $path,
			}
		);
	} ## end foreach my $line (@lines)

	return \@cgroups;
} ## end sub _cgroups

#
# Returns a hash ref of the namespaces a PID is in, keyed by name with the
# inode of each as the value. A empty one is handed back for anything that
# is not Linux and for any process that could not be read, which is what
# another user's is when not running as root.
#
sub _namespaces {
	my $self = $_[0];
	my $pid  = $_[1];

	my %namespaces;

	if (   ( $^O !~ /linux/ )
		|| ( !defined($pid) )
		|| ( $pid !~ /^[0-9]+$/ ) )
	{
		return \%namespaces;
	}

	my $dh;
	if ( !opendir( $dh, '/proc/' . $pid . '/ns' ) ) {
		return \%namespaces;
	}
	my @entries = readdir($dh);
	closedir($dh);

	foreach my $entry (@entries) {
		# the _for_children ones are what the next fork lands in rather
		# than what this process is in, which is what is being asked after
		if (   ( $entry =~ /^\./ )
			|| ( $entry =~ /_for_children$/ ) )
		{
			next;
		}

		my $link = readlink( '/proc/' . $pid . '/ns/' . $entry );
		if (   ( !defined($link) )
			|| ( $link !~ /^[a-z\_]+:\[([0-9]+)\]$/ ) )
		{
			next;
		}

		$namespaces{$entry} = $1;
	} ## end foreach my $entry (@entries)

	return \%namespaces;
} ## end sub _namespaces

#
# Returns the namespaces PID 1 is in, which is what the rest are measured
# against, cached for the duration of the run.
#
sub _hostNamespaces {
	my $self = $_[0];

	if ( defined( $self->{host_namespaces} ) ) {
		return $self->{host_namespaces};
	}

	$self->{host_namespaces} = $self->_namespaces(1);

	return $self->{host_namespaces};
} ## end sub _hostNamespaces

#
# Returns a array ref of the namespaces a PID is in that PID 1 is not,
# which is what it has been shut away from the rest of the system in.
# Nothing is reported when either end of the comparison could not be read.
#
sub _privateNamespaces {
	my $self = $_[0];
	my $pid  = $_[1];

	my $host       = $self->_hostNamespaces;
	my $namespaces = $self->_namespaces($pid);

	my @private;
	foreach my $name ( sort keys %{$namespaces} ) {
		if ( !defined( $host->{$name} ) ) {
			next;
		}
		if ( $host->{$name} ne $namespaces->{$name} ) {
			push( @private, $name );
		}
	}

	return \@private;
} ## end sub _privateNamespaces

#
# Picks the container out of a cgroup path, returning a hash ref with the
# keys type and id, or undef for a path that names none. The runtimes each
# name the cgroup they put a container in after it, be it the ID they gave
# it or the name it was started under, with the scope and slice systemd
# wraps that in around it when systemd is what did the starting.
#
sub _containerFromPath {
	my $self = $_[0];
	my $path = $_[1];

	my @checks = (
		[ 'docker',     qr/(?:^|\/)docker[\-\/]([0-9a-f]{12,64})(?:\.scope)?(?:$|\/)/ ],
		[ 'podman',     qr/(?:^|\/)libpod[\-_]([0-9a-f]{12,64})(?:\.scope)?(?:$|\/)/ ],
		[ 'containerd', qr/(?:^|\/)cri-containerd[\-\/]([0-9a-f]{12,64})(?:\.scope)?(?:$|\/)/ ],
		[ 'crio',       qr/(?:^|\/)crio[\-\/]([0-9a-f]{12,64})(?:\.scope)?(?:$|\/)/ ],
		[ 'lxc',        qr/(?:^|\/)lxc(?:\/|\.(?:payload|monitor)[\.\/])([^\/]+)/ ],
		[ 'machine',    qr/(?:^|\/)machine-([^\/]+)\.scope/ ],
	);

	foreach my $check (@checks) {
		if ( $path =~ $check->[1] ) {
			my $id = $1;

			# systemd puts anything that is not a plain character in a unit
			# name through as a hex escape, which is not how it is known
			$id =~ s/\\x([0-9a-fA-F]{2})/chr(hex($1))/ge;

			return {
				type => $check->[0],
				id   => $id,
			};
		} ## end if ( $path =~ $check->[1] )
	} ## end foreach my $check (@checks)

	return undef;
} ## end sub _containerFromPath

#
# Returns a hash ref with the keys type and id for the container a PID is
# in, which is cached for the duration of the run. Undef is returned for
# anything that is not Linux and for a process that is not in one, or at
# least not in one that named itself in a way that can be picked out.
#
sub _containerInfo {
	my $self = $_[0];
	my $pid  = $_[1];

	if (   ( $^O !~ /linux/ )
		|| ( !defined($pid) )
		|| ( $pid !~ /^[0-9]+$/ ) )
	{
		return undef;
	}

	if ( exists( $self->{containers}{$pid} ) ) {
		return $self->{containers}{$pid};
	}
	# noted as looked up either way, so one that is not there is not asked
	# after over and over
	$self->{containers}{$pid} = undef;

	foreach my $cgroup ( @{ $self->_cgroups($pid) } ) {
		my $container = $self->_containerFromPath( $cgroup->{path} );
		if ( defined($container) ) {
			$self->{containers}{$pid} = $container;
			last;
		}
	}

	return $self->{containers}{$pid};
} ## end sub _containerInfo

#
# Renders the container a PID is in as the runtime that started it with
# the ID after it, in the same manner as _jailString. Undef is returned
# when there is no container to speak of.
#
sub _containerString {
	my $self = $_[0];
	my $pid  = $_[1];

	my $container = $self->_containerInfo($pid);
	if ( !defined($container) ) {
		return undef;
	}

	# a container ID is a long hash that everything shortens to the first
	# dozen characters of, which tells them apart well enough
	my $id = $container->{id};
	if ( $id =~ /^[0-9a-f]{13,}$/ ) {
		$id = substr( $id, 0, 12 );
	}

	return
		  color( $self->{idColors}[0] )
		. $container->{type}
		. color( $self->{idColors}[1] ) . '('
		. color( $self->{idColors}[2] )
		. $id
		. color( $self->{idColors}[1] ) . ')'
		. color('reset');
} ## end sub _containerString

#
# Renders the cgroups a PID is in. Undef is returned when there is nothing
# worth saying, which is the case for a process left sitting in the root
# cgroup where it started.
#
sub _cgroupString {
	my $self = $_[0];
	my $pid  = $_[1];

	my @paths;
	my %seen;
	foreach my $cgroup ( @{ $self->_cgroups($pid) } ) {
		# the v1 hierarchies more often than not all point at the same
		# path, which is worth printing no more than once
		if (   ( $cgroup->{path} eq '/' )
			|| ( defined( $seen{ $cgroup->{path} } ) ) )
		{
			next;
		}
		$seen{ $cgroup->{path} } = 1;
		push( @paths, $cgroup->{path} );
	} ## end foreach my $cgroup ( @{ $self->_cgroups($pid) })

	if ( !defined( $paths[0] ) ) {
		return undef;
	}

	return color( $self->{valColor} ) . join( ' ', @paths ) . color('reset');
} ## end sub _cgroupString

#
# Renders the namespaces a PID is in that PID 1 is not. Undef is returned
# for a process sharing the lot of them with the rest of the system.
#
sub _namespaceString {
	my $self = $_[0];
	my $pid  = $_[1];

	my $private = $self->_privateNamespaces($pid);
	if ( !defined( $private->[0] ) ) {
		return undef;
	}

	return color( $self->{valColor} ) . join( ', ', @{$private} ) . color('reset');
} ## end sub _namespaceString

#
# Returns the path the cgroup v2 hierarchy is mounted at, which is not
# always the /sys/fs/cgroup it usually is, so it is taken from the mount
# table rather than assumed. Undef is returned when there is none, such as
# on a system still running v1 alone. Cached for the duration of the run.
#
sub _cgroupMount {
	my $self = $_[0];

	if ( exists( $self->{cgroup_mount} ) ) {
		return $self->{cgroup_mount};
	}
	$self->{cgroup_mount} = undef;

	if ( $^O !~ /linux/ ) {
		return undef;
	}

	my $fh;
	if ( !open( $fh, '<', '/proc/self/mountinfo' ) ) {
		return undef;
	}
	my @lines = readline($fh);
	close($fh);

	foreach my $line (@lines) {
		chomp($line);

		# there are a variable number of optional fields sitting between the
		# mount point and the separator, so the type has to be picked up
		# from the far side of the latter
		my ( $left, $right ) = split( /\ \-\ /, $line, 2 );
		if ( !defined($right) ) {
			next;
		}

		my @left_fields  = split( /[\ \t]+/, $left );
		my @right_fields = split( /[\ \t]+/, $right );

		if (   ( !defined( $right_fields[0] ) )
			|| ( $right_fields[0] ne 'cgroup2' )
			|| ( !defined( $left_fields[4] ) ) )
		{
			next;
		}

		# anything odd in a path is octal escaped in the mount table
		my $mount = $left_fields[4];
		$mount =~ s/\\([0-7]{3})/chr(oct($1))/ge;

		$self->{cgroup_mount} = $mount;
		last;
	} ## end foreach my $line (@lines)

	return $self->{cgroup_mount};
} ## end sub _cgroupMount

#
# Returns the directory holding the cgroup v2 knobs for a PID, or undef
# when there is not one to be had.
#
sub _cgroupDir {
	my $self = $_[0];
	my $pid  = $_[1];

	my $mount = $self->_cgroupMount;
	if ( !defined($mount) ) {
		return undef;
	}

	# the v2 hierarchy is the one that names no controllers, carrying the
	# lot of them
	my $path;
	foreach my $cgroup ( @{ $self->_cgroups($pid) } ) {
		if ( $cgroup->{controller} =~ /^$/ ) {
			$path = $cgroup->{path};
			last;
		}
	}

	# The root cgroup has nothing of its own to say. A process in a cgroup
	# namespace of its own reports it for want of anything it is allowed to
	# see as well, and reading the root for one of those would hand back
	# the whole system's numbers as though they were the process's.
	if (   ( !defined($path) )
		|| ( $path eq '/' ) )
	{
		return undef;
	}

	my $dir = $mount . $path;
	if ( !-d $dir ) {
		return undef;
	}

	return $dir;
} ## end sub _cgroupDir

#
# Reads a knob from a cgroup directory, handing back its contents with the
# trailing newline taken off, or undef for one that is not there. Which of
# them a cgroup has depends on the controllers turned on for it by its
# parent, so a missing one is nothing out of the ordinary. Cached for the
# duration of the run, as any number of processes may sit in one cgroup.
#
sub _cgroupRead {
	my $self = $_[0];
	my $dir  = $_[1];
	my $name = $_[2];

	if ( !defined($dir) ) {
		return undef;
	}

	if ( exists( $self->{cgroup_files}{$dir}{$name} ) ) {
		return $self->{cgroup_files}{$dir}{$name};
	}
	# noted as read either way, so one that is not there is not asked after
	# over and over
	$self->{cgroup_files}{$dir}{$name} = undef;

	my $fh;
	if ( !open( $fh, '<', $dir . '/' . $name ) ) {
		return undef;
	}
	my $content = do { local $/; readline($fh) };
	close($fh);

	if ( !defined($content) ) {
		return undef;
	}
	$content =~ s/\n$//;

	$self->{cgroup_files}{$dir}{$name} = $content;

	return $content;
} ## end sub _cgroupRead

#
# The same as _cgroupRead for the knobs holding a list of names and values
# a line at a time, such as memory.events and cpu.stat, returning a hash
# ref of them.
#
sub _cgroupKeyed {
	my $self = $_[0];
	my $dir  = $_[1];
	my $name = $_[2];

	my %values;

	my $content = $self->_cgroupRead( $dir, $name );
	if ( !defined($content) ) {
		return \%values;
	}

	foreach my $line ( split( /\n/, $content ) ) {
		if ( $line =~ /^(\S+)[\ \t]+(\S+)$/ ) {
			$values{$1} = $2;
		}
	}

	return \%values;
} ## end sub _cgroupKeyed

#
# Returns a array ref of the PIDs sitting in a cgroup, which for a systemd
# unit is the lot of what it started.
#
sub _cgroupProcs {
	my $self = $_[0];
	my $dir  = $_[1];

	my @pids;

	my $content = $self->_cgroupRead( $dir, 'cgroup.procs' );
	if ( !defined($content) ) {
		return \@pids;
	}

	foreach my $line ( split( /\n/, $content ) ) {
		if ( $line =~ /^([0-9]+)$/ ) {
			push( @pids, $1 );
		}
	}

	return \@pids;
} ## end sub _cgroupProcs

#
# Renders what a cgroup is using of the memory it is allowed, which is the
# whole cgroup rather than the one process, and takes in the page cache on
# top of the anonymous memory, so it is not the RSS over again.
#
sub _cgroupMemoryString {
	my $self = $_[0];
	my $dir  = $_[1];

	my $current = $self->_cgroupRead( $dir, 'memory.current' );
	if (   ( !defined($current) )
		|| ( $current !~ /^[0-9]+$/ ) )
	{
		return undef;
	}

	my $toReturn = $self->memString( $current, 'rss' );

	# a limit of max is no limit at all, leaving nothing to measure against
	my $max  = $self->_cgroupRead( $dir, 'memory.max' );
	my $high = $self->_cgroupRead( $dir, 'memory.high' );
	if (   ( defined($max) )
		&& ( $max =~ /^[0-9]+$/ ) )
	{
		$toReturn = $toReturn . color( $self->{varColor} ) . ' / ' . color('reset') . $self->memString( $max, 'vsz' );
	} elsif ( ( defined($high) )
		&& ( $high =~ /^[0-9]+$/ ) )
	{
		# the soft limit, which is pushed back under rather than kept under
		$toReturn
			= $toReturn
			. color( $self->{varColor} ) . ' / '
			. color('reset')
			. $self->memString( $high, 'vsz' )
			. color( $self->{varColor} ) . ' high'
			. color('reset');
	} ## end elsif ( ( defined($high) ) && ( $high =~ /^[0-9]+$/...))

	my $peak = $self->_cgroupRead( $dir, 'memory.peak' );
	if (   ( defined($peak) )
		&& ( $peak =~ /^[0-9]+$/ ) )
	{
		$toReturn
			= $toReturn . color( $self->{varColor} ) . ' peak ' . color('reset') . $self->memString( $peak, 'size' );
	}

	my $swap = $self->_cgroupRead( $dir, 'memory.swap.current' );
	if (   ( defined($swap) )
		&& ( $swap =~ /^[1-9][0-9]*$/ ) )
	{
		$toReturn
			= $toReturn . color( $self->{varColor} ) . ' swap ' . color('reset') . $self->memString( $swap, 'size' );
	}

	return $toReturn;
} ## end sub _cgroupMemoryString

#
# Renders what a cgroup is allowed of the CPU and what it has been held
# back to it with. Undef is returned when it has neither a quota nor any
# throttling to it, the time it has used being no more than what the
# process table already says for every process in it.
#
sub _cgroupCpuString {
	my $self = $_[0];
	my $dir  = $_[1];

	my @parts;

	# the quota and the period it is handed out over, which says a good
	# deal more as the number of cores it works out to
	my $max = $self->_cgroupRead( $dir, 'cpu.max' );
	if (   ( defined($max) )
		&& ( $max =~ /^([0-9]+)[\ \t]+([0-9]+)$/ )
		&& ( $2 > 0 ) )
	{
		my $cores = sprintf( '%.2f', $1 / $2 );
		$cores =~ s/0+$//;
		$cores =~ s/\.$//;
		push( @parts, color( $self->{varColor} ) . 'quota ' . color( $self->{valColor} ) . $cores . color('reset') );
	}

	my $stat = $self->_cgroupKeyed( $dir, 'cpu.stat' );

	my $throttled;
	if (   ( defined( $stat->{nr_throttled} ) )
		&& ( $stat->{nr_throttled} =~ /^[1-9][0-9]*$/ ) )
	{
		$throttled
			= color( $self->{varColor} )
			. 'throttled '
			. color( $self->{processColor} )
			. $stat->{nr_throttled}
			. color('reset');

		if (   ( defined( $stat->{throttled_usec} ) )
			&& ( $stat->{throttled_usec} =~ /^[0-9]+$/ ) )
		{
			# timeString takes microseconds on Linux, which is what the
			# cgroup knobs are counted in
			$throttled
				= $throttled
				. color( $self->{varColor} ) . ' for '
				. color('reset')
				. $self->timeString( $stat->{throttled_usec} );
		} ## end if ( ( defined( $stat->{throttled_usec} ) ...))
	} ## end if ( ( defined( $stat->{nr_throttled} ) ) ...)

	# nothing here is worth a line of its own for a cgroup that is neither
	# capped nor being held back
	if (   ( !defined( $parts[0] ) )
		&& ( !defined($throttled) ) )
	{
		return undef;
	}

	if (   ( defined( $stat->{usage_usec} ) )
		&& ( $stat->{usage_usec} =~ /^[0-9]+$/ ) )
	{
		push( @parts,
			color( $self->{varColor} ) . 'used ' . color('reset') . $self->timeString( $stat->{usage_usec} ) );
	}

	if ( defined($throttled) ) {
		push( @parts, $throttled );
	}

	return join( color( $self->{valColor} ) . ', ' . color('reset'), @parts );
} ## end sub _cgroupCpuString

#
# Renders how many processes a cgroup is holding against how many it is
# allowed. Undef is returned when there is no limit set, the count on its
# own saying nothing the list of them under jail_info does not.
#
sub _cgroupPidsString {
	my $self = $_[0];
	my $dir  = $_[1];

	my $max     = $self->_cgroupRead( $dir, 'pids.max' );
	my $current = $self->_cgroupRead( $dir, 'pids.current' );

	if (   ( !defined($max) )
		|| ( $max !~ /^[0-9]+$/ )
		|| ( !defined($current) )
		|| ( $current !~ /^[0-9]+$/ ) )
	{
		return undef;
	}

	return
		  color( $self->{valColor} )
		. $current
		. color( $self->{varColor} ) . ' / '
		. color( $self->{valColor} )
		. $max
		. color('reset');
} ## end sub _cgroupPidsString

#
# Renders the times a cgroup has been up against one of its limits, which
# is where a OOM kill shows up. Undef is returned for one that has never
# been, everything sitting at zero having nothing to say.
#
sub _cgroupEventsString {
	my $self = $_[0];
	my $dir  = $_[1];

	my $events = $self->_cgroupKeyed( $dir, 'memory.events' );

	my @parts;
	foreach my $key ( 'oom_kill', 'oom_group_kill', 'oom', 'max', 'high', 'low' ) {
		if (   ( !defined( $events->{$key} ) )
			|| ( $events->{$key} !~ /^[1-9][0-9]*$/ ) )
		{
			next;
		}
		push( @parts,
				  color( $self->{varColor} )
				. $key . ' '
				. color( $self->{processColor} )
				. $events->{$key}
				. color('reset') );
	} ## end foreach my $key ( 'oom_kill', 'oom_group_kill',...)

	if ( !defined( $parts[0] ) ) {
		return undef;
	}

	return join( color( $self->{valColor} ) . ', ' . color('reset'), @parts );
} ## end sub _cgroupEventsString

#
# Renders how much of the time something in a cgroup was held up waiting
# on the CPU, the memory, or the disk, as the ten second and one minute
# run of it. Undef is returned when nothing is being held up at all.
#
sub _cgroupPressureString {
	my $self = $_[0];
	my $dir  = $_[1];

	my @parts;
	foreach my $what ( 'cpu', 'memory', 'io' ) {
		my $content = $self->_cgroupRead( $dir, $what . '.pressure' );
		if ( !defined($content) ) {
			next;
		}

		# the some line covers anything at all being held up, where full is
		# only the times nothing in the cgroup could run
		my $avg10;
		my $avg60;
		foreach my $line ( split( /\n/, $content ) ) {
			if ( $line !~ /^some[\ \t]/ ) {
				next;
			}
			if ( $line =~ /avg10=([0-9\.]+)/ ) {
				$avg10 = $1;
			}
			if ( $line =~ /avg60=([0-9\.]+)/ ) {
				$avg60 = $1;
			}
		} ## end foreach my $line ( split( /\n/, $content ) )

		if (   ( !defined($avg10) )
			|| ( $avg10 <= 0 ) )
		{
			next;
		}

		my $rendered
			= color( $self->{varColor} ) . $what . ' ' . color( $self->{processColor} ) . $avg10 . color('reset');
		if ( defined($avg60) ) {
			$rendered
				= $rendered
				. color( $self->{valColor} ) . '/'
				. color( $self->{processColor} )
				. $avg60
				. color('reset');
		}
		push( @parts, $rendered );
	} ## end foreach my $what ( 'cpu', 'memory', 'io' )

	if ( !defined( $parts[0] ) ) {
		return undef;
	}

	return join( color( $self->{valColor} ) . ', ' . color('reset'), @parts );
} ## end sub _cgroupPressureString

#
# Builds the table of the cgroups and namespaces a PID is in, which is
# what stands in for the jail parameters on Linux. A empty string is
# returned for anything else and for any process that could not be read.
#
sub _containerTable {
	my $self     = $_[0];
	my $pid      = $_[1];
	my $commands = $_[2];

	if ( $^O !~ /linux/ ) {
		return '';
	}

	my @rows;

	foreach my $cgroup ( @{ $self->_cgroups($pid) } ) {
		# the v2 hierarchy names no controllers, being the one carrying all
		# of them, so there is nothing to tell it apart by
		my $key = 'cgroup';
		if ( $cgroup->{controller} !~ /^$/ ) {
			$key = $key . ':' . $cgroup->{controller};
		}
		push(
			@rows,
			[
				color( $self->{varColor} ) . $key . color('reset'),
				color( $self->{valColor} ) . $cgroup->{path} . color('reset'),
			]
		);
	} ## end foreach my $cgroup ( @{ $self->_cgroups($pid) })

	my $host       = $self->_hostNamespaces;
	my $namespaces = $self->_namespaces($pid);
	foreach my $name ( sort keys %{$namespaces} ) {
		my $value = color( $self->{valColor} ) . $namespaces->{$name} . color('reset');

		# the ones it does not share with PID 1 are the whole point of
		# looking, so they are called out rather than left to be spotted
		if (   ( defined( $host->{$name} ) )
			&& ( $host->{$name} ne $namespaces->{$name} ) )
		{
			$value = $value . ' ' . color( $self->{processColor} ) . 'private' . color('reset');
		}

		push( @rows, [ color( $self->{varColor} ) . 'ns:' . $name . color('reset'), $value, ] );
	} ## end foreach my $name ( sort keys %{$namespaces} )

	#
	# the knobs of the cgroup itself, which are only there for the ones a
	# controller has been turned on for
	#
	my $dir = $self->_cgroupDir($pid);
	if ( defined($dir) ) {
		# what is turned on is what says why the rest of these are or are
		# not here
		foreach my $name ( 'cgroup.controllers', 'cgroup.type' ) {
			my $value = $self->_cgroupRead( $dir, $name );
			if (   ( defined($value) )
				&& ( $value !~ /^$/ ) )
			{
				push(
					@rows,
					[
						color( $self->{varColor} ) . $name . color('reset'),
						color( $self->{valColor} ) . $value . color('reset'),
					]
				);
			} ## end if ( ( defined($value) ) && ( $value !~ /^$/...))
		} ## end foreach my $name ( 'cgroup.controllers', 'cgroup.type')

		# what else is in here, gathered up under the command each is
		# running in the same manner as the peers of a endpoint
		my $procs = $self->_cgroupProcs($dir);
		if ( defined( $procs->[0] ) ) {
			push(
				@rows,
				[
					color( $self->{varColor} ) . 'cgroup.procs' . color('reset'),
					color( $self->{valColor} )
						. ( $#{$procs} + 1 ) . ' '
						. $self->_commandGroups( $procs, $commands )
						. color('reset'),
				]
			);
		} ## end if ( defined( $procs->[0] ) )

		# the sizes are worth making readable in the same manner as the
		# rest of the memory bits
		foreach my $name (
			'memory.current',      'memory.peak', 'memory.high', 'memory.max',
			'memory.swap.current', 'memory.swap.max'
			)
		{
			my $value = $self->_cgroupRead( $dir, $name );
			if ( !defined($value) ) {
				next;
			}
			if ( $value =~ /^[0-9]+$/ ) {
				$value = $self->memString( $value, 'size' );
			} else {
				$value = color( $self->{valColor} ) . $value . color('reset');
			}
			push( @rows, [ color( $self->{varColor} ) . $name . color('reset'), $value, ] );
		} ## end foreach my $name ( 'memory.current', 'memory.peak'...)

		# What memory.current is made up of, which is what says how much of
		# it is the cgroup's own and how much is just page cache it has been
		# through. There are a great many of these and the ones sitting at
		# zero have nothing to add, so only what is actually there is
		# printed, and only the handful worth reading through at that.
		my $memory_stat = $self->_cgroupKeyed( $dir, 'memory.stat' );
		foreach my $key (
			'anon',       'file',        'shmem',    'file_mapped', 'file_dirty',   'file_writeback',
			'swapcached', 'unevictable', 'anon_thp', 'kernel',      'kernel_stack', 'pagetables',
			'percpu',     'sock',        'slab'
			)
		{
			if (   ( !defined( $memory_stat->{$key} ) )
				|| ( $memory_stat->{$key} !~ /^[1-9][0-9]*$/ ) )
			{
				next;
			}
			push(
				@rows,
				[
					color( $self->{varColor} ) . 'memory.stat:' . $key . color('reset'),
					$self->memString( $memory_stat->{$key}, 'size' ),
				]
			);
		} ## end foreach my $key ( 'anon', 'file', 'shmem', 'file_mapped'...)

		# these are counts of things that happened rather than sizes, so
		# there is nothing to make readable about them
		foreach my $key ( 'pgmajfault', 'pswpin', 'pswpout' ) {
			if (   ( !defined( $memory_stat->{$key} ) )
				|| ( $memory_stat->{$key} !~ /^[1-9][0-9]*$/ ) )
			{
				next;
			}
			push(
				@rows,
				[
					color( $self->{varColor} ) . 'memory.stat:' . $key . color('reset'),
					color( $self->{valColor} ) . $memory_stat->{$key} . color('reset'),
				]
			);
		} ## end foreach my $key ( 'pgmajfault', 'pswpin', 'pswpout')

		foreach my $name ( 'pids.current', 'pids.peak', 'pids.max', 'cpu.max' ) {
			my $value = $self->_cgroupRead( $dir, $name );
			if (   ( defined($value) )
				&& ( $value !~ /^$/ ) )
			{
				push(
					@rows,
					[
						color( $self->{varColor} ) . $name . color('reset'),
						color( $self->{valColor} ) . $value . color('reset'),
					]
				);
			} ## end if ( ( defined($value) ) && ( $value !~ /^$/...))
		} ## end foreach my $name ( 'pids.current', 'pids.peak',...)

		# the times are counted in microseconds, which is what timeString
		# takes on Linux
		my $stat = $self->_cgroupKeyed( $dir, 'cpu.stat' );
		foreach my $key ( 'usage_usec', 'user_usec', 'system_usec', 'nr_periods', 'nr_throttled', 'throttled_usec' ) {
			if ( !defined( $stat->{$key} ) ) {
				next;
			}
			my $value = color( $self->{valColor} ) . $stat->{$key} . color('reset');
			if (   ( $key =~ /_usec$/ )
				&& ( $stat->{$key} =~ /^[0-9]+$/ ) )
			{
				$value = $self->timeString( $stat->{$key} );
			}
			push( @rows, [ color( $self->{varColor} ) . 'cpu.stat:' . $key . color('reset'), $value, ] );
		} ## end foreach my $key ( 'usage_usec', 'user_usec', 'system_usec'...)

		my $events = $self->_cgroupKeyed( $dir, 'memory.events' );
		foreach my $key ( sort keys %{$events} ) {
			my $value = color( $self->{valColor} ) . $events->{$key} . color('reset');
			# the ones that actually happened are the whole point of looking
			if ( $events->{$key} =~ /^[1-9][0-9]*$/ ) {
				$value = color( $self->{processColor} ) . $events->{$key} . color('reset');
			}
			push( @rows, [ color( $self->{varColor} ) . 'memory.events:' . $key . color('reset'), $value, ] );
		}

		foreach my $what ( 'cpu', 'memory', 'io' ) {
			my $content = $self->_cgroupRead( $dir, $what . '.pressure' );
			if ( !defined($content) ) {
				next;
			}
			foreach my $line ( split( /\n/, $content ) ) {
				if ( $line !~ /^(some|full)[\ \t]+(.*)$/ ) {
					next;
				}
				push(
					@rows,
					[
						color( $self->{varColor} ) . $what . '.pressure:' . $1 . color('reset'),
						color( $self->{valColor} ) . $2 . color('reset'),
					]
				);
			} ## end foreach my $line ( split( /\n/, $content ) )
		} ## end foreach my $what ( 'cpu', 'memory', 'io' )
	} ## end if ( defined($dir) )

	if ( !defined( $rows[0] ) ) {
		return '';
	}

	my $ctb = Text::ANSITable->new;
	$ctb->border_style('Default::none_ascii');
	$ctb->color_theme('Default::no_color');
	$ctb->show_header(1);
	$ctb->set_column_style( 0, pad => 0 );
	$ctb->set_column_style( 1, pad => 1 );
	$ctb->columns(
		[
			color( $self->{varColor} ) . 'CONTAINER ARG' . color('reset'),
			color( $self->{varColor} ) . 'VALUE' . color('reset')
		]
	);
	$ctb->add_rows( \@rows );

	return $ctb->draw;
} ## end sub _containerTable

#
# Proc::ProcessTable works the memory sizes out in a 32 bit integer on
# some systems, FreeBSD included, so anything past 2G comes back having
# wrapped around into the negative. Adding the 4G it lost back on puts
# that right for any process that has not gone past 4G, which is as far
# as what is reported may be taken.
#
sub _procMem {
	my $self = $_[0];
	my $mem  = $_[1];

	if ( !defined($mem) ) {
		return 0;
	}

	if ( $mem < 0 ) {
		$mem = $mem + 2**32;
	}

	return $mem;
} ## end sub _procMem

#
# Adds up the size of the shared memory objects in a list of files from
# _lsof. One held on more than one FD is only counted the once, the
# object being what takes up the memory rather than the handle on it.
#
sub _shmTotal {
	my $self  = $_[0];
	my $files = $_[1];

	if ( !defined($files) ) {
		return 0;
	}

	my $total = 0;
	my %seen;
	foreach my $file ( @{$files} ) {
		if (   ( !$self->_isShm($file) )
			|| ( $file->{size} !~ /^[0-9]+$/ ) )
		{
			next;
		}

		# The endpoint ID names the object itself, which is what tells one
		# anonymous object from another. Linux reports no node identifier
		# at all, so that falls back to the device and inode there.
		my $ids = $self->_peerIDs($file);
		if ( defined($ids) ) {
			if ( defined( $seen{ $ids->{id} } ) ) {
				next;
			}
			$seen{ $ids->{id} } = 1;
		}

		$total = $total + $file->{size};
	} ## end foreach my $file ( @{$files} )

	return $total;
} ## end sub _shmTotal

#
# Returns true if the file from _lsof is a shared memory object.
#
sub _isShm {
	my $self = $_[0];
	my $file = $_[1];

	if ( !defined($file) ) {
		return 0;
	}

	if ( $file->{type} =~ /^[Ss][Hh][Mm]$/ ) {
		return 1;
	}

	# Linux has no type of its own for these, handing them the same REG
	# every other file gets, so the name is what tells them apart. POSIX
	# objects live on the tmpfs mounted at /dev/shm, SysV segments are
	# named after their key, and the anonymous ones made by memfd_create
	# after whatever they were passed.
	if (
		( $file->{type} =~ /^[Rr][Ee][Gg]$/ )
		&& (   ( $file->{match_name} =~ /^\/dev\/shm\// )
			|| ( $file->{match_name} =~ /^\/SYSV/ )
			|| ( $file->{match_name} =~ /^\/memfd:/ ) )
		)
	{
		return 1;
	}

	return 0;
} ## end sub _isShm

#
# Returns true if the type from _lsof is one the FD deduping applies to,
# which is the regular files and the devices sitting on a path.
#
sub _isDedupType {
	my $self = $_[0];
	my $type = $_[1];

	if (   ( $type =~ /[Vv][Rr][Ee][Gg]/ )
		|| ( $type =~ /[Rr][Ee][Gg]/ )
		|| ( $type =~ /[Vv][Dd][Ii][Dd]/ )
		|| ( $type =~ /[Vv][Cc][Hh][Rr]/ ) )
	{
		return 1;
	}

	return 0;
} ## end sub _isDedupType

#
# Works out the IDs used to tie the two ends of a pipe, FIFO, unix
# socket, or shared memory entry from _lsof together, returning a hash
# ref with the keys id and peer_id. The peer_id is undef when the entry
# neither names a far end of its own nor is the sort shared by way of
# both ends holding it, such as a unix socket lsof names after the path
# it is bound to, and undef is returned for anything that has no ID at
# all.
#
sub _peerIDs {
	my $self = $_[0];
	my $file = $_[1];

	my $class;
	if ( $self->_isUnix($file) ) {
		$class = 'unix';
	} elsif ( $self->_isPipe($file) ) {
		$class = 'pipe';
	} elsif ( $self->_isShm($file) ) {
		$class = 'shm';
	} else {
		return undef;
	}

	# The node identifier names the object itself, which is what both ends
	# of one have in common, with the device and inode falling in for it
	# on anything lsof reports no identifier for.
	my $id;
	if ( $file->{node_id} !~ /^$/ ) {
		$id = $class . ':' . $file->{node_id};
	} elsif ( ( $file->{device} !~ /^$/ )
		&& ( $file->{node} =~ /^[0-9]+$/ ) )
	{
		$id = $class . ':' . $file->{device} . ':' . $file->{node};
	} elsif ( $file->{device} !~ /^$/ ) {
		$id = $class . ':' . $file->{device};
	} elsif ( ( $class eq 'shm' )
		&& ( $file->{match_name} !~ /^$/ ) )
	{
		$id = $class . ':' . $file->{match_name};
	} else {
		return undef;
	}

	# A SysV segment is handed the same device and a inode of zero as every
	# other one of them on Linux, leaving what it is named after its key as
	# the only thing telling one from the next. The same goes for anything
	# else lsof reports no inode of its own for, such as a object that has
	# been unlinked.
	if (   ( $class eq 'shm' )
		&& ( $file->{node_id}    =~ /^$/ )
		&& ( $file->{node}       !~ /^[1-9][0-9]*$/ )
		&& ( $file->{match_name} !~ /^$/ ) )
	{
		$id = $id . ':' . $file->{match_name};
	}

	# Systems such as FreeBSD point at the far end of a pipe or connected
	# unix socket via the name, where the address named is the ID of the
	# object on the other side of it.
	my $peer_id;
	if ( $file->{match_name} =~ /^\-\>(\S+)/ ) {
		$peer_id = $class . ':' . $1;
	} elsif ( $class ne 'unix' ) {
		# a pipe, FIFO, or shared memory object is instead shared by way
		# of both ends holding the same one, which unix sockets do not do,
		# tying those together on Linux meaning lsof +E or ss -x
		$peer_id = $id;
	}

	return {
		id      => $id,
		peer_id => $peer_id,
	};
} ## end sub _peerIDs

#
# Returns a hash ref with the keys holders and pointers, both of which
# are hash refs of PIDs keyed by a endpoint ID. The holders are the PIDs
# with that endpoint open and the pointers the PIDs whose endpoint points
# at it, which are the two ways the far end of one may be found. This
# requires a system wide lsof, so the result is cached for the duration
# of the run.
#
sub _allPeers {
	my $self = $_[0];

	if ( defined( $self->{peer_pids} ) ) {
		return $self->{peer_pids};
	}

	my %holders;
	my %pointers;
	my %endpoints;
	my %endpoint_known;
	# a endpoint may be open on more than one FD in a process, which is
	# worth mentioning no more than once
	my %seen_holder;
	my %seen_pointer;
	my %seen_endpoint;
	foreach my $file ( @{ $self->_allFiles } ) {
		my $ids = $self->_peerIDs($file);
		if (   ( !defined($ids) )
			|| ( $file->{pid} =~ /^$/ ) )
		{
			next;
		}

		if ( !defined( $seen_holder{ $ids->{id} }{ $file->{pid} } ) ) {
			$seen_holder{ $ids->{id} }{ $file->{pid} } = 1;
			push( @{ $holders{ $ids->{id} } }, $file->{pid} );
		}

		if (   ( defined( $ids->{peer_id} ) )
			&& ( !defined( $seen_pointer{ $ids->{peer_id} }{ $file->{pid} } ) ) )
		{
			$seen_pointer{ $ids->{peer_id} }{ $file->{pid} } = 1;
			push( @{ $pointers{ $ids->{peer_id} } }, $file->{pid} );
		}

		# whatever lsof +E named as being on the far end of it, which is the
		# only way around for the unix sockets on Linux
		if ( $self->_lsofHasEndpoint($file) ) {
			$endpoint_known{ $ids->{id} } = 1;
		}
		foreach my $endpoint_pid ( @{ $self->_lsofEndpointPIDs($file) } ) {
			if ( !defined( $seen_endpoint{ $ids->{id} }{$endpoint_pid} ) ) {
				$seen_endpoint{ $ids->{id} }{$endpoint_pid} = 1;
				push( @{ $endpoints{ $ids->{id} } }, $endpoint_pid );
			}
		}
	} ## end foreach my $file ( @{ $self->_allFiles } )

	$self->{peer_pids} = {
		holders        => \%holders,
		pointers       => \%pointers,
		endpoints      => \%endpoints,
		endpoint_known => \%endpoint_known,
	};

	return $self->{peer_pids};
} ## end sub _allPeers

#
# Renders the commands holding the far end of a pipe, FIFO, or unix
# socket entry from _lsof. Undef is returned if there is nothing to be
# said about the far end and a ? if the entry has one that is out of
# reach.
#
sub _peerCommands {
	my $self     = $_[0];
	my $file     = $_[1];
	my $commands = $_[2];

	my $ids = $self->_peerIDs($file);
	if ( !defined($ids) ) {
		return undef;
	}

	my $peers = $self->_allPeers;

	my @peer_pids;
	my %seen;
	# The process itself is never worth printing as the far end of its own
	# entry. It is always one of the holders on systems that tie the two
	# ends together via the node, as Linux does, and on the ones that hand
	# each end a object of its own it turns up for the pipe or socket pair
	# a process made for itself, where the two rows pointing at each other
	# are the whole of what there is to say.
	$seen{ $file->{pid} } = 1;

	# A far end that was reached and turned out to be nothing but the
	# process itself, which is what tells one from a far end that could not
	# be reached at all once the process has been taken back out of it.
	my $self_only = 0;
	if (
		(
			   ( defined( $ids->{peer_id} ) )
			&& ( $ids->{peer_id} ne $ids->{id} )
			&& ( defined( $peers->{holders}{ $ids->{peer_id} } ) )
		)
		|| ( defined( $peers->{endpoints}{ $ids->{id} } ) )
		)
	{
		$self_only = 1;
	} ## end if ( ( ( defined( $ids->{peer_id} ) ) && (...)))

	# whatever holds the endpoint this one points at is on the far end
	if (   ( defined( $ids->{peer_id} ) )
		&& ( defined( $peers->{holders}{ $ids->{peer_id} } ) ) )
	{
		foreach my $peer_pid ( @{ $peers->{holders}{ $ids->{peer_id} } } ) {
			if ( !defined( $seen{$peer_pid} ) ) {
				$seen{$peer_pid} = 1;
				push( @peer_pids, $peer_pid );
			}
		}
	} ## end if ( ( defined( $ids->{peer_id} ) ) && ( defined...))

	# and so is whatever points at this endpoint, which is the only way
	# around for the unix sockets lsof names after the path they are bound
	# to, such as the accepted end of a connection
	if ( defined( $peers->{pointers}{ $ids->{id} } ) ) {
		foreach my $peer_pid ( @{ $peers->{pointers}{ $ids->{id} } } ) {
			if ( !defined( $seen{$peer_pid} ) ) {
				$seen{$peer_pid} = 1;
				push( @peer_pids, $peer_pid );
			}
		}
	}

	# and so is whatever lsof +E named as being on the far end of it, which
	# is what covers the unix sockets on Linux
	if ( defined( $peers->{endpoints}{ $ids->{id} } ) ) {
		foreach my $peer_pid ( @{ $peers->{endpoints}{ $ids->{id} } } ) {
			if ( !defined( $seen{$peer_pid} ) ) {
				$seen{$peer_pid} = 1;
				push( @peer_pids, $peer_pid );
			}
		}
	}

	if ( !defined( $peer_pids[0] ) ) {
		# the far end was there to be had and is the process itself, so
		# there is nothing to say of it rather than anything to be said
		# about not getting at it
		if ($self_only) {
			return undef;
		}

		# A endpoint lsof points somewhere with is known to have a far end,
		# as is one held more than once, so say that it could not be
		# reached. Anything else may just be a FIFO or socket nothing else
		# has open, where there is nothing to say.
		if (
			   ( ( defined( $ids->{peer_id} ) ) && ( $ids->{peer_id} ne $ids->{id} ) )
			|| ( defined( $peers->{endpoint_known}{ $ids->{id} } ) )
			|| (   ( $file->{share_count} =~ /^[0-9]+$/ )
				&& ( $file->{share_count} > 1 ) )
			)
		{
			return '?';
		}
		return undef;
	} ## end if ( !defined( $peer_pids[0] ) )

	return $self->_commandGroups( \@peer_pids, $commands );
} ## end sub _peerCommands

#
# Gathers a list of PIDs up under the command each of them is running and
# renders it. Something like a shared memory object may be held by a great
# many processes, which for the most part are copies of each other, so
# they are grouped rather than printing the same command over and over.
# Both how many commands are printed and how many PIDs are printed for any
# one of them are capped via peer_max, as even grouped up it may be more
# than is worth reading through, with zero or less printing all of them.
#
sub _commandGroups {
	my $self     = $_[0];
	my $pids     = $_[1];
	my $commands = $_[2];

	my %groups;
	my @order;
	foreach my $pid ( sort { $a <=> $b } @{$pids} ) {
		my $command = $self->_peerCommandName( $pid, $commands, $self->{peer_command_length} );
		if ( !defined( $groups{$command} ) ) {
			$groups{$command} = [];
			push( @order, $command );
		}
		push( @{ $groups{$command} }, $pid );
	}

	my $more_commands = 0;
	if (   ( $self->{peer_max} > 0 )
		&& ( $#order >= $self->{peer_max} ) )
	{
		$more_commands = $#order + 1 - $self->{peer_max};
		@order         = @order[ 0 .. $self->{peer_max} - 1 ];
	}

	my @rendered;
	foreach my $command (@order) {
		my @group_pids = @{ $groups{$command} };

		my $more_pids = 0;
		if (   ( $self->{peer_max} > 0 )
			&& ( $#group_pids >= $self->{peer_max} ) )
		{
			$more_pids  = $#group_pids + 1 - $self->{peer_max};
			@group_pids = @group_pids[ 0 .. $self->{peer_max} - 1 ];
		}

		my $rendered = $command . '(' . join( ', ', @group_pids );
		if ( $more_pids > 0 ) {
			$rendered = $rendered . ', + ' . $more_pids . ' more';
		}
		push( @rendered, $rendered . ')' );
	} ## end foreach my $command (@order)

	my $toReturn = join( ', ', @rendered );
	if ( $more_commands > 0 ) {
		$toReturn = $toReturn . ', + ' . $more_commands . ' more';
	}

	return $toReturn;
} ## end sub _commandGroups

#
# Walks the pipe edges out from the PID, returning a array ref of the
# paths found, each of which includes the PID it started from. The seen
# hash ref is what keeps it from looping back around on itself.
#
sub _pipeWalk {
	my $self  = $_[0];
	my $edges = $_[1];
	my $pid   = $_[2];
	my $seen  = $_[3];

	my %new_seen = %{$seen};
	$new_seen{$pid} = 1;

	# A process may sit on either end of more than one pipe, so the number
	# of paths through a busy set of them can climb fast. Both how many
	# are gathered and how far they are followed are capped to keep that
	# from getting away.
	my @paths;
	if (   ( defined( $edges->{$pid} ) )
		&& ( keys(%new_seen) < $self->{pipe_chain_max_depth} ) )
	{
		foreach my $next ( sort keys %{ $edges->{$pid} } ) {
			if ( defined( $new_seen{$next} ) ) {
				next;
			}
			foreach my $path ( @{ $self->_pipeWalk( $edges, $next, \%new_seen ) } ) {
				push( @paths, [ $pid, @{$path} ] );
				if ( $#paths >= ( $self->{pipe_chain_max} - 1 ) ) {
					return \@paths;
				}
			}
		} ## end foreach my $next ( sort keys %{ $edges->{$pid} ...})
	} ## end if ( ( defined( $edges->{$pid} ) ) && ( keys...))

	# a dead end is still a path, just a single item one
	if ( !defined( $paths[0] ) ) {
		push( @paths, [$pid] );
	}

	return \@paths;
} ## end sub _pipeWalk

#
# Returns a array ref of what there is to say about the pipes a PID sits
# on, each being a hash ref with a type of chain, channel, or pipe.
#
# A pipe with one process writing and one reading is a plain link, the
# sort a shell makes when it strings two commands together, and those are
# followed out into the chains they form. Anything else, such as the pile
# a worker pool shares out, is left as the one pipe it is rather than
# being strung into a pipeline it is not.
#
sub _pipeChains {
	my $self = $_[0];
	my $pid  = $_[1];

	my $holders = $self->_pipeHolders;

	my %forward;
	my %backward;
	my @other_pipes;
	foreach my $key ( sort keys %{$holders} ) {
		my $writers = $self->_pipeEnd( $holders, $key, 'w' );
		my $readers = $self->_pipeEnd( $holders, $key, 'r' );

		# A plain link, which is what a pipeline is built out of. A pipe a
		# whole pool was forked holding has the one process that was given
		# it at either end, the rest being copies that came along with the
		# fork, but a log a pack of workers all write to really does have
		# every one of them on it, so each is a link of its own rather than
		# only the one pair being taken.
		if (   ( defined( $writers->{own}[0] ) )
			&& ( defined( $readers->{own}[0] ) ) )
		{
			my $linked = 0;
			foreach my $writer ( @{ $writers->{own} } ) {
				foreach my $reader ( @{ $readers->{own} } ) {
					# a process on both ends of the one pipe is talking to
					# itself, which is no link at all
					if ( $writer eq $reader ) {
						next;
					}
					$linked                     = 1;
					$forward{$writer}{$reader}  = 1;
					$backward{$reader}{$writer} = 1;
				} ## end foreach my $reader ( @{ $readers->{own} } )
			} ## end foreach my $writer ( @{ $writers->{own} } )
			if ($linked) {
				next;
			}
		} ## end if ( ( defined( $writers->{own}[0] ) ) && ...)

		# anything else only gets a line of its own when the process being
		# asked after is actually on it
		if (   ( defined( $holders->{$key}{w}{$pid} ) )
			|| ( defined( $holders->{$key}{r}{$pid} ) ) )
		{
			# A pipe a process made for itself, with nothing on either end of
			# it but the process itself, says nothing here beyond the same
			# command printed twice, and something like a browser holds a
			# pile of them. It is already there in the open files as the two
			# ends pointing at each other, so it is left to those.
			if ( !$self->_pipeIsSelfOnly( $holders, $key, $pid ) ) {
				push(
					@other_pipes,
					{
						type    => 'pipe',
						writers => $writers,
						readers => $readers,
					}
				);
			} ## end if ( !$self->_pipeIsSelfOnly( $holders, $key...))
		} ## end if ( ( defined( $holders->{$key}{w}{$pid} ...)))
	} ## end foreach my $key ( sort keys %{$holders} )

	# Two processes each running a pipe at the other are talking both ways,
	# which is the one channel between them rather than two pipelines that
	# happen to point opposite ways. Taking those out here rather than
	# reading them back off the chains keeps what is printed the same from
	# either end of one, a walk started from either side otherwise having
	# already been through the far end by the time it comes back around.
	my @channels;
	my %paired;
	foreach my $from ( sort keys %forward ) {
		foreach my $to ( sort keys %{ $forward{$from} } ) {
			if ( !defined( $forward{$to}{$from} ) ) {
				next;
			}

			my $pair_key = join( "\0", sort { $a <=> $b } ( $from, $to ) );
			if ( !defined( $paired{$pair_key} ) ) {
				$paired{$pair_key} = 1;

				# which way round it was found says nothing, a channel
				# running both ways, so the process being asked after leads
				# where it is one of the two
				my @channel = ( $from, $to );
				if ( $channel[1] eq $pid ) {
					@channel = ( $channel[1], $channel[0] );
				}

				# only the ones it is actually on are its to report
				if (   ( $from eq $pid )
					|| ( $to eq $pid ) )
				{
					push(
						@channels,
						{
							type => 'channel',
							pids => \@channel,
						}
					);
				} ## end if ( ( $from eq $pid ) || ( $to eq $pid ) )
			} ## end if ( !defined( $paired{$pair_key} ) )

			# both ways of it go, the pair being the one thing now, and
			# leaving either behind would have it printed over again as a
			# pipeline of its own
			delete( $forward{$from}{$to} );
			delete( $backward{$to}{$from} );
			delete( $forward{$to}{$from} );
			delete( $backward{$from}{$to} );
		} ## end foreach my $to ( sort keys %{ $forward{$from} })
	} ## end foreach my $from ( sort keys %forward )

	# whatever plain links are left over are followed out into the
	# pipelines they form
	my @chains;
	my %seen_chains;
	foreach my $head ( @{ $self->_pipeWalk( \%backward, $pid, {} ) } ) {
		# whatever the head took is spoken for, a process being in a
		# pipeline once rather than on both sides of itself
		my %head_seen;
		foreach my $head_pid ( @{$head} ) {
			$head_seen{$head_pid} = 1;
		}

		foreach my $tail ( @{ $self->_pipeWalk( \%forward, $pid, \%head_seen ) } ) {
			# both walks start from the PID, so the head is flipped around
			# and the duplicate copy of it dropped off of the tail
			my @chain = ( reverse( @{$head} ), @{$tail}[ 1 .. $#{$tail} ] );

			if ( $#chain < 1 ) {
				next;
			}
			my $key = join( ',', sort { $a <=> $b } @chain );
			if ( defined( $seen_chains{$key} ) ) {
				next;
			}
			$seen_chains{$key} = 1;
			push( @chains, \@chain );
		} ## end foreach my $tail ( @{ $self->_pipeWalk( \%forward...)})
	} ## end foreach my $head ( @{ $self->_pipeWalk( \%backward...)})

	my @toReturn = @channels;
	foreach my $chain (@chains) {
		push(
			@toReturn,
			{
				type => 'chain',
				pids => $chain,
			}
		);
	}

	push( @toReturn, @other_pipes );

	if ( $#toReturn >= $self->{pipe_chain_max} ) {
		@toReturn = @toReturn[ 0 .. $self->{pipe_chain_max} - 1 ];
	}

	return \@toReturn;
} ## end sub _pipeChains

#
# Renders the command used for a PID on the far end of a endpoint,
# truncating it to the length passed to it, which does not happen at all
# for a length of zero or less. A ? is used for any process that can't be
# looked up.
#
sub _peerCommandName {
	my $self     = $_[0];
	my $pid      = $_[1];
	my $commands = $_[2];
	my $length   = $_[3];

	my $command = '?';
	if ( defined( $commands->{$pid} ) ) {
		$command = $commands->{$pid};
	}

	if (   ( $length > 0 )
		&& ( length($command) > $length ) )
	{
		$command = substr( $command, 0, $length ) . '...';
	}

	return $command;
} ## end sub _peerCommandName

#
# The same as _peerCommandName for a PID in a pipe chain, which has a
# truncation length of its own, with the PID it belongs to tacked onto
# the end of it.
#
sub _peerCommand {
	my $self     = $_[0];
	my $pid      = $_[1];
	my $commands = $_[2];

	return $self->_peerCommandName( $pid, $commands, $self->{pipe_chain_command_length} ) . '(' . $pid . ')';
}

#
# Renders one PID in a pipe chain, picking the process being asked after
# out from the rest of them.
#
sub _pipeCommandString {
	my $self      = $_[0];
	my $chain_pid = $_[1];
	my $pid       = $_[2];
	my $commands  = $_[3];

	my $command = $self->_peerCommand( $chain_pid, $commands );

	if ( $chain_pid eq $pid ) {
		return color( $self->{processColor} ) . $command . color('reset');
	}

	return color( $self->{valColor} ) . $command . color('reset');
} ## end sub _pipeCommandString

#
# Renders one end of a pipe that is not a plain link, being whatever the
# pipe was made for followed by whatever only came by it through being
# forked off of one of those. A end with nothing on it at all, such as the
# read end of a pipe every reader has since gone away from, prints as a ?.
#
sub _pipeEndString {
	my $self     = $_[0];
	my $end      = $_[1];
	my $pid      = $_[2];
	my $commands = $_[3];

	my @parts;

	foreach my $end_pid ( @{ $end->{own} } ) {
		push( @parts, $self->_pipeCommandString( $end_pid, $pid, $commands ) );
	}

	if ( defined( $end->{inherited}[0] ) ) {
		my @inherited = @{ $end->{inherited} };

		# these are all but always the same command over again, the whole of
		# what sets them apart being which fork they are, so only the PIDs
		# are printed
		my $more = 0;
		if (   ( $self->{peer_max} > 0 )
			&& ( $#inherited >= $self->{peer_max} ) )
		{
			$more      = $#inherited + 1 - $self->{peer_max};
			@inherited = @inherited[ 0 .. $self->{peer_max} - 1 ];
		}

		my $rendered
			= color( $self->{varColor} ) . 'inherited(' . color( $self->{valColor} ) . join( ', ', @inherited );
		if ( $more > 0 ) {
			$rendered = $rendered . ', + ' . $more . ' more';
		}
		push( @parts, $rendered . color( $self->{varColor} ) . ')' . color('reset') );
	} ## end if ( defined( $end->{inherited}[0] ) )

	if ( !defined( $parts[0] ) ) {
		return color( $self->{valColor} ) . '?' . color('reset');
	}

	# the space is kept out of the color as per _pipeChainTable
	return join( color( $self->{valColor} ) . ',' . color('reset') . ' ', @parts );
} ## end sub _pipeEndString

#
# Builds the pipe chain table for a PID, returning a empty string if
# there is nothing worth showing.
#
sub _pipeChainTable {
	my $self     = $_[0];
	my $pid      = $_[1];
	my $commands = $_[2];

	my @rows;
	foreach my $item ( @{ $self->_pipeChains($pid) } ) {
		my $row;

		# The spaces around the joiners are kept out of the color they are
		# printed in, as a row wide enough to be wrapped has any space
		# sitting right in front of a color code eaten, which runs the
		# commands together with whatever is between them.
		if ( $item->{type} eq 'pipe' ) {
			$row
				= $self->_pipeEndString( $item->{writers}, $pid, $commands ) . ' '
				. color( $self->{varColor} ) . '|'
				. color('reset') . ' '
				. $self->_pipeEndString( $item->{readers}, $pid, $commands );
		} else {
			# a chain of just the process itself says nothing, which is what
			# is left over when the far end of every pipe is out of reach
			if ( $#{ $item->{pids} } < 1 ) {
				next;
			}

			my @parts;
			foreach my $chain_pid ( @{ $item->{pids} } ) {
				push( @parts, $self->_pipeCommandString( $chain_pid, $pid, $commands ) );
			}

			# a channel is the one pipe apiece either way between two
			# processes rather than a pipeline running through them
			my $joiner = '|';
			if ( $item->{type} eq 'channel' ) {
				$joiner = '<->';
			}

			$row = join( ' ' . color( $self->{varColor} ) . $joiner . color('reset') . ' ', @parts );
		} ## end else [ if ( $item->{type} eq 'pipe' ) ]

		push( @rows, [$row] );
	} ## end foreach my $item ( @{ $self->_pipeChains($pid) ...})

	if ( !defined( $rows[0] ) ) {
		return '';
	}

	my $ctb = Text::ANSITable->new;
	$ctb->border_style('Default::none_ascii');
	$ctb->color_theme('Default::no_color');
	$ctb->show_header(1);
	$ctb->set_column_style( 0, pad => 0 );
	$ctb->columns( [ color( $self->{varColor} ) . 'PIPE CHAINS' . color('reset') ] );
	$ctb->add_rows( \@rows );

	return $ctb->draw;
} ## end sub _pipeChainTable

=head2 timeString

Turns the raw run string into something usable.

=cut

sub timeString {
	my $self = $_[0];
	my $time = $_[1];

	if ( !defined($time) ) {
		$time = 0;
	}

	if ( $^O =~ /linux/ ) {
		$time = $time / 1000000;
	}

	# the fractional part is not wanted and % would quietly drop it anyways
	$time = int($time);

	my $hours   = int( $time / 3600 );
	my $minutes = int( ( $time % 3600 ) / 60 );
	my $seconds = $time % 60;

	#this will be returned
	my $toReturn = '';

	#process the hours bit
	if ( $hours == 0 ) {
		#don't do anything if time is 0
	} elsif ( $hours >= 10 ) {
		$toReturn = color( $self->{timeColors}->[3] ) . $hours . ':';
	} else {
		$toReturn = color( $self->{timeColors}->[2] ) . $hours . ':';
	}

	#process the minutes bit, zero padding it if it follows the hours
	if (   ( $hours > 0 )
		|| ( $minutes > 0 ) )
	{
		if ( $hours > 0 ) {
			$minutes = sprintf( '%02d', $minutes );
		}
		$toReturn = $toReturn . color( $self->{timeColors}->[1] ) . $minutes . ':';

		$seconds = sprintf( '%02d', $seconds );
	} ## end if ( ( $hours > 0 ) || ( $minutes > 0 ) )

	$toReturn = $toReturn . color( $self->{timeColors}->[0] ) . $seconds . color('reset');

	return $toReturn;
} ## end sub timeString

=head2 memString

Turns the raw run string into something usable.

=cut

sub memString {
	my $self = $_[0];
	my $mem  = $_[1];
	my $type = $_[2];

	if ( !defined($mem) ) {
		$mem = 0;
	}

	my $toReturn = '';

	if ( $mem < 10000 ) {
		$toReturn = color( $self->{ $type . 'Colors' }[0] ) . $mem;
	} elsif ( ( $mem >= 10000 )
		&& ( $mem < 1000000 ) )
	{
		$mem = $mem / 1000;
		$mem = sprintf( '%.3f', $mem );

		$toReturn = color( $self->{ $type . 'Colors' }[0] ) . $mem . color( $self->{ $type . 'Colors' }[3] ) . 'k';
	} elsif ( ( $mem >= 1000000 )
		&& ( $mem < 1000000000 ) )
	{
		$mem = ( $mem / 1000 ) / 1000;
		$mem = sprintf( '%.3f', $mem );
		my @mem_split = split( /\./, $mem );

		$toReturn
			= color( $self->{ $type . 'Colors' }[1] )
			. $mem_split[0] . '.'
			. color( $self->{ $type . 'Colors' }[0] )
			. $mem_split[1]
			. color( $self->{ $type . 'Colors' }[3] ) . 'M';
	} elsif ( $mem >= 1000000000 ) {
		$mem = ( ( $mem / 1000 ) / 1000 ) / 1000;
		$mem = sprintf( '%.3f', $mem );
		my @mem_split = split( /\./, $mem );

		$toReturn
			= color( $self->{ $type . 'Colors' }[2] )
			. $mem_split[0] . '.'
			. color( $self->{ $type . 'Colors' }[1] )
			. $mem_split[1]
			. color( $self->{ $type . 'Colors' }[3] ) . 'G';
	} ## end elsif ( $mem >= 1000000000 )

	return $toReturn . color('reset');
} ## end sub memString

=head2 startString

Generates a short time string based on the supplied unix time.

=cut

sub startString {
	my $self      = $_[0];
	my $startTime = $_[1];

	my ( $sec,  $min,  $hour,  $mday,  $mon,  $year,  $wday,  $yday,  $isdst )  = localtime($startTime);
	my ( $csec, $cmin, $chour, $cmday, $cmon, $cyear, $cwday, $cyday, $cisdst ) = localtime(time);

	#add the required stuff to make this sane
	$year  += 1900;
	$cyear += 1900;
	$mon   += 1;
	$cmon  += 1;

	#find the most common one and return it
	if ( $year != $cyear ) {
		return
			  $year
			. sprintf( '%02d', $mon )
			. sprintf( '%02d', $mday ) . '-'
			. sprintf( '%02d', $hour ) . ':'
			. sprintf( '%02d', $min );
	}
	if ( $mon != $cmon ) {
		return
			  sprintf( '%02d', $mon )
			. sprintf( '%02d', $mday ) . '-'
			. sprintf( '%02d', $hour ) . ':'
			. sprintf( '%02d', $min );
	}
	if ( $mday != $cmday ) {
		return sprintf( '%02d', $mday ) . '-' . sprintf( '%02d', $hour ) . ':' . sprintf( '%02d', $min );
	}

	#just return this for anything less
	return sprintf( '%02d', $hour ) . ':' . sprintf( '%02d', $min );
} ## end sub startString

=head1 SHARED MEMORY

The total size of the shared memory a process holds is shown with the
rest of the memory bits. A object held on more than one FD is counted the
once, the object being what takes up the memory rather than the handle
on it.

    Total SHM 1.076M

FreeBSD and the like hand these a SHM type of their own. Linux has no
such type, giving them the same REG every other file gets, so there they
are picked out by name instead.

    /dev/shm/*  POSIX objects, which live on a tmpfs
    /SYSV*      SysV segments, which are named after their key
    /memfd:*    the anonymous ones made by memfd_create

The TYPE column is whatever lsof called it either way, so these read as
REG on Linux rather than SHM.

Every one of them is deduped and has its peers looked up in the same
manner as any other, so what else holds a object is shown for it as per
L</peers> and the ones that print the same are rolled up as per
L</dont_dedup>.

=head1 JAILS

On FreeBSD, any process with a JID other than 0 has the jail it is in
looked up, showing the name of it with the number after it in the same
manner as the UID and GID.

    jid  test(1) test.example.org /jails/test

The hostname and path are only tacked on when they have anything to add,
the first being more often than not just the name over again and the
second nothing worth mentioning for a jail sharing the file system it was
started from. Just the number is shown for a jail that can not be looked
up, such as one that has gone away since the process table was read.

B<jail_info> adds a section with every parameter of the jail in it,
which is the lot of what jls reports for one.

    JAIL ARG      VALUE
    host.hostname test.example.org
    jid           1
    name          test
    path          /jails/test
    persist       true

The lookup takes a run of jls, which is only done for a process that is
in a jail, and only once per jail no matter how many PIDs are given.

=head1 CONTAINERS

Linux has no jails, shutting a process away with cgroups and namespaces
instead, so that is what is shown in their place there.

The cgroup a process is in is shown with the rest of its info, that being
what names the systemd unit or the container it belongs to. Nothing is
shown for one left sitting in the root cgroup it started in, such as a
kernel thread.

    Cgroup /system.slice/postgresql@17-main.service

Every namespace it does not share with PID 1 is shown as well, those
being what it has been shut away from the rest of the system in. A
process sharing the lot of them has nothing to say here.

    Namespaces mnt, net, pid, uts

When the cgroup names a container, the runtime that started it is shown
with the ID after it, in the same manner as the UID and GID. The long
hash a runtime hands a container is cut down to the first dozen
characters, which is how everything else prints them.

    Container docker(3f2a1b8c9d4e)

The runtimes below are the ones picked out. Anything else still has its
cgroup and namespaces shown, just with no name put to it.

    docker
    podman
    containerd
    crio
    lxc
    machine      systemd-nspawn and the like

=head2 CGROUP LIMITS

What the cgroup is using of what it is allowed is shown along with it,
each line being left off when it has nothing to say, be it a limit that
was never set or a controller that was never turned on for it.

    Cgroup mem      98.304k / 33.554M peak 33.554M
    Cgroup cpu      quota 0.1, used 26, throttled 2604 for 4:05
    Cgroup pids     1 / 50
    Cgroup events   oom_kill 1, oom 1, max 879
    Cgroup pressure cpu 74.00/77.31, memory 0.15/2.73

All of it covers the whole cgroup rather than the one process, so a unit
that started a dozen of them reports what the lot are using between
them. B<Cgroup mem> takes in the page cache on top of the anonymous
memory as well, so it is not the RSS over again and will read higher than
it for anything that has been through a pile of files.

The limit is only shown when there is one, B<memory.max> falling back to
the softer B<memory.high> with B<high> after it. B<Cgroup cpu> is only
shown for a cgroup that is either capped or being held back, the time it
has used saying no more than the process table already does otherwise,
and its quota is the share of a single core it works out to. B<Cgroup
events> and B<Cgroup pressure> only turn up when something actually
happened, everything sitting at zero having nothing to report.

None of it is read for a process in the root cgroup, which has nothing of
its own to report, nor for one whose cgroup can not be found under the
mount point, that being what a process in a cgroup namespace of its own
looks like from outside of it. Reading the root for one of those would
hand back the whole system's numbers as though they belonged to the
process.

Only the v2 hierarchy is read. A system still running v1 alone has its
cgroup paths shown as ever, just with none of this alongside them.

=head2 jail_info

B<jail_info> adds a section with every cgroup and namespace in it, the
ones not shared with PID 1 being called out, followed by the knobs of the
cgroup itself and what else is sitting in it.

    CONTAINER ARG           VALUE
    cgroup                  /piddler-test
    ns:mnt                  4026532643 private
    ns:net                  4026531833
    cgroup.controllers      cpuset cpu io memory pids
    cgroup.procs            1 sh -c while :; do :; done(369709)
    memory.current          90.112k
    memory.max              33.554M
    pids.max                50
    cpu.max                 10000 100000
    cpu.stat:nr_throttled   2829
    memory.events:oom_kill  1
    cpu.pressure:some       avg10=85.84 avg60=79.75 avg300=47.38

B<cgroup.procs> is everything sitting in the cgroup, gathered up under
the command each of them is running and capped in the same manner as the
peers of a endpoint, as per L</peer_max>. B<cgroup.controllers> is what
says why any of the rest are missing, a knob only being there for a
controller that was turned on.

The B<memory.stat> lines break B<memory.current> down into where it
actually went, which is what says how much of a cgroup is its own
anonymous memory and how much is page cache it has read through, the two
often being nothing alike.

    memory.current       40.747M
    memory.stat:anon     3.871M
    memory.stat:file     29.131M
    memory.stat:shmem    12.263M

There are a great many of these, so only the handful worth reading
through are printed, and only the ones with something in them at that.
B<memory.stat:shmem> is all the tmpfs and shared memory charged to the
cgroup, which is not the B<Total SHM> shown with the process info, that
being the shared memory objects the one process has open as per
L</SHARED MEMORY>.

All of it is read from /proc and the cgroup mount, so there is nothing to
run for it the way there is for a jail. The namespaces of a process
belonging to another user are kept from everyone but root, so those go
unshown when it is not root doing the asking.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-proc-processtable-piddler at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Proc-ProcessTable-piddler>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Proc::ProcessTable::piddler


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Proc-ProcessTable-piddler>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Proc-ProcessTable-piddler>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Proc-ProcessTable-piddler>

=item * Search CPAN

L<https://metacpan.org/release/Proc-ProcessTable-piddler>

=item * Repository

L<https://github.com/VVelox/Proc-ProcessTable-piddler>

=back


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2019 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1;    # End of Proc::ProcessTable::piddler
