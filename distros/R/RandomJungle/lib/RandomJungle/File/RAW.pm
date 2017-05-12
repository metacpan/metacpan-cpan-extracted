package RandomJungle::File::RAW;

=head1 NAME

RandomJungle::File::RAW - Low level access to the data in the RandomJungle RAW input file

=cut

use strict;
use warnings;

use Carp;
use Data::Dumper;
use Devel::StackTrace;

=head1 VERSION

Version 0.03

=cut

our $VERSION = 0.03;
our $ERROR; # used if new() fails

=head1 SYNOPSIS

RandomJungle::File::RAW provides access to the data contained within the RAW file used as input
for RandomJungle.  This module was developed to support files in ped format only.
See RandomJungle::Jungle for higher-level methods.

	use RandomJungle::File::RAW;

	my $raw = RandomJungle::File::RAW->new( filename => $rawfile ) || die $RandomJungle::File::RAW::ERROR;
	$raw->parse || die $raw->err_str;

	my $file = $raw->get_filename; # returns the filename of the RAW file
	my $aref = $raw->get_header_labels; # FID, IID, PAT, MAT
	my $aref = $raw->get_variable_labels; # SEX, PHENOTYPE, rs... (not incl FID, IID, PAT, MAT)
	my $aref = $raw->get_sample_labels; # from the IID column in the RAW file (ordered by line in the file)
	my $href = $raw->get_sample_data; # all sample data records (convience method for RJ::File::DB)

	# Retrieve information by sample ($iid, from get_sample_labels)
	# These methods set err_str and return undef on error ($iid not specified or invalid)
	my $val = $raw->get_phenotype_for_sample( $iid ); # $iid is from get_sample_labels()
	my $aref = $raw->get_data_for_sample( $iid ); # variable data, suitable for classification (split, spliced)
	my $line = $raw->get_data_for_sample( $iid, orig => 1 ); # original line (unsplit, unspliced) from the RAW file

	my $href = $raw->get_data; # for debugging only; returns raw data structs

	# Error handling
	$raw->set_err( 'Something went boom' );
	my $msg = $raw->err_str;
	my $trace = $raw->err_trace;

=cut

#*********************************************************************
#                          Public Methods
#*********************************************************************

=head1 METHODS

=head2 new()

Creates and returns a new RandomJungle::File::RAW object:

	my $raw = RandomJungle::File::RAW->new( filename => $rawfile );

The 'filename' parameter is required.
Sets $ERROR and returns undef on failure.

=cut

sub new
{
	# Returns RJ::File::RAW object on success
	# Sets $ERROR and returns undef on failure (e.g., 'filename' param not set)
	my ( $class, %args ) = @_;

	my $obj = {};
	bless $obj, $class;
	$obj->_init( %args ) || return; # $ERROR set by _init()

	return $obj;
}

=head2 parse()

Parses the RAW file specified in new():

	my $retval = $raw->parse;

Returns a true value on success.  Sets err_str and returns undef on failure.

=cut

sub parse
{
	# Sets err_str and returns undef if error opening RAW file
	# Sets err_str and returns undef if unexpected header row format
	# Returns true on success

	my ( $self ) = @_;

	open( my $infh, '<', $self->{raw_file}{filename} ) or
		do
		{
			my $err = 'Error opening ' . $self->{raw_file}{filename} . "\n" . $!;
			$self->set_err( $err );
			return;
		};

	# FID IID PAT MAT SEX PHENOTYPE rs6813086_T ...

	# expected column names and indices
	my %col_names =
		(
			IID			=> 1,
			SEX			=> 4,
			PHENOTYPE	=> 5,
		);

	my $header = <$infh>;
	$header = localize_string( $header ); # for cross-platform compatibility
	chomp $header;
	my @labels = split( / /, $header );

	while( my ( $name, $i ) = each %col_names )
	{
		if( $name ne $labels[$i] )
		{
			my $err = "Warning: unexpected name in column $i (expected $name, got $labels[$i])";
			$self->set_err( $err );
			return;
		}
	}

	# sex and phenotype are included as variables
	$self->{raw_data}{header_labels} = [ splice( @labels, 0, $col_names{SEX} ) ];
	$self->{raw_data}{variable_labels} = [ @labels ];

	while( my $line = <$infh> )
	{
		$line = localize_string( $line ); # for cross-platform compatibility
		chomp $line;
		my @data = split( / /, $line );

		my $iid = $data[ $col_names{IID} ];

		$self->{raw_data}{data}{$iid} = {	SEX => $data[ $col_names{SEX} ],
											PHENOTYPE => $data[ $col_names{PHENOTYPE} ],
											orig_data => $line, };

		push( @{ $self->{raw_data}{samples} }, $iid );
	}

	close $infh;

	return 1;
}

=head2 get_filename()

Returns the name of the RAW file specified in new():

	my $file = $raw->get_filename;

=cut

sub get_filename
{
	my ( $self ) = @_;
	return $self->{raw_file}{filename};
}

=head2 get_variable_labels()

Returns an array ref containing the labels for the variables in the input file.  Note that the first
four columns in a ped formatted file (FID, IID, PAT, MAT) are not considered variables and therefore
they are not included in the results.  The array will likely contain SEX and PHENOTYPE, followed
by a list of SNP IDs.

	my $aref = $raw->get_variable_labels; # SEX, PHENOTYPE, rs...

=cut

sub get_variable_labels
{
	# returns an aref of variable labels ( SEX, PHENOTYPE, rs... )
	# this does not include the header labels ( FID, IID, PAT, MAT )
	my ( $self ) = @_;
	my @labels = @{ $self->{raw_data}{variable_labels} }; # copy
	return \@labels;
}

=head2 get_header_labels()

Returns an array ref containing the header labels from the input file, corresponding to the first
four columns of a ped formatted file (FID, IID, PAT, MAT):

	my $aref = $raw->get_header_labels; # FID, IID, PAT, MAT

=cut

sub get_header_labels
{
	# returns an aref of header labels ( FID, IID, PAT, MAT )
	my ( $self ) = @_;
	my @labels = @{ $self->{raw_data}{header_labels} }; # copy
	return \@labels;
}

=head2 get_sample_labels()

Returns an array ref containing a list of sample labels, ordered according to line number in the
input file.  The labels are taken from the IID column.

	my $aref = $raw->get_sample_labels;

=cut

sub get_sample_labels
{
	# returns an aref of sample labels, in the order they appeared in the RAW file (by row)
	# these labels correspond to the IID column in the RAW file (ped format)
	my ( $self ) = @_;
	my @labels = @{ $self->{raw_data}{samples} }; # copy
	return \@labels;
}

=head2 get_phenotype_for_sample()

Returns the phenotype value for a given sample (specified using the sample label from the IID column):

	my $val = $raw->get_phenotype_for_sample( $iid ); # see get_sample_labels()

Sets err_str and returns undef on error ($iid not specified or invalid).

=cut

sub get_phenotype_for_sample
{
	# returns the value from the PHENOTYPE column for the specified sample (IID)
	# sets err_str and returns undef if $iid is not specified or if it is invalid
	my ( $self, $iid ) = @_;

	if( ! defined $iid )
	{
		$self->set_err( 'No sample specified' );
		return;
	}

	if( ! exists $self->{raw_data}{data}{$iid} )
	{
		$self->set_err( "Invalid sample [$iid]" );
		return;
	}

	return $self->{raw_data}{data}{$iid}{PHENOTYPE};
}

=head2 get_sample_data()

Returns a hash ref containing data for each sample in the input file.  This is a convenience method
for RandomJungle::File::DB and probably should not be called directly outside of that module, as the
interface and return structure is not guaranteed to be stable.

	my $href = $raw->get_sample_data; # convenience method for RandomJungle::File::DB

=cut

sub get_sample_data
{
	# returns an href to all the variable data records
	# this is a convience method for RJ::File::DB
	my ( $self ) = @_;
	return $self->{raw_data}{data};
}

=head2 get_data_for_sample()

This method retrieves data for a given sample, specified using the sample label from the IID column.
If called with only a single parameter (the sample label), an array ref will be returned that contains
the sample's variable data, suitable for classification by a RandomJungle::Tree object:

	my $aref = $raw->get_data_for_sample( $iid ); # variable data, suitable for classification

If called with 'orig => 1', the original line from the input file (unsplit, unspliced) will be returned:

	my $line = $raw->get_data_for_sample( $iid, orig => 1 ); # original line from the RAW file

Sets err_str and returns undef on error ($iid not specified or invalid).

=cut

sub get_data_for_sample
{
	# returns an aref to the variable data, suitable for classification (split, spliced)
	# returns the original (unsplit, unspliced) line from the RAW file if orig => 1 is specified
	# sets err_str and returns undef if $sample_iid is not specified or if it is invalid
	my ( $self, $sample_iid, %params ) = @_;

	if( ! defined $sample_iid )
	{
		$self->set_err( 'No sample specified' );
		return;
	}

	if( ! exists $self->{raw_data}{data}{$sample_iid} )
	{
		$self->set_err( "Invalid sample [$sample_iid]" );
		return;
	}

	# $orig_line is unsplit, unspliced:  FID IID PAT MAT SEX PHENOTYPE ...
	my $orig_line = $self->{raw_data}{data}{$sample_iid}{orig_data};

	if( exists $params{orig} && $params{orig} == 1 )
	{
		return $orig_line;
	}

	my @data = split( / /, $orig_line );
	my ( $fid, $iid, $pat, $mat ) = splice( @data, 0, 4 ); # remove for classification

	return \@data;
}

=head2 get_data()

Returns the data structures contained in $self:

	my $href = $raw->get_data;

This method is for debugging only and should not be used in production code.

=cut

sub get_data
{
	# deprecated
	my ( $self ) = @_;

	my %h = (
				raw_file => $self->{raw_file},
				raw_data => $self->{raw_data},
			);

	return \%h;
}

=head2 set_err()

Sets the error message (provided as a parameter) and creates a stack trace:

	$raw->set_err( 'Something went boom' );

=cut

sub set_err
{
	my ( $self, $errstr ) = @_;

	$self->{err_str} = $errstr || '';
	$self->{err_trace} = Devel::StackTrace->new;
}

=head2 err_str()

Returns the last error message that was set:

	my $msg = $raw->err_str;

=cut

sub err_str
{
	my ( $self ) = @_;

	return $self->{err_str};
}

=head2 err_trace()

Returns a backtrace for the last error that was encountered:

	my $trace = $raw->err_trace;

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
	# sets $ERROR and returns undef if $args{filename} is not defined or file does not exist

	my ( $self, %args ) = @_;

	@{ $self }{ keys %args } = values %args;

	# filename (mandatory)

	if( ! defined $self->{filename} )
	{
		$ERROR = "'filename' is not defined";
		return;
	}
	elsif( ! -e $self->{filename} )
	{
		$ERROR = "$self->{filename} does not exist";
		return;
	}

	$self->{raw_file}{filename} = $self->{filename};
}

sub localize_string
{
	my ( $content ) = @_;

	my $localized = $content;
	$localized =~ s[\012\015][\n]g; # added to support x0Ax0D
	$localized =~ s[\015{1,2}\012][\n]sg; # from File::LocalizeNewlines, collapse x0Dx0A and x0Dx0Dx0A
	$localized =~ s[\015|\012][\n]sg; # from File::LocalizeNewlines, normalize remaining

	return $localized;
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

Guts:

$self
	raw_file
		filename => $filename
	raw_data
		header_labels => [ FID, IID, PAT, MAT ] (expected)
		variable_labels => [ SEX, PHENOTYPE, rs... ]
		data
			$iid
				SEX => $val
				PHENOTYPE => $val
				orig_data => $line (unsplit, unspliced) # use for classifying sample with tree (but not vals for header labels!)
		samples => [ $iid, ... ]
	err_str => $errstr
	err_trace => Devel::StackTrace object

=cut

1;
