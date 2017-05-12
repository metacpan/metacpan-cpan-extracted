#  File: Stem/Util.pm

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

package Stem::Util ;

use strict ;
use Carp ;

=head1 Stem::Util

This file includes two subroutines: read_file and write_file.

=cut

=head2 read_file

read_file is a utility sub to slurp in a file. 

It returns a list of lines when called in list context.
It returns one big string when called in scalar context. 

=cut

# utility sub to slurp in a file. list/scalar context determines either
# list of lines or long single string

sub read_file {

	my( $file_name ) = shift ;

	local( *FH ) ;
	open( FH, $file_name ) || carp "can't open $file_name $!" ;

	return <FH> if wantarray ;

	my $buf ;

	sysread( FH, $buf, -s FH ) ;
	return $buf ;
}

=head2 load_file

load_file is a utility sub to load a file of data.  It reads in a file
and converts it to an internal form according to the first line of the
file. The default file format is Perl data and eval is used to convert
it. These other formats are also supported:

	YAML

=cut

sub load_file {

	my( $file_name ) = shift ;

	my $text = read_file( $file_name ) ;

	my @load_vals ;

	if ( $text =~ /^.*#YAML/ ) {

		require YAML ;

		eval {
			@load_vals =  YAML::Load( $text ) ;
		} ;

		return "Load error in file '$file_name' with YAML: $@" if $@ ;

# lose the outer anon array wrapper and return the values

		return $load_vals[0] ;
	}

	@load_vals = eval "($text)" ;

	return "Load error in file '$file_name' with eval: $@" if $@ ;
	return \@load_vals ;
}


=head2 write_file

write_sub is a utility sub to write a file. It takes a file
name and a list of strings.  It opens the file and writes
all data passed into the file.  This will overwrite any data
in the file.

=cut

# utility sub to write a file. takes a file name and a list of strings

sub write_file {

	my( $file_name ) = shift ;

	local( *FH ) ;

	open( FH, ">$file_name" ) || carp "can't create $file_name $!" ;

	print FH @_ ;
}

1 ;
