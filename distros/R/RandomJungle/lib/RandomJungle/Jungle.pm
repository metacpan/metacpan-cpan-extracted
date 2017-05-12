package RandomJungle::Jungle;

=head1 NAME

RandomJungle::Jungle - Consolidated interface for Random Jungle input and output data

=cut

use strict;
use warnings;

use Carp;
use Devel::StackTrace;

use RandomJungle::File::DB;
use RandomJungle::Tree;

=head1 VERSION

Version 0.05

=cut

our $VERSION = 0.05;
our $ERROR; # used if new() fails

=head1 SYNOPSIS

RandomJungle::Jungle provides a simplified interface to access Random Jungle input and output data.
See RandomJungle::Tree for methods relating to the classification trees produced by Random Jungle,
and RandomJungle::File::DB for lower-level methods that are wrapped by this module.

	use RandomJungle::Jungle;

	my $rj = RandomJungle::Jungle->new( db_file => $file ) || die $RandomJungle::Jungle::ERROR;
	$rj->store( xml_file => $file, oob_file => $file, raw_file => $file ) || die $rj->err_str;
	my $href = $rj->summary_data(); # for loaded data

	my $href = $rj->get_filenames; # filenames specified in store()
	my $href = $rj->get_rj_input_params; # input params that were used when RJ was run
	my $aref = $rj->get_variable_labels; # (expected:  SEX PHENOTYPE var1 ...)
	my $aref = $rj->get_sample_labels; # from the IID column of the RAW file

	# Returns data for the specified sample, where $label is the IID from the RAW file
	my $href = $rj->get_sample_data_by_label( label => $label ) || warn $rj->err_str;

	my $aref = $rj->get_tree_ids;
	my $tree = $rj->get_tree_by_id( $id ) || warn $rj->err_str; # RJ::Tree object

	# Returns hash of arefs containing lists of tree IDs, by OOB state for the sample
	my $href = $rj->get_oob_for_sample( $label ) || warn $rj->err_str;

	# Returns the OOB state for a given sample and tree ID
	my $val = $rj->get_oob_state( sample => $label, tree_id => $id ) || warn $rj->err_str;

	# Returns a hash of arefs containing lists of sample labels, by OOB for the tree
	my $href = $rj->get_oob_for_tree( $tree_id ) || warn $rj->err_str;

	# Error handling
	$rj->set_err( 'Something went boom' );
	my $msg = $rj->err_str;
	my $trace = $rj->err_trace;

=cut

#*********************************************************************
#                          Public Methods
#*********************************************************************

=head1 METHODS

=head2 new()

Creates and returns a new RandomJungle::Jungle object:

	my $rj = RandomJungle::Jungle->new( db_file => $file ) || die $RandomJungle::Jungle::ERROR;

The 'db_file' parameter is required.
Returns undef and sets $ERROR on failure.

=cut

sub new
{
	# carps and returns undef if $args{db_file} is not defined
	my ( $class, %args ) = @_;

	my $obj = {};
	bless $obj, $class;
	$obj->_init( %args ) || return; # $ERROR is set by _init()

	return $obj;
}

=head2 store()

This method loads data into the RandomJungle::File::DB database.  All parameters are optional,
so files can be loaded in a single call or in multiple calls.  Each type of file can only be
loaded once; subsequent calls to this method for a given file type will overwrite the
previously-loaded data.

	$rj->store( xml_file => $file, oob_file => $file, raw_file => $file ) || die $rj->err_str;

Returns true on success.  Sets err_str and returns false if an error occurred.

=cut

sub store
{
	# Stores files specified by [xml_file oob_file raw_file] into the db
	# Returns true on success, returns false and sets err_str on failure
	my ( $self, %args ) = @_;

	my $rjdb = $self->{rjdb};
	if( ! defined $rjdb )
	{
		$self->set_err( "Cannot store data without valid db connection" );
		return;
	}

	my %params;
	foreach my $filetype qw( xml_file oob_file raw_file )
	{
		if( defined $args{$filetype} )
		{
			$params{$filetype} = $args{$filetype};
		}
	}

	$rjdb->store_data( %params ) ||
		do
		{
			# need to preserve the error from the original class
			my $err = join( "\n", $rjdb->err_str, $rjdb->err_trace );
			$self->set_err( $err );
			return;
		};

	return 1;
}

=head2 get_filenames()

Returns a hash reference containing the names of the files specified in store():

	my $href = $rj->get_filenames;

Keys in the href are db, xml, oob, and raw.

=cut

sub get_filenames
{
	# Returns an href containing the names of the data source files in the db
	my ( $self ) = @_;

	my $rjdb = $self->{rjdb};

	my %data = ( db  => $rjdb->get_db_filename,
				 xml => $rjdb->get_xml_filename,
				 oob => $rjdb->get_oob_filename,
				 raw => $rjdb->get_raw_filename, );

	return \%data;
}

=head2 get_rj_input_params()

Returns a href of the input parameters used when Random Jungle was run:

	my $href = $rj->get_rj_input_params; # $href->{$param_name} = $param_value;

=cut

sub get_rj_input_params
{
	# Returns a href of the input params that were used for RJ
	my ( $self ) = @_;

	my $rjdb = $self->{rjdb};
	my $href = $rjdb->get_rj_params;

	return $href;
}

=head2 get_variable_labels()

Returns a reference to an array that contains the variable labels from the RAW file:

	my $aref = $rj->get_variable_labels; # (expected:  SEX PHENOTYPE var1 ...)

=cut

sub get_variable_labels
{
	# Returns an aref of the variable labels from the RAW file (expected:  SEX PHENOTYPE var1 ...)
	my ( $self ) = @_;

	my $rjdb = $self->{rjdb};
	my $aref = $rjdb->get_variable_labels;

	return $aref;
}

=head2 get_sample_labels()

Returns a reference to an array that contains the sample labels from the IID column of the RAW file:

	my $aref = $rj->get_sample_labels;

=cut

sub get_sample_labels
{
	# Returns an aref of sample labels from the IID column of the RAW file
	my ( $self ) = @_;

	my $rjdb = $self->{rjdb};
	my $aref = $rjdb->get_sample_labels;

	return $aref;
}

=head2 get_sample_data_by_label()

Returns a hash ref containing data for the sample specified by label => $label, where label is
the IID from the RAW file.  Sets err_str and returns undef if label is not specified or is invalid.

	my $href = $rj->get_sample_data_by_label( label => $label ) || warn $rj->err_str;

$href has the following structure:
	SEX => $val,
	PHENOTYPE => $val,
	orig_data => $line, (unsplit, unspliced)
	index => $i, (index in aref from get_sample_labels(), can be used to index into OOB matrix)
	classification_data => $aref, (can be passed to RandomJungle::Tree->classify_data)

=cut

sub get_sample_data_by_label
{
	# Returns sample data specified by label => $label, where label is the IID from the RAW file
	# Sets err_str and returns undef if label is not specified or is invalid
	my ( $self, %args ) = @_;

	my $rjdb = $self->{rjdb};
	my $href = $rjdb->get_sample_data( %args );

	if( ! defined $href )
	{
		# need to preserve the error from the original class
		my $err = join( "\n", $rjdb->err_str, $rjdb->err_trace );
		$self->set_err( $err );
		return;
	}

	return $href;
}

=head2 get_tree_ids()

Returns an array ref of tree IDs (sorted numerically):

	my $aref = $rj->get_tree_ids;

=cut

sub get_tree_ids
{
	# Returns an aref of tree IDs
	my ( $self ) = @_;

	my $rjdb = $self->{rjdb};
	my $aref = $rjdb->get_tree_ids;

	return $aref;
}

=head2 get_tree_by_id()

Returns a RandomJungle::Tree object for the specified tree.

	my $tree = $rj->get_tree_by_id( $id ) || warn $rj->err_str;

Sets err_str and returns undef if tree ID is undef or invalid, or if an internal error occurred.

=cut

sub get_tree_by_id
{
	# Returns RJ::Tree object on success, sets err_str and returns undef on failure
	# Sets err_str and returns undef if tree ID is undef or invalid, or if missing
	# required params to ::Tree->new()
	my ( $self, $id ) = @_;

	if( ! defined $id )
	{
		$self->set_err( "Tree ID is required to retrieve tree" );
		return;
	}

	my $rjdb = $self->{rjdb};

	my $href = $rjdb->get_tree_data( $id ); # Returns an empty href if tree ID is invalid

	if( ! exists $href->{$id} )
	{
		$self->set_err( "Error retrieving data for tree [$id] (may be invalid ID) - cannot create object" );
		return;
	}

	# get variable labels so can translate from indices to labels if desired
	my $aref = $rjdb->get_variable_labels; # incl. sex, phenotype, and all genotypes

	# include variable labels as an optional param when creating the tree; returns undef if fails
	my $tree = RandomJungle::Tree->new( %{ $href->{$id} }, variable_labels => $aref );

	if( ! defined $tree )
	{
		$self->set_err( $RandomJungle::Tree::ERROR );
		return;
	}

	return $tree;
}

=head2 get_oob_for_sample()

Returns lists of tree IDs, by OOB state, for the specified sample label.

	my $href = $rj->get_oob_for_sample( $label ) || warn $rj->err_str;

The href contains the following keys, each of which point to an array reference containing tree IDs:
	sample_used_to_construct_trees => [],
	sample_not_used_to_construct_trees => [],

Sets err_str and returns undef if the specified sample cannot be found (invalid label) or on error.

=cut

sub get_oob_for_sample
{
	# Takes a sample label as single param, where label is the sample label (IID) from the RAW file.
	# Returns an href with keys sample_used_to_construct_trees and sample_not_used_to_construct_trees,
	# each of which are an aref of tree IDs.
	# Sets err_str and returns undef if the specified sample cannot be found (invalid label) or on error.
	my ( $self, $label ) = @_;

	if( ! defined $label )
	{
		$self->set_err( "Sample label is undefined" );
		return;
	}

	my $rjdb = $self->{rjdb};
	my $tree_ids = $rjdb->get_tree_ids;

	my $line = $rjdb->get_oob_by_sample( label => $label );

	if( ! defined $line )
	{
		# need to preserve the error from the original class
		my $err = join( "\n", $rjdb->err_str, $rjdb->err_trace );
		$self->set_err( $err );
		return;
	}

	my @states = split( "\t", $line );

	my $oob_results = $self->_classify_oob_states( \@states, $tree_ids ) || return;

	my %results = ( sample_used_to_construct_trees => $oob_results->{in_bag},
					sample_not_used_to_construct_trees => $oob_results->{oob} );

	return \%results;
}

=head2 get_oob_state()

Returns the OOB state for a given sample label and tree ID:

	my $val = $rj->get_oob_state( sample => $label, tree_id => $id ) || warn $rj->err_str;

Expected values are 0 (the sample is "in bag" for the tree) or 1 (the sample is "out of bag" for the tree).

Sets err_str and returns undef if sample or tree_id are not defined, or if sample label is invalid.

=cut

sub get_oob_state
{
	# Returns the OOB state (expect 0 or 1) for a given sample and tree ID, specified as params
	# using sample => $label, tree_id => $id, where label is from the IID column of the RAW file.
	# Sets err_str and returns undef if sample or tree_id are not defined, or if sample label is invalid.
	my ( $self, %params ) = @_;

	if( ! defined $params{sample} || ! defined $params{tree_id} )
	{
		$self->set_err( "sample and tree_id are required parameters to determine OOB state" );
		return;
	}

	my $rjdb = $self->{rjdb};

	# find tree index given ID (shouldn't assume they are equal) - removing for efficiency
	#my @tree_ids = @{ $rjdb->get_tree_ids };
	#my ( $tree_i ) = grep { $tree_ids[$_] == $params{tree_id} ? 1 : 0 } ( 0 .. $#tree_ids );
	my $tree_i = $params{tree_id};

	my $line = $rjdb->get_oob_by_sample( label => $params{sample} );

	if( ! defined $line )
	{
		# need to preserve the error from the original class
		my $err = join( "\n", $rjdb->err_str, $rjdb->err_trace );
		$self->set_err( $err );
		return;
	}

	my $oob_state = ( split( "\t", $line ) )[ $tree_i ];

	return $oob_state;
}

=head2 get_oob_for_tree()

Returns lists of sample labels, by OOB state, for the specified tree ID.

	my $href = $rj->get_oob_for_tree( $tree_id ) || warn $rj->err_str;

The href contains the following keys, each of which point to an array reference containing sample labels:
	in_bag_samples => [],
	oob_samples => [],

Sets err_str and returns undef if the specified tree ID cannot be found (invalid) or on error.

=cut

sub get_oob_for_tree
{
	# Takes a tree ID as single param.
	# Returns an href with keys in_bag_samples and oob_samples
	# each of which are an aref of sample labels (where label is from the IID column of the RAW file).
	# Sets err_str and returns undef if the specified tree ID cannot be found (invalid) or on error.
	my ( $self, $tree_id ) = @_;

	if( ! defined $tree_id )
	{
		$self->set_err( "Tree ID is undefined" );
		return;
	}

	my $rjdb = $self->{rjdb};

	# Validate $tree_id
	my $href = $rjdb->get_tree_data( $tree_id );

	if( scalar keys %$href == 0 )
	{
		$self->set_err( "Invalid tree ID [$tree_id]" );
		return;
	}

	my $samples = $rjdb->get_sample_labels;
	my @states;

	foreach my $sample ( @$samples )
	{
		my $state = $self->get_oob_state( sample => $sample, tree_id => $tree_id );
		return if( ! defined $state );
		push( @states, $state );
	}

	my $oob_results = $self->_classify_oob_states( \@states, $samples );

	return if( ! defined $oob_results );

	my %results = ( in_bag_samples => $oob_results->{in_bag},
					oob_samples => $oob_results->{oob} );

	return \%results;
}

=head2 summary_data()

Returns an href containing a summary of the data that is loaded into the db:

	my $href = $rj->summary_data();

$href contains the output of other methods in this class, and it has the following structure:

	filenames => get_filenames(),
	rj_params => get_rj_input_params(),
	variable_labels => get_variable_labels() and see below,
	sample_labels   => get_sample_labels() and see below,
	tree_ids        => get_tree_ids() and see below,

The keys variable_labels, sample_labels, and tree_ids all point to hrefs.
Each href has the following structure:

	all_labels => $aref, (for variable_labels and sample_labels)
	all_ids    => $aref, (for tree_ids only)
	first => $val, (the first element of the all* aref)
	last  => $val, (the last element of the all* aref)
	count => $val, (the size of the all* aref)

=cut

sub summary_data
{
	# Returns an href containing a summary of the data that is loaded into the db
	my ( $self ) = @_;

	my %data;

	$data{filenames} = $self->get_filenames;
	$data{rj_params} = $self->get_rj_input_params;

	my $vars = $self->get_variable_labels;
	$data{variable_labels}{all_labels} = $vars;
	$data{variable_labels}{count} = scalar @$vars;
	$data{variable_labels}{first} = $vars->[0];
	$data{variable_labels}{last} = $vars->[-1];

	my $samples = $self->get_sample_labels;
	$data{sample_labels}{all_labels} = $samples;
	$data{sample_labels}{count} = scalar @$samples;
	$data{sample_labels}{first} = $samples->[0];
	$data{sample_labels}{last} = $samples->[-1];

	my $trees = $self->get_tree_ids;
	$data{tree_ids}{all_ids} = $trees;
	$data{tree_ids}{count} = scalar @$trees;
	$data{tree_ids}{first} = $trees->[0];
	$data{tree_ids}{last} = $trees->[-1];

	return \%data;
}

=head2 set_err()

Sets the error message (provided as a parameter) and creates a stack trace:

	$rj->set_err( 'Something went boom' );

=cut

sub set_err
{
	my ( $self, $errstr ) = @_;

	$self->{err_str} = $errstr || '';
	$self->{err_trace} = Devel::StackTrace->new;
}

=head2 err_str()

Returns the last error message that was set:

	my $msg = $rj->err_str;

=cut

sub err_str
{
	my ( $self ) = @_;

	return $self->{err_str};
}

=head2 err_trace()

Returns a backtrace for the last error that was encountered:

	my $trace = $rj->err_trace;

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
	# Sets $ERROR and returns undef if $args{db_file} is not defined
	my ( $self, %args ) = @_;

	@{ $self->{params} }{ keys %args } = values %args;

	if( ! defined $args{db_file} )
	{
		$ERROR = "Cannot create new object - db_file is a required parameter";
		return;
	}

	my $rjdb = RandomJungle::File::DB->new( db_file => $args{db_file} );

	if( ! defined $rjdb )
	{
		$self->set_err( $RandomJungle::File::DB::ERROR );
		return;
	}

	$self->{rjdb} = $rjdb;
}

sub _classify_oob_states
{
	# Takes aref to OOB states and aref to labels (e.g., tree IDs or sample labels)
	# Translates the OOB state at each position into 'in_bag' and 'oob'.
	# Returns an href with those categories as keys, which point to arefs containing the
	# labels in each category.  This can be used to find, for a given sample, which trees
	# the sample was used to construct.  It can also be used to find which samples were
	# in/out of bag for a given tree.
	# Sets err_str and returns undef if @states and @labels are different sizes, or
	# if a state is invalid.
	my ( $self, $states, $labels ) = @_;

	if( scalar @$states != scalar @$labels )
	{
		$self->set_err( "Warning: number of OOB states does not equal the number of labels provided" );
		return;
	}

	my ( @used, @notused );

	foreach my $i ( 0 .. scalar @$states - 1 )
	{
		if( $states->[$i] eq '0' )
		{
			push( @used, $labels->[$i] ); # in bag
		}
		elsif( $states->[$i] eq '1' )
		{
			push( @notused, $labels->[$i] ); # OOB
		}
		else
		{
			my $val = $states->[$i];
			$self->set_err( "Warning: unrecognized OOB state [$val] for label $labels->[$i]" );
			return;
		}
	}

	my $results = { in_bag => \@used, oob => \@notused };

	return $results;
}

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

$self
	params
		db_file => $filename
		<arg in new()> => $val
	rjdb => $RJ_DB object
	err_str => $errstr
	err_trace => Devel::StackTrace object

=cut

1;

