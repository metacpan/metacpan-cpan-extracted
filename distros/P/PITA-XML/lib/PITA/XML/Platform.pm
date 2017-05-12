package PITA::XML::Platform;

=pod

=head1 NAME

PITA::XML::Platform - Data object representing a platform configuration

=head1 SYNOPSIS

  # Create a platform configuration
  my $platform = PITA::XML::Platform->new(
      scheme => 'perl5',
      path   => '/usr/bin/perl',
      env    => \%ENV,
      config => \%Config::Config,
  );
  
  # Get the current perl5 platform configuration
  my $current = PITA::XML::Platform->autodetect_perl5;

=head1 DESCRIPTION

C<PITA::XML::Platform> is an object for holding information about
the platform that a package is being tested on

It can be created either as part of the parsing of a L<PITA::XML>
file, or if you wish you can create one from the local system configuration.

Primarily it just holds information about the host's environment and the
Perl configuration.

=head1 METHODS

As the functionality for L<PITA::XML> is still in flux, the methods
will be documented once we stop changing them daily :)

=cut

use 5.005;
use strict;
use Carp         ();
use Params::Util qw{ _STRING _HASH };

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.52';
}





#####################################################################
# Constructor and Accessors

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Check the object
	$self->_init;

	$self;
}

sub autodetect_perl5 {
	my $class = shift;

	# Source the information
	my $path = $^X;
	require Config;

	# Hand it off to the constructor
	$class->new(
		scheme => 'perl5',
		path   => $path,
		env    => { %ENV },            # Only provide a copy
		config => { %Config::Config }, # Only provide a copy
	);
}

# Format-check the parameters
sub _init {
	my $self = shift;

	# Check the platform scheme
	unless ( PITA::XML->_SCHEME($self->scheme) ) {
		Carp::croak('Invalid or missing platform testing scheme');
	}

	# Check the path we used
	unless ( _STRING($self->path) ) {
		Carp::croak('Invalid or missing scheme path');
	}

	# Check we have an environment
	unless ( _HASH($self->env) ) {
		Carp::croak('Invalid, missing, or empty environment');
	}

	# Check we have a config
	unless ( _HASH($self->config) ) {
		Carp::croak('Invalid, missing, or empty config');
	}

	$self;
}

sub scheme {
	$_[0]->{scheme};
}

sub path {
	$_[0]->{path};
}

sub env {
	$_[0]->{env};
}

sub config {
	$_[0]->{config};
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
