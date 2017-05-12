#  File: Stem/Boot.pm

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

package Stem::Boot ;

use strict ;
use Carp ;
use Symbol ;

my $attr_spec = [

	{
		'name'		=> 'reg_name',
		'help'		=> <<HELP,
This is the name under which this Cell was registered.
HELP
	},
	{
		'name'		=> 'boot_file',
		'required'	=> 1,
		'help'		=> <<HELP,
This is the file that describes the processes to bootstrap
HELP
	},
	{
		'name'		=> 'name',
		'help'		=> <<HELP,
Name of this boot entry
HELP
	},
	{
		'name'		=> 'cmd',
		'help'		=> <<HELP,
Path to command that will be booted
HELP
	},
	{
		'name'		=> 'log',
		'help'		=> <<HELP,
Default Name of logical log to send all status and process output
HELP
	},
	{
		'name'		=> 'delay',
		'help'		=> <<HELP,
Default delay (in seconds) between spawning processes
HELP
	},
	{
		'name'		=> 'user',
		'help'		=> <<HELP,
Default user id to run the processes
HELP
	},
	{
		'name'		=> 'wrap',
		'default'	=> '/bin/sh -c',
		'help'		=> <<HELP,
Default command wrapper for each process
HELP
	},
	{
		'name'		=> 'chdir',
		'help'		=> <<HELP,
Default dir to chdir to before running each process
HELP
	},
	{
		'name'		=> 'boot_now',
		'type'		=> 'boolean',
		'default'	=> 1,
		'help'		=> <<HELP,
Boot this program when this object is created
HELP
	},
	{
		'name'		=> 'restart',
		'help'		=> <<HELP,
Restart this program when it exits
HELP
	},
] ;

my %name2boot ;


sub new {

	my( $class ) = shift ;

	my $self = Stem::Class::parse_args( $attr_spec, @_ ) ;
	return $self unless ref $self ;

	my $boot_info = Stem::Util::load_file( $self->{'boot_file'} ) ;
	return $boot_info unless ref $boot_info ;

	foreach my $boot ( @{$boot_info} ) {

		die "boot entry is not a hash\n" unless ref $boot eq 'HASH' ;

		if ( my $skip = $boot->{'skip'} ) {

			next if lc $skip eq 'yes' ;
		}

		my $boot_obj = Stem::Class::parse_args( $attr_spec,
					%{$self},
					%{$boot}
		) ;

		die "boot entry error: $boot_obj\n" unless ref $boot_obj ;

		my $cmd = $boot_obj->{'cmd'} ;
		die "boot entry is missing 'cmd'\n" unless $cmd ;

		my $name = $boot_obj->{'name'} ;
		die "boot entry is missing 'name'\n" unless $name ;

		$name2boot{ $name } = $boot_obj ;

		if ( $boot_obj->{'boot_now'} ) {

			$boot_obj->run_cmd() ;
		}
	}

	return ;
}


sub run_cmd {

	my( $self ) = @_ ;

#print Store $self ;

	my $cmd ;

	if ( my $user = $self->{'user'} ) {

		if ( getpwuid($<) ne $user ) {

			$cmd .= "su - $user ; " ;
		}
	}

	if ( my $wrap = $self->{'wrap'} ) {

		$cmd .= qq{$wrap "} ;
		$self->{'wrap_end'} ||= '"' ;
	}

	if ( my $chdir = $self->{'chdir'} ) {

		$cmd .= "cd $chdir ; " ;
	}

	if ( my $stem_env = $self->{'stem_env'} ) {

		my $cmd_env = join ' ', map(
				"$_='$stem_env->{$_}'", keys %{$stem_env} ) ;

		$cmd =~ s/run_stem/run_stem $cmd_env/ ;
	}

	$cmd .= $self->{'cmd'} ;

	$cmd .= $self->{'wrap_end'} if $self->{'wrap_end'} ;

	my $handle = gensym ;

#print "$cmd\n" ;

	if ( my $pid = open( $handle, '-|' ) ) {

#print "pid $pid\n" ;
		$self->{'pid'} = $pid ;
		$self->{'handle'} = $handle ;
	}
	elsif ( defined( $pid ) ) {

		local( %ENV ) = ( %ENV, %{ $self->{'env'} || {} } ) ;

		open( STDERR, '>&STDOUT' ) ;

		exec $cmd ;
		die "Couldn't exec [$cmd]\n" ;
	}
	else {

		die "couldn't fork\n" ;
	}

	my $aio = Stem::AsyncIO->new(

			'object'	=> $self,
			'read_fh'	=> $handle,
			'read_method'	=> 'boot_read',
			'closed_method'	=> 'boot_closed',
	) ;

	$self->{'aio'} = $aio ;

	if ( my $log = $self->{'log'} ) {

		Stem::Log::Entry->new(
			'logs'	=> $log,
			'label'	=> 'boot',
			'text'	=>
			"Booting $self->{'name'} PID = $self->{'pid'}: $cmd\n",
		) ;
	}

	return ;
}

sub boot_read {

	my( $self, $data ) = @_ ;

#print "BOOT READ [$$data]\n" ;

	if ( my $log = $self->{'log'} ) {

		Stem::Log::Entry->new(
			'logs'	=> $log,
			'label'	=> 'boot',
			'text'	=> "Output for $self->{'name'}\n[${$data}]\n",
		) ;
	}

	return ;
}

sub boot_closed {

	my( $self ) = @_ ;

#print "BOOT closed\n" ;

	$self->{'aio'}->shut_down() ;
	delete $self->{'aio'} ;

	my $boot_pid = $self->{'pid'} ;
	my $pid = waitpid( $boot_pid, 0 ) ;

#print "WAIT [$pid]\n" ;

	if ( my $log = $self->{'log'} ) {

		Stem::Log::Entry->new(
			'logs'	=> $log,
			'label'	=> 'boot',
			'text'	=> "Boot $self->{'name'} exited PID = $pid",
		) ;
	}

# do restart if needed




	return ;
}

1 ;
