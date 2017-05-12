package Perl::Signature::Set;

=pod

=head1 NAME

Perl::Signature::Set - Create, store and check groups of signatures

=head1 DESCRIPTION

There are a number of cases where you might want to create and look after
a whole bunch of signatures.

The most common of these is:

  1. Generate signatures
  2. Do some process that shouldn't change the files functionally
  3. Test to make sure it didn't

Examples for 2. could be things like applying L<Perl::Tidy>, merging in
documentation-only patches from external sources, and other similar
things.

Perl::Signature::Set lets you create an object that can store a while
bunch of file signatures, save the set to a file, load it in again,
and test the lot to check for changes.

=head2 Saving and Loading

For simplicity and easy of creation, Perl::Signature::Set has been
implemented as a subclass of L<Config::Tiny>.

=head1 METHODS

=cut

use strict;
use Config::Tiny    ();
use Perl::Signature ();

use vars qw{$VERSION @ISA $errstr};
BEGIN {
	$VERSION = '1.09';
	@ISA     = 'Config::Tiny';
	$errstr  = '';
}





#####################################################################
# Constructor and Accessors

=pod

=head2 new

Creates a new Perl::Signature::Set object. Takes as an optional argument
the normalization layer you wish to use.

Returns a new Perl::Signature::Set object.

=cut

sub new {
	my $class = ref $_[0] ? ref shift : shift;
	my $layer = @_ ? (defined $_[0] and $_[0] =~ /^[12]$/) ? shift : return undef : 1;

	# Create the basic object
	my $self = bless {
		signature => {
			layer => $layer,
			},
		files => {},
		}, $class;

	$self;
}

=pod

=head2 layer

The C<layer> accessor returns the normalization layer that was used for
all of the signatures in the object.

=cut

sub layer { $_[0]->{signature}->{layer} }





#####################################################################
# Perl::Signature Methods

=pod

=head2 add $file

The C<add> method takes the name of a file to generate a signature for
and add to the set.

Returns the actual L<Perl::Signature> object created as a convenience,
or C<undef> if the file has already been added, or on error.

=cut

sub add {
	my $self = shift;
	my $file = -f $_[0] ? shift : return undef;
	return undef if $self->{files}->{$file};

	# Create the Signature object, and add it
	my $Signature = Perl::Signature->new( $file ) or return undef;
	$self->{files}->{$file} = $Signature;
}

=pod

=head2 files

The C<files> method provides all of the names of the files contained
in the set, in default sorted order.

Returns a list of file names, or the null list if the set contains no
files.

=cut

sub files {
	my $self  = shift;
	my @files = sort keys %{$self->{files}};
	@files;
}

=pod

=head2 file $filename

The C<file> method is used to get the L<Perl::Signature> object for a
single named file.

Returns a L<Perl::Signature> object, or C<undef> if the file is not in
the set.

=cut

sub file {
	my $self = shift;
	my $file = defined $_[0] ? shift : return undef;
	$self->{files}->{$file};
}

=pod

=head2 signatures

The C<signatures> method returns all of the Signature objects from
the Set, in filename-sorted order.

Returns a list of L<Perl::Signature> objects, or the null list if
the set does not contain any Signature objects.

=cut

sub signatures {
	my $self  = shift;
	my $files = $self->{files};
	map { $files->{$_} } sort keys %$files;
}

=pod

=head2 changes

The C<changes> method checks the signatures for each file and provides
a hash listing the files that have changed as the key,
and either "changed" or "removed" as the value.

Returns a HASH reference, false (C<''>) if there are no changes, or
C<undef> on error.

=cut

sub changes {
	my $self = shift;

	# Iterate of the files and check each one
	my %results = ();
	foreach my $file ( keys %{$self->{files}} ) {
		if ( -f $file ) {
			my $changed = $self->{files}->{$file}->changed;
			return undef unless defined $changed;
			$results{$file} = 'changed' if $changed;
		} else {
			$results{$file} = 'removed';
		}
	}

	keys %results ? \%results : '';
}





#####################################################################
# Config::Tiny Methods

sub read_string {
	my $class = shift;

	# Create the basic object using the parent method
	my $self = $class->SUPER::read_string(@_);

	# Check and clean up
	$self->{signature}          or return undef;
	$self->{signature}->{layer} or return undef;
	$self->{files}              or return undef;

	# Manually bless a signature object for each file entry
	my $files = $self->{files};
	foreach my $file ( keys %$files ) {
		my $signature = $files->{$file};
		$signature =~ /^[a-f0-9]{32}$/ or return undef;
		$files->{$file} = bless {
			file      => $file,
			signature => $signature,
		}, 'Perl::Signature';
	}

	$self;
}

sub write_string {
	my $self = shift;

	# Create the equivalent Config::Tiny object
	my $save = Config::Tiny->new;
	$save->{signature}->{layer} = $self->{signature}->{layer};
	foreach my $file ( keys %{$self->{files}} ) {
		$save->{files}->{$file} = $self->{files}->{$file}->original;
	}

	$save->write_string;
}

sub errstr { $errstr }
sub _error { $errstr = $_[1]; undef }

1;

=pod

=head1 SUPPORT

All bugs should be filed via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Signature>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<http://ali.as/>, L<PPI>, L<Perl::Signature>, L<Perl::Compare>

=head1 COPYRIGHT

Copyright 2005 - 2008 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
