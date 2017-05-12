#  File: Stem/Class.pm

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

package Stem::Class ;

use strict ;

#use Data::Dumper ;

# dispatch table for attribute 'type' checking and conversion

my %type_to_code = (

	'boolean'	=> \&_type_boolean,
	'hash'		=> \&_type_hash,
	'list'		=> \&_type_list,
	'HoL'		=> \&_type_hash_of_list,
	'LoL'		=> \&_type_list_of_list,
	'HoH'		=> \&_type_hash_of_hash,
	'LoH'		=> \&_type_list_of_hash,
	'addr'		=> \&_type_address,
	'address'	=> \&_type_address,
	'obj'		=> \&_type_object,
	'object'	=> \&_type_object,
	'cb_object'	=> \&_type_object,
	'handle'	=> \&_type_handle,
) ;

sub parse_args {

	my( $attr_spec, %args_in ) = @_ ;

	my( $package ) = caller ;

#print "PACK $package\n" ;

	my $obj = bless {}, $package ;

#print Dumper( $attr_spec ) ;
#print "class args ", Dumper( \%args_in ) ;

	my( $cell_info_obj, $cell_info_name ) ;

	my $reg_name = $args_in{ 'reg_name' } || '' ;

	foreach my $field ( @{$attr_spec} ) {

		my $field_name = $field->{'name'} or next ;

		my $field_val = $args_in{ $field_name } ;

		if ( my $class = $field->{'class'} ) {

# optinally force a sub-object build by passing a default empty list
# for its value
# Stem::Cell is always built

			if ( $field->{'always_create'} ||
			     $class eq 'Stem::Cell' ) {

				$field_val ||= [] ;
			}

			my @class_args ;

			if ( ref $field_val eq 'HASH' ) {

				@class_args = %{$field_val} ;
			}
			elsif ( ref $field_val eq 'ARRAY' ) {

				@class_args  = @{$field_val} ;
			}
			else {
				next ;
			}

			my $class_args = $field->{'class_args'} ;

			if ( $class_args && ref $class_args eq 'HASH' ) {

				push( @class_args, %{$class_args} ) ;
			}
			elsif ( $class_args && ref $class_args eq 'ARRAY' ) {

				push( @class_args, @{$class_args} ) ;
			}

# Stem::Cell wants to know its owner's cell name

			push( @class_args, 'reg_name' => $reg_name )
				if $class eq 'Stem::Cell' ;

			$field_val = $class->new( @class_args ) ;

			return <<ERR unless $field_val ;
Missing attribute class object for '$field_name' for class $package
ERR

			return $field_val unless ref $field_val ;

# track the field info for Stem::Cell for use later

			if ( $class eq 'Stem::Cell' ) {

				$cell_info_obj = $field_val ;
				$cell_info_name = $field_name ;
			}
		}

# handle a callback type attribute. it does all the parsing and object stuffing
# the callback should return 

		if ( my $callback = $field->{'callback'} and $field_val ) {


			my $cb_err = $callback->( $obj,
						  $field_name, $field_val ) ;

			return $cb_err if $cb_err ;

			next ;
		}

		if ( my $env_name = $field->{'env'} ) {

			my @prefixes = ( $reg_name ) ?
					( "${reg_name}:", "${reg_name}_", '' ) :
					( '' ) ;

			foreach my $prefix ( @prefixes ) {

#print "ENV NAME [$prefix$env_name]\n" ;

 				my $env_val =
					$Stem::Vars::Env{"$prefix$env_name"} ;

				next unless defined $env_val ;

				$field_val = $env_val ;
#print "ENV field $field_name [$env_val]\n" ;
				last ;
			}
		}

		unless( defined $field_val ) {

			if ( $field->{'required'} ) {

				return <<ERR ;
Missing required field '$field_name' for class $package
ERR
			}

			$field_val = $field->{'default'}
					if exists $field->{'default'} ;
		}

#print "field $field_name [$field_val]\n" ;

		next unless defined $field_val ;

		if ( my $type = $field->{'type'} ) {
			
			my $type_code = $type_to_code{$type} ;
			return "Unknown attribute type '$type'"
							unless $type_code ;
			
			my $err = $type_code->(
				\$field_val, $type, $field_name ) ;
#print "ERR $err\n" ;
			return $err if $err ;
		}

		$obj->{$field_name} = $field_val ;
	}

	if ( $cell_info_obj ) {

		return <<ERR unless $reg_name ;
Missing 'name' in configuration for class $package.
It is required for use by Stem::Cell
ERR

		$cell_info_obj->cell_init( $obj,
					   $reg_name,
					   $cell_info_name
		) ;
	}

#print "class obj ", Dumper( $obj ) ;

	return $obj ;
}

sub _type_boolean {

	my ( $val_ref, $type ) = @_ ;

	return if ${$val_ref} =~ s/^(?:|1|Y|Yes)$/1/i || 
		  ${$val_ref} =~ s/^(?:|0|N|No)$/0/i ;

	return "Attribute value '${$val_ref}' is not boolean"
}

sub _type_object {

	my ( $val_ref, $type ) = @_ ;

	return if ref ${$val_ref} ;

	return "Attribute value '${$val_ref}' is not an object"
}

sub _type_address {

	my ( $val_ref, $type, $name ) = @_ ;

	my( $to_hub, $cell_name, $target ) =
			Stem::Msg::split_address( ${$val_ref} ) ;

	return if $cell_name ;

	return "Attribute $name: value '${$val_ref}' is not a valid Stem address"
}

sub _type_handle {

	my ( $val_ref, $type ) = @_ ;

	return if defined fileno( ${$val_ref} ) ;

	return "Attribute value '${$val_ref}' is not an open IO handle"
}

sub _type_list {

	my ( $val_ref, $type ) = @_ ;

	my $err = _convert_to_list( $val_ref ) ;

	return unless $err ;

	return "Attribute value '${$val_ref}' is not a list\n$err" ;
}

sub _type_hash {

	my ( $val_ref, $type ) = @_ ;

	my $err = _convert_to_hash( $val_ref ) ;

	return unless $err ;

	return "Attribute value '${$val_ref}' is not a hash\n$err" ;
}

sub _type_list_of_list {

	my ( $val_ref, $type ) = @_ ;

#print Dumper $val_ref ;
	my $err = _convert_to_list( $val_ref ) ;

#print Dumper $val_ref ;

	return $err if $err ;

	foreach my $sub_val ( @{$$val_ref}) {

		$err = _convert_to_list( \$sub_val ) ;
		return <<ERR if $err ;
Attribute's secondary value '$sub_val' can't be converted to a list\n$err" ;
ERR
	}

#print Dumper $val_ref ;

	return ;
}

sub _type_list_of_hash {

	my ( $val_ref, $type ) = @_ ;

#print Dumper $val_ref ;
	my $err = _convert_to_list( $val_ref ) ;

#print Dumper $val_ref ;

	return $err if $err ;

	foreach my $sub_val ( @{$$val_ref}) {

		$err = _convert_to_hash( \$sub_val ) ;
		return <<ERR if $err ;
Attribute's secondary value '$sub_val' can't be converted to a hash\n$err" ;
ERR
	}

#print Dumper $val_ref ;

	return ;
}


sub _type_hash_of_list {

	my ( $val_ref, $type ) = @_ ;

#print Dumper $val_ref ;
	my $err = _convert_to_hash( $val_ref ) ;

#print Dumper $val_ref ;

	return $err if $err ;

	foreach my $val ( values %{$$val_ref}) {

		$err = _convert_to_list( \$val ) ;
		return <<ERR if $err ;
Attribute's secondary value '$val' can't be converted to a list\n$err" ;
ERR
	}

#print Dumper $val_ref ;

	return ;
}

sub _type_hash_of_hash {

	my ( $val_ref, $type ) = @_ ;

#print Dumper $val_ref ;
	my $err = _convert_to_hash( $val_ref ) ;

#print Dumper $val_ref ;

	return $err if $err ;

	foreach my $val ( values %{$$val_ref}) {

		$err = _convert_to_hash( \$val ) ;
		return <<ERR if $err ;
Attribute's secondary value '$val' can't be converted to a hash\n$err" ;
ERR
	}

#print Dumper $val_ref ;

	return ;
}

sub _convert_to_list {

	my ( $val_ref ) = @_ ;

	my $val_type = ref ${$val_ref} ;

	return if $val_type eq 'ARRAY' ;

	unless ( $val_type ) {

		${$val_ref} = [ ${$val_ref} ] ;
		return ;
	}

	if ( $val_type eq 'HASH' ) {

		${$val_ref} = [ %{${$val_ref}} ] ;
		return ;
	}

	return 'It must be a scalar or a reference to an array or hash' ;
}

sub _convert_to_hash {

	my ( $val_ref ) = @_ ;

	my $val_type = ref ${$val_ref} ;

	return if $val_type eq 'HASH' ;

	if ( $val_type eq 'ARRAY' ) {

		${$val_ref} = { @{${$val_ref}} } ;
		return ;
	}

	return 'It must be a reference to an array or hash' ;
}

1 ;
