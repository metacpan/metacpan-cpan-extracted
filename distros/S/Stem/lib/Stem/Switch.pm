#  File: Stem/Switch.pm

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

package Stem::Switch ;

use Stem::Trace 'log' => 'stem_status', 'sub' => 'TraceStatus' ;
use Stem::Trace 'log' => 'stem_error' , 'sub' => 'TraceError' ;

use strict ;

=head1 Stem::switch

Stem::Switch has several functions:

 new 
 msg_in 
 data_in 
 map_cmd 
 info_cmd 
 status_cmd 

=cut

my $this_package = __PACKAGE__ ;

my $attr_spec = [

	{
		'name'		=> 'reg_name',
		'required'	=> 1,
		'help'		=> <<HELP,
Required field.
This is a unique name used to register this instance of a Switch.
HELP
	},

	{
		'name'		=> 'in_map',
		'default'	=> {},
		'type'		=> 'HoL',
		'help'		=> <<HELP,
This field contains the incoming address map.
Any message coming in to one of these addresses will be resent out
to every address in out_map.
HELP
	},

	{
		'name'		=> 'out_map',
		'default'	=> {},
		'type'		=> 'HoL',
		'help'		=> <<HELP,
This contains the outgoing addresses for this Switch.
HELP
	},
] ;

=head2 new

new creates a new Stem::Switch object, parsing $attr_spec and any arguments
passed to it.

It returns the new object.

=cut

sub new {

	my( $class ) = shift ;

	my $self = Stem::Class::parse_args( $attr_spec, @_ ) ;
	return $self unless ref $self ;

##########
# to be replaced with Stem::Class supporting 'hash' attribute types
##########

	if ( ref $self->{'in_map'} eq 'ARRAY' ) {

		$self->{'in_map'} = { @{$self->{'in_map'}} } ;
	}

	if ( ref $self->{'out_map'} eq 'ARRAY' ) {

		$self->{'out_map'} = { @{$self->{'out_map'}} } ;
	}

	return( $self ) ;
}

use Data::Dumper ;


sub msg_in {

	my( $self, $msg ) = @_ ;

	my $in_target = $msg->to_target() ;

	my $in_map = $self->{'in_map'}{$in_target} ;

	return unless $in_map ;

	my @out_keys = ref $in_map ? @{$in_map} : ($in_map) ;

# loop over all the output keys for this in_map entry

	foreach my $out_key ( @out_keys ) {

		my $out_addr = $self->{'out_map'}{$out_key} ;

		next unless $out_addr ;

		my @out_addrs = ref $out_addr ? @{$out_addr} : ($out_addr) ;

# loop over all the output address for this out_map entry

		foreach my $out_addr ( @out_addrs ) {

# now we clone the message with the new address

			my $switched_msg = $msg->clone(

				'to'	=>	$out_addr,
			) ;

			$switched_msg->dispatch() ;
		}
	}
}


sub map_cmd {

	my( $self, $msg ) = @_ ;

	my @tokens = split( ' ', ${$msg->data()} ) ;

	my $target = shift @tokens ;

	$self->{'in_map'}{$target} = \@tokens ;

	return ;
}

sub out_map_cmd {

	my( $self, $msg ) = @_ ;

	my @tokens = split( ' ', ${$msg->data()} ) ;

	my $key = shift @tokens ;

	$self->{'out_map'}{$key} = \@tokens ;

	return ;
}
	

sub info_cmd {

	my( $self, $msg ) = @_ ;

	return <<INFO ;

Info Response
Class: $this_package
Ref: $self

This cell is a message multiplex or switch. Any message addressed to a
target in the cell, can be resent to any subset of the output map
addresses.

INFO

}


sub status_cmd {

	my( $self, $msg ) = @_ ;

	my( $status_text ) ;

	$status_text = <<TEXT ;

Status of switch: $self->{'reg_name'}

In Map:

TEXT

	foreach my $target ( sort keys %{$self->{'in_map'}} ) {

		my $targets_ref = $self->{'in_map'}{$target} ;
		my @targets = ref $targets_ref ?
				@{$targets_ref} : ($targets_ref) ;

		$status_text .= "\t$target -> @targets\n" ;
	}

	$status_text .= "\nOut Map:\n\n" ;

	my $out_ref = $self->{'out_map'} ;

	foreach my $key ( sort keys %{$out_ref} ) {

		my $out_addr = $out_ref->{$key} ;

		my @out_addrs = ref $out_addr ? @{$out_addr} : ($out_addr) ;

		$status_text .= "\t$key -> @out_addrs\n" ;
	}

	return $status_text ;
}

1 ;
