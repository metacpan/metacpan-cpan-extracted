#  File: Stem/Route.pm

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

package Stem::Route;

#use Stem::Trace 'log' => 'stem_status', 'sub' => 'TraceStatus' ;
#use Stem::Trace 'log' => 'stem_error' , 'sub' => 'TraceError' ;

use strict ;

use base 'Exporter' ;
use vars qw( %EXPORT_TAGS ) ;

%EXPORT_TAGS = (
	'cell' => [ qw(
		register_cell
		alias_cell
		unregister_cell
		lookup_cell
		lookup_cell_name
		register_class
	) ],
	'filter' => [ qw(
		push_filter_on_cell
		pop_filter_from_cell
	) ],
) ;

Exporter::export_ok_tags( qw( cell filter ) );

use constant DEBUG => 1;

my %cell_info ;
my %cell_name_to_obj ;

register_class( __PACKAGE__, 'reg' ) ;

#use diagnostics -verbose;

## registration takes a minimum args of an object and a name.
## an optional third arg of target is also accepted.
##
## the idea here is that when a portal connects, it's registered
## with the local hub - which makes everyone aware of the new
## portal.
##
## a couple remaining questions though .. should this registration
## include the capabilities of the new portal?  should we add
## an 'authentication' capability to the registration process?
## ...just a few thoughts


sub register_cell {

	my( $obj, $name, $target ) = @_ ;

	unless( $obj && $name ) {

		my $err = <<ERR ;
register() requires an object and a name, with an optional target.
ERR

#		TraceError $err ;

		return $err ;
	}

	$target = '' unless defined $target ;

	if ( $cell_name_to_obj{ $name }{ $target } ) {

		my $err =
			"register_Cell $name:$target is already registered\n" ;

		return $err ;
	}

	$cell_name_to_obj{ $name }{ $target } = $obj ;

	$cell_info{ $obj }{'names'}{ $name }{ $target } = 1 ;
	$cell_info{ $obj }{'primary_name'} ||= [ $name, $target ] ;

	return ;
}

sub register_class {

	my( $class, @nicks ) = @_ ;

	foreach my $name ( $class, @nicks ) {

		register_cell( $class, $name ) ;
	}
}

sub alias_cell {

	my( $obj, $name, $target ) = @_ ;

	unless( $obj && $name ) {

		my $err = <<ERR ;
alias_cell() requires an object and a name, with an optional target.
ERR

#		TraceError $err ;

		return $err ;
	}

	$target = '' unless defined $target ;


	unless ( lookup_cell( $name, $target ) ) {

		my $err = "Alias_cell: $name:$target is not registered\n" ;

#		TraceError $err ;

		return $err ;
	}

	$cell_name_to_obj{ $name }{ $target } = $obj ;
	$cell_info{ $obj }{'names'}{ $name }{ $target } = 1 ;


	return ;
}

sub unregister_cell {

	my( $obj ) = shift ;

	my $info_ref = $cell_info{ $obj } ;

	unless ( $info_ref ) {

		my $err = "unregister_cell: object [$obj] is not registered" ;
		return $err ;
	}

	foreach my $name ( keys %{ $info_ref->{'names'} } ) {

		foreach my $target (
			keys %{ $info_ref->{'names'}{$name} } ) {

			delete $cell_name_to_obj{ $name }{ $target } ;
			delete $cell_name_to_obj{ $name } if $target eq '' ;
		}
	}

	delete $cell_info{ $obj } ;

	return ;
}


# this sub returns a cell if it is registered. otherwise it returns a
# proper false
#
# first check that the cell or parent cell exists.
# if it is a targeted address then find the targeted cell or its parent cell
# otherwise look for the regular cell with a null target.

sub lookup_cell {

	my( $name, $target ) = @_ ;

#print "LOOK N [$name] T [$target]\n" ;
	return unless exists( $cell_name_to_obj{ $name } ) ;

# look for a targeted cell first and then for a configured or class cell

	if ( defined $target ) {

		my $obj = $cell_name_to_obj{ $name }{ $target } ;
		return $obj if $obj ;
	}

	return $cell_name_to_obj{ $name }{''} ;
}


sub lookup_cell_name {

	my( $obj ) = @_ ;

	my $names_ref =	$cell_info{ $obj }{'primary_name'} ;

	return ( @{$names_ref} ) if $names_ref ;

	return ;
}


sub push_filter_on_cell {

	my( $obj, $filter ) = @_ ;

	unless ( exists( $cell_info{ $obj } ) ) {

		my $err = "push_filter_on_cell: object [$obj] is not registered" ;
		return $err ;
	}

	push( @{ $cell_info{ $obj }{'filters'} }, $filter ) ;

	return ;
}

sub pop_filter_on_cell {

	my( $obj ) = @_ ;

	unless ( exists( $cell_info{ $obj } ) ) {

		my $err = "pop_filter_on_cell: object [$obj] is not registered" ;
		return $err ;
	}

	pop( @{ $cell_info{ $obj }{'filters'} } ) ;

	return ;
}

sub get_cell_filters {

	my( $obj ) = @_ ;

	return ( wantarray ) ?  @{ $cell_info{ $obj }{'filters'} } :
				$cell_info{ $obj }{'filters'} ;
}


sub status_cmd {

	my( $class, $msg ) = @_ ;

	my ( @cell_lines, %class_cell_texts ) ;

#print map "$_ => $cell_name_to_obj{$_}\n", keys %cell_name_to_obj ;

	foreach my $name ( keys %cell_name_to_obj ) {

		my $cell = $cell_name_to_obj{$name}{''} ;

#print "CELL $cell\n" ;

# see if this is a Class Cell name

		unless ( ref $cell ) {

			my $pad = "\t" x ( 3 - int( length( $cell ) / 8 ) ) ;

			$class_cell_texts{$cell} ||= "\t$cell$pad=>" ;

			next if $name eq $cell ;

# it is a Class Cell alias
			$class_cell_texts{$cell} .= " $name" ;
			next ;
		}

		my $pad = "\t" x ( 4 - int( length( $name ) / 8 ) ) ;

		my $cell_text = "\t$name$pad=> $cell\n" ;

		foreach my $target ( keys %{ $cell_name_to_obj{$name} } ) {

			next if $target eq '' ;

			my $cell = $cell_name_to_obj{$name}{$target} ;

			my $pad = "\t" x (3 - int( length( ":$target" ) / 8 )) ;

			$cell_text .= "\t\t:$target$pad=> $cell\n" ;
		}

		push @cell_lines, $cell_text ;
	}

	@cell_lines = sort @cell_lines ;
	my @class_lines = map { "$_\n" } sort values %class_cell_texts ;

	my $hub_name = $Stem::Vars::Hub_name || '' ;

	return <<STATUS ;

Route Status for Hub '$hub_name'

	Object Cells with Target names of their Cloned Cells

@cell_lines
	Class Cells with their Aliases

@class_lines

STATUS

}

1;

__END__

=head1 NAME

Stem::Route - Manages the Message Routing Tables and Cell Registry

=head1 SYNPOSIS

  use Stem::Route qw( :all );

# $target is optional
  register_cell( $object, $name, $target ) ;
  unregister_cell($object);
# or alternately...
# again $target is optional
  unregister_by_name($name, $target);

=head1 DESCRIPTION

The Stem::Route class manages the registry of Stem Cells and their
names for a given Stem Hub (process). Any object which has selected
methods which take Stem::Msg objects as arguments can be a registered
cell. There are only 4 class methods in this module which work with
the cell registry. They can be exported into a module individually or
you can use the export tag :all to get them all.

	register_cell( $object, $name )
	register_cell( $object, $name, $target )

	This class method takes the object to be registered and its
	cell name and an optional target name. The object is
	registered as the cell in this hub with this name/target
	address. The cell address must be free to use - if it is in
	used an error string is logged and returned. This address will be the
	primary one for this cell. undef or () is returned upon
	success.

	alias_cell( $object, $alias )
	alias_cell( $object, $alias, $target )

	This class method takes the object and a cell alias for it and
	an optional target name. The object will be registered as the
	cell in this hub with this alias/target address. The object
	must already be registered cell or an error string is logged
	and returned.  undef or () is returned upon a success.

	lookup_cell( $name, $target )

	This class method takes a cell name and an optional target and
	it looks up the cell registered under that address pair. It
	returns the object if found or undef or () upon failure.

	unregister_cell( $object )

	This class method takes a object and deletes it and all of its
	names and aliases from the cell registry. If the object is not
	registered an error string is logged and returned.

=head1 AUTHOR

Originally started by Uri, current breakout by a-mused.

=head1 STATUS

Actively being developed.

=head1 LAST-CHANGE

Mon Jan 22 14:15:52 EST 2001

=head1 NOTES

  newest at the bottom

  23 Jan 01
  [01:09:34] <uri> here is a registry issue: i want to interpose cell in a
           message stream. how do i do that without redoing all the configs?
  [01:09:50] <uri> sorta like invisible renaming on the fly
  [01:09:56] <amused> hrmm
  [01:10:11] <uri> think about it. that will be big one day
  [01:11:01] <uri> just like sysv streams. we push stuff onto the registry address. then messages get sent down
           the list of pushed cells before being delivered to the real destination.
  [01:11:29] <uri> so we need a way of moving messages from cell to cell without registering them globally but in
           some sort of pipeline
  [01:13:39] <amused> doesn't that violate a whole bunch of models and break distributed (multi-target) stuff?
  [01:13:45] <uri> so instead of deliver, they RETURN a message. like status_cmd returns a status string
  [01:14:12] <uri> no, only certain cells do that and only when they get
           messages delivered that way.
  [01:14:31] <uri> like stream_msg_in is called and it will return a message.
  [01:14:44] <uri> insteead of msg_in or status_cmd.
  [01:14:51] <amused> gotcha
  [01:14:58] <uri> special input/output.
  [01:15:00] <uri> same cell
  [01:16:18] <uri> i like that. A LOT! very easy to do cell wise. and not much
           work on the delivery side. some way to make the registry store a
           stack of these under the name. make it a simple structure instead
           of a cell you find with lookup.
  [13:14:51] <uri> you push filter cells onto the destination cell (indexed by
           its object ref). then any alias to it will have the same stack of
           filters.
  [13:15:52] <uri> when we deliver a message (the stuf you are touching), we
           lookup the cell and then lookup via its ref) any filters. we then
           loop over the filters passing in the message and getting one in
           return and passint it to the next filter.
  [13:16:02] <uri> just like sysV streams but unidirectional.
  [13:16:38] <uri> we can interpose ANY set of filters before any named cell
           transparently
  [13:16:39] <uri> this is VERY cool.
  [13:16:53] <uri> but not critical now. i just want to write up some notes on
           it.

=cut

