package PITA::XML::Request;

=pod

=head1 NAME

PITA::XML::Request - A request for the testing of a software package

=head1 SYNOPSIS

  # Create a request specification
  my $dist = PITA::XML::Request->new(
      scheme    => 'perl5',
      distname  => 'PITA-XML',
  
      # The package to test
      file      => PITA::XML::File->new(
          filename  => 'Foo-Bar-0.01.tar.gz',
          digest    => 'MD5.0123456789ABCDEF0123456789ABCDEF',
          ),
 
      # Optional fields for repository-based requests
      authority => 'cpan',
      authpath  => '/id/A/AD/ADAMK/Foo-Bar-0.01.tar.gz',
      );

=head1 DESCRIPTION

C<PITA::XML::Request> is an object for holding information about
a request for a distribution to be tested. It is created most often
as part of the parsing of a L<PITA::XML> XML file.

It holds the testing scheme, name of the distribition, file information,
and authority information (if the distribution was sourced from a
repository such as CPAN)

=head1 METHODS

=cut

use 5.006;
use strict;
use Carp                ();
use File::Spec          ();
use File::Basename      ();
use Config::Tiny        ();
use Params::Util        qw{ _INSTANCE _STRING };
use PITA::XML::Storable ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '0.52';
	@ISA     = 'PITA::XML::Storable';
}

sub xml_entity { 'request' }





#####################################################################
# Constructor and Accessors

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Check the object
	$self->_init;

	$self;
}

# Format-check the parameters
sub _init {
	my $self = shift;

	# Check the id, if it has one
	if ( defined $self->id ) {
		unless ( PITA::XML->_GUID($self->id) ) {
			Carp::croak('Invalid id value format');
		}
	}

	# Check the scheme
	unless ( PITA::XML->_SCHEME($self->scheme) ) {
		Carp::croak('Missing, invalid or unsupported scheme');
	}

	# Arbitrarily apply the normal standard for distributions
	### Might need to change this down the line
	unless ( PITA::XML->_DISTNAME($self->distname) ) {
		Carp::croak('Missing or invalid distname');
	}

	# Check the (required) file
	unless ( _INSTANCE($self->file, 'PITA::XML::File') ) {
		Carp::croak('Missing or invalid file');
	}

	# Is there an authority
	if ( $self->authority ) {
		# Check the authority
		unless ( _STRING($self->authority) ) {
			Carp::croak('Invalid authority');
		}
	} else {
		$self->{authority} = '';
	}

	# Check the cpanpath
	if ( $self->authpath ) {
		# Check the authpath
		unless ( _STRING($self->authpath) ) {
			Carp::croak('Invalid authpath');
		}
	} else {
		$self->{authpath} = '';
	}

	# Authpath and authority are needed together
	if ( $self->authpath and ! $self->authority ) {
		Carp::croak('No authority provided with authpath');
	}
	# Authpath and authority are needed together
	if ( $self->authority and ! $self->authpath ) {
		Carp::croak('No authpath provided with authority');
	}

	$self;
}

=pod

=head2 id

The C<id> accessor returns the unique identifier of the request, if
it has one. This should be some form of L<Data::UUID> string.

Returns the identifier as a string, or C<undef> if the request has not
been assigned an id.

=cut

sub id { $_[0]->{id} }

=pod

=head2 scheme

The C<scheme> accessor returns the name of the testing scheme that the
distribution is to be tested under.

In this initial implementation, the following schemes are supported.

=over 4

=item perl5

Perl 5 general testing scheme.

Auto-detect the specific sub-scheme (currently either C<perl5.makefile>
or C<perl5.build>)

=item perl5.make

Traditional Perl 5 testing scheme.

Executes C<perl Makefile.PL>, C<make>, C<make test>,
C<make install>.

=item perl5.build

L<Module::Build> Perl 5 testing scheme.

Executes C<perl Build.PL>, C<Build>, C<Build test>,
C<Build install>.

=item perl6

Perl 6 general testing scheme.

Specifics are yet to be determined.

=back

=cut

sub scheme {
	$_[0]->{scheme};
}

=pod

=head2 distname

The C<distname> accessor returns the name of the request as a string.

Most often, this would be something like 'Foo-Bar' with a primary focus on
the class Foo::Bar.

=cut

sub distname {
	$_[0]->{distname};
}

=pod

=head2 file

The C<file> accessor returns the L<PITA::XML::File> that contains the
package to test.

=cut

sub file {
	$_[0]->{file};
}

=pod

=head2 authority

If present, the C<authority> accessor returns the name of the package
authority. For example, CPAN distributions use the authority C<'cpan'>.

=cut

sub authority {
	$_[0]->{authority};
}

=pod

=head2 authpath

When testing distributions , the C<authpath> returns the path for
the Request file within the CPAN.

For non-CPAN distributions, returns false (the null string).

=cut

sub authpath {
	$_[0]->{authpath};
}

=pod

=head2 find_file $base

The C<find_file> method takes a file or directory as a param (which
must exist) and tries to locate the actual file on disk at a location
within or relative to the passed path.

Returns the merge path to the file (if it exists) or C<undef> if not.

=cut

sub find_file {
	my $self = shift;
	my $path = shift;
	if ( -f $path ) {
		$path = File::Basename::dirname($path);
	}
	unless ( -d $path ) {
		Carp::croak("Invalid or non-existant base path");
	}

	# Add the filename to the base dir
	my $file = File::Spec->catfile( $path, $self->file->filename );
	return -f $file ? $file : undef;
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PITA-XML>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>, L<http://ali.as/>

=head1 SEE ALSO

L<PITA::XML>

The Perl Image-based Testing Architecture (L<http://ali.as/pita/>)

=head1 COPYRIGHT

Copyright 2005 - 2013 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
