package MyCPAN::Indexer::Reporter::Base;
use strict;
use warnings;

use parent qw(MyCPAN::Indexer::Component);
use vars qw($VERSION $logger);
$VERSION = '1.282';

use Carp qw(croak confess);
use File::Basename qw(basename);
use File::Spec::Functions;
use Log::Log4perl;

BEGIN {
	$logger = Log::Log4perl->get_logger( 'Reporter' );
	}

=encoding utf8

=head1 NAME

MyCPAN::Indexer::Reporter::Base - Common bits for MyCPAN reporter classes

=head1 SYNOPSIS

Use this as a base class in you reporter classes. Extend or override the
parts that you need.

=head1 DESCRIPTION

This is a base class for MyCPAN reporters. It mostly deals with file
and directory names that it composes from configuration and run details.
Most things should just use what is already there.

There is one abstract method that a subclass must implement on its own.
The C<get_report_file_extension> methods allows each reporter to have
a unique extension by which it can recognize its own reports.

=head2 Methods

=over 4

=item component_type

This returns the C<reporter_type>.

=cut

sub component_type { $_[0]->reporter_type }

=item get_report_path( $info, $Notes )

Returns the path of the file that stores the run results. It puts
together the configuration for the C<{success|error}_report_subdir>,
the distribution name, and the distribution extension.

You should probably leave this alone.

=cut

sub get_report_path
	{
	my( $self, $info ) = @_;

	catfile(
		map { $self->$_( $info ) } qw(
			get_report_subdir
			get_report_filename
			)
		);
	}

=item get_report_subdir

Return the subdirectory under the C<report_dir> for the report, depending
on the success of the indexing.

=cut

sub get_report_subdir
	{
	my( $self, $info ) = @_;

	$logger->warn( "Argument doesn't know how to run_info!" )
		unless eval { $info->can( 'run_info' ) };

	my $config = $self->get_config;

	my $dir_key  = $info->run_info( 'completed' )
			?
		$self->get_success_report_subdir
			:
		$self->get_error_report_subdir;

	$dir_key = $self->get_error_report_subdir
		if grep { $info->run_info($_) } qw(error fatal_error);

	$config->get( "${dir_key}_report_subdir" );
	}

=item get_report_filename

Returns the filename portion of the report path based on the examined
distribution name.

You should probably leave this alone.

=cut

sub get_report_filename
	{
	my( $self, $arg ) = @_;

	my $dist_file = do {
		if( ref $arg ) { $arg->{dist_info}{dist_file} }
		elsif( defined $arg ) { $arg }
		};
	$logger->logcroak( "Did not get a distribution file name!" )
		unless $dist_file;

	no warnings 'uninitialized';
	( my $basename = basename( $dist_file ) ) =~ s/\.(tgz|tar\.gz|zip)$//;

	my $rel_path = $self->get_dist_report_subdir(
		join '.', $basename, $self->get_report_file_extension
		);
	}

=item get_dist_report_subdir( FILENAME )

Creates a subdirectory path from a report name. There are 150,000
distributions so we shouldn't put all of those in one directory.

For a report such as F<HTTP-Size-0.01.yml>, the subdirectory path is
F<H/HT/HTTP-Size-0.01.yml>. The method is fairly dumb about it since
it does not care what the first two characters are. If the report name
is F<-0.01.yml> (yep, there really is), the path is F<-/-0/-0.01.yml>.

=cut

sub get_dist_report_subdir
	{
	my( $self, $filename ) = @_;

	catfile(
		substr( $filename, 0, 1 ),
		substr( $filename, 0, 2 ),
		$filename
		);
	}

=item get_report_file_extension

Returns the filename portion of the report path based on the examined
distribution name. This is an abstract method which you must override.

Every reporter should chose their own extension. This allows each
reporter to recognize their previous results.

=cut

sub get_report_file_extension
	{
	$logger->logcroak(
		'You must implement get_report_file_extension in a derived class!'
		);
	}

=item get_successful_report_path( DIST )

Returns the filename for a successful report. This is slightly
different from C<get_report_filename> which might also return the
filename for an success report.

=cut

sub get_successful_report_path
	{
	my $self = shift;

	catfile(
		map { $self->$_( @_ ) } qw(
			get_success_report_dir
			get_report_filename
			)
		);
	}

=item get_error_report_path( DIST )

Returns the filename for a error report. This is slightly different
from C<get_report_filename> which might also return the
filename for an error report.

=cut

sub get_error_report_path
	{
	my $self = shift;

	catfile(
		map { $self->$_( @_ ) } qw(
			get_error_report_dir
			get_report_filename
			)
		);
	}

=item get_success_report_subdir

=item get_error_report_subdir

Returns the subdirectory name for a report. This is just the subdirectory,
not the full path.

The defaults are F<success> and F<error>.

=cut

sub get_success_report_subdir { 'success' }

sub get_error_report_subdir   { 'error'   }

=item get_success_report_dir

=item get_error_report_dir

Returns the path to the report directory. This combines the subdirectory
name and the report path.

=cut

sub get_success_report_dir
	{
	catfile(
		$_[0]->get_config->report_dir,
		$_[0]->get_success_report_subdir
		);
	}

sub get_error_report_dir
	{
	catfile(
		$_[0]->get_config->report_dir,
		$_[0]->get_error_report_subdir
		);
	}

=item check_for_previous_successful_result( $dist )

Returns false (!) if it looks like there is already a successful report
for the noted distribution. If there is not a successful report,
it returns the filename it expected to find.

=cut

sub check_for_previous_successful_result
	{
	my $self = shift;

	my $path = $self->get_successful_report_path( @_ );
	return if -e $path;

	basename( $path );
	}

=item check_for_previous_error_result( $dist )

Return the report filename if there was an error report for $dist,
and false otherwise.

=cut

sub check_for_previous_error_result
	{
	my( $self, $dist ) = @_;
	my $path = $self->get_error_report_path( $dist );
	return -e $path ? basename( $path ) : ();
	}

=back

=head1 SOURCE AVAILABILITY

This code is in Github:

	git://github.com/briandfoy/mycpan-indexer.git

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2008-2018, brian d foy <bdfoy@cpan.org>. All rights reserved.

You may redistribute this under the terms of the Artistic License 2.0.

=cut

1;
