package Module::Extract;

=pod

=head1 NAME

Module::Extract - Base class for working with Perl distributions

=head1 SYNOPSIS

Creating a Module::Extract subclass.

  package My::Readme;
  
  # Shows the README file for a module
  
  use strict;
  use base 'Module::Extract';
  
  sub show {
      my $self   = shift;
      my $readme = $self->file_path('README');
      if ( -f $readme ) {
          system( "cat $readme" );
      } else {
          print "Dist does not have a README file";
      }
  }
  
  1;

A script that uses the module to show the readme file for a distribution
filename provided by the user.

  #!/usr/bin/perl
  
  use My::Readme;
  
  My::Readme->new( dist_file => $ARGV[0] )->show;
  
  exit(0);

=head1 DESCRIPTION

B<Module::Extract> is a convenience base class for creating module that
work with Perl distributions.

Its purpose is to take care of the mechanisms of locating and extracting
a Perl distribution so that your module can do something specific to the
distribution.

This module was originally created to provide an abstraction for the
extraction logic for both L<Module::Inspector> and L<Module::P4P> and
to allow additional features to be added in the future without having
to modify both of them, because the general problem of "locate, download,
and expand a distribution" is one that is almost ideal for adding
additional features down the line.

=cut

use strict;
use Carp ();
use File::Path ();
use File::Temp ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}

# Flag Archive::Extract for prefork'ing if needed
eval " use prefork 'Archive::Extract'; ";





#####################################################################
# Constructor and Accessors

=pod

=head2 new

  my $from_file = My::Class->new(
      dist_file => 'tarball.tar.gz',
      );
  
  my $from_dir = My::Class->new(
      dist_dir  => 'some/dir',
      );

The C<new> constructor takes a C<dist_file> and/or a C<dist_dir> param,
locates and (if needed) expands the distribution tarball.

It takes either a C<dist_file> param, which should be the local path
to the tarball, or a C<dist_dir> which should be the path to a directory
which contains an already-expanded distribution (such as from a
repository checkout).

Return a new B<Module::Extract>-subclass object, or dies on error.

=cut

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	if ( $self->dist_file ) {
		# Create the inspector for a tarball
		unless ( $self->dist_file =~ /\.(?:zip|tgz|tar\.gz)$/ ) {
			Carp::croak("The dist_file '" . $self->dist_file . "' is not a zip|tgz|tar.gz");
		}
		unless ( -f $self->dist_file ) {
			Carp::croak("The dist_file '" . $self->dist_file . "' does not exist");
		}

		# Do we have a directory to unroll to
		if ( $self->dist_dir ) {
			# The directory should not exist
			if ( -d $self->dist_dir ) {
				Carp::croak("Cannot reuse an pre-existing dist_dir '"
					. $self->dist_dir
					. "'" );
			}

			# Create it
			File::Path::mkpath( $self->dist_dir );
		} else {
			# Find a temp directory
			$self->{dist_dir} = File::Temp::tempdir( CLEANUP => 1 );
		}

		# Double check it now exists and is writable
		unless ( -d $self->dist_dir and -w $self->dist_dir ) {
			Carp::croak("The dist_dir '" . $self->dist_dir . "' is not writeable");
		}

		# Unpack dist_file into dist_dir
		require Archive::Extract;
		my $archive = Archive::Extract->new( archive => $self->dist_file )
			or Carp::croak("Failed to extract dist_file '"
				. $self->dist_file . "'"
				);
		$self->{dist_type} = $archive->type;
		unless ( $archive->extract( to => $self->dist_dir ) ) {
			Carp::croak("Failed to extract dist_file '"
				. $self->dist_file . "'"
				);
		}

		# Double check the expansion directory
		if ( $archive->extract_path ne $self->dist_dir ) {
			# Archive::Extract can extract to a single
			# directory beneath the target, in which case
			# we actually want to be using that as our dist_dir.
			$self->{dist_dir} = $archive->extract_path;
		}

	} elsif ( $self->dist_dir ) {
		# Create the inspector for a directory
		unless ( -d $self->dist_dir ) {
			Carp::croak("Missing or invalid module root $self->{dist_dir}");
		}

	} else {
		# Missing a module location
		Carp::croak("Did not provide a dist_file or dist_dir param");
	}

	$self;
}

=pod

=head2 dist_file

The C<dist_file> accessor returns the (absolute) path to the
distribution tarball. If the inspector was created with C<dist_dir>
rather than C<dist_file>, this will return C<undef>.

=cut

sub dist_file {
	$_[0]->{dist_file};
}

=pod

=head2 dist_type

The C<dist_type> method returns the archive type of the
distribution tarball. This will be either 'tar.gz', 'tgz', or
'zip'. Other file types are not supported at this time.

If the inspector was created with C<dist_dir> rather than 
C<dist_file>, this will return C<undef>.

=cut

sub dist_type {
	$_[0]->{dist_type};
}

=pod

=head2 dist_dir

The C<dist_dir> method returns the (absolute) distribution root directory.

If the inspector was created with C<dist_file> rather than C<dist_file>,
this method will return the temporary directory created to hold the
unwrapped tarball.

=cut

sub dist_dir {
	$_[0]->{dist_dir};
}

=pod

=head2 file_path

  my $local_path = $inspector->file_path('lib/Foo.pm');

To simplify implementations, most tools that work with distributions
identify files in unix-style relative paths.

The C<file_path> method takes a unix-style relative path and returns
a localised absolute path to the file on disk (either in the actual
distribution directory, or the temp directory holding the expanded
tarball.

=cut

sub file_path {
	File::Spec->catfile( $_[0]->dist_dir, $_[1] );
}

=pod

=head2 dir_path

  my $local_path = $inspector->file_path('lib');

The C<dir_path> method is the matching pair of the C<file_path> method.

As for that method, it takes a unix-style relative directory name,
and returns a localised absolute path to the directory.

=cut

sub dir_path {
	File::Spec->catdir( $_[0]->dist_dir, $_[1] );
}

1;

=pod

=head1 SUPPORT

This module is stored in an Open Repository at the following address.

L<http://svn.phase-n.com/svn/cpan/trunk/Module-Extract>

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

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Module-Extract>

For other issues, for commercial enhancement or support, or to have your
write access enabled for the repository, contact the author at the email
address above.

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Module::Inspector>, L<Module::P4P>

=head1 COPYRIGHT

Copyright 2006 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
