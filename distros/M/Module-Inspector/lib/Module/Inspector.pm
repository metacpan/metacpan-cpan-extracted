package Module::Inspector;

=pod

=head1 NAME

Module::Inspector - An integrated API for inspecting Perl distributions

=head1 DESCRIPTION

An entire ecosystem of CPAN modules exist around the files and formats
relating to the CPAN itself. Parsers and object models for various
different types of files have been created over the years by various people
for various projects.

These modules have a variety of different styles, and work in various
different ways.

So when it comes to analysing the structure of a Perl module (either
inside a repository, in a tarball, or in unpacked form) it is certainly
quite possible to do.

It's just that often it takes a high level of experience with the
various modules in question, and the knowledge of how to combine the
dozen of so modules in one cohesive program.

Personally, I have always found this laborious.

What I would prefer is a single API that is easy to use, implements the
magic invisibly behind the scenes, and co-ordinates the use of the
various modules for me as needed.

B<Module::Inspector> provides such an API, and provides a companion to
the L<Class::Inspector> API for accessing information on class after
installation.

It provides a wrapper around the various modules used to read and examine
the different parts of a Perl module distribution tarball, and can inspect
a module unrolled on disk, in a repository checkout, or just look directly
inside a tarball.

=head1 METHODS

=cut

use 5.005;
use strict;
use base 'Module::Extract';
use Carp                   ();
use version                ();
use Params::Util           ('_STRING');
use File::Find::Rule       ();
use File::Find::Rule::VCS  ();
use File::Find::Rule::Perl ();
use Module::Manifest       ();
use Module::Math::Depends  ();
use YAML::Tiny             ();

use vars qw{$VERSION %SPECIAL};
BEGIN {
	$VERSION = '1.05';
	%SPECIAL = (
		'MANIFEST' => 'Module::Manifest',
		'META.yml' => 'YAML::Tiny',
		);
}

# If prefork is available, flag PPI for preforking if needed
eval " use prefork 'PPI::Document::File';   ";





#####################################################################
# Constructor

=pod

=head2 new

  # Inspect a plain dist directory or cvs/svn checkout
  my $dir = Module::Inspector->new(
          dist_dir => $dirpath,
          );
  
  # Inspect a tarball
  my $file = Module::Inspector->new(
          dist_file => 'Foo-Bar-0.01.tar.gz',
          );

The C<new> constructor creates a new module inspector. It takes a
named param of either C<dist_file>, which should be the file path
of the dist tarball, or C<dist_dir>, which is the root of the
distribution directory (if it is already unrolled).

The distribution will be quickly pre-scanned to locate the various
significant documents in the distribution (although only a few are
initially supported).

Returns a new C<Module::Inspector> object, or dies on exception.

=cut

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);

	# Auto-detect version control
	unless ( defined $self->version_control ) {
		$self->{version_control} = $self->_version_control;
	}

	# Create the document store
	$self->{document} = {};

	# Add all single special files to the document store
	foreach my $file ( sort keys %SPECIAL ) {
		next unless -f $self->file_path($file);
		$self->{document}->{$file} = $SPECIAL{$file};
	}

	# Populate the document store with all Perl files
	my $find_perl = File::Find::Rule->ignore_vcs($self->version_control)->perl_file;
	foreach my $file ( $find_perl->relative->in($self->dist_dir) ) {
		$self->{document}->{$file} = 'PPI::Document::File';
	}

	$self;
}

=pod

=head2 version_control

  my $vcs_type = $self->version_control;

For reasons that will hopefully be more apparant later,
B<Module::Inspector> detects any version control system
in use within the C<dist_dir> for the module.

Currently, support is limited to detection of CVS and
Subversion.

Returns a the name of the version control system detected in use
as a string (currently 'cvs' or 'svn'). If no version control is
able to be detected returns the null string ''.

=cut

sub version_control {
	my $self = shift;

	# Determine it if we haven't yet
	unless ( exists $self->{version_control} ) {
		if ( -d $self->file_path('.svn') ) {
			# We in a subversion checkout
			$self->{version_control} = 'svn';

		} elsif ( -f $self->file_path('CVS/Repository') ) {
			# We in a CVS checkout
			$self->{version_control} = 'cvs';

		} else {
			# We have none, or can't tell
			$self->{version_control} = '';
		}
	}

	$self->{version_control};
}

=head2 documents

The C<documents> method returns a list of the names of all the documents
detected by the C<Module::Inspector>.

In scalar context, returns the number of identifyable documens found in
the distribution.

=cut

sub documents {
	if ( wantarray ) {
		return sort keys %{ $_[0]->{document} };
	} else {
		return scalar keys %{ $_[0]->{document} };
	}
}

=pod

=head2 document_type

  # Returns 'PPI::Document::File'
  my $ppi_class = $inspector->document_type('lib/Foo.pm');

In B<Module::Inspector>, all documents are represented as objects.

Thus, for each different type of document, there is going to be a
different class that implements the document objects for that type.

The C<document_type> method returns the type for a provided document
as a class name.

Please note that at this time these document types are not necesarily
stable, and over the first several releases I may need to change
the class I'm using to represent a particular document type.

=cut

sub document_type {
	my $self = shift;
	my $file = _STRING(shift)
		or Carp::croak("Missing or invalid param to document_type");
	unless ( defined $self->{document}->{$file} ) {
		Carp::croak("Document $file does not exist in module");
	}
	ref($self->{document}->{$file}) or $self->{document}->{$file};
}

=pod

=head2 document

  my $perl = $inspector->document('lib/Foo.pm');

The C<document> method returns the document object for a named file,
loading and caching it on the fly if needed.

The type of object will vary depending on the document.

For example, a Perl file will be returned as a L<PPI::Document>,
a F<MANIFEST> file as a L<Module::Manifest>, and so on.

Returns an object, or dies on error.

=cut

sub document {
	my $self = shift;
	my $file = _STRING(shift)
		or Carp::croak("Missing or invalid param to document_type");
	unless ( defined $self->{document}->{$file} ) {
		Carp::croak("Document $file does not exist in module");
	}

	# Return the document if loaded
	if ( ref $self->{document}->{$file} ) {
		return $self->{document}->{$file};
	}

	# Load the document
	my $path   = $self->file_path($file);
	my $loader = $self->{document}->{$file};
	if ( $loader eq 'PPI::Document::File' ) {
		require PPI::Document::File;
		my $document = PPI::Document::File->new( $path )
			or Carp::croak("Failed to load $file with PPI::Document::File");
		$self->{document}->{$file} = $document;

	} elsif ( $loader eq 'YAML::Tiny' ) {
		my $document = YAML::Tiny->read( $path )
			or Carp::croak("Failed to load $file with $loader");
		$self->{document}->{$file} = $document;

	} elsif ( $loader eq 'Module::Manifest' ) {
		my $document = Module::Manifest->new( $path )
			or Carp::croak("Failed to load $file with $loader");
		$self->{document}->{$file} = $document;

	} else {
		die "Internal Error: Unknown document loader '$loader'";
	}

	$self->{document}->{$file};
}





#####################################################################
# Analysis Layer

=pod

=head2 dist_name

  # Returns Config-Tiny
  my $name = $inspector->dist_name;

The C<dist_name> method returns the name of the distribution, as
determined from the META.yml file.

Returns the name as a string, or dies on error.

=cut

sub dist_name {
	my $self = shift;
	my $meta = $self->document('META.yml');
	$meta->[0]->{name} or Carp::croak(
		"META.yml does not have a name: value"
		);
}

=pod

=head2 dist_version

The C<dist_version> method returns the version of the distribution, as
determined from the F<META.yml> file in the distribution.

Returns a L<version> object, or dies on error.

=cut

sub dist_version {
	my $self    = shift;
	my $meta    = $self->document('META.yml');
	my $version = $meta->[0]->{version}
		or Carp::croak("META.yml does not have a version: value");
	version->new($version);
}

=pod

=head2 dist_requires

  my $depends = $inspector->dist_requires;

The C<dist_requires> method checks for any run-time dependencies of the
distribution and returns them as a L<Module::Math::Depends> object.

See the docs for L<Module::Math::Depends> for more information on its
structure and API.

If the distribution has no run-time dependencies, the object will still
be returned, but will be empty.

Returns a single L<Module::Math::Depends> object, or dies on error.

=cut

sub dist_requires {
	my $self     = shift;
	my $meta     = $self->document('META.yml');
	my $requires = $meta->[0]->{requires};
	return $requires
		? Module::Math::Depends->from_hash( $requires )
		: Module::Math::Depends->new;
}

=pod

=head2 dist_build_requires

The C<dist_build_requires> method returns the build-time-only
dependencies of the distribution.

If there are no build-time dependencies, the object will still
be returned, but will be empty.

Returns a L<Module::Math::Depends> object, or dies on exception.

=cut

sub dist_build_requires {
	my $self     = shift;
	my $meta     = $self->document('META.yml');
	my $requires = $meta->[0]->{build_requires};
	return $requires
		? Module::Math::Depends->from_hash( $requires )
		: Module::Math::Depends->new;
}

=pod

=head2 dist_depends

The C<dist_depends> method returns as for the two methods above
(C<dist_requires> and C<dist_build_requires>) except that this
method returns a merged dependency object, representing BOTH the
install-time and run-time dependencies for the distribution.

If there are no build-time or run-time dependencies, the object
will be returned, but will be empty.

Returns a L<Module::Math::Depends> object, or dies on error.

=cut

sub dist_depends {
	my $self           = shift;
	my $requires       = $self->dist_requires;
	my $build_requires = $self->dist_build_requires;
	$requires->merge( $build_requires );
	return $requires;
}

1;

=pod

=head1 TO DO

- Implement most of the functionality

=head1 SUPPORT

This module is stored in an Open Repository at the following address.

L<http://svn.ali.as/cpan/trunk/Module-Inspector>

Write access to the repository is made available automatically to any
published CPAN author, and to most other volunteers on request.

If you are able to submit your bug report in the form of new (failing)
unit tests, or can apply your fix directly instead of submitting a patch,
you are B<strongly> encouraged to do so as the author currently maintains
over 100 modules and it can take some time to deal with non-Critcal bug
reports or patches.

This will guarentee that your issue will be addressed in the next
release of the module.

If you cannot provide a direct test or fix, or don't have time to do so,
then regular bug reports are still accepted and appreciated via the CPAN
bug tracker.

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Module-Inspector>

For other issues, for commercial enhancement or support, or to have your
write access enabled for the repository, contact the author at the email
address above.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Class::Inspector>

=head1 COPYRIGHT

Copyright 2006 - 2008 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
