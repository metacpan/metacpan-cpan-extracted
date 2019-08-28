package Proc::ProcessTable::InfoString;

use 5.006;
use strict;
use warnings;
use Term::ANSIColor;

=head1 NAME

Proc::ProcessTable::InfoString - Greats a PS like stat string showing various symbolic represenation of various flags/state as well as the wchan.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

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

   Flags   Description
   O       Swapped Output
   E       Exiting
   s       Session Leader
   L       POSIX lock advisory
   +       has controlling terminal
   X       traced by a debugger
   F       being forked

=head1 METHODS

=head2 new

This initiates the object.

One argument is taken and that is a optional hash reference.

=head3 args hash

This will be passed to L<Term::ANSIColor>.

If not specified, no ANSI color codes are used.

The return string is terminated by a ANSI color reset character.

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
	$flags{is_locked}=0;
	$flags{traced_by_debugger}=0;
	$flags{is_stopped}=0;
	$flags{is_kern_proc}=0;
	$flags{posix_advisory_lock}=0;

	if ( $^O =~ /freebsd/ ) {
		if ( hex($proc->flags) & 0x00002 ) {
			$flags{controlling_tty_active}=1;
		}
		if ( hex($proc->flags) & 0x00000002 ) {
			$flags{is_session_leader}=1;
		}
		#if ( hex($proc->flags) &  ){$flags{is_being_forked}=1; }
		if ( hex($proc->flags) & 0x02000 ) {
			$flags{working_on_exiting}=1;
		}
		if ( hex($proc->flags) & 0x00002 ) {
			$flags{has_controlling_terminal}=1;
		}
		if ( hex($proc->flags) & 0x00000004 ) {
			$flags{is_locked}=1;
		}
		if ( hex($proc->flags) & 0x00800 ) {
			$flags{traced_by_debugger}=1;
		}
		if ( hex($proc->flags) & 0x00001 ) {
			$flags{posix_advisory_lock}=1;
		}
	}

	my $info=$proc->{state};
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
	}

	#add initial color if needed
	if ( defined( $self->{flags_color} ) ){
		$info=color( $self->{flags_color} ).$info;
	}

	#checks if it is swapped out
	if (
		( $proc->{state} ne 'zombie' ) &&
		( $proc->{rss} == '0' ) &&
		( $flags{is_kern_proc} == '0' )
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
	if ( $flags{is_locked} || $flags{posix_advisory_lock} ) {
		$info=$info.'L';
	}
	if ( $flags{has_controlling_terminal} ) {
		$info=$info.'+';
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
		if ( -e '/proc/'.$proc->{pid}.'/wchan') {
			open( my $wchan_fh, '<', '/proc/'.$proc->{pid}.'/wchan' );
			$wchan=readline( $wchan_fh );
			close( $wchan_fh );
		}
		$info=$info.$wchan;
	} else {
		$info=$info.$proc->{wchan};
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

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Proc-ProcessTable-InfoString>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Proc-ProcessTable-InfoString>

=item * Search CPAN

L<https://metacpan.org/release/Proc-ProcessTable-InfoString>

=item * Repository

L<https://gitea.eesdp.org/vvelox/Proc-ProcessTable-InfoString>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2019 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Proc::ProcessTable::InfoString
