package PITA::XML::Report;

use 5.005;
use strict;
use Carp                ();
use Params::Util        qw{ _INSTANCE _SET0 };
use PITA::XML::Storable ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '0.52';
	@ISA     = 'PITA::XML::Storable';
}

sub xml_entity { 'report' }





#####################################################################
# Constructor and Accessors

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;
	$self->_init;
	$self;
}

sub _init {
	my $self = shift;

	# Zero or more installs
	$self->{installs} ||= [];
	unless ( _SET0( $self->{installs}, 'PITA::XML::Install') ) {
		Carp::croak('Invalid installs');
	}

	$self;
}

sub add_install {
	my $self    = shift;
	my $install = _INSTANCE(shift, 'PITA::XML::Install');
	unless ( $install ) {
		Carp::croak('Did not provide a PITA::XML::Install object');
	}

	# Add it to the array
	push @{$self->{installs}}, $install;

	1;
}

sub installs {
	return (@{$_[0]->{installs}});
}

1;

__END__

=pod

=head1 NAME

PITA::XML::Report - A PITA report on the results of zero or more installs

=head1 SYNOPSIS

  # Create a new empty report file
  $report = PITA::XML::Report->new;
  
  # Load an existing report
  $report = PITA::XML::Report->read('filename.pita');

=head1 DESCRIPTION

The Perl Image Testing Architecture (PITA) is designed to provide a
highly modular and flexible set of components for doing testing of Perl
distributions.

Within PITA, the L<PITA::XML::Report> module provides the primary method
of reporting the results of installation attempts.

The L<PITA::XML::Report> class itself provides a way to create a set of
testing results, and then store (and later recover) these results as
you wish to a file.

A single PITA report file consists of structured XML that can be validated
against a known schema, while storing a large amount of testing data without
any ambiguity or the edge cases you may find in a YAML, email or text-file
file.

The ability to take testing results from another arbitrary user and validate
them also makes implementing a parser very simple, and thus allows the
creation of aggregators and processing systems without undue thoughts about
the report files themselves.

=head1 METHODS

=head2 validate

  # Validate a file without loading it
  PITA::XML::Report->validate( 'filename.pita' );
  PITA::XML::Report->validate( $filehandle     );

The C<validate> static method provides standalone validation of
a file or file handle, without creating a L<PITA::XML::Report> object.

Returns true, or dies if it fails to validate the file or file handle.

=head1 new

  # Create a new (empty) report file
  $empty = PITA::XML::Report->new;

The C<new> constructor creates a new, empty, report.

Returns a new L<PITA::XML::Report> object, or C<undef> on error.

=head1 read

  # Load an existing file
  $report = PITA::XML::Report->read( 'filename.pita' );
  $report = PITA::XML::Report->read( $filehandle     );

The C<read> constructor takes a file name or handle and parses it to
create a new C<PITA::XML::Report> object.

If passed a file handle object, it B<must> be seekable (an L<IO::Seekable>
subclass) as the file will need to be read twice. The first pass validates
the file against the schema, and the second populates the object with
L<PITA::XML::Install> reports.

Returns a new C<PITA::XML::Report> object, or dies on error (most often
due to problems validating an incorrect file).

=head2 add_install

  # Add a new install object to the report
  $report->add_install( $install );

All L<PITA::XML> files can contain more than one install report.

The C<add_install> method takes a single L<PITA::XML::Install> object
as a parameter and adds it to the L<PITA::XML> object.

=head2 installs

The C<installs> method returns all of the L<PITA::XML::Install> objects
from the L<PITA::XML> as a list.

=head2 write

  my $output = '';
  $report->write( \$output        );
  $report->write( 'filename.pita' );

The C<write> method is used to save the report out to a named file,
or to a string by passing it by reference.

It takes a single parameter, which can be either an XML SAX Handler
(any object that C<isa> L<XML::SAX::Base>) or any value that is
legal to pass as the C<Output> parameter to L<XML::SAX::Writer>'s
C<new> constructor.

Returns true when the file is written, or dies on error.

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PITA-XML>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>, L<http://ali.as/>

=head1 SEE ALSO

The Perl Image-based Testing Architecture (L<http://ali.as/pita/>)

=head1 COPYRIGHT

Copyright 2005 - 2013 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
