package Perl::Compare;

=pod

=head1 NAME

Perl::Compare - Normalized Comparison for Perl Source Trees

=head2 STATUS

In the original 0.01 implementation of this module, cobbled together as
a proof-of-concept during a 9 hour caffiene-fuelled exploratory hacking
session, the "Document Normalization" process was included/embedded
inside of Perl::Compare.

In the 6 months between then and the first beta of L<PPI>, it was realised
that normalization was both a more independant and important process than
only as part of a Document comparison system.

As such, normalization has been moved into the PPI core as L<PPI::Normal>,
and a basic form of comparison can be done with the following.

  sub compare ($$) {
  	$_[0]->normalized == $_[1]->normalized
  }

This can be done without needing either Perl::Compare OR
L<Perl::Signature> (a dependency of this module).

This module is now primarily intended for use in testing entire directory
trees of modules. Using this module for comparison of single files is
discouraged, as it will unduly increase the number of module dependencies
in your code/module.

=head1 DESCRIPTION

Perl::Compare is designed to allow you to create customised comparisons
between different directory trees of Perl source code which are based on
normalized documents, and thus ignore "unimportant" changes to files.

=head2 Comparison Targets

A comparison target is either a directory containing Perl code, a
L<Perl::Signature::Set> object, or a file that contains a frozen
 L<Perl::Signature::Set> (not yet supported, dies with 'CODE INCOMPLETE').

=head1 METHODS

=cut

use strict;
use File::chdir; # Imports $CWD
use Params::Util         '_INSTANCE';
use List::MoreUtils      ();
use Perl::Signature      ();
use Perl::Signature::Set ();
use File::Find::Rule     ();

use vars qw{$VERSION %SYMBOLS};
BEGIN {
	$VERSION = '0.11';

	# Change report symbols
	%SYMBOLS = (
		added   => '+',
		removed => '-',
		changed => '!',
		);
}





#####################################################################
# Constructor and Accessors

=pod

=head2 new from => $target [, filter => $Rule ]

The C<new> constructor creates a new comparison object. It takes a number
of different arguments to control it.

=over

=item from

The mandatory C<from> argument should be the target for the main source
tree. The comparison report works on a from->to basis, so an entry will
be 'added' if it is not present in the C<from> target but is present in
the comparison target.

=item layer

The optional C<layer> argument specifies the document normalisation layer
to be used in the comparison. (1 by default)

If you use a stored L<Perl::Signature::Set> file in the comparison, it
B<must> match the layer used when creating the Perl::Compare object.

=item filter

The optional C<filter> argument allows you to pass a L<File::Find::Rule>
object that will limit the comparison to a particular set of files.

By default, the comparison object will check .pm, .pl and .t files only.

=back

Returns a Perl::Compare object, or C<undef> on error or invalid arguments.

=cut

sub new {
	my $class = ref $_[0] ? ref shift : shift;
	my %args  = @_;

	# Check params
	my $layer  = exists $args{layer}
		? (defined $args{layer} and $args{layer} eq '1') ? shift : return undef
		: 1;
	my $filter = _INSTANCE($args{filter}, 'File::Find::Rule') ? $args{filter}
		: File::Find::Rule->name( qr/\.(?:pm|pl|t)$/ );
	$filter->relative->file;
	
	# Create the object
	my $self = bless {
		layer  => 1,
		filter => $filter,
		}, $class;

	# Check the two things to compare
	$self->{from} = $self->target($args{from}) or return undef;

	$self;
}

=pod

=head2 layer

The C<layer> accessor returns the normalization layer to be used for
the comparison.

=cut

sub layer { $_[0]->{layer} }

=pod

=head2 filter

The C<filter> accessor returns the L<File::Find::Rule> filter to be
used for finding the files for the comparison.

=cut

sub filter { $_[0]->{filter} }





#####################################################################
# Perl::Compare Methods

=pod

=head2 compare $target

The C<compare> method takes as argument a single comparison target
and runs a standard comparison of the different from the contructor
C<from> argument to the target argument.

The result is a reference to a HASH where the names of the files are
the key, and the value is one of either 'added', 'removed', or 'changed'.

Returns a reference to a HASH if there is a different between the two
targets, false if there is no difference, or C<undef> on error.

=cut

sub compare {
	my $self  = shift;
	my $to    = $self->target(shift) or return undef;
	my $from  = $self->{from}        or return undef;

	# Get the list of all files
	my @files = List::MoreUtils::uniq( $from->files, $to->files );

	# Build the set of changes
	my %result = ();
	foreach my $file ( @files ) {
		my $from_sig = $from->file($file);
		my $to_sig   = $to->file($file);
		if ( $from_sig and $to_sig ) {
			if ( $from_sig->original ne $to_sig->original ) {
				$result{$file} = 'changed';
			}
		} elsif ( $from_sig ) {
			$result{$file} = 'removed';
		} elsif ( $to_sig ) {
			$result{$file} = 'added';
		}
	}

	%result ? \%result : '';
}

=pod

=head2 compare_report $target

The C<compare_report> takes the same argument and performs the same task as
the C<compare> method, but instead of a structured hash, it formats the
results into a conveniently-printable summary in the following format.

  + file/added/in_target.t
  ! file/functionally/different.pm
  - removed/in/target.pl

Returns the report as a single string, or C<undef> on error

=cut

sub compare_report {
	my $self    = shift;
	my $compare = $self->compare(@_) or return undef;

	my $report = '';
	foreach my $file ( sort keys %$compare ) {
		$report .= "$SYMBOLS{$compare->{$file}} $file\n";
	}

	$report;
}





#####################################################################
# Support Methods

sub target {
	my $self = shift;
	my $it   = defined $_[0] ? shift : return undef;
	if ( _INSTANCE($it, 'Perl::Signature::Set') ) {
		$it->layer == $self->layer or return undef;
		return $it;
	} elsif ( -d $it ) {
		my @files = $self->{filter}->in( $it );
		local $CWD = $it;
		my $Set = Perl::Signature::Set->new( $self->layer ) or return undef;
		foreach my $file ( @files ) {
			$Set->add( $file ) or return undef;
		}
		return $Set;
	} elsif ( -f $it ) {
		# Check to see if it is a frozen ::Set
		die "CODE INCOMPLETE";
	}

	undef;
}

1;

=pod

=head1 SUPPORT

Bugs should always be submitted via the CPAN bug tracker, located at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Compare>

For general comments, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<PPI>, L<PPI::Normal>, L<Perl::Signature>

=head1 COPYRIGHT

Copyright 2004 - 2008 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
