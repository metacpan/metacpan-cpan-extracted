#  File: Stem/Log/Entry.pm

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

use Stem::Log ;

package Stem::Log::Entry ;

Stem::Route::register_class( __PACKAGE__, 'entry' ) ;


my $attr_spec = [

	{
		'name'		=> 'text',
		'default'	=> '',
		'help'		=> <<HELP,
Text for this log entry. Can be filtered with the rule 'match_text'.
HELP
	},
	{
		'name'		=> 'label',
		'default'	=> 'info',
		'help'		=> <<HELP,
Label for this log entry. This is used to tag log entries from
different sources. Can be filtered with the rule 'match_label'.
HELP
	},
	{
		'name'		=> 'level',
		'default'	=> '1',
		'help'		=> <<HELP,
Severity level for this log entry. It is an integer with 0 being the
most severe level and 10 the lowest (this maps to the levels of
syslog). There are several rules which can filter based on the level.
HELP
	},
	{
		'name'		=> 'logs',
		'type'		=> 'list',
		'help'		=> <<HELP,
This is a list of logical logs where this entry is submitted. The
first one is considered the original log. If this is not passed, then
the entry must be explicitly submitted by the submit method.
HELP
	},
] ;



sub new {

	my( $class ) = shift ;

	my $self = Stem::Class::parse_args( $attr_spec, @_ ) ;
	return $self unless ref $self ;

	$self->{'time'} = time() ;
	$self->{'hub_name'} = $Stem::Vars::Hub_name ;
	$self->{'host_name'} = $Stem::Vars::Host_name ;
	$self->{'program_name'} = $Stem::Vars::Program_name ;

	if ( my $logs_attr = $self->{'logs'} ) {

		$self->submit( @{$logs_attr} ) ;
	}

	return $self ;
}

sub submit {

	my( $self, @logs ) = @_ ;

	foreach my $log_name ( @logs ) {

#print "LOG [$log_name]\n" ;
		if ( $log_name =~ /^(\w+):(\w+)$/ ) {

			my $to_hub = $1 ;
			my $to_log = $2 ;

			my $log_msg = Stem::Msg->new(
					'to'	=> "$to_hub:" . __PACKAGE__,
					'from'		=> __PACKAGE__,
					'type'		=> 'log',
					'log'		=> $to_log,
					'data'		=> $self,
			) ;

#print $log_msg->dump( 'LOG out' ) ;


			$log_msg->dispatch() ;

			next ;
		}

		my $log_obj = Stem::Log::find_log( $log_name ) ;

		next unless $log_obj ;


		my $entry_copy ||= { %{$self} } ;

		$entry_copy->{'log_name'} = $log_name ;
		$entry_copy->{'orig_log_name'} ||= $log_name ;
		$entry_copy->{'entry_obj'} = $self ;

		$log_obj->submit( $entry_copy ) ;
	}
}

# this method is how a remote log message is delivered locally

sub log_in {

	my( $class, $msg ) = @_ ;

	my $entry = $msg->data() ;

	print "$entry\n" unless ref $entry ;

#print $msg->dump( 'LOG in' ) ;

	$entry->submit( $msg->log() ) ;

	return ;
}

1 ;
