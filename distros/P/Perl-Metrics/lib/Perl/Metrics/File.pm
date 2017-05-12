package Perl::Metrics::File;

=pod

=head1 NAME

Perl::Metrics::File - A local file to generate metrics for

=head1 DESCRIPTION

This class provides objects that link files on the local filesystem to
the main metrics table via their document C<hex_id> (see L<PPI::Document>)

=head1 METHODS

In addition to the general methods provided by L<Class::DBI>, this class has
the following additional methods.

=cut

use strict;
use Perl::Metrics    ();
use PPI::Document    ();
use base 'Perl::Metrics::CDBI';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.09';
}




#####################################################################
# Class::DBI Setup and Accessors

=pod

=head2 path

The C<path> accessor returns a string which contains the non-relative file
path on the local system.

=head2 checked

The C<checked> accessor returns the Unix epoch time for when the C<hex_id>
was last checked for this file.

=head2 hex_id

In the L<Perl::Metrics> system all documents are identified by the
hexidecimal MD5 value for their newline-localized contents.

The C<hex_id> accessor returns this id for the file.

=cut

Perl::Metrics::File->table( 'files' );
Perl::Metrics::File->columns( Essential =>
	'path',    # Absolute local filesystem path - '/foo/bar/baz.pm'
	'checked', # UNIX epoch time last checked   - '1128495103'
	'hex_id',  # Document MD5 Identifier        - 'abcdef1234567890'
	);

# Add custom deletion cascade
Perl::Metrics::File->add_trigger(
	before_delete => sub { $_[0]->before_delete },
	);
sub before_delete {
	my $self = shift;

	if ( $self->search( hex_id => $self->hex_id )->count == 1 ) {
		# We are the last file with this hex_id.
		# Remove any metrics that were accumulated.
		$self->metrics->delete_all;
	}

	1;
}

=pod

=head2 metrics @options

The C<metric> accessor finds and returns all C<::Metric> object
that match the C<hex_id> of the C<::File>.

=cut

sub metrics {
	my $self   = shift;

	# Apply default search options to those passed
	my @params = ( hex_id => $self->hex_id, @_ );
	unless ( ref($params[-1]) eq 'HASH' ) {
		# Add standard ordering
		push @params, { order_by => 'package, name' };
	}

	# Execute the search
	return wantarray
		? Perl::Metrics::Metric->search( @params )
		: scalar Perl::Metrics::Metric->search( @params );
}

=pod

=head2 Document

The C<Document> method provides a convenient shortcut which will
load the L<PPI::Document> object for the file (while confirming the
C<hex_id> matches).

Returns a L<PPI::Object> or dies on error.

=cut

sub Document {
	my $self = shift;
	my $path = $self->path;

	# Load and check the Document object
	my $Document = PPI::Document->new( $path )
		or Carp::croak("Failed to load Perl document '$path'");
	unless ( $Document->hex_id eq $self->hex_id ) {
		Carp::croak("Document at '$path' fails hex_id match check");
	}

	$Document;
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Metrics>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Perl::Metrics>, L<PPI>

=head1 COPYRIGHT

Copyright 2005 - 2008 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
