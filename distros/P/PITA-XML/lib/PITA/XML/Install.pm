package PITA::XML::Install;

=pod

=head1 NAME

PITA::XML::Install - A PITA report on a single distribution install

=head1 DESCRIPTION

C<PITA::XML::Install> is a data object that contains the complete
set of information on a single test/install run for a distribution on a
single host of an arbitrary platform.

=cut

use 5.006;
use strict;
use Carp         ();
use Params::Util qw{ _INSTANCE _SET0 };

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.52';
}





#####################################################################
# Constructor and Accessors

=pod

=head2 new

  # Create a new Install object
  my $install = PITA::XML::Install->new(
      request  => $request
      platform => $platform,
      analysis => $analysis,
      );

The C<new> constructor is used to create a new installation report, a
collection of which are serialized to the L<PITA::XML> XML file.

Returns a new C<PITA::XML::Install> object, or dies on error.

=cut

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Check the object
	$self->_init;

	$self;
}

sub _init {
	my $self = shift;

	# We must have a platform spec
	unless ( _INSTANCE($self->platform, 'PITA::XML::Platform') ) {
		Carp::croak('Invalid or missing platform');
	}

	# We must have a testing request
	unless ( _INSTANCE($self->request, 'PITA::XML::Request') ) {
		Carp::croak('Invalid or missing request');
	}

	# The platform scheme should match the platform scheme
	# (ignoring any part after the dot in the request)
	my $scheme_regexp = '^' . quotemeta($self->platform->scheme) . '\\b';
	unless ( $self->request->scheme =~ /$scheme_regexp/ ) {
		Carp::croak('Platform scheme does not match request scheme');
	}

	# Zero or more commands
	$self->{commands} ||= [];
	unless ( _SET0( $self->{commands}, 'PITA::XML::Command') ) {
		Carp::croak('Invalid commands');
	}

	# Zero or more tests
	$self->{tests} ||= [];
	unless ( _SET0( $self->{tests}, 'PITA::XML::Test') ) {
		Carp::croak('Invalid tests');
	}

	# Analysis is optional
	if ( defined $self->analysis or exists $self->{analysis} ) {
		unless ( _INSTANCE($self->analysis, 'PITA::XML::Analysis') ) {
			Carp::croak('Invalid analysis object');
		}
	} else {
		$self->{analysis} = undef;
	}

	$self;
}





#####################################################################
# Main Methods

=pod

=head2 request

The C<request> accessor returns testing request information.

Returns a L<PITA::XML::Distribution> object.

=cut

sub request {
	$_[0]->{request};
}

=pod

=head2 platform

The C<platform> accessor returns the platform specification for the install.

Returns a L<PITA::XML::Platform> object.

=cut

sub platform {
	$_[0]->{platform};
}

=pod

=head2 add_command

  $install->add_command( $command );

The C<add_command> method adds a L<PITA::XML::Command> object to the
list of commands in the install object.

Returns true, or dies is you do not pass a L<PITA::XML::Command> object.

=cut

sub add_command {
	my $self    = shift;
	my $command = _INSTANCE(shift, 'PITA::XML::Command')
		or Carp::croak("Did not provide a PITA::XML::Command to add_command");
	push @{ $self->{commands} }, $command;
	1;
}

=pod

=head2 commands

The C<commands> accessor returns the commands executed during the testing.

Returns a list of zero or more L<PITA::XML::Command> objects.

=cut

sub commands {
	@{ $_[0]->{commands} };
}

=pod

=head2 add_test

  $install->add_test( $test );

The C<add_test> method adds a L<PITA::XML::Test> object to the
list of test results in the install object.

Returns true, or dies is you do not pass a L<PITA::XML::Test> object.

=cut

sub add_test {
	my $self = shift;
	my $test = _INSTANCE(shift, 'PITA::XML::Test')
		or Carp::croak("Did not provide a PITA::XML::Test to add_test");
	push @{ $self->{tests} }, $test;
	1;
}

=pod

=head2 tests

The C<tests> accessor returns the results of the individual tests run during the testing.

Returns a list of zero or more L<PITA::XML::Test> objects.

=cut

sub tests {
	@{ $_[0]->{tests} };
}

=pod

=head2 analysis

The C<analysis> accessor returns the analysis object for the test run.

Returns a L<PITA::XML::Analysis> object, or C<undef> if no analysis
performed during the testing.

=cut

sub analysis {
	$_[0]->{analysis};
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
