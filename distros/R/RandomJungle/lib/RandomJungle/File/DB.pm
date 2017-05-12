package RandomJungle::File::DB;

=head1 NAME

RandomJungle::File::DB - Low level access to the data in the RandomJungle DB file

=cut

use strict;
use warnings;

use Carp;
use Data::Dumper;
use DBM::Deep;
use Devel::StackTrace;

use RandomJungle::File::XML;
use RandomJungle::File::OOB;
use RandomJungle::File::RAW;

=head1 VERSION

Version 0.05

=cut

our $VERSION = 0.06;
our $ERROR; # used if new() fails

=head1 SYNOPSIS

RandomJungle::File::DB provides access to the data contained within the RandomJungle database that
is created using this module.
See RandomJungle::Jungle and RandomJungle::Tree for higher-level methods.

	use RandomJungle::File::DB;

	my $rjdb = RandomJungle::File::DB->new( db_file => $filename ) || die $RandomJungle::File::DB::ERROR;

	# Load data files into the db (all params are optional)
	$rjdb->store_data( xml_file => $file1, oob_file => $file2, raw_file => $file3 ) || warn $rjdb->err_str;

	# Get the filenames for the data that was loaded
	my $file = $rjdb->get_db_filename;
	my $file = $rjdb->get_xml_filename;
	my $file = $rjdb->get_oob_filename;
	my $file = $rjdb->get_raw_filename;

	my $href = $rjdb->get_rj_params; # input params that were used when RJ was run
	my $aref = $rjdb->get_header_labels; # (expected:  FID IID PAT MAT)
	my $aref = $rjdb->get_variable_labels; # (expected:  SEX PHENOTYPE var1 ...)
	my $aref = $rjdb->get_sample_labels; # from the IID column of the RAW file
	my $aref = $rjdb->get_tree_ids; # sorted numerically

	# Returns the line (unsplit, unspliced) from the OOB file for a given sample (one param is required)
	my $line = $rjdb->get_oob_by_sample( label => $sample_label, index => $sample_index )
		or warn $rjdb->err_str;

	# Returns data for the sample specified by label => $label, where label is the IID from the RAW file
	my $href = $rjdb->get_sample_data( label => $label ) || warn $rjdb->err_str;

	# Returns a href (not RJ::Tree objects) for each tree ID specified as an input param
	my $href = $rjdb->get_tree_data( @tree_ids ); # may be big - use with caution

=cut

#*********************************************************************
#                          Public Methods
#*********************************************************************

=head1 METHODS

=head2 new()

Creates and returns a new RandomJungle::File::DB object:

	my $rjdb = RandomJungle::File::DB->new( db_file => $filename );

The 'db_file' parameter is required.  Sets $ERROR and returns undef on failure.

=cut

sub new
{
	# Returns RJ::File::DB object on success
	# Sets $ERROR and returns undef on failure (e.g., 'db_file' param not set)
	my ( $class, %args ) = @_;

	my $obj = {};
	bless $obj, $class;
	$obj->_init( %args ) || return; # $ERROR set by _init()

	return $obj;
}

=head2 store_data()

This method loads data into the RJ::File::DB database.  All parameters are optional, so files can be
loaded in a single call or in multiple calls.  Each type of file can only be loaded once; subsequent
calls to this method for a given file type will overwrite the previously-loaded data.

	$rjdb->store_data( xml_file => $file1, oob_file => $file2, raw_file => $file3 ) || die $rjdb->err_str;

Returns true on success.  Sets err_str and returns false if an error occurred.

=cut

sub store_data
{
	# Returns true on success, false on failure
	# The _load*file methods set err_str on failure (file does not exist or ::[XML|OOB|RAW]->new fails)
	my ( $self, %args ) = @_;

	my $ok = 1;
	my $errstr = '';

	if( defined $args{xml_file} )
	{
		$self->{params}{xml_file} = $args{xml_file};
		$self->_load_xml_file( $args{xml_file} ) ||
			do
			{
				$ok = 0;
				$errstr .= $self->err_str;
			};
	}

	if( defined $args{oob_file} )
	{
		$self->{params}{oob_file} = $args{oob_file};
		$self->_load_oob_file( $args{oob_file} ) ||
			do
			{
				$ok = 0;
				$errstr .= $self->err_str;
			};
	}

	if( defined $args{raw_file} )
	{
		$self->{params}{raw_file} = $args{raw_file};
		$self->_load_raw_file( $args{raw_file} ) ||
			do
			{
				$ok = 0;
				$errstr .= $self->err_str;
			};
	}

	if( ! $ok )
	{
		$self->set_err( $errstr );
	}

	return $ok;
}

=head2 get_db_filename()

Returns the name of the DB file specified in store_data():

	my $file = $rjdb->get_db_filename;

=cut

sub get_db_filename
{
	# Returns the db filename
	my ( $self ) = @_;
	return $self->{params}{db_file};
}

=head2 get_xml_filename()

Returns the name of the XML file specified in store_data():

	my $file = $rjdb->get_xml_filename;

=cut

sub get_xml_filename
{
	# Returns the XML filename
	my ( $self ) = @_;
	my $db = $self->{db};
	my $data = $db->{XML}{filename}; # copy so can't modify db
	return $data;
}

=head2 get_rj_params()

Returns a href of the input parameters used when Random Jungle was run:

	my $href = $rjdb->get_rj_params; # $href->{$param_name} = $param_value;

=cut

sub get_rj_params
{
	# Returns a href of the input params that were used for RJ
	my ( $self ) = @_;
	my $db = $self->{db};
	my %data = %{ $db->{XML}{options} }; # copy so can't modify db
	return \%data;
}

=head2 get_tree_ids()

Returns an array ref of tree IDs (sorted numerically):

	my $aref = $rjdb->get_tree_ids;

=cut

sub get_tree_ids
{
	# Returns an aref of tree IDs
	my ( $self ) = @_;
	my $db = $self->{db};
	#my @ids = sort { $a <=> $b } keys %{ $db->{XML}{tree_data} };
	#my @ids = @{ $db->{XML}{tree_ids} };
	my @ids = split( "\t", $db->{XML}{tree_ids_str} );
	return \@ids;
}

=head2 get_tree_data()

Returns a href containing a data record for each tree ID specified as an input param.  The record
for each tree is a data structure from the XML file, not a RandomJungle::Tree object.  Invalid tree
IDs are skipped.  An empty href is returned if no valid IDs are provided.

	my $href = $rjdb->get_tree_data( @tree_ids ); # may be big - use with caution

Note:  This method is not intended to be called directly.  See RandomJungle::Jungle::get_tree_by_id().

=cut

sub get_tree_data
{
	# Returns a href containing a record for each tree ID specified as an input param
	# Note the return struct contains data from the XML file (not RJ::Tree objects)
	# Invalid tree IDs are skipped
	# Returns an empty href if no valid IDs are provided
	my ( $self, @tree_ids ) = @_;

	my $db = $self->{db};
	my %data;

	foreach my $id ( @tree_ids )
	{
		# Devel::Cover has a bug that doesn't detect coverage on this statement with a DBM::Deep
		# hash.  See https://rt.cpan.org/Ticket/Display.html?id=72027 for the bug report.
		next if( ! exists $db->{XML}{tree_data}{$id} );

		$data{$id} = {};
		%{ $data{$id} } = %{ $db->{XML}{tree_data}{$id} };
	}

	return \%data;
}

=head2 get_oob_filename()

Returns the name of the OOB file specified in store_data():

	my $file = $rjdb->get_oob_filename;

=cut

sub get_oob_filename
{
	# Returns the OOB filename
	my ( $self ) = @_;
	my $db = $self->{db};
	my $data = $db->{OOB}{filename}; # copy so can't modify db
	return $data;
}

=head2 get_oob_by_sample()

Returns the line (unsplit, unspliced) from the OOB file for a given sample.  The sample is specified
by either label => $label or index => $index (one is required), where label is the sample label
(IID) from the RAW file and index is the row number of the sample in the RAW file.
Sets err_str and returns undef if neither required parameter is specified or if the specified sample
cannot be found.

	my $line = $rjdb->get_oob_by_sample( label => $sample_label, index => $sample_index )
		or warn $rjdb->err_str;

=cut

sub get_oob_by_sample
{
	# Returns the line (unsplit, unspliced) from the OOB file for a given sample
	# Sample is specified by either label => $label or index => $index (one is required),
	# where label is the sample label (IID) from the RAW file
	# and index is the row num of the sample in the RAW file (not the sample label, IID)
	# Carps and returns undef if neither required param is specified or if the
	# specified sample id cannot be found
	my ( $self, %args ) = @_;

	# id supported for legacy code but is deprecated in favor of label (consistent with ::RAW)
	if( ! defined $args{label} && defined $args{id} )
	{
		$args{label} = $args{id};
	}

	if( ! defined $args{label} && ! defined $args{index} )
	{
		$self->set_err( 'Getting OOB by sample requires either sample label or index as input' );
		return;
	}

	my $db = $self->{db};
	my $sample_i = exists $args{index} ? $args{index} : $self->_sample_label_to_index( $args{label} );

	if( ! defined $sample_i )
	{
		$self->set_err( "Cannot find sample index for sample label ($args{label})" );
		return;
	}

	my $line = $db->{OOB}{matrix}[$sample_i]; # will auto-vivify if OOB file is truncated

	if( ! defined $line )
	{
		$self->set_err( "Cannot find data for sample $sample_i (out of range?)" );
		return;
	}

	return $line;
}

=head2 get_raw_filename()

Returns the name of the RAW file specified in store_data():

	my $file = $rjdb->get_raw_filename;

=cut

sub get_raw_filename
{
	# Returns the RAW filename
	my ( $self ) = @_;
	my $db = $self->{db};
	my $data = $db->{RAW}{filename}; # copy so can't modify db
	return $data;
}

=head2 get_header_labels()

Returns a reference to an array that contains the header labels from the RAW file:

	my $aref = $rjdb->get_header_labels; # (expected:  FID IID PAT MAT)

=cut

sub get_header_labels
{
	# Returns an aref of the header labels from the RAW file (expected:  FID IID PAT MAT)
	my ( $self ) = @_;
	my $db = $self->{db};
	my @data = @{ $db->{RAW}{header_labels} };
	return \@data;
}

=head2 get_variable_labels()

Returns a reference to an array that contains the variable labels from the RAW file:

	my $aref = $rjdb->get_variable_labels; # (expected:  SEX PHENOTYPE var1 ...)

=cut

sub get_variable_labels
{
	# Returns an aref of the variable labels from the RAW file (expected:  SEX PHENOTYPE var1 ...)
	my ( $self ) = @_;
	my $db = $self->{db};
	#my @data = @{ $db->{RAW}{variable_labels} };
	my @data = split( "\t", $db->{RAW}{variable_labels_str} );
	return \@data;
}

=head2 get_sample_labels()

Returns a reference to an array that contains the sample labels from the IID column of the RAW file:

	my $aref = $rjdb->get_sample_labels;

=cut

sub get_sample_labels
{
	# Returns an aref of sample labels from the IID column of the RAW file
	my ( $self ) = @_;
	my $db = $self->{db};
	#my @data = @{ $db->{RAW}{sample_labels} };
	my @data = split( "\t", $db->{RAW}{sample_labels_str} );
	return \@data;
}

=head2 get_sample_data()

Returns a hash ref containing data for the sample specified by label => $label, where label is
the IID from the RAW file.  Sets err_str and returns undef if label is not specified or is invalid.

	my $href = $rjdb->get_sample_data( label => $label ) || warn $rjdb->err_str;

$href has the following structure:
	SEX => $val,
	PHENOTYPE => $val,
	orig_data => $line, (unsplit, unspliced)
	index => $i, (index in aref from get_sample_labels(), can be used to index into OOB matrix)
	classification_data => $aref, (can be passed to RandomJungle::Tree->classify_data)

=cut

sub get_sample_data
{
	# Returns sample data specified by label => $label, where label is the IID from the RAW file
	# Sets err_str and returns undef if label is not specified or is invalid
	my ( $self, %args ) = @_;

	if( ! defined $args{label} )
	{
		$self->set_err( 'Cannot retrieve sample data without sample label' );
		return;
	}

	my $db = $self->{db};
	my $label = $args{label};

	# Devel::Cover has a bug that doesn't detect coverage on this statement with a DBM::Deep
	# hash.  See https://rt.cpan.org/Ticket/Display.html?id=72027 for the bug report.
	if( ! exists $db->{RAW}{raw_data}{$label} )
	{
		$self->set_err( "Error retrieving sample data - invalid label ($label)" );
		return;
	}

	my %data = %{ $db->{RAW}{raw_data}{$label} };
	$data{label} = $label;

	# Prepare an array of data values that is suitable for passing to ::Tree->classify_data
	# Requires splitting and splicing off the non-variable elements
	my @data = split( / /, $data{orig_data} ); # FID IID PAT MAT SEX PHENOTYPE ...
	my ( $fid, $iid, $pat, $mat ) = splice( @data, 0, 4 );
	$data{classification_data} = \@data;

	return \%data;
}

=head2 set_err()

Sets the error message (provided as a parameter) and creates a stack trace:

	$rjdb->set_err( 'Something went boom' );

=cut

sub set_err
{
	my ( $self, $errstr ) = @_;

	$self->{err_str} = $errstr || '';
	$self->{err_trace} = Devel::StackTrace->new;
}

=head2 err_str()

Returns the last error message that was set:

	my $msg = $rjdb->err_str;

=cut

sub err_str
{
	my ( $self ) = @_;

	return $self->{err_str};
}

=head2 err_trace()

Returns a backtrace for the last error that was encountered:

	my $trace = $rjdb->err_trace;

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
	# sets $ERROR and returns undef if $args{db_file} is not defined
	my ( $self, %args ) = @_;

	if( ! defined $args{db_file} )
	{
		$ERROR = "Cannot create new object - db_file is a required parameter";
		return;
	}

	$self->_db_connect( $args{db_file} );
}

sub _db_connect
{
	my ( $self, $file ) = @_;

	# removed check so does not prevent creation of new dbm file
	#if( ! -e $file )
	#{
	#	carp "Error - cannot connect to db: $file does not exist";
	#	return;
	#}

	$self->{params}{db_file} = $file;

	my $db = DBM::Deep->new( $file ); # apparently no risk of failure (see docs)

	$self->{db} = $db;
	return 1;
}

sub _load_xml_file
{
	# returns true on success, sets err_str and returns undef on failure
	# overwrites any existing XML entries in the db
	my ( $self, $file ) = @_;

	my $rj_xml = RandomJungle::File::XML->new( filename => $file ) ||
		do
		{
			# need to preserve the error from the original class
			my $err = $RandomJungle::File::XML::ERROR;
			$self->set_err( $err );
			return;
		};

	$rj_xml->parse ||
		do
		{
			# need to preserve the error from the original class
			my $err = join( "\n", $rj_xml->err_str, $rj_xml->err_trace );
			$self->set_err( $err );
			return;
		};

	my $db = $self->{db};
	$db = $db->{XML} = {}; # will overwrite existing

	$db->{filename} = $rj_xml->get_filename;
	$db->{options} = $rj_xml->get_RJ_input_params;
	$db->{tree_data} = $rj_xml->get_tree_data;
	#$db->{tree_ids} = $rj_xml->get_tree_ids;
	$db->{tree_ids_str} = join( "\t", @{ $rj_xml->get_tree_ids } );

	return 1;
}

sub _load_oob_file
{
	# returns true on success, sets err_str and returns undef on failure
	# overwrites any existing OOB entries in the db
	my ( $self, $file ) = @_;

	my $rj_oob = RandomJungle::File::OOB->new( filename => $file ) ||
		do
		{
			# need to preserve the error from the original class
			my $err = $RandomJungle::File::OOB::ERROR;
			$self->set_err( $err );
			return;
		};

	$rj_oob->parse ||
		do
		{
			# need to preserve the error from the original class
			my $err = join( "\n", $rj_oob->err_str, $rj_oob->err_trace );
			$self->set_err( $err );
			return;
		};

	my $db = $self->{db};
	$db = $db->{OOB} = {}; # will overwrite existing

	$db->{filename} = $rj_oob->get_filename;
	$db->{matrix} = $rj_oob->get_matrix;

	return 1;
}

sub _load_raw_file
{
	# returns true on success, sets err_str and returns undef on failure
	# overwrites any existing RAW entries in the db
	my ( $self, $file ) = @_;

	my $rj_raw = RandomJungle::File::RAW->new( filename => $file ) ||
		do
		{
			# need to preserve the error from the original class
			my $err = $RandomJungle::File::RAW::ERROR;
			$self->set_err( $err );
			return;
		};

	$rj_raw->parse ||
		do
		{
			# need to preserve the error from the original class
			my $err = join( "\n", $rj_raw->err_str, $rj_raw->err_trace );
			$self->set_err( $err );
			return;
		};

	my $db = $self->{db};
	$db = $db->{RAW} = {}; # will overwrite existing

	$db->{filename} = $rj_raw->get_filename;
	$db->{header_labels} = $rj_raw->get_header_labels;
	$db->{raw_data} = $rj_raw->get_sample_data;

	#$db->{variable_labels} = $rj_raw->get_variable_labels;
	$db->{variable_labels_str} = join( "\t", @{ $rj_raw->get_variable_labels } );

	#$db->{sample_labels} = $rj_raw->get_sample_labels;
	my $sample_lbls = $rj_raw->get_sample_labels;
	$db->{sample_labels_str} = join( "\t", @$sample_lbls );

	# add index to sample hashes so can easily index into OOB matrix
	#my $num_samples = scalar @{ $db->{sample_labels} };
	my $num_samples = scalar @$sample_lbls;

	foreach my $i ( 0 .. $num_samples-1 )
	{
		#my $sample_iid = $db->{sample_labels}[$i];
		my $sample_iid = $sample_lbls->[$i];
		$db->{raw_data}{$sample_iid}{index} = $i;
	}

	return 1;
}

=head1 INTERNAL METHODS

=head2 _sample_label_to_index()

Returns the sample index (row in the RAW file, used to index into the OOB file) for a given
sample label (from the IID column in the RAW file).  Returns undef if the parameter is undef
or if the label is invalid.

	my $sample_index = $rjdb->_sample_label_to_index( $sample_label ) || warn "Invalid label";

=cut

sub _sample_label_to_index
{
	# Returns the sample index (row in the RAW file, used to index into the OOB file)
	# for a given sample label (from the IID column in the RAW file).
	# Returns undef if the param is undef or an invalid label
	my ( $self, $label ) = @_;

	return if( ! defined $label );

	my $db = $self->{db};

	# Devel::Cover has a bug that doesn't detect coverage on this statement with a DBM::Deep
	# hash.  See https://rt.cpan.org/Ticket/Display.html?id=72027 for the bug report.
	return if( ! exists $db->{RAW}{raw_data}{$label} );

	return $db->{RAW}{raw_data}{$label}{index};
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
		xml_file => $filename
		oob_file => $filename
		raw_file => $filename
		$args => $val (passed as params to new)
	db => $dbm_deep_object
	err_str => $errstr
	err_trace => Devel::StackTrace object

$dbm_deep_object
	XML
		filename => $filename
		options
			$name => $value (input parameters for RJ)
		tree_data
			$tree_id
				id => $tree_id, (also used to index into OOB matrix (column within $line)
				var_id_str => varID string from XML, e.g., '((490,967,1102,...))'
				values_str => values string from XML, e.g., '(((0)),((0)),((1)),...)'
				branches_str => branches string from XML, e.g., '((1,370),(2,209),(3,160),...)'
		#tree_ids => [ $tree_id, ... ] # no longer used, stored as string for efficient retrieval
		tree_ids_str => join( "\t", $tree_id, ... )
	OOB
		filename => $filename
		matrix => [ $line, ... ]
	
	RAW
		filename => $filename
		header_labels => [ FID, IID, PAT, MAT ] (expected)
		#variable_labels => [ SEX, PHENOTYPE, rs... ] # no longer used, stored as string for efficient retrieval
		variable_labels_str => join( "\t", qw( SEX PHENOTYPE rs... ) )
		#sample_labels => [ $iid, ... ] # no longer used, stored as string for efficient retrieval
		sample_labels_str => join( "\t", $iid, ... )
		raw_data
			$iid
				SEX => $val
				PHENOTYPE => $val
				orig_data => $line (unsplit, unspliced)
				index => $i (order in sample array, used to index into OOB matrix)


=cut

1;

