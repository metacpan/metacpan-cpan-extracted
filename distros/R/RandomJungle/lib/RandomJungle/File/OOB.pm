package RandomJungle::File::OOB;

=head1 NAME

RandomJungle::File::OOB - Low level access to the data in the RandomJungle OOB output file

=cut

use strict;
use warnings;

use Carp;
use Data::Dumper;
use Devel::StackTrace;

=head1 VERSION

Version 0.05

=cut

our $VERSION = 0.05;
our $ERROR; # used if new() fails

=head1 SYNOPSIS

RandomJungle::File::OOB provides access to the data contained within RandomJungle's OOB output file.
See RandomJungle::Jungle for higher-level methods.

	use RandomJungle::File::OOB;

	my $oob = RandomJungle::File::OOB->new( filename => $oobfile ) || die $RandomJungle::File::OOB::ERROR;
	$oob->parse || die $oob->err_str;

	my $file = $oob->get_filename; # returns the filename of the OOB file
	my $aref = $oob->get_matrix; # returns an aref to the entire matrix (all lines, in file order)

	# Note $i is the index (row num) of the sample, not the IID
	my $line = $oob->get_data_for_sample_index( $i ) || die $oob->err_str; # $line is unsplit

	my $href = $oob->get_data; # for debugging only; returns raw data structs

	# Error handling
	$oob->set_err( 'Something went boom' );
	my $msg = $oob->err_str;
	my $trace = $oob->err_trace;

=cut

#*********************************************************************
#                          Public Methods
#*********************************************************************

=head1 METHODS

=head2 new()

Creates and returns a new RandomJungle::File::OOB object:

	my $oob = RandomJungle::File::OOB->new( filename => $oobfile );

The 'filename' parameter is required.
Returns undef and sets $ERROR on failure.

=cut

sub new
{
	# Returns RJ::File::OOB object on success
	# Returns undef and sets $ERROR on failure (e.g., 'filename' param not set)

	my ( $class, %args ) = @_;

	my $obj = {};
	bless $obj, $class;
	$obj->_init( %args ) || return; # $ERROR set by _init()

	return $obj;
}

=head2 parse()

Parses the OOB file specified in new():

	my $retval = $oob->parse;

Returns a true value on success.  Sets err_str and returns undef on failure.

=cut

sub parse
{
	# sets err_str and returns undef if error opening OOB file
	# returns true on success

	my ( $self ) = @_;

	open( my $infh, '<', $self->{oob_file}{filename} ) or
		do
		{
			my $msg = 'Error opening ' . $self->{oob_file}{filename} . "\n" . $!;
			$self->set_err( $msg );
			return;
		};

	# Each row corresponds to a sample, each column is a tree.
	# Assumes order of the rows (samples) is the same as in the .raw file (see IID column).
	# Values in the matrix indicate whether the sample was used to construct the tree (0)
	# or if the sample was out of bag (OOB, 1).  See Breiman 2001 for algorithm.

	my $i = 0; # line counter for sample index

	while( my $line = <$infh> )
	{
		#print "Reading line $i\n" if $i % 250 == 0;

		next if $line =~ m/^\s*$/; # skip blank lines

		$line = localize_string( $line ); # for cross-platform compatibility
		chomp $line;
		$line =~ s/\s+$//; # remove trailing tab

#		my @vals = split( "\t", $line );
#		$self->{matrix}[$i] = \@vals;
		$self->{matrix}[$i] = $line; # note: $i is the row # of the sample, NOT the IID!

		$i++;
	}

	close $infh;

	return 1;
}

=head2 get_data_for_sample_index()

Returns a line from the OOB file, specified by sample index (row number, not IID):

	my $line = $oob->get_data_for_sample_index( $i ) || die $oob->err_str;

=cut

sub get_data_for_sample_index
{
	# Returns unsplit line on success
	# Note:  $i is the index (row num) of the sample, not the IID
	# Sets err_str and returns undef on error ($i not specified or invalid)
	my ( $self, $sample_i ) = @_;

	if( ! defined $sample_i )
	{
		$self->set_err( "No sample index specified" );
		return;
	}

	if( $sample_i =~ m/\D/ || ! defined $self->{matrix}[$sample_i] )
	{
		$self->set_err( "Invalid sample index [$sample_i]" );
		return;
	}

	return $self->{matrix}[$sample_i];
}

=head2 get_matrix()

Returns a reference to an array that contains the lines in the OOB file:

	my $aref = $oob->get_matrix;

=cut

sub get_matrix
{
	# returns an aref to the entire matrix
	my ( $self ) = @_;
	return $self->{matrix};
}

=head2 get_filename()

Returns the name of the OOB file specified in new():

	my $file = $oob->get_filename;

=cut

sub get_filename
{
	my ( $self ) = @_;
	return $self->{oob_file}{filename};
}

=head2 get_data()

Returns the data structures contained in $self:

	my $href = $oob->get_data;

This method is for debugging only and should not be used in production code.

=cut

sub get_data
{
	my ( $self ) = @_;

	my %h = (
				oob_file => $self->{oob_file},
				matrix => $self->{matrix},
			);

	return \%h;
}

=head2 set_err()

Sets the error message (provided as a parameter) and creates a stack trace:

	$oob->set_err( 'Something went boom' );

=cut

sub set_err
{
	my ( $self, $errstr ) = @_;

	$self->{err_str} = $errstr || '';
	$self->{err_trace} = Devel::StackTrace->new;
}

=head2 err_str()

Returns the last error message that was set:

	my $msg = $oob->err_str;

=cut

sub err_str
{
	my ( $self ) = @_;

	return $self->{err_str};
}

=head2 err_trace()

Returns a backtrace for the last error that was encountered:

	my $trace = $oob->err_trace;

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
	# returns undef and sets $ERROR if $args{filename} is not defined or file does not exist

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

	$self->{oob_file}{filename} = $self->{filename};
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
	oob_file
		filename => $filename
	matrix => [ $line_0, $line_1, ... ]
	err_str => $errstr
	err_trace => Devel::StackTrace object

Note:  $lines are unsplit as [ $oob_tree_0, $oob_tree_1, ...] takes too much disk space

=cut

1;
