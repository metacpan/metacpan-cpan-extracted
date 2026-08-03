package Proc::ProcessTable::InfoString;

use 5.006;
use strict;
use warnings;
use Term::ANSIColor;
use Exporter 'import';

our @EXPORT_OK = ( 'proc_infostring_describe' );

=head1 NAME

Proc::ProcessTable::InfoString - Creates a PS like stat string showing a symbolic representation of various flags/state as well as the wchan.

=head1 VERSION

Version 0.2.0

=cut

our $VERSION = '0.2.0';


=head1 SYNOPSIS

    use Proc::ProcessTable::InfoString;
    use Proc::ProcessTable;

    my $is = Proc::ProcessTable::InfoString->new();

    my $p = Proc::ProcessTable->new( 'cache_ttys' => 1 );
    my $pt = $p->table;

    foreach my $proc ( @{ $pt } ){
        print $proc->pid.' '.$is->info( $proc )."\n";
    }

The mapping for the left side of the output is as below.

   States  Description
   Z       Zombie
   S       Sleep
   W       Wait
   R       Run
   T       Stopped
   t       Tracing stop
   I       Idle
   L       Blocked on a kernel lock
   D       Uninterruptible sleep
   X       Dead
   K       Wakekill
   P       Parked
   ?       Unknown state

   Flags   Description
   O       Swapped Output
   E       Exiting
   s       Session Leader
   L       POSIX lock advisory
   +       has controlling terminal
   c       controlling tty is active
   X       traced by a debugger
   F       being forked

Flag support varies by OS, being limited by what L<Proc::ProcessTable>
reports there.

   OS                    Flags
   FreeBSD, MidnightBSD  O, E, s, L, +, c, F, X
   Linux, GNU/kFreeBSD   O, E, s, +, F, X
   OpenBSD               O, s, +
   NetBSD, DragonFly     s, +
   anything else         O

On NetBSD and DragonFly, both of which use a procfs based
implementation, L<Proc::ProcessTable> does not report a state, the
state field holding the wait channel instead, so the state always
shows as ?. Those two also do not report resident memory, so there is
no swapped out flag. OpenBSD for its part reports no wait channel.

L</proc_infostring_describe> returns the above as a printable
description tailored to the OS in question, meant for use in help
output.

    use Proc::ProcessTable::InfoString qw(proc_infostring_describe);

    print proc_infostring_describe();

=head1 METHODS

=head2 new

This initiates the object.

One argument is taken and that is an optional hash reference.

=head3 args hash

The values below are color names to be passed to the color function
of L<Term::ANSIColor>.

If a color is not specified, no ANSI color codes are used for that
section. When a color is used, that section of the string is
terminated by an ANSI color reset.

=head4 flags_color

The color to use for the flags section of the string.

=head4 wchan_color

The color to use for the wait channel section of the string.

=cut

sub new {
	my %args;
	if (defined($_[1])) {
		%args= %{$_[1]};
	}

	my $self = {
				};
	bless $self;

	my @args_feed=(
				   'flags_color',
				   'wchan_color',
				   );

	foreach my $feed ( @args_feed ){
		$self->{$feed}=$args{$feed};
	}

	return $self;
}

=head2 info

Creates the info string for a process.

One argument is taken and that is a L<Proc::ProcessTable::Process>
object, as found in the table returned by L<Proc::ProcessTable>.

If the passed value is undefined or not a Proc::ProcessTable::Process
object, an empty string is returned.

    print $proc->pid.' '.$is->info( $proc )."\n";

=cut

sub info {
	my $self=$_[0];
	my $proc=$_[1];

	# make sure we got the required bits for proceeding
	if (
		( ! defined( $proc ) ) ||
		( ref( $proc ) ne 'Proc::ProcessTable::Process' )
		){
		return '';
	}
	my %flags;
	$flags{is_session_leader}=0;
	$flags{is_being_forked}=0;
	$flags{working_on_exiting}=0;
	$flags{has_controlling_terminal}=0;
	$flags{controlling_tty_active}=0;
	$flags{traced_by_debugger}=0;
	$flags{is_stopped}=0;
	$flags{is_kern_proc}=0;
	$flags{posix_advisory_lock}=0;

	# the procfs based implementations, used on NetBSD, DragonFly, and FreeBSD
	# prior to 5, report the flags as a comma separated list of words instead
	# of as a number... those implementations also store the wait channel in
	# the state field, meaning there is no state to display for them
	my $flags_are_words=0;
	if ( defined( $proc->{flags} ) && ( $proc->{flags} =~ /[^0-9a-fA-FxX]/ ) ) {
		$flags_are_words=1;
	}
	my $state_is_wchan=0;

	# exact matches as gnukfreebsd would otherwise match freebsd, while
	# Proc::ProcessTable uses its Linux implementation there
	if (
		( $^O eq 'freebsd' ) ||
		( $^O eq 'midnightbsd' )
		) {
		if ( $flags_are_words ) {
			# ancient FreeBSD, using the procfs implementation, which only
			# knows about these two
			$state_is_wchan=1;
			if ( $proc->{flags} =~ /ctty/ ) {
				$flags{has_controlling_terminal}=1;
			}
			if ( $proc->{flags} =~ /sldr/ ) {
				$flags{is_session_leader}=1;
			}
		} else {
			my $proc_flags=0;
			if ( defined( $proc->{flags} ) ) {
				$proc_flags=hex( $proc->{flags} );
			}
			if ( ( $proc_flags & 0x00002 ) && ( $proc->ttynum != -1 ) ) {
				$flags{controlling_tty_active}=1;
			}
			if ( defined( $proc->sess ) && ( $proc->sess == $proc->pid ) ) {
				$flags{is_session_leader}=1;
			}
			if ( $proc_flags & 0x00010 ) {
				$flags{is_being_forked}=1;
			}
			if ( $proc_flags & 0x02000 ) {
				$flags{working_on_exiting}=1;
			}
			if ( $proc_flags & 0x00002 ) {
				$flags{has_controlling_terminal}=1;
			}
			if ( $proc_flags & 0x00004 ) {
				$flags{is_kern_proc}=1;
			}
			if ( $proc_flags & 0x00800 ) {
				$flags{traced_by_debugger}=1;
			}
			if ( $proc_flags & 0x00001 ) {
				$flags{posix_advisory_lock}=1;
			}
		}
	}

	# NetBSD and DragonFly both use a procfs based implementation, which
	# reports the flags as a comma separated list of words, of which only
	# ctty and sldr exist
	if (
		( $^O eq 'netbsd' ) ||
		( $^O eq 'dragonfly' )
		) {
		$state_is_wchan=1;
		if ( defined( $proc->{flags} ) ) {
			if ( $proc->{flags} =~ /ctty/ ) {
				$flags{has_controlling_terminal}=1;
			}
			if ( $proc->{flags} =~ /sldr/ ) {
				$flags{is_session_leader}=1;
			}
		}
	}

	# OpenBSD does not provide a flags field at all, so session leader and
	# having a controlling terminal are all that may be figured out
	if ( $^O eq 'openbsd' ) {
		if ( defined( $proc->{sess} ) && ( $proc->{sess} == $proc->pid ) ) {
			$flags{is_session_leader}=1;
		}
		# no tty is NODEV, which may show up as either -1 or as the same bits
		# read unsigned, depending on platform
		if (
			defined( $proc->{ttynum} ) &&
			( $proc->{ttynum} != -1 ) &&
			( $proc->{ttynum} != 0xffffffff )
			) {
			$flags{has_controlling_terminal}=1;
		}
	}

	# gnukfreebsd is Debian GNU/kFreeBSD, where Proc::ProcessTable uses its
	# Linux implementation
	if (
		( $^O eq 'linux' ) ||
		( $^O eq 'gnukfreebsd' )
		) {
		# on Linux the flags field is a plain decimal number, not a hex string
		my $proc_flags=$proc->flags;
		if ( defined( $proc->sess ) && ( $proc->sess == $proc->pid ) ) {
			$flags{is_session_leader}=1;
		}
		if ( $proc->ttynum != 0 ) {
			$flags{has_controlling_terminal}=1;
		}
		# PF_EXITING
		if ( $proc_flags & 0x00000004 ) {
			$flags{working_on_exiting}=1;
		}
		# PF_KTHREAD
		if ( $proc_flags & 0x00200000 ) {
			$flags{is_kern_proc}=1;
		}
		# PF_FORKNOEXEC, forked but has not yet called exec...
		# kernel threads never exec so it is meaningless noise for them
		if ( ( $proc_flags & 0x00000040 ) && ( !$flags{is_kern_proc} ) ) {
			$flags{is_being_forked}=1;
		}
		# hash access as the tracer field is not present in all Proc::ProcessTable versions
		if ( exists( $proc->{tracer} ) && defined( $proc->{tracer} ) && ( $proc->{tracer} != 0 ) ) {
			$flags{traced_by_debugger}=1;
		}
	}

	# hash access as Linux does not set the state field at all when it runs
	# into a state it does not recognize... lowercased as OpenBSD reports the
	# state in upper case
	my $state=$proc->{state};
	if ( !defined( $state ) ) {
		$state='';
	}
	$state=lc( $state );
	my $info=$state;
	if ( $state_is_wchan ) {
		# no state to map, the field holds the wait channel
		$info='?';
	} elsif (
		$info eq 'sleep'
		) {
		$info='S';
	} elsif (
			 $info eq 'zombie'
			 ) {
		$info='Z';
	} elsif (
			 $info eq 'wait'
			 ) {
		$info='W';
	} elsif (
			 $info eq 'run'
			 ) {
		$info='R';
	} elsif (
			 $info eq 'stop'
			 ) {
		$flags{is_stopped}=1;
		$info='T';
	} elsif (
			 $info eq 'idle'
			 ) {
		$info='I';
	} elsif (
			 $info eq 'lock'
			 ) {
		$info='L';
	} elsif (
			 $info eq 'defunct'
			 ) {
		$info='Z';
	} elsif (
			 $info eq 'uwait'
			 ) {
		$info='D';
	} elsif (
			 $info eq 'tracingstop'
			 ) {
		$flags{is_stopped}=1;
		$info='t';
	} elsif (
			 $info eq 'dead'
			 ) {
		$info='X';
	} elsif (
			 $info eq 'wakekill'
			 ) {
		$info='K';
	} elsif (
			 $info eq 'parked'
			 ) {
		$info='P';
	} else {
		$info='?';
	}

	#add initial color if needed
	if ( defined( $self->{flags_color} ) ){
		$info=color( $self->{flags_color} ).$info;
	}

	#checks if it is swapped out... hash access as the procfs based
	#implementations, NetBSD and DragonFly, do not provide a rss field
	if (
		( $state ne 'zombie' ) &&
		( $state ne 'defunct' ) &&
		( defined( $proc->{rss} ) ) &&
		( $proc->{rss} == 0 ) &&
		( $flags{is_kern_proc} == 0 )
		) {
		$info=$info.'O';
	}

	#handles the various flags
	if ( $flags{working_on_exiting} ) {
		$info=$info.'E';
	}
	if ( $flags{is_session_leader} ) {
		$info=$info.'s';
	}
	if ( $flags{posix_advisory_lock} ) {
		$info=$info.'L';
	}
	if ( $flags{has_controlling_terminal} ) {
		$info=$info.'+';
	}
	if ( $flags{controlling_tty_active} ) {
		$info=$info.'c';
	}
	if ( $flags{is_being_forked} ) {
		$info=$info.'F';
	}
	if ( $flags{traced_by_debugger} ) {
		$info=$info.'X';
	}

	# adds the initial color reset if needed
	if ( defined( $self->{flags_color} ) ){
		$info=$info.color( 'reset' );
	}
	$info=$info.' ';


	# adds the second color if needed
	if ( defined( $self->{wchan_color} ) ){
		$info=$info.color( $self->{wchan_color} );
	}

	# adds the wait channel
	if (
		( $^O eq 'linux' ) ||
		( $^O eq 'gnukfreebsd' )
		) {
		my $wchan='';
		if ( open( my $wchan_fh, '<', '/proc/'.$proc->pid.'/wchan' ) ) {
			$wchan=readline( $wchan_fh );
			# a bare 0 means no wait channel
			if ( ( ! defined( $wchan ) ) || ( $wchan eq '0' ) ) {
				$wchan='';
			}
			close( $wchan_fh );
		}
		$info=$info.$wchan;
	} else {
		# hash access as the wchan accessor croaks on platforms lacking the
		# field, such as OpenBSD... the procfs based implementations, NetBSD
		# and DragonFly, use nochan for a process that is not blocked
		if ( defined( $proc->{wchan} ) && ( $proc->{wchan} ne 'nochan' ) ) {
			$info=$info.$proc->{wchan};
		}
	}

	# adds the second color reset if needed
	if ( defined( $self->{wchan_color} ) ){
		$info=$info.color( 'reset' );
	}

	return $info;
}

=head1 FUNCTIONS

=head2 proc_infostring_describe

Returns a human readable description of what the various parts of the
info string mean. Meant for use by programs wanting to print a
explanation of the info string as part of their help output.

This is a plain function and does not require calling L</new> first. It
may be optionally imported.

    use Proc::ProcessTable::InfoString qw(proc_infostring_describe);

    print proc_infostring_describe();

Or called without importing it.

    print Proc::ProcessTable::InfoString::proc_infostring_describe();

The states and flags described are the ones this module is able to
figure out for the OS in question, so what is printed for FreeBSD
differs from what is printed for Linux, OpenBSD, NetBSD, or DragonFly.

=head3 args

Args are taken as a plain hash.

=head4 os

The OS to describe the info string for. If not specified, the OS perl
is currently running on, $^O, is used.

    print proc_infostring_describe( os => 'linux' );

=cut

sub proc_infostring_describe {
	my %args= @_;

	my $os=$args{os};
	if ( ! defined( $os ) ) {
		$os=$^O;
	}

	# every state and flag this module knows how to produce, in the order
	# they appear in the info string
	my @all_states=(
					[ 'S', 'sleep' ],
					[ 'R', 'run' ],
					[ 'I', 'idle' ],
					[ 'W', 'wait' ],
					[ 'D', 'uninterruptible sleep' ],
					[ 'L', 'blocked on a kernel lock' ],
					[ 'T', 'stopped, such as via SIGSTOP' ],
					[ 't', 'stopped by a tracer, such as a debugger' ],
					[ 'Z', 'zombie, has exited and is waiting on its parent to reap it' ],
					[ 'X', 'dead' ],
					[ 'K', 'wakekill' ],
					[ 'P', 'parked' ],
					[ '?', 'unknown state' ],
					);
	my @all_flags=(
				   [ 'O', 'swapped out, has no resident memory' ],
				   [ 'E', 'exiting' ],
				   [ 's', 'session leader' ],
				   [ 'L', 'holds a POSIX advisory lock' ],
				   [ '+', 'has a controlling terminal' ],
				   [ 'c', 'the controlling tty is active' ],
				   [ 'F', 'forked, but has not called exec yet' ],
				   [ 'X', 'traced by a debugger' ],
				   );

	# which of those are actually usable is decided by what
	# L<Proc::ProcessTable> is able to report for the OS in question
	# exact matches as gnukfreebsd would otherwise match freebsd, while it is
	# Debian GNU/kFreeBSD, where Proc::ProcessTable uses its Linux
	# implementation
	my @wanted_states;
	my @wanted_flags;
	if (
		( $os eq 'freebsd' ) ||
		( $os eq 'midnightbsd' )
		) {
		@wanted_states=( 'S', 'R', 'I', 'W', 'L', 'T', 'Z', '?' );
		@wanted_flags=( 'O', 'E', 's', 'L', '+', 'c', 'F', 'X' );
	} elsif (
			 ( $os eq 'linux' ) ||
			 ( $os eq 'gnukfreebsd' )
			 ) {
		@wanted_states=( 'S', 'R', 'I', 'W', 'D', 'T', 't', 'Z', 'X', 'K', 'P', '?' );
		@wanted_flags=( 'O', 'E', 's', '+', 'F', 'X' );
	} elsif ( $os eq 'openbsd' ) {
		@wanted_states=( 'S', 'R', 'I', 'T', 'Z', '?' );
		@wanted_flags=( 'O', 's', '+' );
	} elsif (
			 ( $os eq 'netbsd' ) ||
			 ( $os eq 'dragonfly' )
			 ) {
		@wanted_states=( '?' );
		@wanted_flags=( 's', '+' );
	} else {
		# a OS with no flag handling of its own, so everything is listed
		# as there is no telling what it reports
		@wanted_states=map( { $_->[0] } @all_states );
		@wanted_flags=( 'O' );
	}

	# OpenBSD is the one OS here with no wait channel to show
	my $has_wchan=1;
	if ( $os eq 'openbsd' ) {
		$has_wchan=0;
	}

	my $described="Info string for ".$os.", formed as below.\n"
		."\n"
		."    <state>[flags]";
	if ( $has_wchan ) {
		$described=$described." [wait channel]";
	}
	$described=$described."\n"
		."\n"
		."States\n";
	foreach my $state ( @all_states ) {
		if ( grep( { $_ eq $state->[0] } @wanted_states ) ) {
			$described=$described.sprintf( "   %-4s%s\n", $state->[0], $state->[1] );
		}
	}

	$described=$described."\n"
		."Flags\n";
	foreach my $flag ( @all_flags ) {
		if ( grep( { $_ eq $flag->[0] } @wanted_flags ) ) {
			$described=$described.sprintf( "   %-4s%s\n", $flag->[0], $flag->[1] );
		}
	}

	if ( $has_wchan ) {
		$described=$described."\n"
			."Wait Channel\n"
			."   The kernel function or resource the process is currently blocked on,\n"
			."   blank when it is not blocked.\n";
	}

	return $described;
}

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-proc-processtable-infostring at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Proc-ProcessTable-InfoString>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Proc::ProcessTable::InfoString


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Proc-ProcessTable-InfoString>

=item * Search CPAN

L<https://metacpan.org/release/Proc-ProcessTable-InfoString>

=back


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2019 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Proc::ProcessTable::InfoString
