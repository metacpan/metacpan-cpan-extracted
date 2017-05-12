#  File: Stem/Log/Tail.pm

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

package Stem::Log::Tail ;

use strict ;
use IO::Seekable ;
use Data::Dumper ;

use Stem::Trace 'log' => 'stem_status', 'sub' => 'TraceStatus' ;
use Stem::Trace 'log' => 'stem_error' , 'sub' => 'TraceError' ;

my $attr_spec = [

	{
		'name'		=> 'path',
		'required'	=> 1,
		'help'		=> <<HELP,
This is the full path to the file we want to tail.
HELP
	},

	{
		'name'		=> 'data_log',
		'required'	=> 1,
		'help'		=> <<HELP,
This is the log which gets sent the data log entries.
HELP
	},

	{
		'name'		=> 'status_log',
		'help'		=> <<HELP,
This is the log which gets sent the status log entries.
These include things like: Log has been rotated, deleted, moved, etc...
HELP
	},
	{
		'name'		=> 'label',
		'default'	=> 'tail',
		'help'		=> <<HELP,
Label to tag tailed log entry.
HELP
	},
	{
		'name'		=> 'level',
		'default'	=> '5',
		'help'		=> <<HELP,
Severity level for this tailed log entry.
HELP
	},
	{
		'name'		=> 'interval',
		'help'		=> <<HELP,
This specifies (in seconds) how often we check the log file for new
data.  If this is not specified, you need to call the tail_cmd method
to check for new data.
HELP
	},
	{
		'name'		=> 'delay',
		'default'	=> 10,
		'help'		=> <<HELP,
This specifies (in seconds) how long the delay is before the
first repeated checking of the log file for new data.
HELP
	},
] ;


sub new {

	my( $class ) = shift ;

	my $self = Stem::Class::parse_args( $attr_spec, @_ ) ;
	return $self unless ref $self ;

print "TAIL INT $self->{'interval'}\n" ;

	if ( my $interval = $self->{'interval'} ) {

		$self->{'timer'} = Stem::Event::Timer->new(
				'object'	=> $self,
				'method'	=> 'tail_cmd',
				'interval'	=> $interval,
				'delay'		=> $self->{'delay'},
				'repeat'	=> 1,
				'hard'		=> 1,
		) ;

print "TIMER $self->{'timer'}\n" ;

	}

	$self->{'prev_size'} = 0 ;
	$self->{'prev_mtime'} = 0 ;
	$self->{'prev_inode'} = -1 ;

	return( $self ) ;
}

sub tail_cmd {

	my( $self ) = @_ ;

print "TAILING\n" ;

	local( *LOG ) ;

	my $path = $self->{'path'} ;

	unless( open( LOG, $path ) ) {

		return if $self->{'open_failed'} ;
		$self->{'open_failed'} = 1 ;

		if ( my $status_log = $self->{'status_log'} ) {

			Stem::Log::Entry->new(
				'logs'	=> $status_log,
				'label'	=> 'LogTail status',
				'text'	=>
					"LogTail: missing log $path $!\n",
			) ;
		}
		return ;
	}

	$self->{'open_failed'} = 0 ;

	my( $inode, $size, $mtime ) = (stat LOG)[1, 7, 9] ;

	TraceStatus "size $size mtime $mtime $inode" ;

	my $prev_inode = $self->{'prev_inode'} ;
	my $prev_size = $self->{'prev_size'} ;

	if ( $prev_inode == -1 ) {

		$self->{'prev_inode'} = $inode ;

		if ( my $status_log = $self->{'status_log'} ) {

			Stem::Log::Entry->new(
				'logs'	=> $status_log,
				'level'	=> 6,
				'label'	=> 'LogTail status',
				'text'	=>
					"LogTail: first open of $path\n",
			) ;
		}
	}
	elsif ( $inode != $prev_inode ) {

		$self->{'prev_inode'} = $inode ;

		if ( my $status_log = $self->{'status_log'} ) {

			Stem::Log::Entry->new(
				'logs'	=> $status_log,
				'level'	=> 6,
				'label'	=> 'LogTail status',
				'text'	=>
					"LogTail: $path has moved\n",
			) ;
		}

# tail the entire file as it is new

		$prev_size = 0 ;

	}
	elsif ( $size < $prev_size ) {
	
		if ( my $status_log = $self->{'status_log'} ) {

			Stem::Log::Entry->new(
				'logs'	=> $status_log,
				'level'	=> 6,
				'label'	=> 'LogTail status',
				'text'	=>
					"LogTail: $path has shrunk\n",
			) ;
		}

# tail the entire file as it has shrunk

		$prev_size = 0 ;
	}
	elsif ( $size == $prev_size ) {

		TraceStatus "no changes" ;
		return ;
	}

	$self->{'prev_size'} = $size ;

	my $delta_size = $size - $prev_size ;

	return unless $delta_size ;

	my $read_buf ;

	sysseek( *LOG, $prev_size, SEEK_SET ) ;
	sysread( *LOG, $read_buf, $delta_size ) ;

	Stem::Log::Entry->new(
		'logs'	=> $self->{'data_log'},
		'level'	=> $self->{'level'},
		'label'	=> $self->{'label'},
		'text'	=> $read_buf,
	) ;

	return ;
}

1 ;
