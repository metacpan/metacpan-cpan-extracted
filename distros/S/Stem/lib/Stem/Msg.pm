#  File: Stem/Msg.pm

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

package Stem::Msg ;

use strict ;
use Carp ;

use Stem::Route qw( lookup_cell ) ;
use Stem::Trace 'log' => 'stem_status', 'sub' => 'TraceStatus' ;
use Stem::Trace 'log' => 'stem_error' , 'sub' => 'TraceError' ;
use Stem::Trace 'log' => 'stem_msg'   , 'sub' => 'TraceMsg' ;

my $msg_id = 0;

my $attr_spec = [

	{
		'name'		=> 'type',
		'help'		=> <<HELP,
This is the type of the message. It is used to select the delivery method in
the addressed Cell.
HELP
	},

	{
		'name'		=> 'cmd',
		'help'		=> <<HELP,
This is used for the delivery method if the message type is 'cmd'.
HELP
	},
	{
		'name'		=> 'reply_type',
		'default'	=> 'response',
		'help'		=> <<HELP,
This is the type that will be used in a reply message.
HELP
	},

	{
		'name'		=> 'data',
		'help'		=> <<HELP,
This is the data the message is carrying. It should (almost) always be
a reference.
HELP
	},

	{
		'name'		=> 'log',
		'help'		=> <<HELP,
This is the name of the log in a log type message.
HELP
	},

	{
		'name'		=> 'status',
		'help'		=> <<HELP,
This is the status in a status message.
HELP
	},

	{
		'name'		=> 'ack_req',
		'type'		=> 'boolean',
		'help'		=> <<HELP,
This flag means when this message is delivered, a 'msg_ack' message
sent back as a reply.
HELP
	},

	{
		'name'		=> 'in_portal',
		'help'		=> <<HELP,
This is the name of the Stem::Portal that received this message.
HELP
	},
	{
		'name'		=> 'msg_id',
		'help'		=> <<HELP,
A unique id for the message.
HELP
	},
	{
		'name'		=> 'reply_id',
		'help'		=> <<HELP,
For replies, this is the msg_id of the message being replied to.
HELP
	},
] ;

# get the plain (non-address) attributes for the AUTOLOAD and the
# message dumper

my %is_plain_attr = map { $_->{'name'}, 1 } @{$attr_spec} ;

# add the address types and parts to our attribute spec with callbacks
# for parsing

# lists of the address types and parts

my @addr_types = qw( to from reply_to ) ;
my @addr_parts = qw( hub cell target ) ;

# these are used to grab the types and parts from the method names in AUTOLOAD

my $type_regex = '(' . join( '|', @addr_types ) . ')' ;
my $part_regex = '(' . join( '|', @addr_parts ) . ')' ;

# build all the accessor methods as closures

{
	no strict 'refs' ;

	foreach my $attr ( map $_->{'name'}, @{$attr_spec} ) {

		*{$attr} = sub {

			$_[0]->{$attr} = $_[1] if @_ > 1 ;
			return $_[0]->{$attr}
		} ;
	}

	foreach my $type ( @addr_types ) {

		*{$type} = sub {
			my $self = shift ;
			$self->{ $type } = shift if @_ ;
			return $self->{ $type } ;
		} ;

##########
# WORKAROUND
# this array seems to be needed. i found a bug when i used
# a scalar and bumped it. the closures all had the value of 3.
##########

		my @part_nums = ( 0, 1, 2 ) ;

		foreach my $part ( @addr_parts ) {

			my $part_num = shift @part_nums ;

			*{"${type}_$part"} = sub {
				my $self = shift ;

# split the address for this type of address (to,from,reply_to)

				my @parts = split_address( $self->{$type} ) ;


				if ( @_ ) {

					$parts[ $part_num ] = shift ;

					$self->{$type} =
						make_address_string( @parts ) ;
				}
#print "PART $type $part_num [$parts[ $part_num ]]\n" if $type eq 'from' ;

				return $parts[ $part_num ] ;
			} ;
		}
	}
}

# used for faster parsing.

my @attrs = qw( to from reply_to type cmd reply_type log data ) ;

sub new {

	my( $class ) = shift ;

# 	my $self = Stem::Class::parse_args( $attr_spec, @_ ) ;
# 	return $self unless ref $self ;

#print "A [$_]\n" for @_ ;

	my %args = @_ ;

#use YAML ;
#print Dump \%args ;

	my $self = bless { map { exists $args{$_} ?
				( $_ => $args{$_} ) : () } @attrs } ;

#print $self->dump( 'NEW' ) ;

	$self->{'type'} = 'cmd' if exists $self->{'cmd'} ;

        $self->{'msg_id'} ||= $class->_new_msg_id;

#	TraceMsg "MSG: [$_] => [$args{$_}]\n" for sort keys %args ;

#	TraceMsg $self->dump( 'new MSG' ) ;

	return( $self ) ;
}

sub _new_msg_id {

	my( $class ) = shift ;

        $msg_id = 0 if $msg_id == 2 ** 31;

        return ++$msg_id;
}

sub clone {

	my( $self ) = shift ;

	my $msg = Stem::Msg->new(
			 ( map { exists $self->{$_} ?
				( $_, $self->{$_} ) : () }
				@addr_types, keys %is_plain_attr ),
			 @_
	) ;

#	TraceMsg $self->dump( 'self' ) ;
#	TraceMsg $msg->dump( 'clone' ) ;

	return $msg ;
}

sub split_address {

# return an empty address if no input

	return( '', '', '' ) unless @_ && $_[0] ;

# parse out the address parts so 

# the cell part can be a token or a class name with :: between tokens.
# delimiter can be /, @, -, or : with : being the convention
# this is how triplets 
# hub:cell:target

#print "SPLIT IN [$_[0]]\n" ;

	$_[0] =~ m{
			^		# beginning of string
			(?:		# group /hub:/
			   (\w*)	# grab /hub/
			   ([:/@-])	# grab any common delimiter
			)?		# hub: is optional
			(		# grab /cell/
			   (?:\w+|::)+	# group cell (token or class name)
			)		# /cell/ is required
			(?:		# group /:target/
			   \2		# match first delimiter
			   (\w*)	# grab /target/
			)?		# :target is optional
			$}x		# end of string

# an bad address can be checked with @_ == 1 as a proper address is
# always 3. 

		 or return "bad string address" ;

# we return the list of hub, cell, target and give back nice null strings if 
# needed.

#print "SPLIT ", join( '--', $1 || '', $3, $4 || '' ), "\n" ;

	return( $1 || '', $3, $4 || '' ) ;
}

# sub address_string {

# 	my( $addr ) = @_ ;

# #use YAML ;
# #print "ADDR [$addr]", Dump( $addr ) ;
# 	return $addr unless ref $addr ;

# 	return 'BAD ADDRESS' unless ref $addr eq 'HASH' ;

# 	return $addr->{'cell'} if keys %{$addr} == 1 && $addr->{'cell'} ;

# 	return join ':', map { $_ || '' } @{$addr}{qw( hub cell target ) } ;
# }

sub make_address_string {

 	my( $hub, $cell_name, $target ) = @_ ;

	$hub = '' unless defined $hub ;
	$target = '' unless defined $target ;

	return $cell_name unless length $hub || length $target ;

 	return join ':', $hub, $cell_name, $target ;
}

sub reply {

	my( $self ) = shift ;

#	TraceMsg "Reply [$self]" ;

#	TraceMsg $self->dump( 'reply self' ) ;

#print $self->dump( 'reply self' ) ;

	my $to = $self->{'reply_to'} || $self->{'from'} ;
	my $from = $self->{'to'} ;

	my $reply_msg = Stem::Msg->new(
				'to'	=> $to,
				'from'	=> $from,
				'type'	=> $self->{'reply_type'} || 'response',
                                'reply_id' => $self->{'msg_id'},
				@_
	) ;

#	TraceMsg $reply_msg->dump( 'new reply' ) ;
#$reply_msg->dump( 'new reply' ) ;

	return( $reply_msg ) ;
}

#####################
#####################
# add forward method which clones the old msg and just updates the to address.
#
# work needs to be done on from/origin parts and who sets them
#####################
#####################


sub error {

	my( $self, $err_text ) = @_ ;

#	TraceError "ERR [$self] [$err_text]" ;

	my $err_msg = $self->reply( 'type' => 'error',
				    'data' => \$err_text ) ;

#	TraceError $err_msg->dump( 'error' ) ;

	return( $err_msg ) ;
}


########################################
########################################
# from/origin address will be set if none by looking up the cell that
# is currently be called with a message. or use
# Stem::Event::current_object which is set before every event
# delivery.
########################################
########################################


my @msg_queue ;

sub dispatch {

	my( $self ) = @_ ;

warn( caller(), $self->dump() ) and die
		'Msg: No To Address' unless $self->{'to'} ;
warn( caller(), $self->dump() ) and die
		'Msg: No From Address' unless $self->{'from'} ;


#  $self->deliver() ;
#  return ;

#  	unless ( @msg_queue ) {
	unless ( ref ( $self ) ) {
		 $self = Stem::Msg->new( @_ ) ;
	}
#  		Stem::Event::Plain->new( 'object' => __PACKAGE__,
#  					 'method' => 'deliver_msg_queue' ) ;
#  	}
	return "missing to attr in msg" unless $self ->{"to"} ;
	return "missing from attr in msg" unless $self ->{"from"} ;
	return "missing type attr in msg" unless $self ->{"type"} ;
	push @msg_queue, $self ;
}

sub process_queue {

	while( @msg_queue ) {

		my $msg = shift @msg_queue ;

#print $msg->dump( 'PROCESS' ) ;
		my $err = $msg->_deliver() ;

		if ( $err ) {

			my $err_text = "Undelivered:\n$err" ;
#print $err_text, $msg->dump( 'ERR' ) ;
			TraceError $msg->dump( "$err_text" ) ;

		}
	}
}

sub _deliver {

	my( $self ) = @_ ;

#print $self->dump( "DELIVER" ) ;

	my( $to_hub, $cell_name, $target ) = split_address( $self->{'to'} ) ;

	unless( $cell_name ) {

		return <<ERR ;
Can't deliver to bad address: '$self->{'to'}'
ERR
	}

#print "H [$to_hub] C [$cell_name] T [$target]\n" ;

	if ( $to_hub && $Stem::Vars::Hub_name ) {

		if ( $to_hub eq $Stem::Vars::Hub_name ) {

			if ( my $cell = lookup_cell( $cell_name, $target ) ) {

				return $self->_deliver_to_cell( $cell ) ;
			}

			return <<ERR ;
Can't find cell $cell_name in local hub $to_hub
ERR
		}

		return $self->send_to_portal( $to_hub ) ;
	}

# no hub, see if we can deliver to a local cell 

	if ( my $cell = lookup_cell( $cell_name, $target ) ) {

		return $self->_deliver_to_cell( $cell ) ;
	}

# see if this came in from a portal

	if ( $self->{'in_portal'} ) {

		return "message from another Hub can't be delivered" ;
	}

# not a local cell or named hub, send it to DEFAULT portal

	my $err = $self->send_to_portal() ;
	return $err if $err ;

	return ;
}

sub send_to_portal {

	my( $self, $to_hub ) = @_ ;

	eval {

		Stem::Portal::send_msg( $self, $to_hub ) ;
	} ;

	return "No Stem::Portal Cell was configured" if $@ ;

	return ;
}


sub _find_local_cell {

	my ( $self ) = @_ ;

	my $cell_name	= $self->{'to'}{'cell'} ;
	my $target	= $self->{'to'}{'target'} ;

	return lookup_cell( $cell_name, $target ) ;
}

sub _deliver_to_cell {

	my ( $self, $cell ) = @_ ;

# set the method 

	my $method = ( $self->{'type'} eq 'cmd' ) ?
				"$self->{'cmd'}_cmd" :
				"$self->{'type'}_in" ;

#print "METH: $method\n" ;

# check if we can deliver there or to msg_in

	unless ( $cell->can( $method ) ) {

		return $self->dump( <<DUMP ) unless( $cell->can( 'msg_in' ) ) ;
missing message delivery methods '$method' and 'msg_in'
DUMP

		$method = 'msg_in' ;
	}

	TraceMsg "MSG to $cell $method" ;

	my @response = $cell->$method( $self ) ;

#print "RESP [@response]\n" ;

# if we get a response then return it in a message

	if ( @response && $self->{'type'} eq 'cmd' ) {

# make the response data a reference

		my $response = shift @response ;
		my $data = ( ref $response ) ? $response : \$response ;

#print $self->dump( 'CMD msg' ) ;
		my $reply_msg = $self->reply(
					'data' => $data,
		) ;

#print $reply_msg->dump( 'AUTO REPONSE' ) ;

		$reply_msg->dispatch() ;
	}

	if ( $self->{'ack_req'} ) {

		my $reply_msg = $self->reply( 'type' => 'msg_ack' ) ;

		$reply_msg->dispatch() ;
	}

	return ;
}

# dump a message for debugging

sub dump {

	my( $self, $label, $deep ) = @_ ;

	require Data::Dumper ;

	my $dump = '' ;
	$label ||= 'UNKNOWN' ;

	my( $file_name, $line_num ) = (caller)[1,2] ;

	$dump .= <<LABEL ;

>>>>
MSG Dump at Line $line_num in $file_name
$label = {
LABEL

	foreach my $type ( @addr_types ) {

		my $addr = $self->{$type} ;

		next unless $addr ;

		my $addr_text = $addr || 'NONE' ;

		$dump .= "\t$type\t=> $addr_text\n" ;
	}

	foreach my $attr ( sort keys %is_plain_attr ) {

		next unless exists $self->{$attr} ;

		my $tab = ( length $attr > 4 ) ? "" : "\t" ;

		my( $val_text, $q, $ret ) ; 

		if ( $deep || $attr eq 'data' ) {

			$val_text = Data::Dumper::Dumper( $self->{$attr} ) ;

			$val_text =~ s/^.+?=// ;
			$val_text =~ s/;\n?$// ;
			$val_text =~ s/^\s+/\t\t/gm ;
			$val_text =~ s/^\s*([{}])/\t$1/gm ;

			$q = '' ;
			$ret = "\n" ;
		}
		else {
			$val_text = $self->{$attr} ;
			$q = $val_text =~ /\D/ ? "'" : '' ;
			$ret = '' ;
		}

		$dump .= <<ATTR ;
	$attr$tab	=> $ret$q$val_text$q,
ATTR

	}

	$dump .= "}\n<<<<\n\n" ;

	return($dump) ;
}

1 ;
