package MyCPAN::Indexer::Queue;
use strict;
use warnings;

use parent qw(MyCPAN::Indexer::Component);
use vars qw($VERSION $logger);
$VERSION = '1.282';

use File::Basename;
use File::Find;
use File::Find::Closures  qw( find_by_regex );
use File::Path            qw( mkpath );
use File::Spec::Functions qw( catfile rel2abs );
use Log::Log4perl;

BEGIN {
	$logger = Log::Log4perl->get_logger( 'Queue' );
	}

=encoding utf8

=head1 NAME

MyCPAN::Indexer::Queue - Find distributions to index

=head1 SYNOPSIS

Use this in backpan_indexer.pl by specifying it as the queue class:

	# in backpan_indexer.config
	queue_class  MyCPAN::Indexer::Queue

=head1 DESCRIPTION

This class returns a list of Perl distributions for the BackPAN
indexer to process.

=head2 Methods

=over 4

=item component_type

This is a queue type.

=cut

sub component_type { $_[0]->queue_type }

=item get_queue

C<get_queue> sets the key C<queue> in C<$Notes> hash reference. It
finds all of the tarballs or zip archives in under the directories
named in C<backpan_dir> and C<merge_dirs> in the configuration.

It specifically skips files that end in C<.txt.gz> or C<.data.gz>
since PAUSE creates those meta files near the actual module
installations.

If the C<organize_dists> configuration value is true, it also copies
any distributions it finds into a PAUSE-like structure using the
value of the C<pause_id> configuration to create the path.

This queue component tries to skip any distributions that already have
a report to make the list of distributions to examine much shorter. It
relies on the

=cut

sub get_queue
	{
	my( $self ) = @_;

	my @dirs =
		(
		$self->get_config->backpan_dir,
		split /\x00/, $self->get_config->merge_dirs || ''
		)
		;

	foreach my $dir ( @dirs )
		{
		$logger->error( "Distribution source directory does not exist: [$dir]" )
			unless -e $dir;
		}

	@dirs = grep { -d $_ } @dirs;
	$logger->logdie( "No directories to index!" ) unless @dirs;

	my $queue = $self->_get_file_list( @dirs );

	if( $self->get_config->organize_dists )
		{
		$self->_setup_organize_dists( $dirs[0] );

		# I really hate this following line. It's sure to
		# break on something
		my $regex = catfile( qw( authors id (.) .. .+? ), '' );

		foreach my $i ( 0 .. $#$queue )
			{
			my $file = $queue->[$i];
			$logger->debug( "Processing $file" );

			next if $file =~ m|$regex|;
			$logger->debug( "Copying $file into PAUSE structure" );

			$queue->[$i] = $self->_copy_file( $file, $dirs[0] );
			}
		}

	$self->set_note( 'queue', $queue );

	1;
	}

sub _get_file_list
	{
	my( $self, @dirs ) = @_;

	$logger->debug( "Taking dists from [@dirs]" );
	my( $wanted, $reporter ) =
		File::Find::Closures::find_by_regex( qr/\.(?:(?:tar\.|t)gz|zip)$/ );

	find( $wanted, @dirs );

	my $dist_count = () = $reporter->();
	$logger->info( "Found $dist_count distributions to possibly index" );

	my $files_to_examine = [
		grep { ! $self->report_exists_already( $_ ) }
		map  { rel2abs($_) }
		grep { ! /.(data|txt).gz$/ and ! /02packages/ }
		$reporter->()
		];

	{
	my $examine_count = () = @$files_to_examine;
	$logger->info( "Found $examine_count distributions to actually index" );
	my $success_reports = $self->success_report_count || 0;
	my $error_reports = $self->error_report_count || 0;

	my $success_percent = sprintf "%d", 100 * eval { $success_reports / $dist_count } || 0;
	my $error_percent   = sprintf "%d", 100 * eval { $error_reports / $dist_count } || 0;

	$logger->info( "Found $success_reports previous success reports ($success_percent%)" );
	$logger->info( "Found $error_reports previous error reports ($error_percent%)" );
	}

	return $files_to_examine;
	}

=item report_exists_already( DIST )

This method goes through this process to decide what to return:

=over 4

=item Return false if the C<fresh_start> configuration is true
(so existing reports don't matter).

=item Return true if there is a successful report already.

=item Return false if C<retry_errors> is true.

=item Return true if there is already an error report.

=item Return false as the default case.

=back

=cut

BEGIN {
my $success_reports;
my $error_reports;

sub report_exists_already
	{
	my( $self, $dist ) = @_;

	return 0 if $self->get_config->fresh_start;

	my $reporter = $self->get_coordinator->get_component( 'reporter' );

	my $success_report = $reporter->get_successful_report_path( $dist );
	do { $success_reports++; return 1 } if -e $success_report;

	return 0 if $self->get_config->retry_errors;
	my $error_report = $reporter->get_error_report_path( $dist );
	do { $error_reports++; return 1 } if -e $error_report;

	return 0;
	}

sub success_report_count { $success_reports }

sub error_report_count { $error_reports }
}

sub _setup_organize_dists
	{
	my( $self, $base_dir ) = @_;

	my $pause_id = eval { $self->get_config->pause_id } || 'MYCPAN';

	eval { mkpath
		catfile( $base_dir, $self->_path_parts( $pause_id ) ),
		{ mode => 0775 }
		};
	$logger->error( "Could not create PAUSE author path for [$pause_id]: $@" )
		if $@;

	1;
	}

sub _path_parts
	{
	catfile (
		qw(authors id),
		substr( $_[1], 0, 1 ),
		substr( $_[1], 0, 2 ),
		$_[1]
		);
	}

# if there is an error with the rename, return the original file name
sub _copy_file
	{
	require File::Copy;

	my( $self, $file, $base_dir ) = @_;

	my $pause_id = eval { $self->get_config->pause_id } || 'MYCPAN';

	my $basename = basename( $file );
	$logger->debug( "Need to copy file $basename into $pause_id" );

	my $new_name = rel2abs(
		catfile( $base_dir, $self->_path_parts( $pause_id ), $basename )
		);

	if( -e $new_name and
		$self->_file_md5( $new_name ) eq $self->_file_md5( $file ) )
		{
		$logger->debug( "Files [$file] and [$new_name] are the same. Not copying" );
		}

	my $rc = File::Copy::copy( $file => $new_name );
	$logger->error( "Could not copy [$file] to [$new_name]: $!" )
		unless $rc;

	return $rc ? $new_name : $file;
	}

sub _file_md5
	{
	my( $self, $file ) = @_;

	require Digest::MD5;

	open my( $fh ), '<', $file or return '';

	my $ctx = Digest::MD5->new;
	$ctx->addfile($fh);
 	$ctx->hexdigest;
	}

1;

=back

=head1 SEE ALSO

MyCPAN::Indexer, MyCPAN::Indexer::Tutorial

=head1 SOURCE AVAILABILITY

This code is in Github:

	git://github.com/briandfoy/mycpan-indexer.git

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2008-2018, brian d foy <bdfoy@cpan.org>. All rights reserved.

You may redistribute this under the terms of the Artistic License 2.0.

=cut
