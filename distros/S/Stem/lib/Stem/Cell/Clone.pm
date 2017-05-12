#  File: Stem/Cell/Clone.pm

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

package Stem::Cell ;

use strict ;

sub cell_cloneable {

	my( $self ) = @_ ;

	my $cell_info = $self->_get_cell_info() ;

	return $cell_info->{'cloneable'} ;
}

#####################
#####################
# add check of max clone count
#####################
#####################

my @clone_fields = qw(

	no_io
	data_addr
	errors_to_output
	pipe_addr
	pipe_args
	codec
	work_ready_addr
	trigger_method
	sequence_done_method
	send_data_on_close
	stderr_log
) ;

sub _clone {

	my( $cell_info ) = @_ ;

	my $owner_obj = $cell_info->{'owner_obj'} ;

	return $owner_obj unless $cell_info->{'cloneable'} ;

# copy the object

	my $clone = bless { %{$owner_obj} }, ref $owner_obj ;

# get a new target id and the cell name

	my $target = $cell_info->{'id_obj'}->next() ;

	my $cell_name = $cell_info->{'cell_name'} ;

# keep track of the clone in the parent and register it

	$cell_info->{'clones'}{$target} = $clone ;

	my $err = register_cell( $clone, $cell_name, $target ) ;

	die $err if $err ;

# the parent loses its args to the clone. parent cells never do real work

##################
## add parent private INFO/ARGS for use by status command
##################

	my $args = delete $cell_info->{'args'} ;

# create the clone info and save it in the cloned object

	my $cell_info_attr = $cell_info->{'cell_info_attr'} ;

	my $from_addr = Stem::Msg::make_address_string( 
			$Stem::Vars::Hub_name,
			$cell_name,
			$target
	) ;

#print "FROM ADDR $cell_info->{'from_addr'}\n" ;
	my $clone_info = bless {

		'owner_obj'		=> $clone,
		'parent_obj'		=> $owner_obj,
		'cell_name'		=> $cell_name,
		'target'		=> $target,
		'from_addr'		=> $from_addr,
		'args'			=> $args,
		'cell_info_attr'	=> $cell_info_attr,
		map { $_ => $cell_info->{$_} } @clone_fields,
	} ;

# save the new clone info into the clone itself ;

	$clone->{$cell_info_attr} = $clone_info ;

	return $clone ;
}

sub _clone_delete {

	my ( $self ) = @_ ;

	my $parent_obj		= $self->{'parent_obj'} ;

	return unless $parent_obj ;

	my $owner_obj		= $self->{'owner_obj'} ;

	my $cell_info_attr	= $self->{'cell_info_attr'} ;

#print $self->cell_status_cmd() ;

# break all circular links
# delete the refs to the parent and parent objects in the cell info
# and the owner object ref to this cell info

	delete @{$self}{ qw( owner_obj parent_obj ) } ;
	delete $owner_obj->{$cell_info_attr} ;

	delete $self->{'args'} ;

# clean up the parent clones hash and the registry

	my $parent_info		= $parent_obj->{$cell_info_attr} ;
	my $target		= $self->{'target'} ;

	delete $parent_info->{'clones'}{$target} ;
	$parent_info->{'id_obj'}->delete( $target ) ;

	my $err = unregister_cell( $owner_obj ) ;
}

1 ;
