#  File: Stem/Portal.pm

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

package Stem::Portal ;

use strict ;
use Carp ;
use Data::Dumper ;

use Stem::AsyncIO ;
use Stem::Vars ;
use Stem::Packet ;
use Stem::Socket ;
use Stem::Trace 'log' => 'stem_status', 'sub' => 'TraceStatus' ;
use Stem::Trace 'log' => 'stem_error' , 'sub' => 'TraceError' ;

my %name_to_portal ;
my %portal_to_names ;

my $default_portal ;


Stem::Route::register_class( __PACKAGE__, 'port' ) ;

my $attr_spec_portal = [

	{
		'name'		=> 'reg_name',
		'default'	=> '',
		'help'		=> <<HELP,
This is a unique name used to register this instance of a Portal.
HELP
	},
	{
		'name'		=> 'server',
		'env'		=> 'server',
		'help'		=> <<HELP,
This determines if we are a server or a client.
If it is true, we are a server.  Otherwise, we are a client.
HELP
	},
	{
		'name'		=> 'sync',
		'type'		=> 'boolean',
		'default'	=> 1,
		'help'		=> <<HELP,
Mark this as a synchronously connecting Portal. Default is syncronous
connections, set to 0 for asynchronous. In both cases the same method
callbacks are used.
HELP
	},
	{
		'name'		=> 'port',
		'default'	=> 10_000,
		'env'		=> 'port',
		'help'		=> <<HELP,
This determines which port we bind to  if we are a server.
This determines which port we connect to if we are a client. 
The default value is 10,000.
HELP
	},
	{
		'name'		=> 'host',
		'default'	=> 'localhost',
		'env'		=> 'host',
		'help'		=> <<HELP,
This determines which host we attach to when we are a client.
The default value is localhost.
HELP
	},

	{
		'name'		=> 'spawn_conf_file',
		'help'		=> <<HELP,
This tells the portal to fork another Stem Hub and pass this value as
the configuration file argument to run_stem.  The new Hub will be
connected to this Portal and be private to it.
HELP
	},

	{
		'name'		=> 'spawn_conf_args',
		'help'		=> <<HELP,

This tells the portal to fork another Stem Hub and pass (via a
message) this data to the Stem::Conf as a configuration 
The new Hub will be connected to this Portal and be private
to it.

HELP
	},


	{
		'name'		=> 'run_stem_args',
		'help'		=> <<HELP,
These are the command line arguments to run_stem for the spawned Hub.
HELP
	},
	{
		'name'		=> 'codec',
		'help'		=> <<HELP,
This is the sub-class that is used to convert messages to/from a byte
stream for this portal
HELP
	},
	{
		'name'		=> 'disable',
		'env'		=> 'disable',
		'type'		=> 'boolean',
		'help'		=> <<HELP,
This flag will disable this Portal. It will not construct an object and
no errors will be returned.
HELP
	},

] ;

sub new {

	my( $class ) = shift ;

	my $self = Stem::Class::parse_args( $attr_spec_portal, @_ ) ;
	return $self unless ref $self ;

	return if $self->{ 'disable' } ;

	my $name = $Stem::Vars::Hub_name ;

	if ( $Env{'portal_use_stdio'} ) {

		return $self->new_child_portal() ;
	}

	if ( $self->{'spawn_conf_file'} || $self->{'spawn_conf_args'} ) {

		return $self->new_parent_portal() ;
	}

	if ( $self->{'server'} ) {

		$self->{'type'} = 'listener' ;
		$self->{'server_name'} = $name ;
	}
	else {

		$self->{'type'} = 'client' ;
		$self->{'name'}	= $name ;
	}

#print "REG new [$self->{'reg_name'}]\n" ;

	my $sock_obj = Stem::Socket->new(
				'object'	=> $self,
				'host'		=> $self->{'host'},
				'port'		=> $self->{'port'},
				'server'	=> $self->{'server'},
				'sync'		=> $self->{'sync'},
	) ;

	ref $sock_obj or return <<ERR ;
Stem::Portal '$self->{'reg_name'}' tried to connect/listen to $self->{'host'}:$self->{'port'}
$sock_obj
ERR

	$self->{'sock_obj'} = $sock_obj ;

	return ;
}

sub connected {

	my( $self, $connected_sock ) = @_ ;

	my( $portal ) ;

	TraceStatus "Portal Connected" ;

	$self->{'read_fh'} = $connected_sock ;
	$self->{'write_fh'} = $connected_sock ;

	my $type = $self->{'type'} ;

	if ( $type eq 'listener' ) {

# fork off a new portal by making a clone of the listener portal

		$portal = bless { %$self } ;
		$portal->{'type'} = 'accepted' ;

		my $name = $portal->{'server_name'} ;

		$portal->{'name'} = $name ;

		delete( $portal->{'sock_obj'} ) ;
	}
	else {

#print "Portal Connected\n" ;

# a client portal is just itself

		$portal = $self ;

#print "REG [$self->{'reg_name'}]\n" ;

		if ( my $name = $self->{'reg_name'} ) {

			$portal->register( $name ) ;
		}

		unless ( $default_portal ) {

			$portal->register( 'DEFAULT' ) ;
			$default_portal = $portal ;
		}
	}

	my $err = $portal->_activate() ;

	die $err if $err ;
}

my $run_stem_path ;

sub new_parent_portal {

	my( $self ) = @_ ;

	$run_stem_path ||= do {

		require Stem::Proc ;
		require Stem::InstallConfig ;

		$Stem::InstallConfig{ run_stem_path } ;
	} ;

	my $conf_file = $self->{'spawn_conf_file'} || 'portal_child' ;

	my @run_stem_args = @{$self->{'run_stem_args'} || []} ;

	my $proc = Stem::Proc->new(

			path		=> $run_stem_path,
			proc_args	=> [
				'portal_use_stdio=1',
				@run_stem_args,
				$conf_file,
			],
			spawn_now	=> 1,
			cell_attr	=> [
				no_io	=> 1,
			],
	) ;

	$self->{'proc'} = $proc ;

	TraceStatus "Portal Paren" ;

	$self->{'read_fh'} = $proc->read_fh() ;
	$self->{'write_fh'} = $proc->write_fh() ;

#print "REG [$self->{'reg_name'}]\n" ;

	my $err = $self->_activate() ;


	die $err if $err ;
###########
#	 $self->{'spawn_conf_args'} ) {
#### when can we send the conf data?
##########


}

sub new_child_portal {

	my( $self ) = @_ ;

	$self->{'type'} = 'child' ;


	TraceStatus "Portal Child" ;

	$self->{'read_fh'} = \*STDIN ;
	$self->{'write_fh'} = \*STDOUT ;

#print "REG [$self->{'reg_name'}]\n" ;

	unless ( $default_portal ) {

		$self->register( 'DEFAULT' ) ;
		$default_portal = $self ;
	}

	if ( my $portal_name = $Env{'portal_name'} ) {

		$self->register( $portal_name ) ;
	}

	my $err = $self->_activate() ;

	die $err if $err ;
}


sub _activate {

	my( $self ) = @_ ;

	TraceStatus "Active portal" ;

	my $aio = Stem::AsyncIO->new(

			'object'	=> $self,
			'read_fh'	=> $self->{'read_fh'},
			'write_fh'	=> $self->{'write_fh'},
			'read_method'	=> 'portal_data',
			'closed_method'	=> 'portal_closed',
	) ;

	return $aio unless ref $aio ;

	$self->{'aio'} = $aio ;

	my $packet = Stem::Packet->new( 'codec' => $self->{'codec'} ) ;
	return $packet unless ref $packet ;
	$self->{'packet'} = $packet ;

	my $msg = Stem::Msg->new( 'from' => "${Stem::Vars::Hub_name}:port",
				  'type'     => 'register',
	) ;

	return $msg unless ref $msg ;

	$self->write_msg( $msg ) ;

	return ;
}

# this is not a method, but a class sub

sub send_msg {

	my ( $msg, $to_hub ) = @_ ;

	$to_hub ||= 'DEFAULT' ;

	my $self = $name_to_portal{ $to_hub } ;

	return "unknown Portal '$to_hub'" unless $self ;

	$msg->from_hub( $self->{'name'} ) unless $msg->from_hub() ;
#	$msg->from_hub( $self->{'name'} ) ;

	unless( $self->{'remote_hub'} ) {

		push( @{$self->{'queued_msgs'}}, $msg ) ;

		return ;
	}

	$self->write_msg( $msg ) ;

	return ;
}

# this is a regular method called by the above sub.

sub write_msg {

	my( $self, $msg ) = @_ ;

	my $packet_text = $self->{'packet'}->to_packet( $msg ) ;

#print "PACK SEND [$packet_text]\n" ;

	$self->{'aio'}->write( $packet_text ) ;
}

sub portal_data {

	my( $self, $packet_text ) = @_ ;

	my $packet = $self->{'packet'} ;

# parse out all messages that may be in the input data

	while( my $msg = $packet->to_data( $packet_text ) ) {

		$self->_portal_msg_in( $msg ) ;

# no more incoming data in this callback 

		$packet_text = '' ;
	}
}

sub _portal_msg_in {

	my( $self, $msg ) = @_ ;

	if ( $msg->type() eq 'register' ) {

# register the other hub and mark this hub as connecting to it.

		$self->{'remote_hub'} = $msg->from_hub() ;
		warn( caller(), $msg->dump() ) and die
			'Msg Has No Remote Hub' unless $self->{'remote_hub'} ;
		$self->register( $self->{'remote_hub'} ) ;

# handle messages that got queued while the portal was down

		while( my $queued_msg = shift @{$self->{'queued_msgs'}} ) {

#print $queued_msg->dump( 'QUEUED' ) ;
			$self->write_msg( $queued_msg ) ;
		}

                return ;
	}

	$msg->in_portal( $self->{'remote_hub'} ) ;
	$msg->dispatch() ;
}


sub portal_closed {

	my( $self ) = @_ ;

#TraceStatus "Portal closed" ;

	Stem::Route::unregister_cell( $self ) ;
	my $names = $self->unregister() ;

	if ( $self->{'type'} eq 'accepted' ) {

#		TraceStatus "client hub '$self->{'name'}' closed" ;

		$self->shut_down() ;
		return ;
	}

	my @hub_names = ref $names ? @{$names} : 'UNKNOWN' ;

	Stem::Event::end_loop() ;

	die "server hub [@hub_names] died" ;
}

sub shut_down {

	my( $self ) = @_ ;

	TraceStatus "SHUT DOWN port : ". Dumper($self);

	$self->{'aio'}->shut_down() ;
	delete @{$self}{qw( object aio )} ;
}

# this is for messages directly to this portal. messages are sent out
# the portal via the send class method
#
# UNUSED so far

sub msg_in {

	my( $self, $msg ) = @_ ;

	TraceStatus "portal msg in" ;
}

sub register {

	my( $self, $name ) = @_ ;

#print "NAME [$name]: ", caller(), "\n" ;

	TraceStatus "portal arg: [$self] [$name]\n\t",
					map( "<$_>", caller() ), "\n" ;

	$name_to_portal{ $name } = $self ;
	push( @{$portal_to_names{ $self }}, $name ) ;
}

sub unregister {

	my( $name ) = @_ ;

# convert a name to its object ;

	my $portal = ref $name ? $name : $name_to_portal{ $name } ;

	if ( $portal ) {

		delete $name_to_portal{ $portal } ;

		my $names = delete $portal_to_names{ $portal } ;

		return $names ;

	}

	return ;
}

sub status_cmd {

	my ($self, $msg ) = @_ ;

#print $msg->dump( 'PORT' ) ;

	my $status = <<STATUS ;

Portal Status for Hub '$Stem::Vars::Hub_name'

STATUS

	foreach my $port_name ( sort keys %name_to_portal ) {

		my $portal = $name_to_portal{ $port_name } ;

		$status .= <<STATUS ;
$port_name
	Hub:	$portal->{'remote_hub'}
	Type:	$portal->{'type'}

STATUS

	}

	return $status ;
}

1 ;
