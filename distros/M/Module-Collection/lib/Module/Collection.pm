package Module::Collection;

=pod

=head1 NAME

Module::Collection - Examine a group of Perl distributions

=head1 DESCRIPTION

B<WARNING: THIS IS AN EARLY RELEASE FOR INFORMATIONAL PURPOSES ONLY.
PARTS OF THIS MODULE ARE SUBJECT TO CHANGE WITHOUT NOTICE.>

The canonical source of all CPAN and Perl installation functionality is a
simple group of release tarballs, contained within some directory.

After all, at the very core CPAN is just a simple FTP server containing
a number of files uploaded by authors.

B<Module::Collection> is a a simple object which takes an arbitrary
directory, scans it for tarballs (which are assumed to be distribution
tarballs) and allows you to load up the tarballs as L<Module::Inspector>
objects.

While this is a fairly simple and straight forward implementation, and
is certainly not scalable enough to handle all of CPAN, it should be
quite sufficient for loading and examining a typical group of
distribution tarballs generated as part of a private project.

=cut

use 5.005;
use strict;
use Carp                  ();
use Params::Util          '_STRING';
use File::Find::Rule      ();
use Module::Inspector     ();
use Module::Math::Depends ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.02';
}

my $find_dist = File::Find::Rule->relative->file->name('*.tar.gz');





#####################################################################
# Constructor and Accessors

=pod

=head2 new

  my $collection = Module::Collection->new( root => $directory );

The C<new> constructor creates a new collection. It takes the named
C<root> param (the only param now, but with more to come) and scans
recursively inside it for any tarballs, which should be Perl
distribution release tarballs.

Returns a new B<Module::Collection> object, or dies on error.

=cut

sub new {
	my $class = shift;
	my $self  = bless { @_,
		dists => {},
		}, $class;

	# We need a collection root
	unless ( $self->root and -d $self->root ) {
		Carp::croak("Missing or invalid root directory");
	}

	# Scan the for files.
	# We want readable .tar.gz files (to start with)
	foreach my $file ( $find_dist->in($self->root) ) {
		$self->{dists}->{$file} = 'dist_file';
	}

	$self;
}

=pod

=head2 root

The C<root> accessor returns the path to the collection root, as
provided originally to the constructor.

=cut

sub root {
	$_[0]->{root};
}





#####################################################################
# Distribution Handling

=pod

=head2 dists

The C<dists> method returns a list of the file names for the
distributions that the collection is currently aware of.

In scalar context, returns the number of dists instead.

=cut

sub dists {
	if ( wantarray ) {
		return sort { lc $a cmp lc $b } keys %{$_[0]->{dists}};
	} else {
		return scalar keys %{$_[0]->{dists}};
	}
}

=pod

=head2 dist_path

  my $file_path = $collection->dist_path('dists/Config-Tiny-2.09.tar.gz');

The c<dist_path> method takes the name of a dist in the collection in
relative unix-style format, and returns a localised absolute path to the
distribution tarball.

=cut

sub dist_path {
	my $self = shift;
	File::Spec->catfile( $self->root, shift );
}

=pod

=head2 dist

  my $inspector = $collection->dist('dists/Config-Tiny-2.09.tar.gz');

The C<dist> methods creates and returns a L<Module::Inspector> object
for the distribution.

=cut

sub dist {
	my $self = shift;
	my $file = _STRING(shift);
	unless ( $file and $self->{dists}->{$file} ) {
		Carp::croak("No dist name provided, or does not exist");
	}

	# Is it already an object
	if ( ref $self->{dists}->{$file} ) {
		# Loaded and cached, return it
		return $self->{dists}->{$file};
	}

	# Convert the dist to a Module::Inspector
	my $module = Module::Inspector->new(
		$self->{dists}->{$file} => $self->dist_path($file),
		)
		or Carp::croak("Failed to create Module::Inspector for $file");

	# Cache and return
	return $self->{dists}->{$file} = $module;
}

=pod

=head2 ignore_dist

Most of the time when working with a collection of release tarballs
your code is only going to want to have to work with a subset.

The C<ignore_dist> method takes the name of a dist in the collection
and removes it from the collection.

Note the method is called "ignore" for a reason. This does NOT in any
way delete or remove the dist itself, it just removes it from the
collection's view.

Returns true or dies on error.

=cut

sub ignore_dist {
	my $self = shift;
	my $file = _STRING(shift);
	unless ( $file and $self->{dists}->{$file} ) {
		Carp::croak("No dist name provided, or does not exist");
	}

	# Remove the dist from our collection
	delete $self->{dists}->{$file};
	return 1;
}





#####################################################################
# Common Tasks

=pod

=head2 ignore_old_dists

The C<ignore_old_dists> method scans through all of the dists in the
collection, and removes (ignores) any distribution that has a never
version of the same distribution.

This has the result of taking a whole mishmash of distributions and
leaving you with only the newest version or each unique distribution.

Returns true or dies on error.

=cut

sub ignore_old_dists {
	my $self = shift;

	# Scan the dists.
	my %keep = ();
	foreach my $file ( $self->dists ) {
		my $dist    = $self->dist($file);
		my $name    = $dist->dist_name;
		my $version = $dist->dist_version;

		# Have we seen this dist before
		unless ( exists $keep{$name} ) {
			$keep{$name} = [ $file, $version ];
			next;
		}

		# Compare the versions
		if ( $version > $keep{$name}->[1] ) {
			# Replace with newer
			$self->ignore_dist($keep{$name}->[0]);
			$keep{$name} = [ $file, $version ];
		} else {
			# Existing is newer
			$self->ignore_dist($file);
		}
	}

	return 1;	
}





#####################################################################
# Higher-Level Analysis

sub depends {
	my $self    = shift;
	my $depends = Module::Math::Depends->new;
	foreach my $file ( $self->dists ) {
		$depends->merge( $self->dist($file)->dist_depends );
	}
	$depends;
}

1;

=pod

=head1 TO DO

- Implement most of the functionality

=head1 SUPPORT

This module is stored in an Open Repository at the following address.

L<http://svn.phase-n.com/svn/cpan/trunk/Module-Collection>

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

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Module-Collection>

For other issues, for commercial enhancement or support, or to have your
write access enabled for the repository, contact the author at the email
address above.

=head1 ACKNOWLEDGEMENTS

The biggest acknowledgement must go to Chris Nandor, who wielded his
legendary Mac-fu and turned my initial fairly ordinary Darwin
implementation into something that actually worked properly everywhere,
and then donated a Mac OS X license to allow it to be maintained properly.

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Module::Inspector>

=head1 COPYRIGHT

Copyright 2006 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
