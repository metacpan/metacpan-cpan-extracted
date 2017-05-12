#! /usr/bin/perl -w
################################################################################
#
# Storable.pm (Store a parsed PML Object)
#
################################################################################
#
# Package
#
################################################################################
package PML::Storable;
@ISA = qw( PML );
################################################################################
#
# Includes
#
################################################################################
use strict;
use Storable;
################################################################################
#
# Constants
#
################################################################################
use constant VERSION		=> '0.01';
use constant DATE		=> 'Mon Jun  5 15:29:33 2000';
use constant ID			=> '$Id: Storable.pm,v 1.3 2000/07/31 17:13:46 pjones Exp $';
################################################################################
#
# Global Variables and Default Settings
#
################################################################################
use vars qw($VERSION);
$VERSION	= VERSION;
################################################################################
#
# ==== new ==== ################################################################
#
#   Arguments:
#	1) Class
#	2) Args to PML->new
#
#     Returns:
#	A PML object reblessed as a PML::Storable Object
#
# Description:
#	Creates a new PML object then reblesses it as PML::Storable
#
################################################################################
sub new
{
	my $class = shift;
	my $self = new PML @_;
	
	return bless $self, $class;
} # <-- End new -->
################################################################################
#
# ==== parse ==== ##############################################################
#
#   Arguments:
#	1) Filename or ref to an array of lines
#
#     Returns:
#	None
#
# Description:
#	Checks to see if the object is up to date, if not it calls
#	PML::parse.
#
################################################################################
sub parse
{
	my ($self, $x) = (shift, @_);
	my ($stored_filename, $include, $mod);
	
	# we can't handle arrays or files that don't exist
	if (ref($x) eq 'ARRAY' or not -e $x) {
		return $self->SUPER::parse(@_);
	}
	
	# replace the dir seperator '/' with a '.'
	($stored_filename = $x) =~ s/\//./g;
	
	# add the obj dir to the front of the filename
	$stored_filename = $self->[PML->PML_OBJ_DIR] . '/' . $stored_filename;
	$stored_filename .= '.stored';
	
	# get the mod time of the obj
	$mod = -M $stored_filename;
	
	# see if the obj exists and that it is newer then the src
	if (not -e $stored_filename or $mod > -M $x) {
		$self->SUPER::parse(@_);
		return store $self, $stored_filename;
	}
	
	# if we get this far then we need to retrieve the stored obj
	my $obj = retrieve($stored_filename);
	
	# make sure we got it
	unless ($obj) {
		$self->SUPER::parse(@_);
		return store $self, $stored_filename;
	}
	
	# run through and check the dates on the included files
	foreach $include (keys %{$obj->[PML->PML_INCLUDES]}) {
		if (-M $include < $mod) {
			$self->SUPER::parse(@_);
			return store $self, $stored_filename;
		}
	}
	
	# if we get here then all include files are up to date
	# and we should load all the needed modules
	$self->parse_need($obj->[PML->PML_NEED_LIST]);
	
	# last we need to is copy over elements from obj to self
	foreach $x (0 .. 20) {
		$self->[$x] = $obj->[$x];
	}
	
	return 1;
} # <-- End parse -->
################################################################################
#                              END-OF-SCRIPT                                   #
################################################################################
=head1 NAME

Storable.pm

=head1 SYNOPSIS

Quick Usage

=head1 DESCRIPTION

What does it do?

=head1 OPTIONS

Long Usage

=head1 EXAMPLES

Example usage

=head1 SEE ALSO

perl(1)

=head1 AUTHOR

Peter J Jones
pjones@cpan.org

=cut
1;

