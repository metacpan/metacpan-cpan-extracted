package MyCPAN::Indexer::Worker;
use strict;
use warnings;

use parent qw(MyCPAN::Indexer::Component);
use vars qw($VERSION $logger);
$VERSION = '1.282';

use Cwd;
use File::Basename;
use File::Spec::Functions qw(catfile);
use Log::Log4perl;
use MyCPAN::Indexer;
use Proc::ProcessTable;
use YAML;

=encoding utf8

=head1 NAME

MyCPAN::Indexer::Worker - Do the indexing

=head1 SYNOPSIS

Use this in backpan_indexer.pl by specifying it as the queue class:

	# in backpan_indexer.config
	worker_class  MyCPAN::Indexer::Worker

=head1 DESCRIPTION

This class takes a distribution and analyses it. This is what the dispatcher
hands a disribution to for the actual indexing.

=head2 Methods

=over 4

=item get_task

C<get_task> sets the C<child_task> key in the notes. The
value is a code reference that takes a distribution path as its only
argument and indexes that distribution.

See L<MyCPAN::Indexer::Tutorial> for details about what C<get_task> expects
and should do.

=cut

BEGIN {
	$logger = Log::Log4perl->get_logger( 'Worker' );
	}

=item component_type

This is a worker component.

=cut

sub component_type { $_[0]->worker_type }

=item get_task

=cut

sub get_task
	{
	my( $self ) = @_;

	my $config  = $self->get_config;

	my $coordinator = $self->get_coordinator;

	my $indexer = $coordinator->get_component( 'indexer' );

	$logger->debug( "Worker class is " . __PACKAGE__ );
	$logger->debug( "Indexer class is " . $indexer->class );

	my $child_task = sub {
		my $dist = shift;

		my $dist_basename = basename( $dist );

		my $basename = $coordinator->get_reporter->check_for_previous_successful_result( $dist );
		$logger->debug( "Found successful report for $dist_basename" ) unless $basename;
		return bless {
			dist_info => {
				dist_path     => $dist,
				dist_basename => $dist_basename
				},
			skipped => 1,
			}, $indexer->class unless $basename;

		my $previous_error_basename = $coordinator->get_reporter->check_for_previous_error_result( $dist ) || '';
		$logger->debug( "Error report returned [$previous_error_basename]" );
		$logger->debug( "Found error report for $dist_basename" ) if $previous_error_basename;

		# we used to handle this by just deleting all the old error
		# reports in setup_dirs over in MyCPAN::App::BackPAN::Indexer
		# deleting all the reports before we got started made it
		# impossible to get a list of error reports to retry
		if( $previous_error_basename and ! $config->retry_errors )
			{
			$logger->debug( "By config, skipping $dist because I'm not retrying errors" );
			return bless {
				dist_info => {
					dist_path    => $dist,
					dist_basename => $dist_basename,
					},
				skip_error => 1,
				}, $self->get_config->indexer_class;
			}
		elsif( $previous_error_basename and $config->retry_errors )
			{
			# if we are re-trying errors and there is already a report
			# unlink the previous report
			my $report_full_path =  $coordinator->get_reporter->get_error_report_path( $dist );

			$logger->debug( "Trying to unlink $report_full_path" );
			my $rc = unlink $report_full_path;
			$logger->debug( ($rc ? 'unlinked ' : 'failed to unlink ') . $report_full_path );
			}

		$logger->info( "Starting Worker for $dist_basename\n" );

		my $starting_dir = cwd();

		unless( chdir $config->temp_dir )
			{
			$logger->error( "Could not change to " . $config->temp_dir . " : $!\n" );
			exit 255;
			}

		$logger->debug( sprintf "Setting alarm for %d seconds", $config->alarm );
		local $SIG{ALRM} = sub {
			$logger->info( "Alarm rang for $dist_basename in process $$!\n" );
			$self->_cleanup_children;
			$logger->info( "Cleaned up" );
			die;
			};

		local $SIG{CHLD} = 'IGNORE';
		alarm( $config->alarm || 15 );
		$logger->debug( "Examining $dist_basename" );

		my $info = do {
			unless( -e $dist )
				{
				$logger->warn( "Dist $dist does not exist" );
				undef;
				}
			elsif( ! -s $dist )
				{
				$logger->warn( "Dist $dist has zero size" );
				my $info = bless {}, $self->get_config->indexer_class;
				$info->setup_dist_info( $dist );
				$info->set_dist_info( 'unindexable', 'zero size' );
				$info->setup_run_info;
				$info->set_run_info( qw(completed 1) );
				$info;
				}
			else
				{
				$logger->warn( "Indexing $dist" );
				eval { $indexer->run( $dist ) };
				}

			};

		$logger->debug( "Done examining $dist_basename" );
		my $at = $@; chomp $at;
		alarm 0;

		chdir $starting_dir;

		unless( defined $info )
			{
			$logger->error( "Indexing failed for $dist_basename: $at" );
			$info = bless {}, $self->get_config->indexer_class; # XXX TODO make this a real class
			$info->setup_dist_info( $dist );
			$info->setup_run_info;
			$info->set_run_info( qw(completed 0) );
			$info->set_run_info( error => $at );
			}
		elsif( ! eval { $info->run_info( 'completed' ) } )
			{
			$logger->error( "Indexing for $dist_basename did not complete" );
			$self->_copy_bad_dist( $info ) if $config->copy_bad_dists;
			}

		$self->_add_run_info( $info );

		$coordinator->get_note('reporter')->( $info );

		$logger->debug( "Worker for $dist_basename done" );

        # some things hang anyway, so just to be careful we'll cleanup
        # everything here.
		$self->_cleanup_children;

		$logger->debug( "Cleaned up, returning..." );
		$info;
		};

	$coordinator->set_note( 'child_task', $child_task );

	1;
	}

sub _cleanup_children
	{
	$logger->warn( "Cleaning up after $$" );

	my %children =
		map  { $_->{pid}, 1 }
		grep { $_->{'ppid'} == $$ }
		@{ Proc::ProcessTable->new->table };
	$logger->debug( "Child processes are @{[keys %children]}" );

	my @grandchildren =
		map  { $_->{pid} }
		grep { exists $children{ $_->{'ppid'} } }
		@{ Proc::ProcessTable->new->table };
	$logger->debug( "Grandchild processes are @grandchildren" );

	my @processes = ( keys %children, @grandchildren );
	$logger->debug( "There are " . @processes . " processes to clean up" );
	return unless @processes;

	$logger->debug( "Preparing to kill" );

	kill 9, @processes;

	return;
	}

sub _copy_bad_dist
	{
	my( $self, $info ) = @_;

	my $config  = $self->get_config;
	my $bad_dist_dir = $config->copy_bad_dists;
	return unless $bad_dist_dir;

	unless( -d $bad_dist_dir and mkdir $bad_dist_dir ) {
		$logger->error( "Could not make dist dir [$bad_dist_dir]: $!" );
		return;
		}

	my $dist_file = $info->dist_info( 'dist_file' );
	my $basename  = $info->dist_info( 'dist_basename' );
	my $new_name  = catfile( $bad_dist_dir, $basename );

	unless( -e $new_name )
		{
		$logger->debug( "Copying bad dist" );

		my( $in, $out );

		unless( open $out, ">", $new_name )
			{
			$logger->fatal( "Could not copy bad dist to $new_name: $!" );
			return;
			}

		unless( open $in, "<", $dist_file )
			{
			$logger->fatal( "Could not open bad dist to $dist_file: $!" );
			return;
			}

		while( <$in> ) { print { $out } $_ }
		close $in;
		close $out;
		}
	}

sub _add_run_info
	{
	my( $self, $info ) = @_;

	my $config = $self->get_config;

	return unless eval { $info->can( 'set_run_info' ) };

	$info->set_run_info( $_, $config->get( $_ ) )
		foreach ( $config->directives );

	$info->set_run_info( 'uuid', $self->get_note( 'UUID' ) );

	$info->set_run_info( 'child_pid',  $$ );
	$info->set_run_info( 'parent_pid', eval { $config->indexer_class->getppid } );

	$info->set_run_info( 'ENV', \%ENV );

	return 1;
	}

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

1;
