#  File: Stem/Test/ConfTypes.pm

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

package Stem::Test::ConfTypes ;

my $attr_spec = [

	{
		'name'		=> 'bool_attr',
		'type'		=> 'boolean',
		'help'		=> <<HELP,
Boolean attribute for testing Stem::Class
HELP
	},
	{
		'name'		=> 'list_attr',
		'type'		=> 'list',
		'help'		=> <<HELP,
List attribute for testing Stem::Class
HELP
	},
	{
		'name'		=> 'hash_attr',
		'type'		=> 'hash',
		'help'		=> <<HELP,
Hash attribute for testing Stem::Class
HELP
	},
	{
		'name'		=> 'lol_attr',
		'type'		=> 'LoL',
		'help'		=> <<HELP,
List of Lists attribute for testing Stem::Class
HELP
	},
	{
		'name'		=> 'loh_attr',
		'type'		=> 'LoH',
		'help'		=> <<HELP,
List of Hashes attribute for testing Stem::Class
HELP
	},
	{
		'name'		=> 'hol_attr',
		'type'		=> 'HoL',
		'help'		=> <<HELP,
Hash of Lists attribute for testing Stem::Class
HELP
	},
	{
		'name'		=> 'hoh_attr',
		'type'		=> 'HoH',
		'help'		=> <<HELP,
Hash of Hashes attribute for testing Stem::Class
HELP
	},
] ;

sub new {

	my( $class ) = shift ;

	my $self = Stem::Class::parse_args( $attr_spec, @_ ) ;
	return $self unless ref $self ;

#use YAML ;

#	warn Dump $self ;

	return( $self ) ;
}

1 ;
