#  File: Stem/Proc.pm

#  This file is part of Stem.
#  Copyright (C) 1999, 2000, 2001 Stem Systems, Inc.

#  Stem is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.

#  Stem is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.

#  You should have received a copy of the GNU General Public License
#  along with Stem; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

#  For a license to use the Stem under conditions other than those
#  described here, to purchase support for this software, or to purchase a
#  commercial warranty contract, please contact Stem Systems at:

#       Stem Systems, Inc.		781-643-7504
#  	79 Everett St.			info@stemsystems.com
#  	Arlington, MA 02474
#  	USA

package Stem::Proc ;

use Carp qw( cluck ) ;

use strict ;

use Stem::Trace 'log' => 'stem_status', 'sub' => 'TraceStatus' ;
use Stem::Trace 'log' => 'stem_error' , 'sub' => 'TraceError' ;

use IO::Socket ;
use Symbol ;
use Carp ;
use POSIX qw( :sys_wait_h ) ;
use constant EXEC_ERROR	=> 199 ;

use Stem::Route qw( :cell ) ;

use base 'Stem::Cell' ;

my %pid_to_obj ;

my $child_event = Stem::Event::Signal->new(
	'object' => bless({}),
	'signal' => 'CHLD'
) ;

ref $child_event or return
	"Stem::Proc can't create SIG_CHLD handler: $child_event\n" ;

my $attr_spec = [


###############
# if you pass in an optional object, then that will be the base for
# all the callback methods. the message and log options will not be
# done as they work only using the callbacks internal to Stem::Proc.
###############

	{
		'name'		=> 'reg_name',
		'help'		=> <<HELP,
This is the name under which this Cell was registered.
HELP
	},
	{
		'name'		=> 'object',
		'type'		=> 'object',
		'help'		=> <<HELP,
This is the owner object for this Cell and it will get the callbacks.
HELP
	},
	{
		'name'		=> 'path',
		'required'	=> 1,
		'help'		=> <<HELP,
This is the path to the program to run.
HELP
	},
	{
		'name'		=> 'proc_args',
		'default'	=> [],
		'type'		=> 'list',
		'help'		=> <<HELP,
This is a list of the arguments to the program to be run.
HELP
	},
	{
		'name'		=> 'spawn_now',
		'type'		=> 'boolean',
		'help'		=> <<HELP,
This flag means to spawn the process at constructor time. Default is to 
spawn it when triggered via a message. 
HELP
	},
	{
		'name'		=> 'no_io',
		'type'		=> 'boolean',
		'help'		=> <<HELP,
This flag means the process will do no standard I/O and those pipes will
not be created.
HELP
	},
	{
		'name'		=> 'no_read',
		'type'		=> 'boolean',
		'help'		=> <<HELP,
This flag means the Cell will not read from the process and that pipe
will not be created. (unsupported)
HELP
	},
	{
		'name'		=> 'no_write',
		'type'		=> 'boolean',
		'help'		=> <<HELP,
This flag means the Cell will not write to the process and that pipe
will not be created. (unsupported)
HELP
	},
	{
		'name'		=> 'use_stderr',
		'type'		=> 'boolean',
		'help'		=> <<HELP,
This flag means the Cell will read from the stderr handle of the process.
By default the stderr pipe is not created and its output comes in on stdout.
HELP
	},

	{
		'name'		=> 'use_pty',
		'type'		=> 'boolean',
		'help'		=> <<HELP,
This flag will cause the process to be run behind a pseudo-tty device.
HELP
	},
	{
		'name'		=> 'exited_method',
		'default'	=> 'proc_ended',
		'help'		=> <<HELP,
This method is called on the owner object when the process exits.
HELP
	},
	{
		'name'		=> 'cell_attr',
		'class'		=> 'Stem::Cell',
		'help'		=> <<HELP,
This value is the attributes for the included Stem::Cell which handles
cloning, async I/O and pipes.
HELP
	},
] ;


sub new {

	my( $class ) = shift ;

	my $self = Stem::Class::parse_args( $attr_spec, @_ ) ;
	return $self unless ref $self ;


	my $err = $self->find_exec_path() ;
	return $err if $err ;

	$self->{ 'use_stderr' } = 0 if $self->{ 'use_pty' } ;

	$err = $self->cell_set_args(
			'path'		=> $self->{'path'},
			'proc_args'	=> $self->{'proc_args'},
	) ;

	return $err if $err ;

	$self->cell_set_args( 'no_async' => 1 ) if  $self->{ 'no_io' } ;

###########
# cloneable and spawn_now should be mutually exclusive
##########

	if ( $self->{'spawn_now'} ) {

TraceStatus "New Spawn" ;

		my $err = $self->cell_trigger();
		return $err unless ref $err ;

		$err = $self->spawn() ;
		return $err if $err ;
	}

	return $self ;
}


sub find_exec_path {

	my( $self ) = shift ;

	my $proc_path = $self->{'path'} ;

	return if -x $proc_path ;

	foreach my $path ( File::Spec->path() ) {

		my $exec_path = File::Spec->catfile( $path, $proc_path ) ; 

		next unless -f $exec_path ;

		if ( -x $exec_path ) {

			$self->{'path'} = $exec_path ;
			return ;
		}
	}

	return "$self->{'path'} is not found in $ENV{PATH}" ;
}

sub triggered_cell {

	my( $self ) = @_ ;

	my $err = $self->spawn() ;
	return $err if $err ;

#use Data::Dumper ;
#print Dumper \%INC ;

#print $self->status_cmd() ;

	return ;
}


sub spawn {

	my( $self ) = @_ ;

	unless( $self->{'no_io'} ) {

		$self->_parent_io() ;
	}

	$self->{'ppid'} = $$ ;	

	my @exec_args = @{$self->{'proc_args'}} ;

	if ( my $pipe_args_ref = $self->cell_get_args( 'args' ) ) {

		push( @exec_args, (ref $pipe_args_ref) ?
				@{$pipe_args_ref} : $pipe_args_ref ) ;
	}

	my $pid = fork() ;
	defined $pid or die "Stem::Proc can't fork $!" ;

	if ( $pid ) {

# in parent

# must close the child fh in the parent so we will see a closed socket
# when the child exits

		unless( $self->{'no_io'} ) {

			close $self->{'child_fh'} ;
			close $self->{'child_err_fh'} if $self->{'use_stderr'} ;

			delete( $self->{'child_fh'} ) ;
			delete( $self->{'child_err_fh'} ) ;
		}

		TraceStatus "forked $pid" ;

		$self->{'pid'} = $pid ;	
		$pid_to_obj{ $pid } = $self ;

		$self->cell_set_args( 'info' => <<INFO ) ;

Path:	$self->{'path'}
Args:	@exec_args
Pid:	$pid

INFO


	}
	else {

# in child
		unless( $self->{'no_io'} ) {

			$self->_child_io() ;
		}

###############
###############
## add support for setting local(%ENV)
###############
###############

#TraceStatus "Exec'ing $self->{'path'}, @exec_args" ;

		exec $self->{'path'}, @exec_args ;

		exit EXEC_ERROR ;
	}

# back in parent (unless no exec -- FIX THAT!! unless path is
# required) we could do a forked stem hub by execing stem with a new
# config which has a portal with STDIN/STDOUT as fh's

	my $err = $self->cell_set_args( 'aio_args' => [
			'read_fh'	=> $self->{'parent_fh'},
			'write_fh'	=> $self->{'parent_fh'},
			'stderr_fh'	=> $self->{'parent_err_fh'},
			'closed_method'	=> $self->{'exited_method'},
		]
	) ;

	return $err if $err ;

	$self->cell_worker_ready() ;

	return ;
}


sub _parent_io {

	my( $self ) = @_ ;

	my( $parent_fh, $child_fh ) ;


	if ( $self->{'use_pty'} ) {

		require IO::Pty ;
		$parent_fh = IO::Pty->new() ;
		$child_fh = $parent_fh->slave() ;
	}
	else {

		$parent_fh = gensym ;
		$child_fh = gensym ;

		socketpair( $parent_fh, $child_fh,
				 AF_UNIX, SOCK_STREAM, PF_UNSPEC ) ||
					die "can't make socket pair $!" ;
	}

	bless $parent_fh, 'IO::Socket' ;

	$self->{'parent_fh'} = $parent_fh ;

	$parent_fh->blocking( 0 ) ;

	$self->{'child_fh'} = $child_fh ;

#############
# add pty support here
#############

	if ( $self->{'use_stderr'} ) {

		my $parent_err_fh = gensym ;
		my $child_err_fh = gensym ;

		socketpair( $parent_err_fh, $child_err_fh,
				 AF_UNIX, SOCK_STREAM, PF_UNSPEC ) ||
				die "can't make socket pair $!" ;

		$self->{'parent_err_fh'} = $parent_err_fh ;
		$self->{'child_err_fh'} = $child_err_fh ;
	}
}

sub _child_io {

	my( $self ) = @_ ;

	close $self->{'parent_fh'} ;
	close $self->{'parent_err_fh'} if $self->{'use_stderr'} ;

	my $child_fd = fileno( $self->{'child_fh'} ) ;

	open( \*STDIN,  "<&$child_fd" ) ||
				croak "dup open of STDIN failed $!" ;

	open( \*STDOUT, ">&$child_fd" ) ||
				croak "dup open of STDOUT failed $!" ;

	if ( $self->{'use_stderr'} ) {

		my $child_err_fd = fileno( $self->{'child_err_fh'} ) ;

		open( \*STDERR,  ">&$child_err_fd" ) ||
				croak "dup open of STDERR failed $!" ;

	}
	else {
		open( \*STDERR,  ">&$child_fd" ) ||
				croak "dup open of STDERR failed $!" ;
	}
}

sub write {

	my( $self, $data ) = @_ ;

	$self->cell_write( $data ) ;
}


sub read_fh {

	$_[0]->{'parent_fh'} ;
}

sub write_fh {

	$_[0]->{'parent_fh'} ;
}

sub stderr_fh {

	$_[0]->{'parent_err_fh'} ;
}

sub proc_ended {

	my( $self ) = @_ ;

#print "PROC ended, shutting down\n" ;

	$self->shut_down() ;
}

sub signal_cmd {

	my( $self, $msg ) = @_ ;

	my $data = $msg->data() ;

	return unless ref $data eq 'SCALAR' ;

	my $signal = ${$data} ;

	$self->signal( $signal ) ;

	return ;
}

sub signal {

	my( $self, $signal ) = @_ ;

	$signal ||= 'SIGTERM' ;

	TraceStatus "$self->{'pid'} received SIGTERM" ;

	kill $signal, $self->{'pid'} ;
}

sub sig_chld_handler {

	while ( 1 ) {

		my $child_pid = waitpid( -1, WNOHANG ) ;

		return if $child_pid == 0 || $child_pid == -1 ;

		my $proc_status = $? ;

		my ( $exit_code, $exit_signal ) ;

		if ( WIFEXITED( $proc_status ) ) {

			$exit_code = WEXITSTATUS( $proc_status ) ;

			TraceStatus "EXIT: $exit_code" ;

		}
		else {
			$exit_signal = WTERMSIG( $proc_status ) ;

			TraceStatus "EXIT signal: $exit_signal" ;

		}

#print "EXIT CODE [$exit_code]\n" ;

		if ( my $self = $pid_to_obj{ $child_pid } ) {

			$self->{'exit_code'} = $exit_code ;
			$self->{'exit_signal'} = $exit_signal ;

			if ( defined( $exit_code ) &&
			     $exit_code == EXEC_ERROR ) {

				print <<ERR ;
Stem::Proc exec failed on path '$self->{'path'}'
ERR

			}

			$self->exited() ;
		}
		else {
#### ERROR
print "reaped unknown process pid $child_pid\n"
		}

	}
}

sub exited {

	my( $self ) = @_ ;

######################
# handle watchdog here
######################

	$self->{'exited'} = 1 ;

#print "EXITED\n" ;

	$self->shut_down() if $self->{'no_io'} ;

	TraceStatus "Proc $self->{'pid'} exited" ;
}


sub shut_down {

	my( $self ) = @_ ;

#print "PROC SHUT\n" ;

	unless( $self->{'exited'} ) {

		kill 'SIGTERM', $self->{'pid'} ;

		TraceStatus "kill of proc $self->{'pid'}" ;
	}

	return if $self->{'no_io'} ;

	if ( my $pid = $self->{'pid'} ) {

		delete( $pid_to_obj{ $pid } ) ;
	}

	$self->cell_shut_down() ;

	close $self->{'parent_fh'} ;
	close $self->{'parent_err_fh'} if $self->{'use_stderr'} ;
}

1 ;
