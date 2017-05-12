package RandomJungle::Tree;

=head1 NAME

RandomJungle::Tree - A Random Jungle classification tree

=cut

use strict;
use warnings;

use Carp;
use Data::Dumper;
use Devel::StackTrace;

use RandomJungle::Tree::Node;

=head1 VERSION

Version 0.04

=cut

our $VERSION = 0.05;
our $ERROR; # used if new() fails

=head1 SYNOPSIS

RandomJungle::Tree represents a classification tree from Random Jungle.
This class uses RandomJungle::Tree::Node to represent the nodes in the tree.

	use RandomJungle::Tree;

	my $tree = RandomJungle::Tree->new( %params ) || die $RandomJungle::Tree::ERROR;

	my $tree_id = $tree->id;

	# Returns the variables used in the tree
	my $aref = $tree->get_variables; # aref of indices
	my $href = $tree->get_variables( variable_labels => 1 ); # label => index

	# Classifies $data using this tree and returns either the predicted phenotype
	# or RandomJungle::Tree::Node object for the terminal node
	my $predicted_pheno = $tree->classify_data( $data );
	my $node_obj = $tree->classify_data( $data, as_node => 1 );
	my $node_obj = $tree->classify_data( $data, skip_validation => 1 );

	my $node_obj = $tree->get_node_by_vector_index( $vi ) || warn $tree->err_str;

	my $vi = $tree->get_root_node;
	my $node_obj = $tree->get_root_node( as_node => 1 );

	my $aref = $tree->get_all_nodes; # aref of vector indices
	my $aref = $tree->get_all_nodes( as_node => 1 ); # aref of node objects

	my $aref = $tree->get_terminal_nodes; # aref of vector indices
	my $aref = $tree->get_terminal_nodes( as_node => 1 ); # aref of node objects

	# Carps and returns undef on error (invalid index) or if called with index 0 (no parent)
	my $vi_of_parent = $tree->get_parent_of_vector_index( $vi );
	my $node_obj = $tree->get_parent_of_vector_index( $vi, as_node => 1 );

	# Returns an aref containing vector indices of all nodes in the path to the specified
	# vector index, beginning at the root of the tree and ending at the specified vector index.
	my $aref = $tree->get_path_to_vector_index( $vi ) || warn $tree->err_str;

	my $depth = $tree->get_depth_of_vector_index( $vi );

	# $href contains the max depth of the tree and a list of all vector indices at that depth
	my $href = $tree->max_node_depth;

	# Error handling
	$tree->set_err( 'Something went boom' );
	my $msg = $tree->err_str;
	my $trace = $tree->err_trace;

=cut

#*********************************************************************
#                          Public Methods
#*********************************************************************

=head1 METHODS

=head2 new()

Creates and returns a new RandomJungle::Tree object:

	my $tree = RandomJungle::Tree->new( %params ) || die $RandomJungle::Tree::ERROR;

Required keys in %params:
	id => $tree_id (from the XML file)
	var_id_str   => $str (from the XML file)
	values_str   => $str (from the XML file)
	branches_str => $str (from the XML file)

Optional keys in %params:
	variable_labels => $aref (variables from the RAW file, excluding headers)

The required components of %params are returned from RandomJungle::File::XML->get_tree_data().
The aref for variable_labels can be obtained from RandomJungle::Jungle->get_variable_labels().

Sets $ERROR and returns undef on failure.

=cut

sub new
{
	# Returns a RJ::Tree object on success, sets $ERROR and returns undef on failure
	# Required keys in %args [see _init()]:
	#   id => $tree_id (from the XML file)
	#   var_id_str   => $str (from the XML file)
	#   values_str   => $str (from the XML file)
	#   branches_str => $str (from the XML file)
	# Optional keys in %args:
	#   variable_labels => $aref (ALL variables, from .raw file)
	my ( $class, %args ) = @_;

	my $obj = {};
	bless $obj, $class;
	$obj->_init( %args ) || return; # _init() sets $ERROR

	return $obj;
}

=head2 id()

Returns the tree ID:

	my $tree_id = $tree->id;

=cut

sub id
{
	# Returns the tree ID
	my ( $self ) = @_;

	return $self->{id};
}

=head2 get_variables()

Returns the variables used in the tree.  By default, returns an aref of indices (see RAW file).
If  'variable_labels => 1' is specified in %params, returns a href { $label => $index } if
variable_labels was specified in new(), or sets err_str and returns undef otherwise.

	my $aref = $tree->get_variables; # variable indices
	my $href = $tree->get_variables( variable_labels => 1 ); # $href->{$label} = $index

=cut

sub get_variables
{
	# Default (no %params):  return aref of indices for variables used in the tree
	# If  'variable_labels => 1' is specified in %params, a href ($label => $index) for variables
	# used in the tree will be returned (if they are available; undef otherwise).  (Can't make this
	# default behavior b/c would require making variable_labels a req'd param when creating a new Tree.)
	my ( $self, %params ) = @_;

	my @branches = $self->_parse_branches_string();

	my @var_ids = $self->_parse_var_id_string(); # highly redundant; indices (col #s), not labels!
	my %var_ids = map { $_ => 1 } @var_ids; # non-redundant
	# note: %var_ids will contain 0 b/c it is used to mark terminal nodes
	# we need to check the branches at each instance of 0 to disambiguate a terminal node
	# from var 0 actually being used in the tree (in ped format, 0 is sex)

	if( ! $self->_is_variable_index_0_used )
	{
		delete $var_ids{0};
	}

	my @var_indices = sort { $a <=> $b } keys %var_ids;

	if( defined $params{variable_labels} && $params{variable_labels} == 1 )
	{
		if( exists $self->{variable_labels} )
		{
			# create hash lookup for var name => index (assumes var names are unique)
			my $all_labels = $self->{variable_labels}; # all labels from the input (.raw) data file, not FID IID MAT PAT
			my %var_label2index = map { $all_labels->[$_] => $_ } @var_indices;
			return \%var_label2index;
		}
		else
		{
			# this tree object was not created with variable_labels in new()
			$self->set_err( 'Variable labels were not provided to new() - cannot complete request' );
			return;
		}
	}
	else
	{
		# default:  aref of column indices (see .raw file), not variable labels
		return \@var_indices;
	}
}

=head2 classify_data()

Classifies $data using this tree.  Returns the terminal value (predicted phenotype) by default.
If as_node => 1 is specified, returns a RandomJungle::Tree::Node object that represents the
terminal node after classification.  If skip_validation => is specified, the data validation step
will be skipped; this is a performance improvement but if invalid data is present the classification
will fail and undef will be returned.  Use skip_validation with caution.

	my $predicted_pheno = $tree->classify_data( $data );
	my $node_obj = $tree->classify_data( $data, as_node => 1 );
	my $node_obj = $tree->classify_data( $data, skip_validation => 1 );

$data must be an arrayref containing the data values to be classified.  The order of the
columns must be the same as that which was used to construct the tree (see RAW file).
Note: $data must not include header values (for FID, IID, PAT, and MAT).

$data can be obtained from RandomJungle::Jungle->get_sample_data_by_label().

Sets err_str and returns undef if an error occurs (e.g., $data contains a value that is not 0, 1, or 2).

=cut

sub classify_data
{
	# Classifies $data using this tree and returns the predicted phenotype or node object on success.
	#   $data must be an arrayref containing the data values to be classified.  The order of the
	#   columns must be the same as that which was used to construct the tree (see RAW file).
	#   Note: do not include the header values (FID, IID, PAT, MAT) in $data - pass variable cols only
	# Sets err_str and returns undef if an error occurs (e.g., $data contains a value that is not 0, 1, or 2).
	# Returns the terminal value (predicted phenotype) by default.  If as_node => 1 is specified,
	# returns a RJ::Tree::Node object that represents the terminal node after classification.
	# If skip_validation => is specified, the data validation step will be skipped prior to
	# classification (this is a performance improvement).  If invalid data is present the
	# classification will fail and undef will be returned.

	my ( $self, $data, %args ) = @_;

	unless( defined $args{skip_validation} && $args{skip_validation} == 1 )
	{
		$self->_validate_data( $data ) || return; # checks structure and content, not # elements
	}

	my $nodes = $self->{rj_tree};
	my $node_num = 0; # index within the varID/values/branches vector (start at root = 0)

	# could add check to break loop if $nodes->[$node_num] is undef ($node_num out of bounds),
	# but that should not happen given the source of the data and the checks within the loop
	# could do: while( (defined $nodes->[$node_num]) && (! exists $nodes->[$node_num]{terminal_value}) )
	while( ! exists $nodes->[$node_num]{terminal_value} )
	{
		my $var_id = $nodes->[$node_num]{var_id}; # index of variable to be tested
		#return if ! defined $var_id; # commented out - source is internal and should be safe

		my $dataval = $data->[ $var_id ]; # value of data at given variable index
		if( ! defined $dataval )
		{
			# in case @$data is too short and $var_id > $#data
			$self->set_err( 'Warning: undef value obtained from data array (may be shorter than expected)' );
			return;
		}

		my $next_node_num = $nodes->[$node_num]{next_node_for_val}[ $dataval ];
		#return if ! defined $next_node_num; # commented out - source is internal and should be safe

		#print "node i = $node_num, var id = $var_id, data = $dataval, next node i = $next_node_num\n";

		$node_num = $next_node_num;
	}

	#print "node i = $node_num, terminal value = $nodes->[$node_num]{terminal_value}\n";

	if( defined $args{as_node} && $args{as_node} == 1 )
	{
		# return node object if requested
		# this could fail if the node href became corrupted, but that doesn't seem likely
		my $node = $self->get_node_by_vector_index( $node_num );
		return $node;
	}
	else
	{
		# return terminal value (by default)
		return $nodes->[$node_num]{terminal_value};
	}
}

=head2 get_node_by_vector_index()

Returns a RandomJungle::Tree::Node object for a given vector index (from the varID/values/branches
arrays in the XML file).

	my $node_obj = $tree->get_node_by_vector_index( $vi );

Sets err_str and returns undef on error (invalid index).

=cut

sub get_node_by_vector_index
{
	# Returns a RJ::Tree::Node object for a given vector index (from the varID/values/branches
	# arrays in the XML file).  Sets err_str and returns undef on error (invalid index).
	my ( $self, $vi ) = @_;

	$self->_validate_vector_index( $vi ) || return;

	my $node = RandomJungle::Tree::Node->new( vector_index => $vi,
											  node_data => $self->{rj_tree}[$vi] );

	if( ! defined $node )
	{
		# need to preserve the error from the original class
		$self->set_err( $RandomJungle::Tree::Node::ERROR );
		return;
	}

	return $node;
}

=head2 get_root_node()

Returns the root node in the tree (vector index 0).
The vector index is returned by default.  If called with 'as_node => 1' a RandomJungle::Tree::Node
object is returned.

	my $vi = $tree->get_root_node;
	my $node_obj = $tree->get_root_node( as_node => 1 );

=cut

sub get_root_node
{
	# Returns the root node in the tree (vector index 0).
	# Returns vector index by default, or a RJ::Tree::Node object if called with 'as_node => 1'.
	my ( $self, %args ) = @_;

	my $vi = 0; # root has index 0

	if( defined $args{as_node} && $args{as_node} == 1 )
	{
		# return node object if requested
		# this could fail if the node href became corrupted, but that doesn't seem likely
		my $node = $self->get_node_by_vector_index( $vi );
		return $node;
	}
	else
	{
		# return vector index by default
		return $vi;
	}
}

=head2 get_all_nodes()

Returns an aref of all nodes in the tree.
Vector indices are returned by default.  If called with 'as_node => 1' RandomJungle::Tree::Node
objects are returned.

	my $aref = $tree->get_all_nodes;
	my $aref = $tree->get_all_nodes( as_node => 1 );

=cut

sub get_all_nodes
{
	# Returns an aref of all nodes in the tree.
	# Returns vector indices by default, or RJ::Tree::Node objects if called with 'as_node => 1'.
	my ( $self, %args ) = @_;

	my @vector_indices = ( 0 .. scalar @{ $self->{rj_tree} } - 1 );

	if( defined $args{as_node} && $args{as_node} == 1 )
	{
		# return node objects if requested
		# this could fail if the node href became corrupted, but that doesn't seem likely
		my @nodes = map { $self->get_node_by_vector_index( $_ ) } @vector_indices;
		return \@nodes;
	}
	else
	{
		# return vector indices by default
		return \@vector_indices;
	}
}

=head2 get_terminal_nodes()

Returns an aref of all terminal nodes in the tree.
Vector indices are returned by default.  If called with 'as_node => 1' RandomJungle::Tree::Node
objects are returned.

	my $aref = $tree->get_terminal_nodes;
	my $aref = $tree->get_terminal_nodes( as_node => 1 );

=cut

sub get_terminal_nodes
{
	# Returns an aref of all terminal nodes in the tree.
	# Returns vector indices by default, or RJ::Tree::Node objects if called with 'as_node => 1'.
	my ( $self, %args ) = @_;

	my @vector_indices = ( 0 .. scalar @{ $self->{rj_tree} } - 1 );

	my @term_indices = grep { exists $self->{rj_tree}[$_]{terminal_value} } @vector_indices;

	if( defined $args{as_node} && $args{as_node} == 1 )
	{
		# return node objects if requested
		# this could fail if the node href became corrupted, but that doesn't seem likely
		my @nodes = map { $self->get_node_by_vector_index( $_ ) } @term_indices;
		return \@nodes;
	}
	else
	{
		# return vector indices by default
		return \@term_indices;
	}
}

=head2 get_parent_of_vector_index()

Returns the parent of the node with the specified vector index.
The vector index of the parent node is returned by default.  If called with 'as_node => 1'
a RandomJungle::Tree::Node object is returned.

	my $vi_of_parent = $tree->get_parent_of_vector_index( $vi );
	my $node_obj = $tree->get_parent_of_vector_index( $vi, as_node => 1 );

Sets err_str and returns undef on error (invalid index) or if called with index 0
(index 0 is the root node, which has no parent).

=cut

sub get_parent_of_vector_index
{
	# Returns the parent of the node with the specified vector index.
	# Returns the vector index by default, or a RJ::Tree::Node object if called with 'as_node => 1'.
	# Sets err_str and returns undef on error (invalid index) or if called with index 0
	# (index 0 is the root node, which has no parent).
	my ( $self, $vi, %args ) = @_;

	$self->_validate_vector_index( $vi ) || return;

	if( $vi == 0 )
	{
		$self->set_err( 'Root node (vector index 0) has no parent' );
		return;
	}

	my $parent_i = $self->{rj_tree}[$vi]{index_of_parent_node};

	if( defined $args{as_node} && $args{as_node} == 1 )
	{
		# return node object if requested
		# this could fail if the node href became corrupted, but that doesn't seem likely
		my $node = $self->get_node_by_vector_index( $parent_i );
		return $node;
	}
	else
	{
		# return vector index by default
		return $parent_i;
	}
}

=head2 get_path_to_vector_index()

Returns an aref containing the vector indices of all nodes in the path to the specified
vector index, beginning at the root of the tree and ending at the specified vector index.

	my $aref = $tree->get_path_to_vector_index( $vi );

Sets err_str and returns undef on error (invalid vector index).

=cut

sub get_path_to_vector_index
{
	# Returns an aref containing vector indices of all nodes in the path to the specified
	# vector index, beginning at the root of the tree and ending at the specified index.
	# Sets err_str and returns undef on error (invalid vector index).
	my ( $self, $vi ) = @_;

	$self->_validate_vector_index( $vi ) || return;

	my @path = ( $vi );

	while( $vi != 0 )
	{
		my $vi_of_parent = $self->get_parent_of_vector_index( $vi );

		# could check $vi_of_parent for undef, but don't expect that to ever occur once in this
		# loop b/c already check passed param for validity and now using only internal data
		# [ could use while( defined $vi && $vi != 0 ) instead ]

		unshift( @path, $vi_of_parent );
		$vi = $vi_of_parent;
	}

	# Note:  could cache @path in the record for $vi (and all other nodes in this path),
	# but don't anticipate using this method very often.

	return \@path;
}

=head2 get_depth_of_vector_index()

Returns the depth of the node with the specified vector index, where the root node
has a depth of 1, the child nodes of the root have depth = 2, etc.

	my $depth = $tree->get_depth_of_vector_index( $vi );

Sets err_str and returns undef on error (invalid vector index).

=cut

sub get_depth_of_vector_index
{
	# Returns the depth of the node at the specified vector index in the tree, where the root node
	# has a depth of 1 and the child nodes of the root have depth = 2, etc.
	# Returns undef on error (invalid vector index), err_str should also be set.
	# Note:  This method is a wrapper for scalar @{ get_path_to_vector_index }.
	my ( $self, $vi ) = @_;

	$self->_validate_vector_index( $vi ) || return;

	my $path = $self->get_path_to_vector_index( $vi );
	my $depth = scalar @{ $path };

	return $depth;
}

=head2 max_node_depth()

Returns a hash reference that contains the max depth of the tree and a list of all
vector indices at that depth.

	my $href = $tree->max_node_depth;

$href has the following structure:
	depth => $max_depth,
	vector_indices => $aref_of_vi,

where $aref_of_vi is an array reference that contains all vector indices at the max depth.

=cut

sub max_node_depth
{
	# Returns an href: { depth => $max_depth, vector_indices => [ $vi, ... ] }
	# where the vector_indices aref is a list of all vi's at the max depth.
	# This calls get_depth_of_vector_index() internally (which fails with invalid index,
	# but that is not expected as all vi's used here are obtained internally).
	my ( $self ) = @_;

	my $term_vi_aref = $self->get_terminal_nodes;

	# Using $max_depth and @vi_at_max_d in the loop would be more efficient than storing
	# all results in %depths (only to discard most at the end).
	my %depths; # $depth => [ $vi, ... ]

	foreach my $vi ( @$term_vi_aref )
	{
		my $depth = $self->get_depth_of_vector_index( $vi );
		push( @{ $depths{$depth} }, $vi );
	}

	my $max_depth = ( sort { $a <=> $b } ( keys %depths ) )[-1];

	return { depth => $max_depth, vector_indices => $depths{$max_depth} };
}

=head2 set_err()

Sets the error message (provided as a parameter) and creates a stack trace:

	$tree->set_err( 'Something went boom' );

=cut

sub set_err
{
	my ( $self, $errstr ) = @_;

	$self->{err_str} = $errstr || '';
	$self->{err_trace} = Devel::StackTrace->new;
}

=head2 err_str()

Returns the last error message that was set:

	my $msg = $tree->err_str;

=cut

sub err_str
{
	my ( $self ) = @_;

	return $self->{err_str};
}

=head2 err_trace()

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

=head1 INTERNAL METHODS

=cut

sub _init
{
	# Checks for required params and creates data struct for the tree
	# Returns 1 on success, sets err_str and returns undef on failure.
	my ( $self, %args ) = @_;

	@{ $self }{ keys %args } = values %args;

	foreach my $param qw( id var_id_str values_str branches_str )
	{
		if( ! defined $self->{$param} )
		{
			$ERROR = "Cannot create object:  $param is not defined";
			return;
		}
	}

	my $tree = $self->_create_tree;

	if( ! defined $tree )
	{
		# values string contains unexpected value, $ERROR set by _create_tree()
		return;
	}

	$self->{rj_tree} = $tree;

	return 1;
}

sub _create_tree
{
	# Creates a data struct representing the tree using the var ID, values, and branches data
	# in the XML file.  Returns the data struct on success.  Sets err_str and returns undef on failure
	# (unexpected value in the 'values' string).
	my ( $self ) = @_;

	my @var_ids = $self->_parse_var_id_string(); # highly redundant
	my @values = $self->_parse_values_string();
	my @branches = $self->_parse_branches_string();

	my @tree;

	foreach my $i ( 0 .. $#var_ids )
	{
		if( $branches[$i] eq '0,0' )
		{
			# terminal node
			$tree[$i]{terminal_value} = $values[$i];
		}
		else
		{
			$tree[$i]{var_id} = $var_ids[$i]; # index of variable to test

			my $thresh = $values[$i]; # test val for this node

			if( $thresh =~ m/\D/ )
			{
				# unexpected - can't use in numeric comparison below
				$ERROR = "Unexpected value [$thresh] in 'values string' at index $i - tree construction failed";
				return;
			}

			my ( $left, $right ) = split( /,/, $branches[$i] );

			foreach my $genoval ( 0..2 )
			{
				# use the data val as the index into this array, get next node directly
				$tree[$i]{next_node_for_val}[$genoval] = ( $genoval <= $thresh ) ? $left : $right;
			}

			# set cross-refs for reverse lookup (root node (index 0) never gets set so is undef)
			$tree[$left]{index_of_parent_node} = $i;
			$tree[$right]{index_of_parent_node} = $i;
		}
	}

	return \@tree;
}

=head2 _parse_var_id_string()

Parses the 'varID' string from the XML file and returns an array of variable indices.

	my @var_ids = $tree->_parse_var_id_string();

Note:  @var_ids are indices (column numbers) of the variables within the RAW file, not variable labels.

The varID string is a required parameter of new().

=cut

sub _parse_var_id_string
{
	# Parses the var ID string from the XML file and returns an array.
	# Note these are indices (column numbers) of the variables within the RAW file, not var labels.
	my ( $self ) = @_;

	my $var_id = $self->{var_id_str};
	$var_id =~ s[^\(\(][];
	$var_id =~ s[\)\)$][];
	my @var_ids = split( /,/, $var_id ); # highly redundant

	return @var_ids;
}

=head2 _parse_branches_string()

Parses the 'branches' string from the XML file and returns an array of branch elements.
Each element is a string of the format 'left,right', which are the vector indices of the
child nodes of the current node.

	my @branches = $tree->_parse_branches_string();

The branches string is a required parameter of new().

=cut

sub _parse_branches_string
{
	# Parses the branches string from the XML file.
	# Returns an array of elements, each one is a 'left,right' pair.
	my ( $self ) = @_;

	my $branch = $self->{branches_str};
	$branch =~ s[^\(\(][];
	$branch =~ s[\)\)$][];
	my @branches = split( m[\),\(], $branch );

	return @branches;
}

=head2 _parse_values_string()

Parses the 'values' string from the XML file and returns an array of values which are used
as thresholds for classifying genotype data.

	my @values = $tree->_parse_values_string();

The values string is a required parameter of new().

=cut

sub _parse_values_string
{
	# Parses the values string from the XML file and returns an array.
	my ( $self ) = @_;

	my $vals = $self->{values_str};
# old code, broke when terminal value was not single digit
#	$vals =~ s[^\(][];
#	$vals =~ s[\)$][];
#	my @values = map { $_ =~ m/(\d)/ } split( /,/, $vals ); # assumes var is single digit
	$vals =~ s[\(][]g;
	$vals =~ s[\)][]g;
	my @values = split( /,/, $vals );

	return @values;
}

sub _validate_vector_index
{
	# Returns 1 if the specified vector index is valid, sets err_str and returns undef otherwise.
	my ( $self, $vi ) = @_;

	if( ! defined $vi )
	{
		$self->set_err( 'Vector index is undefined' );
		return;
	}
	elsif( ($vi =~ m/\D/) || (! defined $self->{rj_tree}[$vi]) )
	{
		$self->set_err( "Invalid vector index ($vi)" );
		return;
	}

	return 1;
}

sub _is_variable_index_0_used
{
	# Returns 1 if the variable at index 0 was used in the tree, 0 if it was not used in the tree
	my ( $self ) = @_;

	# the variable at index 0 is used in the tree if 0 is in the var_ids array and it is
	# NOT a terminal node (indicated by '0,0' at the corresponding position in the branches array)
	my @var_ids = $self->_parse_var_id_string();
	my @branches = $self->_parse_branches_string();

	my $keep_index_zero = 0; # assume not used in tree

	# check instances of 0 in var index string vs the branch string
	foreach my $i ( 0 .. scalar @var_ids - 1 )
	{
		if( $var_ids[$i] == 0 )
		{
			if( $branches[$i] eq '0,0' )
			{
				# terminal node
			}
			else
			{
				# not a terminal node; the var at index 0 was used in the tree
				$keep_index_zero = 1;
				last;
			}
		}
	}

	return $keep_index_zero;
}

sub _validate_data
{
	# Returns 1 if all values in @$data are 0, 1, or 2.  Sets err_str and returns 0 otherwise.
	my ( $self, $data ) = @_;

	if( ! defined $data )
	{
		$self->set_err( 'No data provided' );
		return 0;
	}
	elsif( ref( $data ) ne 'ARRAY' )
	{
		$self->set_err( 'Data must be provided as a reference to an array' );
		return 0;
	}

	foreach my $i ( 0 .. scalar @$data - 1 )
	{
		if( ! defined $data->[$i] )
		{
			$self->set_err( "Genotype is not defined at index [$i]" );
			return 0;
		}
		elsif( $data->[$i] ne '0' && $data->[$i] ne '1' && $data->[$i] ne '2' )
		{
			# using 'ne' rather than != to protect against warnings if value is non-numeric
			$self->set_err( "Invalid genotype ($data->[$i]) at index [$i]" );
			return 0;
		}
	}

	return 1;
}

=head1 FUTURE IDEAS

$retval = create cytoscape file ( $out_filename )

Add caching for node depth and path to node (if used a lot)

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

$VAR1 = bless( {
                 'rj_tree' => [
                                {
                                  'next_node_for_val' => [
                                                           1,      <== index, not label
                                                           '370',  <== index, not label
                                                           '370'   <== index, not label
                                                         ],
                                  'var_id' => '490'                <== index, not label
                                  'index_of_parent_node' => undef  <== undef for root node (index 0)
                                },
                                {
                                  'terminal_value' => '2'
                                  'index_of_parent_node' => 4
                                },
                 'var_id_str' => '((490,967,1102,...))',     <== indices, not labels
                 'values_str' => '(((0)),((0)),((1)),...)',
                 'branches_str' => '((1,370),(2,209),(3,160),...)',
                 'variable_labels' => [ 'SEX', 'PHENOTYPE', 'Var1', ... ] <== optional in new()
                 'id' => '0'
				 'err_str' => $errstr
				 'err_trace' => Devel::StackTrace object
               }, 'RandomJungle::Tree' );


=cut

1;
