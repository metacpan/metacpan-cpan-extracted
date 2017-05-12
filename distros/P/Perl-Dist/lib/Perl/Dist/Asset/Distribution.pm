package Perl::Dist::Asset::Distribution;

=pod

=head1 NAME

Perl::Dist::Asset::Distribution - "Perl Distribution" asset for a Win32 Perl

=head1 SYNOPSIS

  my $distribution = Perl::Dist::Asset::Distribution->new(
      name  => 'MSERGEANT/DBD-SQLite-1.14.tar.gz',
      force => 1,
  );

=head1 DESCRIPTION

L<Perl::Dist::Inno> supports two methods for adding Perl modules to the
installation. The main method is to install it via the CPAN shell.

The second is to download, make, test and install the Perl distribution
package independantly, avoiding the use of the CPAN client. Unlike the
CPAN installation method, installation the distribution directly does
C<not> allow the installation of dependencies, or the ability to discover
and install the most recent release of the module.

This secondary method is primarily used to deal with cases where the CPAN
shell either fails or does not yet exist. Installation of the Perl
toolchain to get a working CPAN client is done exclusively using the
direct method, as well as the installation of a few special case modules
such as L<DBD::SQLite> where the newest release is broken, but an older
release is known to be good.

B<Perl::Dist::Asset::Distribution> is a data class that provides
encapsulation and error checking for a "Perl Distribution" to be
installed in a L<Perl::Dist>-based Perl distribution using this
secondary method.

It is normally created on the fly by the <Perl::Dist::Inno>
C<install_distribution> method (and other things that call it).

The specification of the location to retrieve the package is done via
the standard mechanism implemented in L<Perl::Dist::Asset>.

=head1 METHODS

This class inherits from L<Perl::Dist::Asset> and shares its API.

=cut

use strict;
use Carp              ();
use Params::Util      qw{ _STRING _ARRAY _INSTANCE };
use File::Spec        ();
use File::Spec::Unix  ();
use URI               ();
use URI::file         ();
use Perl::Dist::Asset ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.16';
	@ISA     = 'Perl::Dist::Asset';
}

use Object::Tiny qw{
	name
	inject
	force
	automated_testing
	release_testing
	makefilepl_param
};





#####################################################################
# Constructor

=pod

=head2 new

The C<new> constructor takes a series of parameters, validates then
and returns a new B<Perl::Dist::Asset::Binary> object.

It inherits all the params described in the L<Perl::Dist::Asset> C<new>
method documentation, and adds some additional params.

=over 4

=item name

The required C<name> param is the name of the package for the purposes
of identification.

This should match the name of the Perl distribution without any version
numbers. For example, "File-Spec" or "libwww-perl".

Alternatively, the C<name> param can be a CPAN path to the distribution
such as shown in the synopsis.

In this case, the url to fetch from will be derived from the name.

=item force

Unlike in the CPAN client installation, in which all modules MUST pass
their tests to be added, the secondary method allows for cases where
it is known that the tests can be safely "forced".

The optional boolean C<force> param allows you to specify is the tests
should be skipped and the module installed without validating it.

=item automated_testing

Many modules contain additional long-running tests, tests that require
additional dependencies, or have differing behaviour when installing
in a non-user automated environment.

The optional C<automated_testing> param lets you specify that the
module should be installed with the B<AUTOMATED_TESTING> environment
variable set to true, to make the distribution behave properly in an
automated environment (in cases where it doesn't otherwise).

=item release_testing

Some modules contain release-time only tests, that require even heavier
additional dependencies compared to even the C<automated_testing> tests.

The optional C<release_testing> param lets you specify that the module
tests should be run with the additional C<RELEASE_TESTING> environment
flag set.

By default, C<release_testing> is set to false to squelch any accidental
execution of release tests when L<Perl::Dist> itself is being tested
under C<RELEASE_TESTING>.

=item makefilepl_param

Some distributions illegally require you to pass additional non-standard
parameters when you invoke "perl Makefile.PL".

The optional C<makefilepl_param> param should be a reference to an ARRAY
where each element contains the argument to pass to the Makefile.PL.

=back

The C<new> method returns a B<Perl::Dist::Asset::Distribution> object,
or throws an exception (dies) on error.

=cut

sub new {
	my $self = shift->SUPER::new(@_);

	# Normalize params
	$self->{force}             = !! $self->force;
	$self->{automated_testing} = !! $self->automated_testing;
	$self->{release_testing}   = !! $self->release_testing;

	# Check params
	unless ( _STRING($self->name) ) {
		Carp::croak("Missing or invalid name param");
	}
	if ( $self->name eq $self->url and not _DIST($self->name) ) {
		Carp::croak("Missing or invalid name param");
	}
	if ( defined $self->inject ) {
		unless ( _INSTANCE($self->inject, 'URI') ) {
			Carp::croak("The inject param must be a fully resolved URI");
		}
	}
	if ( defined $self->makefilepl_param and ! _ARRAY($self->makefilepl_param) ) {
		Carp::croak("Invalid makefilepl_param param");
	}
	$self->{makefilepl_param} ||= [];

	return $self;
}

sub url { $_[0]->{url} || $_[0]->{name} }





#####################################################################
# Main Methods

sub abs_uri {
	my $self = shift;

	# Get the base path
	my $cpan = _INSTANCE(shift, 'URI');
	unless ( $cpan ) {
		Carp::croak("Did not pass a cpan URI");
	}

	# If we have an explicit absolute URI use it directly.
	my $new_abs = URI->new_abs($self->url, $cpan);
	if ( $new_abs eq $self->url ) {
		return $new_abs;
	}

	# Generate the full relative path
	my $name = $self->name;
	my $path = File::Spec::Unix->catfile( 'authors', 'id',
		substr($name, 0, 1),
		substr($name, 0, 2),
		$name,
	);

	URI->new_abs( $path, $cpan );
}





#####################################################################
# Support Methods

sub _DIST {
	my $it = shift;
	unless ( defined $it and ! ref $it ) {
		return undef;
	}
	unless ( $it =~ q|^([A-Z]){2,}/| ) {
		return undef;
	}
	return $it;
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Dist>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Perl::Dist>, L<Perl::Dist::Inno>, L<Perl::Dist::Asset>

=head1 COPYRIGHT

Copyright 2007 - 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
