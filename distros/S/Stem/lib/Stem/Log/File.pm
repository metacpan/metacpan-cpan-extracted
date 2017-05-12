#  File: Stem/Log/File.pm

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

use IO::File ;
use File::Basename ;


package Stem::Log::File ;

#########################
#########################
# add stuff for file rotation, number suffix, etc.
#########################
#########################

my $attr_spec_log = [

	{
		'name'		=> 'path',
		'required'	=> 1,
		'help'		=> <<HELP,
The path for the physical log file
HELP
	},
	{
		'name'		=> 'strftime',
		'default'	=> '%Y%m%d%H%M%S',
		'help'		=> <<HELP,
Format passed to strftime to print the log file suffix timestamp
HELP
	},
	{
		'name'		=> 'use_gmt',
		'default'	=> 1,
		'type'		=> 'boolean',
		'help'		=> <<HELP,
Make strftime use gmtime instead of localtime for the suffix timestamp
HELP
	},

	{
		'name'		=> 'rotate',
		'type'		=> 'hash',
		'help'		=> <<HELP,
This is a list of option key/value pairs that can be applied to log rotation.
HELP
	},

] ;


sub new {

	my( $class ) = shift ;

	my $self = Stem::Class::parse_args( $attr_spec_log, @_ ) ;
	return $self unless ref $self ;

	if ( my $rotate_options = $self->{'rotate'} ) {

		if ( ref $rotate_options eq 'ARRAY' ) {

			$self->{'rotate'} = { @{$rotate_options} } ;
		}
	}

	$self->{'base_path'} = $self->{'path'} ;
	( $self->{'log_dir'}, $self->{'file_name'} ) =
					File::Basename::fileparse( $self->{'path'} ) ;

	my $err = $self->_open_file() ;
	return $err if $err ;

	return( $self ) ;
}


sub write {

	my( $self, $text ) = @_ ;

	$self->{'fh'}->print( $text ) ;

	$self->{'size'} += length( $text ) ;

	my $rotate_options = $self->{'rotate'} ;

	if ( $rotate_options &&
	     $self->{'size'} >= $rotate_options->{'max_size'} ) {

		$self->_rotate() ;
	}
}

sub status_cmd {


}

sub rotate_cmd {

	my ( $self ) = @_ ;

	$self->_rotate() ;
}

sub _rotate {

	my ( $self ) = @_ ;

	my $fh = $self->{'fh'} ;

	close( $fh ) ;

	$self->_open_file() ;
}


sub _open_file {

	my ( $self ) = @_ ;

	my $open_path = $self->{'base_path'} ;

	if ( $self->{'rotate'} ) {

		my $suffix = $self->_get_last_suffix() ||
		             $self->_generate_suffix() ;

		
		$open_path .= ".$suffix" ;
	}

	$self->{'open_path'} = $open_path ;

	my $fh = IO::File->new( ">>$open_path" ) or
		 return "Can't append to log file '$open_path' $!" ;

	$self->{'size'} = -s $fh ;

	$fh->autoflush( 1 ) ;

	$self->{'fh'} = $fh ;

	return ;
}

sub _get_last_suffix {

	my ( $self ) = @_ ;

	my $log_dir = $self->{'log_dir'} ;
	my $file_name = $self->{'file_name'} ;

	local( *DH ) ;

	opendir( DH, $log_dir ) || return '' ;

	my @files = sort grep { /^$file_name/ } readdir(DH) ;

# return the latest file suffix

	if ( @files ) {

		return $1 if $files[-1] =~ /\.(\d+$)/ ;
	}

	return '' ;
}


sub _generate_suffix {

	my ( $self ) = @_ ;

	require POSIX ;

	my @time = ( $self->{'use_gmt'} ) ? gmtime : localtime ;

	return POSIX::strftime( $self->{'strftime'}, @time ) ;
}

1 ;
