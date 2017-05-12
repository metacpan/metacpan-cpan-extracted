#  File: Stem/Console.pm

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

package Stem::Console ;

use Stem::Trace 'log' => 'stem_status', 'sub' => 'TraceStatus' ;
use Stem::Trace 'log' => 'stem_error' , 'sub' => 'TraceError' ;

use strict ;

use Data::Dumper ;
use Symbol ;
use Socket ;

use Stem::AsyncIO ;
use Stem::Vars ;

my $console_obj ;
my $line ;

my( $read_fh, $write_fh, $parent_fh, $child_fh ) ;

if ( $^O =~ /Win32/ ) {


	$parent_fh = gensym ;
	$child_fh = gensym ;

	socketpair( $parent_fh, $child_fh, AF_UNIX, SOCK_STREAM, PF_UNSPEC ) ;
	start_reader() ;
	start_writer() ;

#	close $child_fh ;

	$read_fh = $parent_fh ;
	$write_fh = $parent_fh ;
}
else {

	$read_fh = \*STDIN ;
	$write_fh = \*STDOUT ;
}

return init() unless $Env{'console_disable'} || $Env{'tty_disable'} ;


sub start_reader {

# back to parent

	return if fork() ;

	close $parent_fh ;

#syswrite( \*STDERR, "reader started\n" ) ;
#warn "reader started2\n" ;

	while( 1 ) {

		my $buf ;

		my $cnt = sysread( \*STDIN, $buf, 1000 ) ;

#syswrite( \*STDERR, $buf ) ;

		syswrite( $child_fh, $buf ) ;
	}
}

sub start_writer {

# back to parent

	return if fork() ;

#	close $parent_fh ;

	while( 1 ) {

		my $buf ;

		my $cnt = sysread( $child_fh, $buf, 1000 ) ;

		syswrite( \*STDOUT, $buf ) ;
	}
}

sub init {

	Stem::Route::register_class( __PACKAGE__, 'cons', 'console', 'tty' ) ;

	$Env{'has_console'} = 1 ;

	my $self = bless {} ;

	my $aio = Stem::AsyncIO->new(

			'object'	=> $self,
			'read_fh'	=> $read_fh,
			'write_fh'	=> $write_fh,
			'read_method'	=> 'stdin_read',
			'closed_method'	=> 'stdin_closed',
	) ;

	return $aio unless ref $aio ;

	$self->{'aio'} = $aio ;

	$self->{'prompt'} = $Env{'prompt'} || "\nStem > " ;

	$console_obj = $self ;

	$self->write( "\nEnter 'help' for help\n\n" ) ;
	$self->prompt() ;

	return 1 ;
}

sub stdin_read {

	my( $self, $line_ref ) = @_ ;

	$line = ${$line_ref} ;

	chomp( $line ) ;

	if ( $line =~ /^\s*$/ ) {

		$self->prompt() ;
		return ;
	}

	if ( $line =~ /^quit\s*$/i ) {

		TraceStatus "quitting" ;

		exit ;
	}

	if ( $line =~ /^\s*help\s*$/i ) {

		$self->help() ;
		$self->prompt() ;
		return ;
	}

	if ( my( $key, $val ) = $line =~ /^\s*(\w+)\s*=\s*(.+)$/ ) {

		$val =~ s/\s+$// ;

		$self->echo() ;

		$self->write( "Setting Environment '$key' to '$val'\n" ) ;
		$Env{ $key } = $val ;

		$self->prompt() ;

		return ;
	}

	unless ( $line =~ /^\s*(\S+)\s+(.*)$/ ) {

		$self->write( <<ERR ) ;
Console commands must be in the form
<Cell Address> command [args ...]

ERR
		$self->prompt() ;

		return ;
	}

	my $addr = $1 ;

	my( $cmd_name, $cmd_data ) = split( ' ', $2, 2 ) ;

# allow a leading : on the command to make it a regular message instead

	my $msg_type = ( $cmd_name =~ s/^:// ) ? 'type' : 'cmd' ;

	my $msg = Stem::Msg->new(
			'to'		=> $addr,
			'from'		=> 'console',
			$msg_type	=> $cmd_name,
			'data'		=> \$cmd_data,
	) ;

	if( ref $msg ) {

		$self->echo() ;

		$msg->dispatch() ;
	}
	else {
		$self->write( "Bad console command message: $msg\n" ) ;
	}

	$self->prompt() ;

	return ;
}

sub stdin_closed {

	my( $self ) = @_ ;

	*STDIN->clearerr() ;

	$self->write( "EOF (ignored)\n" ) ;

	$self->prompt() ;
}

sub data_in {

	goto &response_in ;
}

sub response_in {

	my( $self, $msg ) = @_ ;

	$self = $console_obj unless ref $self ;

	return unless $self ;

	my $data = $msg->data() ;

	$self->write( "\n\n" ) ;

	if ( $Env{'console_from'} ) {

		my $from = $msg->from() ;

		$self->write( "[From: $from]\n" ) ;
	}

	if ( ref $data eq 'SCALAR' ) {

		$self->write( ${$data} ) ;
	}
	elsif( ref $data ) {

		$self->write( Dumper( $data ) ) ;
	}
	else {

		$self->write( $data ) ;
	}

	$self->prompt() ;
}

sub write {

	my( $self, $text ) = @_ ;

	$self = $console_obj unless ref $self ;

	$self->{'aio'}->write( $text ) ;
}


sub prompt {

	my( $self ) = @_ ;

	return unless $self->{'prompt'} ;

	$self->write( $self->{'prompt'} ) ;
}

sub echo {

	my( $self ) = @_ ;

	return unless $Env{'console_echo'} ;

	$self->write( "->$line\n" ) ;
}

sub help {

	my( $self ) = @_ ;

	$self->write( <<HELP ) ;

Stem::Console Help:

You can enter various commands to Stem here. 

If the line is of the form:

key=value

then the global command args hash %Stem::Vars::Env has that key set to
the value. Stem environment variables can be used to control log filters,
set cell behavior, set default values for cell attributes and other purposes

If the line is of the form:

address cmd data_text

it is parsed and a command message is created and sent.

The address can be in one of these forms:

	cell
	hub:cell
	hub:cell:target
	:cell:target

The cmd token is the name of the command for the message. If it is
prefixed with a :, then this string becomes the message type instead.

The rest of the line is sent as the data of the message.

Examples:

reg status

will send a 'status' command message to the 'reg' cell which is the
Stem::Route class. A listing of all registered Cells will be returned
and printed.

server:sw map a c d

That will send a 'map' command message to the Cell named 'sw' in the
Hub named 'server'. The data will be the string 'a c d'. That is used
to change the mapping of target 'a' to c, d in the Switch Cell in the
chat and chat2 demos.

HELP

}

1 ;
