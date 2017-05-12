#  File: Stem/Log.pm

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

use strict ;

use Stem::Log::Entry ;
use Stem::Log::File ;

my %logs ;

package Stem::Log ;

use Stem::Trace 'log' => 'stem_status', 'sub' => 'TraceStatus' ;
use Stem::Trace 'log' => 'stem_error' , 'sub' => 'TraceError' ;


use Data::Dumper ;

use Stem::Vars ;

Stem::Route::register_class( __PACKAGE__, 'log' ) ;

my $attr_spec = [

	{
		'name'		=> 'name',
		'required'	=> 1,
		'help'		=> <<HELP,
Name of this logical log.
HELP
	},
	{
		'name'		=> 'file',
		'class'		=> 'Stem::Log::File',
		'help'		=> <<HELP,
The Stem::Log::File object that will create and manage a physical log file.
HELP
	},
	{
		'name'		=> 'format',
		'default'	=> '%T',
		'help'		=> <<HELP,
Format to print entries for this logical log. See elsewhere in this
document for the details of the sprintf-like format'
HELP
	},
	{
		'name'		=> 'strftime',
		'default'	=> '%C',
		'help'		=> <<HELP,
Format passed to strftime to print the %f entry format.
HELP
	},
	{
		'name'		=> 'use_gmt',
		'default'	=> 1,
		'type'		=> 'boolean',
		'help'		=> <<HELP,
Make strftime use gmtime instead of localtime to break the log entry
timestamp into its parts.
HELP
	},
	{
		'name'		=> 'filters',
		'help'		=> <<HELP,
List of key/value pairs. The keys are either rules, actions or 'flag'.
The value is passed to the function for the key. Use a list for complex values.
HELP
	},

] ;


sub new {

	my( $class ) = shift ;

	my $self = Stem::Class::parse_args( $attr_spec, @_ ) ;
	return $self unless ref $self ;

	$logs{ $self->{'name'} } = $self ;

	return ;
}

# table to convert filter keys to code refs to execute
# these are all passed the $entry hash ref, the filter arg and the log object

my %filter_to_code = (

	'match_text'	=> sub { $_[0]->{'text'}  =~ /$_[1]/ },
	'match_label'	=> sub { $_[0]->{'label'} =~ /$_[1]/ },

	'eq_level'	=> sub { $_[0]->{'level'} == $_[1] },
	'lt_level'	=> sub { $_[0]->{'level'} <  $_[1] },
	'le_level'	=> sub { $_[0]->{'level'} <= $_[1] },
	'gt_level'	=> sub { $_[0]->{'level'} >  $_[1] },
	'ge_level'	=> sub { $_[0]->{'level'} >= $_[1] },

	'env_eq_level'	=> sub { $_[0]->{'level'} == ( $Env{ $_[1] } || 0 ) },
	'env_lt_level'	=> sub { $_[0]->{'level'} >  ( $Env{ $_[1] } || 0 ) },
	'env_le_level'	=> sub { $_[0]->{'level'} >= ( $Env{ $_[1] } || 0 ) },
	'env_gt_level'	=> sub { $_[0]->{'level'} <  ( $Env{ $_[1] } || 0 ) },
	'env_ge_level'	=> sub { $_[0]->{'level'} <= ( $Env{ $_[1] } || 0 ) },

	'file'		=> \&_action_file,
	'stdout'	=> \&_action_stdout,
	'stderr'	=> \&_action_stderr,
	'dev_tty'	=> \&_action_dev_tty,
	'console'	=> \&_action_console,
#	'msg'		=> \&_action_msg,
	'write'		=> \&_action_write,
	'wall'		=> \&_action_wall,
	'email'		=> \&_action_email,
	'page'		=> \&_action_page,
	'forward'	=> \&_action_forward,

	'custom'	=> \&_custom_filter,
) ;

my %flag_to_code = (

	'set'		=> sub { $_[0]->{'flag'} = 1 },
	'clear'		=> sub { $_[0]->{'flag'} = 0 },
	'invert'	=> sub { $_[0]->{'flag'} = ! $_[0]->{'flag'} },
	'inverted_test'	=> sub { $_[0]->{'invert_test'} = 1 },
	'normal_test'	=> sub { $_[0]->{'invert_test'} = 0 },
	'or'		=> sub { $_[0]->{'or'} = 1 },
	'and'		=> sub { $_[0]->{'or'} = 0 },
) ;

sub submit {

	my( $self, $entry ) = @_ ;

	$entry->{'format'} = $self->{'format'} ;
	$entry->{'strftime'} = $self->{'strftime'} ;
	$entry->{'use_gmt'} = $self->{'use_gmt'} ;

	my $filter_list = $self->{'filters'} ;

	unless ( $filter_list ) {

# no filter so the default is to log to the file

		_action_file( $entry, 0, $self ) ;

		return ;
	}

# start with all actions enabled

	$entry->{'flag'} = 1 ;

# scan the filter list by pairs

	for( my $i = 0 ; $i < @{$filter_list} ; $i += 2 ) {

		my ( $filter_key, $filter_arg ) =
				@{$filter_list}[$i, $i + 1] ;

# handle the flag operations first.

		if ( $filter_key eq 'flag' ) {

			if ( my $code = $flag_to_code{ $filter_arg } ) {

				$code->( $entry ) ;
			}

			next ;
		}

# skip this filter rule/action if the flag is false

		next unless $entry->{'flag'} && ! $entry->{'invert_test'} ;

# check for and remove a 'not_' prefix

		my $not = $filter_key =~ s/^not_(\w+)$/$1/ ;

#print "FILT $filter_key $filter_arg\n" ;

		my $code = $filter_to_code{ $filter_key } ;

		next unless $code ;

# execute the rule/action code

		my $flag_val = $code->( $entry, $filter_arg, $self ) ;

# don't mung the flag unless we get a boolean return

		next unless defined( $flag_val ) ;

# invert the returned flag value if needed

		$flag_val = ! $flag_val if $not ;

# do the right boolean op

		if ( $entry->{'or'} ) {

			$entry->{'flag'} ||= $flag_val ;
		}
		else {

			$entry->{'flag'} &&= $flag_val ;
		}
	}
}


sub _format_entry {

	my( $entry ) = @_ ;

	my $formatted = $entry->{'format'} ;

	$formatted =~ s/%(.)/_format_field( $entry, $1 )/seg ;

	return $formatted ;
}

my %letter_to_key = (

	'T'	=> 'text',
	't'	=> 'time',
	'L'	=> 'label',
	'l'	=> 'level',
	'H'	=> 'hub_name',
	'h'	=> 'host_name',
	'P'	=> 'program_name',
) ;

sub _format_field {

	my( $entry, $letter ) = @_ ;

	if ( my $key = $letter_to_key{ $letter } ) {

		return $entry->{$key} ;
	}

	if ( $letter eq 'f' ) {

		require POSIX ;

		$entry->{'formatted_time'} ||= do {

			my @times = ( $entry->{'use_gmt'} ) ?
					gmtime( $entry->{'time'} ) :
					localtime( $entry->{'time'} ) ;

			POSIX::strftime( $entry->{'strftime'}, @times ) ;
		} ;

		return $entry->{'formatted_time'} ;
	}

	return $letter ;
}

sub _action_file {

	my( $entry, $arg, $log_obj ) = @_ ;

	my $file = $log_obj->{'file'} ;

	$file or return ;

	$entry->{'formatted'} ||= _format_entry( $entry ) ;

	$file->write( $entry->{'formatted'} ) ;

	return ;
}

sub _action_stdout {

	my( $entry ) = shift ;

	$entry->{'formatted'} ||= _format_entry( $entry ) ;

	print STDOUT $entry->{'formatted'} ;

	return ;
}

sub _action_stderr {

	my( $entry ) = shift ;

	$entry->{'formatted'} ||= _format_entry( $entry ) ;

	print STDERR $entry->{'formatted'} ;

	return ;
}

sub _action_write {

	my( $entry, $arg ) = @_ ;

	$entry->{'formatted'} ||= _format_entry( $entry ) ;

	my @users = ref $arg ? @{$arg} : $arg ;

	foreach my $user ( @users ) {

		system <<SYS ;
/bin/echo '$entry->{'formatted'}' | write $user >/dev/null 2>&1 &
SYS
	}

	return ;
}

sub _action_wall {

	my( $entry ) = shift ;

	$entry->{'formatted'} ||= _format_entry( $entry ) ;


	system <<SYS ;
/bin/echo '$entry->{'formatted'}' | wall &
SYS

	return ;
}

# handle to write log entries to /dev/tty

my $tty_fh ;

sub _action_dev_tty {

	my( $entry ) = shift ;

	$tty_fh ||= IO::File->new( ">/dev/tty" ) ;

	unless( $tty_fh ) {

		warn "can't open log file /dev/tty $!" ;
		return ;
	}

	$entry->{'formatted'} ||= _format_entry( $entry ) ;

	print $tty_fh $entry->{'formatted'} ;

	return ;
}

sub _action_console {

	my( $entry ) = shift ;

	$entry->{'formatted'} ||= _format_entry( $entry ) ;

	return unless Stem::Console->can( 'write' ) ;

	Stem::Console->write( $entry->{'formatted'} ) ;

	return ;
}

sub _action_forward {

	my( $entry, $arg ) = @_ ;

	my @logs = ref $arg ? @{$arg} : $arg ;

	my $entry_obj = $entry->{'entry_obj'} ;

	$entry_obj->submit( @logs ) ;

	return ;
}

sub _action_email {

	my( $entry, $arg ) = @_ ;

	$entry->{'formatted'} ||= _format_entry( $entry ) ;

	my ( $email_addr, $subject ) = ( ref $arg ) ?
				@{$arg} : ( $arg, 'Stem::Log' ) ;

#print "EMAIL  $email_addr: $subject\n" ;

	require Mail::Send ;

	my $mail = Mail::Send->new(
			'To'	=> $email_addr,
			'Subject' => $subject
	) ;

	my $fh = $mail->open();

	$fh->print( $entry->{'formatted'} ) ;

	$fh->close;

	return ;
}

sub _custom_filter {

	my( $entry, $arg ) = @_ ;

#####
# do this
#####

	return ;
}

sub find_log {

	my ( $log_name ) = @_ ;

	return( $logs{ $log_name } ) ;
}

sub status_cmd {

	my $status_text .= sprintf( "%-20s%-40s%10s\n",
						"Logical Log",
	                                        "Physical File",
						"Size" ) ;
	$status_text .= sprintf "-" x 70 . "\n";

	foreach my $log_name ( sort keys %logs ) {

		my $ref = $logs{$log_name} ;

		$status_text .= sprintf "%-20s%-40s%10s\n",
                                                     $log_name,
		                                     $ref->{'file'}{'path'},
						     $ref->{'file'}{'size'} ;
	}

	$status_text .= "\n\n" ;

	return $status_text ;
}

1 ;
