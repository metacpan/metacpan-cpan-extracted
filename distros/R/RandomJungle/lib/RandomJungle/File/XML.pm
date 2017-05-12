package RandomJungle::File::XML;

=head1 NAME

RandomJungle::File::XML - Low level access to the data in the RandomJungle XML output file

=cut

use strict;
use warnings;

use Carp;
use Data::Dumper;
use DBM::Deep;
use Devel::StackTrace;
use XML::Twig;

=head1 VERSION

Version 0.06

=cut

our $VERSION = 0.06;
our $ERROR; # used if new() fails

=head1 SYNOPSIS

RandomJungle::File::XML provides access to the data contained within RandomJungle's XML output file.
See RandomJungle::Jungle and RandomJungle::Tree for higher-level methods.

	use RandomJungle::File::XML;

	my $xml = RandomJungle::File::XML->new( filename => $xmlfile ) || die $RandomJungle::File::XML::ERROR;
	$xml->parse || die $xml->err_str;

	my $file = $xml->get_filename; # returns the filename of the XML file
	my $href = $xml->get_RJ_input_params; # all the input params that were used for RJ
	my $aref = $xml->get_tree_ids; # sorted numerically
	my $href = $xml->get_tree_data; # data for all trees (not RJ::Tree objects)
	my $href = $xml->get_tree_data( tree_id => $id ) || warn $xml->err_str;

	my $href = $xml->get_data; # for debugging only; returns raw data structs

	# Error handling
	$xml->set_err( 'Something went boom' );
	my $msg = $xml->err_str;
	my $trace = $xml->err_trace;

=cut

#*********************************************************************
#                          Public Methods
#*********************************************************************

=head1 METHODS

=head2 new()

Creates and returns a new RandomJungle::File::XML object:

	my $xml = RandomJungle::File::XML->new( filename => $xmlfile );

The 'filename' parameter is required.  Sets $ERROR and returns undef on failure.

=cut

sub new
{
	# Returns RJ::File::XML object on success
	# Returns undef on failure (e.g., 'filename' param not set)
	my ( $class, %args ) = @_;

	my $obj = {};
	bless $obj, $class;
	$obj->_init( %args ) || return; # $ERROR is set by _init()

	return $obj;
}

=head2 parse()

Parses the XML file specified in new():

	my $retval = $xml->parse;

Returns a true value on success.  Sets err_str and returns undef on failure.

=cut

sub parse
{
	# Returns true on success
	# Sets err_str and returns undef on failure (parse error)
	my ( $self ) = @_;

	my $twig = XML::Twig->new(
								twig_handlers =>
								{
									'tree' => sub { $self->_tree( @_ ) },
									'option' => sub { $self->_option( @_ ) },
								},
							);

	my $retval = $twig->safe_parsefile( $self->{xml_file}{filename} ); # does not die on error (but returns 0)

	if( ! $retval )
	{
		$self->set_err( "Error parsing XML file: $@" );
		return;
	}

	$self->{twig} = $twig;

	return 1;
}

=head2 get_filename()

Returns the name of the XML file specified in new():

	my $file = $xml->get_filename;

=cut

sub get_filename
{
	my ( $self ) = @_;
	return $self->{xml_file}{filename};
}

=head2 get_RJ_input_params()

Returns a href containing the input parameters that were used when Random Jungle was run:

	my $href = $xml->get_RJ_input_params; # $href->{$param_name} = $param_value;

This method calls parse() if it has not already been called.

=cut

sub get_RJ_input_params
{
	# Returns an href of all the input params that were used for RJ
	# calls parse() internally if not already called, so subject to that method's behavior on failure
	my ( $self ) = @_;

	if( ! defined $self->{options} )
	{
		$self->parse || return;
	}

	return $self->{options};
}

=head2 get_tree_ids()

Returns an aref of tree IDs (sorted numerically):

	my $aref = $xml->get_tree_ids;

This method calls parse() if it has not already been called.

=cut

sub get_tree_ids
{
	# Returns an aref of tree IDs (sorted numerically)
	# calls parse() internally if not already called, so subject to that method's behavior on failure
	my ( $self ) = @_;

	if( ! defined $self->{options} )
	{
		$self->parse || return;
	}

	my @ids = sort { $a <=> $b } ( keys %{ $self->{tree_data} } );

	return \@ids;
}

=head2 get_tree_data()

Returns an href of tree records (not RandomJungle::Tree objects):

	my $href = $xml->get_tree_data; # data for all trees
	my $href = $xml->get_tree_data( tree_id => $id );

If called without parameters, records for all trees will be returned.
The tree_id parameter can be used to get a single record (returns undef if $id is invalid).

This method calls parse() if it has not already been called.

$href has the following structure:
	$tree_id
		id => $tree_id,
		var_id_str => varID string from XML, e.g., '((490,967,1102,...))'
		values_str => values string from XML, e.g., '(((0)),((0)),((1)),...)'
		branches_str => branches string from XML, e.g., '((1,370),(2,209),(3,160),...)'

$href is suitable for passing to RandomJungle::Tree->new().

=cut

sub get_tree_data
{
	# Returns an href of tree records (not RJ::Tree objects)
	# Default is all trees, can specify tree_id => $id to get a single tree
	# Sets err_str and returns undef if tree_id is specified but invalid
	# calls parse() internally if not already called, so subject to that method's behavior on failure
	my ( $self, %params ) = @_;

	if( ! defined $self->{tree_data} )
	{
		$self->parse || return;
	}

	if( exists $params{tree_id} )
	{
		if( defined $params{tree_id} )
		{
			if( ! exists $self->{tree_data}{ $params{tree_id} } )
			{
				$self->set_err( "Invalid tree ID: $params{tree_id}" );
				return;
			}

			my $href = $self->{tree_data}{ $params{tree_id} }; # single record
			return { $params{tree_id} => $href }; # maintain same struct as for all records
		}
		else
		{
			$self->set_err( 'Tree ID not specified' );
			return; # specified tree_id option without a value
		}
	}

	return $self->{tree_data}; # all records
}

=head2 get_data()

Returns the data structures contained in $self:

	my $href = $xml->get_data;

This method is for debugging only and should not be used in production code.

=cut

sub get_data
{
	# for debugging only
	my ( $self ) = @_;

	if( ! defined $self->{tree_data} )
	{
		$self->parse || return;
	}

	# don't pass the Twig object (big)
	my %h = (
				xml_file => $self->{xml_file},
				options => $self->{options},
				tree_data => $self->{tree_data},
			);

	return \%h;
}

=head2 set_err()

Sets the error message (provided as a parameter) and creates a stack trace:

	$xml->set_err( 'Something went boom' );

=cut

sub set_err
{
	my ( $self, $errstr ) = @_;

	$self->{err_str} = $errstr || '';
	$self->{err_trace} = Devel::StackTrace->new;
}

=head2 err_str()

Returns the last error message that was set:

	my $msg = $xml->err_str;

=cut

sub err_str
{
	my ( $self ) = @_;

	return $self->{err_str};
}

=head2 err_trace()

Returns a backtrace for the last error that was encountered:

	my $trace = $xml->err_trace;

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

	$self->{xml_file}{filename} = $self->{filename};
}

#***** XML::Twig handlers *****

sub _tree
{
	# this sub could probably use some error checking on the $elt method calls
	my ( $self, $twig, $elt ) = @_;

	my $tree_id = $elt->att( 'id' );

	my %t = (
				id => $tree_id,
				var_id_str => $elt->first_child_text( 'variable[@name="varID"]' ),
				values_str => $elt->first_child_text( 'variable[@name="values"]' ),
				branches_str => $elt->first_child_text( 'variable[@name="branches"]' ),
			);

	# store raw data only; no longer convert to ::Tree objects to save memory and simplify saving
	# the data to a db
	$self->{tree_data}{$tree_id} = \%t;

	$twig->purge; # added Feb 7, 2011 to try to free memory (didn't test!)
}

sub _option
{
	# this sub could probably use some error checking on the $elt method calls
	my ( $self, $twig, $elt ) = @_;

	my $opt_name = $elt->att( 'id' );
	my $opt_value = $elt->text;

	$self->{options}{$opt_name} = $opt_value;
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
	xml_file
		filename => $filename
	options
		$name => $value (input parameters for RJ)
	twig => XML::Twig object
	tree_data
		$tree_id
			id => $tree_id,
			var_id_str => varID string from XML, e.g., '((490,967,1102,...))'
			values_str => values string from XML, e.g., '(((0)),((0)),((1)),...)'
			branches_str => branches string from XML, e.g., '((1,370),(2,209),(3,160),...)'
	err_str => $errstr
	err_trace => Devel::StackTrace object

=cut

1;

