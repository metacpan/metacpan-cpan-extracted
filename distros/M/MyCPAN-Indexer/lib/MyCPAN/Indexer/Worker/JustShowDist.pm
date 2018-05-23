package MyCPAN::Indexer::Worker::JustShowDist;
use strict;
use warnings;

use parent qw(MyCPAN::Indexer::Worker);
use vars qw($VERSION $logger);
$VERSION = '1.282';

use File::Basename qw(basename);
use Log::Log4perl;

=encoding utf8

=head1 NAME

MyCPAN::Indexer::Worker::JustShowDist - Do nothing except show what the task is

=head1 SYNOPSIS

Use this in backpan_indexer.pl by specifying it as the queue class:

	# in backpan_indexer.config
	worker_class  MyCPAN::Indexer::Worker::JustShowDist

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

sub get_task
	{
	my( $self ) = @_;

	my $config  = $self->get_config;

	my $indexer = $self->get_coordinator->get_component( 'indexer' );
	my $coordinator = $self->get_coordinator;

	$logger->debug( "Worker class is " . __PACKAGE__ );
	$logger->debug( "Indexer class is " . $indexer->class );

	my $child_task = sub {
		my $dist = shift;

		my $dist_basename = basename( $dist );

		my $basename = $coordinator->get_reporter->check_for_previous_successful_result( $dist );

		my $previous_error_basename = $coordinator->get_reporter->check_for_previous_error_result( $dist ) || '';
		$logger->debug( "Found error report for $dist_basename" ) if $previous_error_basename;

		if( $previous_error_basename and ! $config->retry_errors )
			{
			$logger->debug( "By config, will NOT retry $dist_basename" ) if $previous_error_basename;
			}
		elsif( $previous_error_basename and $config->retry_errors )
			{
			$logger->debug( "By config, will retry $dist_basename" ) if $previous_error_basename;
			}

		my $info = bless {
			dist_info => {
				dist_path     => $dist,
				dist_basename => $dist_basename
				},
			skipped => 1,
			}, $indexer->class unless $basename;

		$info;
		};

	$coordinator->set_note( 'child_task', $child_task );

	1;
	}

=back

=head1 SEE ALSO

MyCPAN::Indexer::Worker, MyCPAN::Indexer::Tutorial

=head1 SOURCE AVAILABILITY

This code is in Github:

	git://github.com/briandfoy/mycpan-indexer.git

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2010-2018, brian d foy <bdfoy@cpan.org>. All rights reserved.

You may redistribute this under the terms of the Artistic License 2.0.

=cut

1;
