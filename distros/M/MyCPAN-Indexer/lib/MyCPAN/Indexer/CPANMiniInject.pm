package MyCPAN::Indexer::CPANMiniInject;
use strict;
use warnings;

use parent qw(MyCPAN::Indexer::Component);
use vars qw($VERSION $logger);
$VERSION = '1.282';

use File::Basename;
use File::Spec::Functions qw(catfile);
use Log::Log4perl;
use MyCPAN::Indexer;
use YAML;

=encoding utf8

=head1 NAME

MyCPAN::Indexer::CPANMiniInject - Do the indexing, and put the dists in a MiniCPAN

=head1 SYNOPSIS

Use this in backpan_indexer.pl by specifying it as the queue class:

	# in backpan_indexer.config
	worker_class  MyCPAN::Indexer::CPANMiniInject

=head1 DESCRIPTION

This class takes a distribution and analyses it. Once it knows the modules
inside the distribution, it adds the distribution to a CPAN::Mini::Inject
staging repository. This portion specifically does not inject the modules
into the MiniCPAN. The injection has to happen after all of the workers
have finished.

=head2 Configuration

=over 4

=item minicpan_inject_config

The location of the configuration file for CPAN::Mini::Config

=back

=cut

=head2 Methods

=over 4

=item get_task( $Notes )

C<get_task> sets the C<child_task> key in the C<$Notes> hash reference. The
value is a code reference that takes a distribution path as its only
argument and indexes that distribution.

See L<MyCPAN::Indexer::Tutorial> for details about what C<get_task> expects
and should do.

=cut

BEGIN {
	$logger = Log::Log4perl->get_logger( 'Worker' );
	}

sub component_type { $_[0]->worker_type }

sub get_task
	{
	my( $self ) = @_;

	my $child_task = sub {
		my $dist = shift;

		my $basename = $self->_check_for_previous_result( $dist );
		return unless $basename;

		my $Config = $self->get_config;

		$logger->info( "Child [$$] processing $dist\n" );

		my $indexer = $self->get_coordinator->get_component( 'indexer' );

		unless( chdir $Config->temp_dir )
			{
			$logger->error( "Could not change to " . $Config->temp_dir . " : $!\n" );
			exit 255;
			}

		local $SIG{ALRM} = sub { die "alarm\n" };
		alarm( $Config->alarm || 15 );
		my $info = eval { $indexer->run( $dist ) };

		unless( defined $info )
			{
			$logger->error( "run failed: $@" );
			return;
			}
		elsif( ! eval { $info->run_info( 'completed' ) } )
			{
			$logger->error( "$basename did not complete\n" );
			$self->_copy_bad_dist( $info ) if $Config->copy_bad_dists;
			}

		alarm 0;

		$self->_add_run_info( $info );

		$self->get_note( 'reporter' )->( $info );

		$logger->debug( "Child [$$] process done" );

		1;
		};

	$self->set_note( 'child_task', $child_task );
	}

sub _copy_bad_dist
	{
	my( $self, $info ) = @_;

	my $config = $self->get_config;

	if( my $bad_dist_dir = $config->copy_bad_dists )
		{
		my $dist_file = $info->dist_info( 'dist_file' );
		my $basename  = $info->dist_info( 'dist_basename' );
		my $new_name  = catfile( $bad_dist_dir, $basename );

		unless( -e $new_name )
			{
			$logger->debug( "Copying bad dist" );

			my( $in, $out );

			unless( open $in, "<", $dist_file )
				{
				$logger->fatal( "Could not open bad dist to $dist_file: $!" );
				return;
				}

			unless( open $out, ">", $new_name )
				{
				$logger->fatal( "Could not copy bad dist to $new_name: $!" );
				return;
				}

			while( <$in> ) { print { $out } $_ }
			close $in;
			close $out;
			}
		}
	}

sub _check_for_previous_result
	{
	my( $self ) = @_;

	my $Config = $self->get_config;

	my $dist = $self->get_dist_info( 'filename' );

	( my $basename = basename( $dist ) ) =~ s/\.(tgz|tar\.gz|zip)$//;

	my $yml_dir        = catfile( $Config->report_dir, "meta"        );
	my $yml_error_dir  = catfile( $Config->report_dir, "meta-errors" );

	my $yml_path       = catfile( $yml_dir,       "$basename.yml" );
	my $yml_error_path = catfile( $yml_error_dir, "$basename.yml" );

	if( my @path = grep { -e } ( $yml_path, $yml_error_path ) )
		{
		$logger->debug( "Found run output for $basename in $path[0]. Skipping...\n" );
		return;
		}

	return $basename;
	}

sub _add_run_info
	{
	my( $self, $info ) = @_;

	my $Config = $self->get_config;

	return unless eval { $info->can( 'set_run_info' ) };

	$info->set_run_info( $_, $Config->get( $_ ) )
		foreach ( $Config->directives );

	$info->set_run_info( 'uuid', $Config->UUID );

	$info->set_run_info( 'child_pid',  $$ );
	$info->set_run_info( 'parent_pid', getppid );

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
