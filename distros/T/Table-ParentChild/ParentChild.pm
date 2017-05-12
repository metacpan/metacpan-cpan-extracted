# ============================================================
# Table::
#  ____                      _    ____ _     _ _     _ 
# |  _ \ __ _ _ __ ___ _ __ | |_ / ___| |__ (_) | __| |
# | |_) / _` | '__/ _ \ '_ \| __| |   | '_ \| | |/ _` |
# |  __/ (_| | | |  __/ | | | |_| |___| | | | | | (_| |
# |_|   \__,_|_|  \___|_| |_|\__|\____|_| |_|_|_|\__,_|
#                                                      
# ============================================================

=head1 NAME

Table::ParentChild - Fast lookup for Parent-Child relationships

=head1 SYNOPSIS

  use Table::ParentChild;
  my $table = new Table::ParentChild( \@relationships );

  my @parents  = $table->parent_lookup( $child_id );
  my @children = $table->child_lookup( $parent_id );
  my $quantity = $table->quantity_lookup( $parent_id, $child_id );

  # Alternatively, given a $child_id...

  my $parent   = $table->parent_lookup( $child_id );
  my @parents  = keys %$parent;

  foreach my $parent_id ( @parents ) {
    my $quantity = $parent->{ $parent_id };
    print "There are $quantity $child_id in $parent_id\n";
  }

  # Or, given a $parent_id...

  my $child    = $table->child_lookup( $parent_id );
  my @children = keys %$child;

  foreach my $child_id ( @children ) {
    my $quantity = $child->{ $child_id };
    print "There are $quantity $child_id in $parent_id\n";
  }

=head1 DESCRIPTION

Table::ParentChild implements a cross-linked list in two
dimensions. It is ideal for describing the parent-child 
relationships of large numbers of entities. For maximum
speed, Table::ParentChild uses hashes to get access to
the table row/column headers, and then traverses a linked-
list written in XS. The emphasis of development was on
speed first, small memory footprint second, ease-of-use 
third, and flexibility be damned :^)>.

To populate a table, simply build an array of arrays.
The first element in the sub-array is the id of the parent.
The second element of the sub-array is the id of the child.
The third (and optional) element of the sub-array is the
quantity. Table::ParentChild will automatically build
appropriate headers for the table and populate the table,
returning a table object for your lookup pleasure.

Be forewarned that ids are implemented as unsigned long 
integers and quantities are implemented as floating point 
values. The values you feed the table will be coerced into 
the appropriate data type, which may cause a failure in 
translation of the data.

=cut

package Table::ParentChild;

require 5.005_62;
use strict;
use warnings;
use Carp;

require Exporter;
require DynaLoader;
use AutoLoader;
use Table::ParentChild::Head;

our @ISA = qw(Exporter DynaLoader);

our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw( );
our $VERSION = '0.05';

# ============================================================
sub new {
# ============================================================
	my ($class) = map { ref || $_ } shift;
	my $relationships = shift;

	my $self = bless {
		parent	=> {},
		child	=> {}
	}, $class;

	foreach my $relationship ( @$relationships ) {
		$self->add_relationship( @$relationship );
	}

	return $self;
}

# ============================================================
sub add_relationship {
# ============================================================
	my $self = shift;
	my $parent_id = shift;
	my $child_id = shift;
	my $quantity = shift;

	no strict;
	$quantity = 1 if( not defined $quantity );

	my $parent;
	my $child;

	if( exists $self->{ parent }{ $parent_id }) {
		$parent = $self->{ parent }{ $parent_id };

	} else {
		$parent = new Table::ParentChild::Head( $parent_id );
		$self->{ parent }{ $parent_id } = $parent;
	}

	if( exists $self->{ child }{ $child_id }) {
		$child = $self->{ child }{ $child_id };

	} else {
		$child = new Table::ParentChild::Head( $child_id );
		$self->{ child }{ $child_id } = $child;
	}

	$parent->add_node( $child, $quantity );

}

# ============================================================
sub parent_lookup {
# ============================================================
	my $self = shift;
	my $child_id = shift;
	my $child;
	my $results;

	if( exists $self->{ child }{ $child_id } ) {
		$child = $self->{ child }{ $child_id };

	} else {
		return;
	}

	$results = $child->search_for_parents;
	return wantarray ? sort keys %$results : $results;
}

# ============================================================
sub child_lookup {
# ============================================================
	my $self = shift;
	my $parent_id = shift;
	my $parent;
	my $results;

	if( exists $self->{ parent }{ $parent_id } ) {
		$parent = $self->{ parent }{ $parent_id };

	} else {
		return;
	}

	$results = $parent->search_for_children;
	return wantarray ? sort keys %$results : $results;
}

1;
__END__

=head2 EXPORT

=head1 AUTHOR

Mike Wong E<lt>mike_w3@pacbell.netE<gt>

Copyright (c) 2002, All Rights Reserved

This software is free software and may be redistributed and/or
modified under the same terms as Perl itself.

=head1 SEE ALSO

perl(1).

=cut
