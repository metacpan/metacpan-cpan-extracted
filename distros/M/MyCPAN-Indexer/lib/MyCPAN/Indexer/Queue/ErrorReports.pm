package MyCPAN::Indexer::Queue::ErrorReports;
use strict;
use warnings;

use parent qw(MyCPAN::Indexer::Queue);
use vars qw($VERSION $logger);
$VERSION = '1.282';

use File::Find;
use Log::Log4perl;
use YAML qw(LoadFile);

BEGIN {
	$logger = Log::Log4perl->get_logger( 'Queue' );
	}

=encoding utf8

=head1 NAME

MyCPAN::Indexer::Queue::ErrorReports - Try to index distributions with error reports

=head1 SYNOPSIS

Use this in backpan_indexer.pl by specifying it as the queue class:

	# in backpan_indexer.config
	queue_class  MyCPAN::Indexer::Queue::ErrorReports

=head1 DESCRIPTION

This class returns a list of Perl distributions for the BackPAN
indexer to process. It selects the distributions that had previous
indexing errors by extracting the distribution path from the error
report. If the distribution isn't in the same place it was during
the original indexing, it won't be in the queue.

=head2 Methods

=over 4

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

=cut

sub _get_file_list
	{
	my( $self ) = @_;

	my @dirs = $self->get_coordinator->get_component( 'reporter' )->get_error_report_dir;

	$logger->debug( "Taking dists from [@dirs]" );
	my( $wanted, $reporter ) =
		File::Find::Closures::find_by_regex( qr/\.(?:yml)$/ );

	$logger->debug( "Running File::Find" );
	find( $wanted, @dirs );

	my @files = $reporter->();
	$logger->debug( "Found " . @files . " error reports" );

	my @queue;
	foreach my $file ( @files )
		{
		$logger->debug( "Trying to read $file" );
		my $yaml = LoadFile( $file );
		my $dist_file = $yaml->{dist_info}{dist_file};
		$logger->debug( "Dist file is $dist_file" );
		if( -e $dist_file )
			{
			push @queue, $dist_file;
			}
		else
			{
			$logger->error( "Could not find $dist_file" );
			}
		}

	$" = "\n";
	print "@queue\n"; exit;
	return \@queue;
	}

1;

=back


=head1 SEE ALSO

MyCPAN::Indexer, MyCPAN::Indexer::Tutorial, MyCPAN::Indexer::Queue

=head1 SOURCE AVAILABILITY

This code is in Github:

	git://github.com/briandfoy/mycpan-indexer.git

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2008-2018, brian d foy <bdfoy@cpan.org>. All rights reserved.

You may redistribute this under the terms of the Artistic License 2.0.

=cut
