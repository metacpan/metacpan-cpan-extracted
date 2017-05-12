#  File: Stem/File.pm

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

package Stem::File ;

use strict ;

my $attr_spec = [

	{
		'name'		=> 'path',
		'required'	=> 1,
		'help'		=> <<HELP,
This is just the path to the file. Given Unix conventions, the path
may include the full file name from the root.  It's required.
HELP
	},

	{
		'name'		=> 'mode',
		'default'	=> 'read',
		'help'		=> <<HELP,
Can be read (default), write, or read/write.  Indicates how the file
is to be opened using Unix conventions.
HELP
	},

] ;


sub new {

	my( $class ) = shift ;

	my $self = Stem::Class::parse_args( $attr_spec, @_ ) ;
	return $self unless ref $self ;

	return $self ;
}


sub msg_in {

	my( $self, $msg ) = @_ ;

	my $type = $msg->type() ;

#print $msg->dump( 'switch' ) ;

	if ( $type eq 'cmd' ) {

		$self->cmd_in( $msg ) ;
		return ;
	}
}


sub read {

	my( $self, $read_size_wanted ) = @_ ;


}

sub read_line {

	my( $self, $read_size_wanted ) = @_ ;

	$self->{'handle'}->readline() ;
}

sub write {

	my( $self, $write_data ) = @_ ;

	$self->{'handle'}->write( $write_data ) ;
}

sub close {

	my( $self ) = @_ ;

	$self->{'handle'}->close() ;

	delete( $self->{'handle'} ) ;
}

1 ;
