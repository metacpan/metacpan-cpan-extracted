package Module::Manifest;

=pod

=head1 NAME

Module::Manifest - Parse and examine a Perl distribution MANIFEST file

=head1 SYNOPSIS

Open and parse a MANIFEST and MANIFEST.SKIP:

  my $manifest = Module::Manifest->new( 'MANIFEST', 'MANIFEST.SKIP' );

Check if a given file matches any known skip masks:

  print "yes\n" if $manifest->skipped('.svn');

=head1 DESCRIPTION

B<Module::Manifest> is a simple utility module created originally for use
in L<Module::Inspector>.

It can load a F<MANIFEST> file that comes in a Perl distribution tarball,
examine the contents, and perform some simple tasks. It can also load the
F<MANIFEST.SKIP> file and check that.

Granted, the functionality needed to do this is quite simple, but the
Perl distribution F<MANIFEST> specification contains a couple of little
idiosyncracies, such as line comments and space-seperated inline
comments.

The use of this module means that any little nigglies are dealt with behind
the scenes, and you can concentrate the main task at hand.

=head2 Comparison to ExtUtil::Manifest

This module is quite similar to L<ExtUtils::Manifest>, or is at least
similar in scope. However, there is a general difference in approach.

L<ExtUtils::Manifest> is imperative, requires the existance of the actual
F<MANIFEST> file on disk, and requires that your current directory remains
the same.

L<Module::Manifest> treats the F<MANIFEST> file as an object, can load
a the file from anywhere on disk, and can run some of the same
functionality without having to change your current directory context.

That said, note that L<Module::Manifest> is aimed at reading and checking
existing MANFIFEST files, rather than creating new ones.

=head1 COMPATIBILITY

This module should be compatible with Perl 5.005 and above. However, it has
only been rigorously tested under Perl 5.10.0 on Linux.

If you encounter any problems on a different version or architecture, please
contact the maintainer.

=head1 METHODS

=cut

use 5.00503;
use strict;
use Carp             ();
use File::Spec       ();
use File::Spec::Unix ();
use File::Basename   ();
use Params::Util     ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.08';
}

# These platforms were copied from File::Spec
my %platforms = (
	MacOS   => 1,
	MSWin32 => 1,
	os2     => 1,
	VMS     => 1,
	epoc    => 1,
	NetWare => 1,
	symbian => 1,
	dos     => 1,
	cygwin  => 1,
);

=pod

=head2 new

  Module::Manifest->new( $manifest, $skip )

Creates a C<Module::Manifest> object, which either parses the files
referenced by the C<$manifest> (for MANIFEST) and C<$skip>
(for MANIFEST.SKIP). If no parameters are specified, it creates an empty
object.

Example code:

  my $manifest = Module::Manifest->new;
  my $manifest = Module::Manifest->new( $manifest );
  my $manifest = Module::Manifest->new( $manifest, $skip );

This method will return an appropriate B<Module::Manifest> object or
throws an exception on error.

=cut

sub new {
	my ($class, $manifest, $skipfile) = @_;

	Carp::carp('Return value discarded') unless (defined wantarray);

	my $self = bless {
		file        => $manifest,
		skipfile    => $skipfile,
	}, $class;

	$self->open( skip     => $skipfile ) if Params::Util::_STRING($skipfile);
	$self->open( manifest => $manifest ) if Params::Util::_STRING($manifest);

	return $self;
}

=pod

=head2 open

  $manifest->open( $type => $filename )

Open and parse the file given by C<$filename>, which may be a relative path.
The available C<$type> options are either: 'skip' or 'manifest'

Example code:

  $manifest->open( skip => 'MANIFEST.SKIP' );
  $manifest->open( manifest => 'MANIFEST' );

This method doesn't return anything, but may throw an exception on error.

=cut

sub open {
	my ($self, $type, $name) = @_;

	Carp::croak('You must call this method as an object') unless (ref $self);
	unless ( defined $name && length $name ) {
		Carp::croak('You must pass a filename to read and parse');
	}

	# Derelativise the file name if needed
	my $file = File::Spec->rel2abs($name);
	$self->{dir} = File::Basename::dirname($file);

	unless ( -f $file and -r _ ) {
		Carp::croak('Did not provide a readable file path');
	}

	my @file;
	unless ( open(MANFILE, $file) ) {
		Carp::croak('Failed to load ' . $name . ': ' . $!);
	}
	# Slurping should be fine since files are relatively small
	@file = <MANFILE>;
	unless ( close MANFILE ) {
		Carp::croak('Failed to close file! This is VERY bad.');
	}

	# Parse the file
	$self->parse( $type => \@file );

	return;
}

=pod

=head2 parse

  $manifest->parse( $type => \@files )

Parse C<\@files>, which is an array reference containing a list of files or
regular expression masks. The available C<$type> options are either: 'skip'
or 'manifest'

Example code:

  $manifest->parse( skip => [
       '\B\.svn\b',
       '^Build$',
       '\bMakefile$',
  ]);

This method doesn't return anything, but may throw an exception on error.

=cut

sub parse {
	my ($self, $type, $array) = @_;

	Carp::croak('You must call this method as an object') unless (ref $self);
	unless ( ref $array eq 'ARRAY' ) {
		Carp::croak('Files or masks must be specified as an array reference');
	}

	# This hash ensures there are no duplicates
	my %hash;
	foreach my $line (@{$array}) {
		next unless $line =~ /^\s*([^\s#]\S*)/;
		if ($hash{$1}++) {
			Carp::carp('Duplicate file or mask ' . $1);
		}
	}

	my @masks = sort keys %hash;
	if ($type eq 'skip') {
		$self->{skiplist} = \@masks;
	} elsif ($type eq 'manifest') {
		$self->{manifest} = \@masks;
	} else {
		Carp::croak('Available types are: skip, manifest');
	}

	return;
}

=pod

=head2 skipped

  $manifest->skipped( $filename )

Check if C<$filename> matches any masks that should be skipped, given the
regular expressions provided to either the C<parse> or C<open> methods.

Absolute path names must first be relativized and converted to a Unix-like
path string by using the C<normalize> method.

Example code:

  if ($manifest->skipped('Makefile.PL')) {
    # do stuff
  }

This method returns a boolean true or false value indicating whether the
file path is skipped according the C<skipfile>.

=cut

sub skipped {
	my ($self, $file) = @_;

	Carp::croak('You must call this method as an object') unless (ref $self);
	Carp::carp('Return value discarded') unless (defined wantarray);
	unless ( defined $file && length $file ) {
		Carp::croak('You must pass a filename or path to check');
	}

	# Quit early if we have no skip list
	return 0 unless (exists $self->{skiplist});

	# Loop through masks and exit early if there's a match
	foreach my $mask (@{ $self->{skiplist} }) {
		return 1 if ($file =~ /$mask/i);
	}
	return 0;
}

=pod

=head2 normalize

  Module::Manifest->normalize( $path, $rel )
  $manifest->normalize( $path, $rel )

This method takes a given platform-specific path string and converts it
to a Unix-style string compatible with the MANIFEST and MANIFEST.SKIP
specifications.

Note that this method normalizes paths depending on the platform detected
by C<$^O> -- that is, Win32 style paths can only be normalized if the
module is currently running under Win32.

By default, this method will relativize file paths to the current working
directory (using L<File::Spec>'s C<abs2rel> method without a C<$root>). To
disable this behaviour, set C<$rel> to a false value.

Example code:

  # Useful for normalizing Win32-style paths
  my $normal = Module::Manifest->normalize('t\\test\\file');
  # Returns: t/test/file (ie, in Unix style for MANIFEST)

This returns a normalized version of the given path.

=cut

sub normalize {
	my (undef, $path, $rel) = @_;

	Carp::carp('Return value discarded') unless (defined wantarray);
	unless ( defined $path && length $path ) {
		Carp::croak('You must pass a filename or path to check');
	}

	# Relativize if $rel is undefined or a true value
	if ( !defined $rel || $path ) {
		$path = File::Spec->abs2rel($path);
	}

	# Portably deal with different OSes
	if ($platforms{$^O}) { # Check if we are on a non-Unix platform
		# Get path info from File::Spec, split apart
		my (undef, $dir, $filename) = File::Spec->splitpath($path);
		my @dir = File::Spec->splitdir($dir);

		# Reconstruct the path in Unix-style
		$dir = File::Spec::Unix->catdir(@dir);
		$path = File::Spec::Unix->catpath(undef, $dir, $filename);
	}

	return $path;
}

=pod

=head2 file

  $manifest->file

The C<file> accessor returns the absolute path of the MANIFEST file that
was loaded.

=cut

sub file {
	my ($self) = @_;
	Carp::croak('You must call this method as an object') unless (ref $self);
	Carp::carp('Return value discarded') unless (defined wantarray);
	return $self->{file};
}

=pod

=head2 skipfile

  $manifest->skipfile

The C<skipfile> accessor returns the absolute path of the MANIFEST.SKIP file
that was loaded.

=cut

sub skipfile {
	my ($self) = @_;
	Carp::croak('You must call this method as an object') unless (ref $self);
	Carp::carp('Return value discarded') unless (defined wantarray);
	return $self->{skipfile};
}

=pod

=head2 dir

  $manifest->dir

The C<dir> accessor returns the path to the directory that contains the
MANIFEST or skip file, and thus SHOULD be the root of the distribution.

=cut

sub dir {
	my ($self) = @_;
	Carp::croak('You must call this method as an object') unless (ref $self);
	Carp::carp('Return value discarded') unless (defined wantarray);
	return $self->{dir};
}

=pod

=head2 files

  $manifest->files

The C<files> method returns the (relative, unix-style) list of files within
the manifest. In scalar context, returns the number of files in the manifest.

Example code:

  my @files = $manifest->files;

=cut

sub files {
	my ($self) = @_;
	Carp::croak('You must call this method as an object') unless (ref $self);
	Carp::carp('Return value discarded') unless (defined wantarray);
	if (exists($self->{manifest})) {
		return @{ $self->{manifest} };
	}
	return ();
}

1;

=pod

=head1 LIMITATIONS

The directory returned by the C<dir> method is overwritten whenever C<open>
is called. This means that, if MANIFEST and MANIFEST.SKIP are not in the
same directory, the module may get a bit confused.

=head1 SUPPORT

This module is stored in an Open Repository at the following address:

L<http://svn.ali.as/cpan/trunk/Module-Manifest>

Write access to the repository is made available automatically to any
published CPAN author, and to most other volunteers on request.

If you are able to submit your bug report in the form of new (failing) unit
tests, or can apply your fix directly instead of submitting a patch, you are
B<strongly> encouraged to do so. The author currently maintains over 100
modules and it may take some time to deal with non-critical bug reports or
patches.

This will guarantee that your issue will be addressed in the next release of
the module.

If you cannot provide a direct test or fix, or don't have time to do so, then
regular bug reports are still accepted and appreciated via the CPAN bug
tracker.

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Module-Manifest>

For other issues, for commercial enhancement and support, or to have your
write access enabled for the repository, contact the author at the email
address above.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head2 CONTIRBUTORS

Jonathan Yu E<lt>jawnsy@cpan.orgE<gt>

=head1 SEE ALSO

L<ExtUtils::Manifest>

=head1 COPYRIGHT

Copyright 2006 - 2010 Adam Kennedy

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included
with this module.

=cut
