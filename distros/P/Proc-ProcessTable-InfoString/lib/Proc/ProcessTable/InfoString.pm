package Proc::ProcessTable::InfoString;

use 5.006;
use strict;
use warnings;
use Term::ANSIColor;

=head1 NAME

Proc::ProcessTable::InfoString - Creates a PS like stat string showing a symbolic representation of various flags/state as well as the wchan.

=head1 VERSION

Version 0.1.0

=cut

our $VERSION = '0.1.0';


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

Flag support varies by OS. FreeBSD has the fullest support. On Linux
the flags E, s, +, F, and X are supported. On other platforms only
the state and wait channel are shown.

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

	if ( $^O =~ /freebsd/ ) {
		my $proc_flags=hex( $proc->flags );
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

	if ( $^O =~ /linux/ ) {
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

	my $state=$proc->state;
	if ( !defined( $state ) ) {
		$state='';
	}
	my $info=$state;
	if (
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

	#checks if it is swapped out
	if (
		( $state ne 'zombie' ) &&
		( $state ne 'defunct' ) &&
		( $proc->rss == 0 ) &&
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
	if ( $^O =~ /linux/ ) {
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
		# hash access as the wchan accessor croaks on platforms lacking the field
		if ( defined( $proc->{wchan} ) ) {
			$info=$info.$proc->{wchan};
		}
	}

	# adds the second color reset if needed
	if ( defined( $self->{wchan_color} ) ){
		$info=$info.color( 'reset' );
	}

	return $info;
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
