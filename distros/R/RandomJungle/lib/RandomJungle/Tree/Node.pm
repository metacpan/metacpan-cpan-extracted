package RandomJungle::Tree::Node;

=head1 NAME

RandomJungle::Tree::Node - A simple representation of a node in a RandomJungle::Tree

=cut

use strict;
use warnings;

use Carp;
use Data::Dumper;
use Devel::StackTrace;

=head1 VERSION

Version 0.02

=cut

our $VERSION = 0.02;
our $ERROR; # used if new() fails

=head1 SYNOPSIS

RandomJungle::Tree::Node is a simple representation of a node in a RandomJungle::Tree.
This class provides access to data about a node.
The constructor is not intended to be called outside of RandomJungle::Tree.

	use RandomJungle::Tree::Node;

	my $node = RandomJungle::Tree::Node->new( vector_index => $i, node_data => $href )
		or die $RandomJungle::Tree::Node::ERROR;

	my $bool = $node->is_terminal;
	my $predicted_pheno = $node->get_terminal_value || warn $node->err_str;

	my $variable_i = $node->get_variable_index || warn $node->err_str;

	my $vector_i = $node->get_vector_index;
	my $vector_i = $node->get_vector_index_of_parent || warn $node->err_str;

	# Returns the index of the next node based on a genotype value ( 0, 1, 2 )
	my $vector_i = $node->get_vector_index_for_genotype( $genotype )
		or warn $node->err_str;

	# Error handling
	$node->set_err( 'Something went boom' );
	my $msg = $node->err_str;
	my $trace = $node->err_trace;

=cut

#*********************************************************************
#                          Public Methods
#*********************************************************************

=head1 METHODS

=head2 new()

Creates and returns a new RandomJungle::Tree::Node object:

	my $node = RandomJungle::Tree::Node->new( vector_index => $i, node_data => $href )
		or die $RandomJungle::Tree::Node::ERROR;

Both parameters are required:
	vector_index is the index of the node in the varID/values/branches vector (see XML file)
	node_data is an href from a RandomJungle::Tree object (from the rj_tree array within the object)

This method sets $ERROR and returns undef on failure.

Note:  This method is not intended to be called outside of RandomJungle::Tree, as the interface
and the structure of the node_data $href is not guaranteed to be stable.

=cut

sub new
{
	# Required params: vector_index => $i, node_data => $href
	# Sets $ERROR and returns undef on failure
	my ( $class, %args ) = @_;

	my $obj = {};
	bless $obj, $class;
	$obj->_init( %args ) || return; # $ERROR set by _init()

	return $obj;
}

=head2 is_terminal()

Returns 1 or 0, depending on whether or not the node is a terminal node, respectively.

	my $bool = $node->is_terminal;

=cut

sub is_terminal
{
	# Returns 1 or 0, depending on whether or not the node is a terminal node
	my ( $self ) = @_;

	return $self->{rj_tree_node}{is_terminal};
}

=head2 get_variable_index()

Returns the index of the variable (from the RAW file) to be tested in this node.
Note this is not the variable label.

	my $variable_i = $node->get_variable_index || warn $node->err_str;

Sets err_str and returns undef if the node is a terminal node.

=cut

sub get_variable_index
{
	# Returns the index of the variable to be tested in this node (from the RAW file)
	# if the node is non-terminal.  If the node is terminal, returns undef and sets err_str.
	my ( $self ) = @_;

	if( $self->is_terminal )
	{
		$self->set_err( 'This is a terminal node: no variable to test' );
		return undef;
	}

	return $self->{rj_tree_node}{variable_index};
}

=head2 get_terminal_value()

Returns the terminal value (predicted phenotype) of the node, if it is a terminal node.

	my $predicted_pheno = $node->get_terminal_value || warn $node->err_str;

Sets err_str and returns undef if the node is not a terminal node.

=cut

sub get_terminal_value
{
	# Returns the terminal value (predicted phenotype) of the node, if it is a terminal node.
	# Returns undef and sets err_str if the node is non-terminal.
	my ( $self ) = @_;

	if( ! $self->is_terminal )
	{
		$self->set_err( 'This is not a terminal node' );
		return undef;
	}

	return $self->{rj_tree_node}{terminal_value};
}

=head2 get_vector_index()

Returns the index of the node in the varID/values/branches vector (see XML file).

	my $vector_i = $node->get_vector_index;

=cut

sub get_vector_index
{
	# Returns the index of the node in the varID/values/branches vector (see XML file).
	my ( $self ) = @_;

	return $self->{rj_tree_node}{vector_index};
}

=head2 get_vector_index_of_parent()

Returns the index of the parent node in the varID/values/branches vector (see XML file).

	my $vector_i = $node->get_vector_index_of_parent || warn $node->err_str;

Sets err_str and returns undef if the node is the root of the tree (index 0).

=cut

sub get_vector_index_of_parent
{
	# Returns the index of the parent node in the varID/values/branches vector (see XML file).
	# Sets err_str and returns undef if this is the root node (index 0).
	my ( $self ) = @_;

	if( $self->get_vector_index == 0 )
	{
		$self->set_err( 'Root node does not have a parent' );
		return;
	}

	return $self->{rj_tree_node}{index_of_parent_node};
}

=head2 get_vector_index_for_genotype()

Takes as input a genotype value (valid values are 0, 1, 2) corresponding to the variable to
be tested in this node (see get_variable_index) and returns the vector index of the next
node in the tree, based on the genotype value.

	my $vector_i = $node->get_vector_index_for_genotype( $genotype )
					or warn $node->err_str;

Sets err_str and returns undef if the node is a terminal node or if the genotype is invalid.

=cut

sub get_vector_index_for_genotype
{
	# Returns the index of the next node based on a genotype value passed as a param.
	# Note the index is of the node in the varID/values/branches vector (see the XML file).
	# Valid genotype values are 0, 1, 2.
	# Sets err_str and returns undef if the node is a terminal node or if the genotype is invalid.
	my ( $self, $genotype ) = @_;

	if( $self->is_terminal )
	{
		$self->set_err( 'Cannot get next vector index for a terminal node' );
		return;
	}

	if( ! defined $genotype )
	{
		$self->set_err( 'Genotype is not defined' );
		return;
	}
	elsif( $genotype ne '0' && $genotype ne '1' && $genotype ne '2' )
	{
		$self->set_err( "Invalid genotype [$genotype]" );
		return;
	}

	return $self->{rj_tree_node}{next_vector_i}[$genotype];
}

=head2 set_err

Sets the error message (provided as a parameter) and creates a stack trace:

	$tree->set_err( 'Something went boom' );

=cut

sub set_err
{
	my ( $self, $errstr ) = @_;

	$self->{err_str} = $errstr || '';
	$self->{err_trace} = Devel::StackTrace->new;
}

=head2 err_str

Returns the last error message that was set:

	my $msg = $tree->err_str;

=cut

sub err_str
{
	my ( $self ) = @_;

	return $self->{err_str};
}

=head2 err_trace

Returns a backtrace for the last error that was encountered:

	my $trace = $tree->err_trace;

=cut

sub err_trace
{
	my ( $self ) = @_;

	return $self->{err_trace}->as_string;
}

#*********************************************************************
#                    Private Methods and Routines
#*********************************************************************

sub _init
{
	# Required params: vector_index => $i, node_data => $href
	# Returns true on success, sets $ERROR and returns undef on failure
	my ( $self, %args ) = @_;

	@{ $self }{ keys %args } = values %args;

	foreach my $param qw( vector_index node_data )
	{
		if( ! defined $self->{$param} )
		{
			$ERROR = "Cannot create object:  $param is not defined";
			return;
		}
	}

	# the index of this node in the varID/values/branches vector from the XML file
	$self->{rj_tree_node}{vector_index} = $args{vector_index};

	# the index of the parent of this node
	$self->{rj_tree_node}{index_of_parent_node} = $args{node_data}{index_of_parent_node};

	if( exists $args{node_data}{var_id} )
	{
		$self->{rj_tree_node}{is_terminal} = 0;

		# the index of the variable to be tested in this node (from the RAW file)
		$self->{rj_tree_node}{variable_index} = $args{node_data}{var_id};

		# aref of vector indices, point to the next node based on genotype value
		# genotype values are 0, 1, 2 and correspond to the indices in the aref
		$self->{rj_tree_node}{next_vector_i} = $args{node_data}{next_node_for_val};
	}
	elsif( exists $args{node_data}{terminal_value} )
	{
		$self->{rj_tree_node}{is_terminal} = 1;

		# this is the predicted phenotype for this node
		$self->{rj_tree_node}{terminal_value} = $args{node_data}{terminal_value};
	}
	else
	{
		$ERROR = "Missing node data - cannot create node object";
		return;
	}

	# clean up $self (only those keys that I processed - don't remove others)
	delete $self->{node_data};
	delete $self->{vector_index};

	return 1;
}

=head1 NOTES

I considered implementing this as a subclass of Tree::DAG_Node
but decided there was too much overhead given the current requirements.
Specifically, DAG_Node requires the associations between nodes to be
built within the nodes themselves, which is not consistent with the
current design of RandomJungle::Tree (it contains information about the structure
of the tree and relationships between the nodes, and each node is independent).

A lot of methods could be added to facilitate classification and/or traversal,
but that's not the point of this class, which is intended to simplify getting data about
a node by wrapping the data structure of a node within RandomJungle::Tree.

=head1 SEE ALSO

RandomJungle::Jungle, RandomJungle::Tree, RandomJungle::Tree::Node,
RandomJungle::XML, RandomJungle::OOB, RandomJungle::RAW,
RandomJungle::DB, RandomJungle::Classification_DB

=head1 AUTHOR

Robert R. Freimuth

=head1 COPYRIGHT

Copyright (c) 2011 Mayo Foundation for Medical Education and Research.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

#*********************************************************************
#                                Guts
#*********************************************************************

=begin guts

# not a terminal node (note 'index_of_parent_node' is undef for root, vector_index 0):
$VAR1 = bless( {
                 'rj_tree_node' => {
                                     'next_vector_i' => [
                                                          1,
                                                          1,
                                                          '20'
                                                        ],
                                     'vector_index' => 0,
                                     'is_terminal' => 0,
                                     'variable_index' => '9',
                                     'index_of_parent_node' => undef
                                   }
				 'err_str' => $errstr
				 'err_trace' => Devel::StackTrace object
               }, 'RandomJungle::Tree::Node' );

# terminal node:
$VAR1 = bless( {
                 'rj_tree_node' => {
                                     'vector_index' => 5,
                                     'terminal_value' => '1',
                                     'is_terminal' => 1,
                                     'index_of_parent_node' => 4
                                   }
				 'err_str' => $errstr
				 'err_trace' => Devel::StackTrace object
               }, 'RandomJungle::Tree::Node' );

=cut

1;

